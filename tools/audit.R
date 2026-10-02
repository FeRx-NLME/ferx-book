#!/usr/bin/env Rscript
# Audit the book source against the pinned ferx build (runs locally and in CI).
#
# Hard checks (non-zero exit on failure):
#   pin        _variables.yml ferx_r_sha == render.yml FERX_R_SHA, ferx_r_tag (if set)
#              resolves to ferx_r_sha on GitHub (and the
#              installed package's RemoteSha, when pak recorded one)
#   calls      every ferx_*() / check_*() call is a pinned export
#   examples   every ferx_example("x") name exists in the pinned registry
#   eval       every `eval: false` chunk carries `#| eval-reason:`
#   output     no hand-written knitr output (`#>` lines) in the source
#   links      no links to the old ferx-nlme.github.io host (the site moved to ferx-nlme.org)
#              and none to retired site sections (learn, examples)
#   ferx-only  no mentions of other NLME software outside URLs
# Coverage (report; hard only with --strict):
#   every row of tools/features.csv has a home chapter in tools/homes.csv and
#   its name occurs in that chapter's source.
#
# Usage: Rscript tools/audit.R [--strict] [--quiet] [--chapter=NN-slug]

args <- commandArgs(trailingOnly = TRUE)
strict <- "--strict" %in% args
quiet <- "--quiet" %in% args

fail <- character()
note <- function(check, msg) fail <<- c(fail, sprintf("[%s] %s", check, msg))

files <- c("index.qmd", sort(list.files("chapters", pattern = "^[^_].*\\.qmd$", full.names = TRUE)))
src <- setNames(lapply(files, readLines, warn = FALSE), files)

features <- read.csv("tools/features.csv", stringsAsFactors = FALSE)
exports <- features$name[features$kind == "export"]
examples <- features$name[features$kind == "example"]

# ---- pin --------------------------------------------------------------------------
pin <- yaml::read_yaml("_variables.yml")
wf <- readLines(".github/workflows/render.yml", warn = FALSE)
wf_sha <- sub('^\\s*FERX_R_SHA:\\s*"?([0-9a-f]+)"?.*$', "\\1", grep("FERX_R_SHA:", wf, value = TRUE))
if (!identical(wf_sha, pin$ferx_r_sha)) note("pin", sprintf("render.yml FERX_R_SHA (%s) != _variables.yml ferx_r_sha (%s)", paste(wf_sha, collapse = ","), pin$ferx_r_sha))
# ch01 offers ferx_r_tag as an install ref "that gives the same build", so the
# tag must resolve to the pinned commit. Checked on GitHub (CI has no ../ferx-r);
# without network the check is skipped and says so rather than passing silently.
if (!is.null(pin$ferx_r_tag)) {
  # Ask for the tag and its peeled form: an annotated tag's commit is the `^{}`
  # line, a lightweight tag has only the plain line. git's exit status tells an
  # unreachable remote (skip, say so) from a tag that does not exist (fail).
  tag_ref <- paste0("refs/tags/", pin$ferx_r_tag)
  ls <- tryCatch(suppressWarnings(system2("git", c("ls-remote", "https://github.com/FeRx-NLME/ferx-r.git",
                                               tag_ref, paste0(tag_ref, "^{}")),
                                          stdout = TRUE, stderr = FALSE)),
                 error = function(e) structure(character(0), status = 127L))
  status <- attr(ls, "status")
  if (!is.null(status) && status != 0) {
    cat("pin: could not reach GitHub to resolve ferx_r_tag", pin$ferx_r_tag, "(git status", status, "); tag check skipped\n")
  } else if (!length(ls)) {
    note("pin", sprintf("ferx_r_tag %s does not exist on FeRx-NLME/ferx-r - fix or remove ferx_r_tag", pin$ferx_r_tag))
  } else {
    peeled <- grep("\\^\\{\\}$", ls, value = TRUE)
    tag_sha <- sub("\\s.*$", "", if (length(peeled)) peeled[1] else ls[1])
    if (!identical(tag_sha, pin$ferx_r_sha)) {
      note("pin", sprintf("ferx_r_tag %s resolves to %s, not ferx_r_sha %s - update or remove ferx_r_tag",
                          pin$ferx_r_tag, tag_sha, pin$ferx_r_sha))
    }
  }
}
if (requireNamespace("ferx", quietly = TRUE)) {
  remote <- utils::packageDescription("ferx")$RemoteSha
  if (!is.null(remote) && !startsWith(pin$ferx_r_sha, remote) && !startsWith(remote, pin$ferx_r_sha)) {
    note("pin", sprintf("installed ferx RemoteSha %s != pinned %s", remote, pin$ferx_r_sha))
  }
}

# features.csv is the list every coverage number below is counted against, so a
# stale one makes the whole audit a statement about the wrong build. It has
# happened: an inventory run that could not reach ferx-core left the file
# untouched and this script still printed AUDIT OK. tools/inventory.R stamps the
# pin it ran at; refuse to grade anything else.
stamp_path <- "tools/features-pin.yml"
if (!file.exists(stamp_path)) {
  note("pin", paste0(stamp_path, " is missing - run tools/inventory.R, which records",
                     " the pin tools/features.csv was generated at"))
} else {
  stamp <- yaml::read_yaml(stamp_path)
  for (key in c("ferx_r_sha", "ferx_core_sha")) {
    # as.character on both sides: an all-digit sha is read back as a number.
    got <- if (is.null(stamp[[key]])) "<missing>" else as.character(stamp[[key]])
    if (!identical(got, as.character(pin[[key]]))) {
      note("pin", sprintf("features.csv was generated at %s %s, _variables.yml pins %s - re-run tools/inventory.R",
                          key, got, pin[[key]]))
    }
  }
}

# ---- per-file checks ------------------------------------------------------------
banned <- "\\b(NONMEM|Monolix|nlmixr2?|PsN|Pumas|Pharmpy|pyDarwin|Phoenix\\s*NLME|NLMIXED|WinBUGS|Stan)\\b"
# CLAUDE.md rule 6: another engine may be named in an analogy, never in a claim that
# ferx is better. A sentence naming one with comparative wording is flagged; whether
# a sentence that passes is an analogy is for review to judge.
comparative <- paste0("\\b(better|best|faster|fastest|quicker|slower|improv\\w*|outperform\\w*|superior|",
                      "inferior|beats?|more (accurate|robust|reliable|efficient|stable))\\b")
strip_urls <- function(x) gsub("https?://[^ )>\"']+", "", x)
claims_over <- function(line) {
  sentences <- strsplit(strip_urls(line), "(?<=[.!?])\\s+", perl = TRUE)[[1]]
  any(grepl(banned, sentences, ignore.case = TRUE) & grepl(comparative, sentences, ignore.case = TRUE))
}

# CLAUDE.md rule 8: reader code runs as shown. Returns the chunks of a file with their
# first line, label and whether the reader sees the code.
chunks_of <- function(lines) {
  starts <- grep("^\\s*```\\{r", lines)
  lapply(starts, function(s) {
    e <- s + 1
    while (e <= length(lines) && !grepl("^\\s*```\\s*$", lines[e])) e <- e + 1
    body <- if (e > s + 1) lines[(s + 1):(e - 1)] else character()
    header <- body[grepl("^\\s*#\\|", body)]
    list(start = s, body = body,
         label = sub("^\\s*#\\|\\s*label:\\s*", "", grep("^\\s*#\\|\\s*label:", header, value = TRUE)[1]),
         visible = !any(grepl("^\\s*#\\|\\s*(echo|include):\\s*(false|FALSE)", header)))
  })
}

for (f in files) {
  lines <- src[[f]]
  txt <- paste(lines, collapse = "\n")

  calls <- unique(regmatches(txt, gregexpr("\\b(ferx_[A-Za-z0-9_]+|check_[a-z_]+)(?=\\()", txt, perl = TRUE))[[1]])
  for (cl in setdiff(calls, exports)) note("calls", sprintf("%s: %s() is not a pinned export", f, cl))

  ex_used <- unique(gsub('ferx_example\\("|"\\)', "", regmatches(txt, gregexpr('ferx_example\\("[^"]+"\\)', txt))[[1]]))
  for (e in setdiff(ex_used, examples)) note("examples", sprintf("%s: ferx_example(\"%s\") not in pinned registry", f, e))

  # eval: false must be followed (within the chunk header) by an eval-reason.
  chunk_starts <- grep("^```\\{r", lines)
  for (s in chunk_starts) {
    j <- s + 1
    header <- character()
    while (j <= length(lines) && grepl("^#\\|", lines[j])) { header <- c(header, lines[j]); j <- j + 1 }
    if (any(grepl("^#\\|\\s*eval:\\s*(false|FALSE)", header)) && !any(grepl("^#\\|\\s*eval-reason:", header))) {
      note("eval", sprintf("%s:%d: eval: false without #| eval-reason:", f, s))
    }
  }
  for (i in grep("^\\s*#>", lines)) note("output", sprintf("%s:%d: hand-written output line", f, i))
  for (i in grep("https?://ferx-nlme\\.github\\.io/", lines)) note("links", sprintf("%s:%d: old site host (use ferx-nlme.org)", f, i))
  for (i in grep("ferx-nlme\\.org/(learn|examples)/", lines)) note("links", sprintf("%s:%d: retired site link", f, i))
  for (i in grep(banned, strip_urls(lines), ignore.case = TRUE)) {
    if (claims_over(lines[i])) note("ferx-only", sprintf("%s:%d: names another engine next to comparative wording: %s",
                                                         f, i, trimws(lines[i])))
  }

  chunks <- chunks_of(lines)
  for (ch in Filter(function(ch) ch$visible, chunks)) {
    for (k in grep("\\bbook_[a-z_]+\\(", ch$body)) {
      note("reader-code", sprintf("%s:%d: book helper in a visible chunk (hide it with echo: false)", f, ch$start + k))
    }
    for (k in grep("#.*\\b(the render|fail the render|render stops)\\b", ch$body)) {
      note("reader-code", sprintf("%s:%d: render-check comment in a visible chunk (move the check to an include: false chunk)",
                                  f, ch$start + k))
    }
  }
  chapter_no <- suppressWarnings(as.integer(sub("^chapters/(\\d+)-.*", "\\1", f)))
  if (!is.na(chapter_no) && chapter_no >= 2 && chapter_no <= 24) {
    packages <- Filter(function(ch) identical(ch$label, "packages") && ch$visible, chunks)
    loads <- if (length(packages)) packages[[1]]$body else character()
    for (pkg in c("ferx", "dplyr", "ggplot2")) {
      if (!any(grepl(sprintf("^library\\(%s\\)", pkg), loads))) {
        note("reader-code", sprintf("%s: no visible `packages` chunk loading %s", f, pkg))
      }
    }
  }
}

common <- readLines(file.path("chapters", "_common.R"), warn = FALSE)
for (i in grep("^\\s*(library|require|suppressPackageStartupMessages)\\(", common)) {
  note("reader-code", sprintf("chapters/_common.R:%d: attaches a package the reader's code would then rely on", i))
}

# ---- coverage ---------------------------------------------------------------------
homes_file <- "tools/homes.csv"
homes <- if (file.exists(homes_file)) read.csv(homes_file, stringsAsFactors = FALSE) else
  data.frame(kind = character(), name = character(), parent = character(), home = character())
cov <- merge(features, homes, by = c("kind", "name", "parent"), all.x = TRUE)
cov$home[is.na(cov$home)] <- ""

esc <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
covered <- function(kind, name, parent, detail, home) {
  if (!nzchar(home)) return(NA)
  hf <- if (home == "index") "index.qmd" else file.path("chapters", paste0(home, ".qmd"))
  if (!hf %in% names(src)) return(FALSE)
  # HTML comments never count as coverage (no hidden checklists).
  txt <- gsub("<!--.*?-->", "", paste(src[[hf]], collapse = "\n"), perl = TRUE)
  has <- function(p) grepl(p, txt, perl = TRUE)
  switch(kind,
    export      = has(paste0("\\b", esc(name), "\\(")),
    # arguments and settings must be named explicitly: `name` or name = value
    argument    = has(paste0("\\b", esc(parent), "\\b")) && has(paste0("(`", esc(name), "`|\\b", esc(name), "\\s*=)")),
    s3method    = has(paste0("\\b", esc(parent), "\\b")) && has(paste0("\\b", esc(detail), "\\b")),
    example     = has(paste0('ferx_example\\("', esc(name), '"\\)')),
    searchfile  = has(paste0('ferx_example\\("', esc(name), '"\\)')) && has("\\$search\\b"),
    # settings: `key`, key = value, or "key" (book_settings_table(c("key", ...)))
    setting     = has(paste0("(`", esc(name), "`|\\b", esc(name), "\\s*=|\"", esc(name), "\")")),
    dsl_block   = has(paste0("\\[", esc(name), "( [A-Za-z_]+)?\\]")),
    data_column = has(paste0("\\b", esc(name), "\\b")),
    warning_code = has(paste0("`", esc(name), "`")),
    has(paste0("\\b", esc(name), "\\b"))
  )
}
cov$covered <- mapply(covered, cov$kind, cov$name, cov$parent, cov$detail, cov$home)

summary_tab <- do.call(rbind, lapply(split(cov, cov$kind), function(d) data.frame(
  kind = d$kind[1], total = nrow(d), assigned = sum(nzchar(d$home)),
  covered = sum(d$covered %in% TRUE))))
if (!quiet) {
  cat("Coverage (features.csv vs homes.csv):\n")
  print(summary_tab, row.names = FALSE)
}
missing <- cov[!(cov$covered %in% TRUE), ]
chapter_arg <- sub("^--chapter=", "", grep("^--chapter=", args, value = TRUE))
if (length(chapter_arg)) {
  todo <- missing[missing$home == chapter_arg, c("kind", "name", "parent")]
  cat(sprintf("\n%s: %d uncovered feature rows\n", chapter_arg, nrow(todo)))
  if (nrow(todo)) print(todo[order(todo$kind, todo$parent, todo$name), ], row.names = FALSE)
}
if (nrow(missing) && !quiet) {
  dir.create("tools/out", showWarnings = FALSE)
  write.csv(missing[c("kind", "name", "parent", "home")], "tools/out/uncovered.csv", row.names = FALSE)
  cat(sprintf("%d uncovered rows -> tools/out/uncovered.csv\n", nrow(missing)))
}
if (strict && nrow(missing)) note("coverage", sprintf("%d feature rows unassigned or uncovered", nrow(missing)))

# ---- result -------------------------------------------------------------------------
if (length(fail)) {
  cat(sprintf("\nAUDIT FAILED: %d problem(s)\n", length(fail)))
  cat(paste0("  ", fail), sep = "\n")
  quit(status = 1)
}
cat("\nAUDIT OK\n")
