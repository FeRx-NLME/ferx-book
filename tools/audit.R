#!/usr/bin/env Rscript
# Audit the book source against the pinned ferx build (runs locally and in CI).
#
# Hard checks (non-zero exit on failure):
#   pin        _variables.yml ferx_r_sha == render.yml FERX_R_SHA (and the
#              installed package's RemoteSha, when pak recorded one)
#   calls      every ferx_*() / check_*() call is a pinned export
#   examples   every ferx_example("x") name exists in the pinned registry
#   eval       every `eval: false` chunk carries `#| eval-reason:`
#   output     no hand-written knitr output (`#>` lines) in the source
#   links      no links to retired ferx-nlme.github.io pages
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
if (requireNamespace("ferx", quietly = TRUE)) {
  remote <- utils::packageDescription("ferx")$RemoteSha
  if (!is.null(remote) && !startsWith(pin$ferx_r_sha, remote) && !startsWith(remote, pin$ferx_r_sha)) {
    note("pin", sprintf("installed ferx RemoteSha %s != pinned %s", remote, pin$ferx_r_sha))
  }
}

# ---- per-file checks ------------------------------------------------------------
banned <- "\\b(NONMEM|Monolix|nlmixr2?|PsN|Pumas|Pharmpy|pyDarwin|Phoenix\\s*NLME|NLMIXED|WinBUGS|Stan)\\b"
strip_urls <- function(x) gsub("https?://[^ )>\"']+", "", x)

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
  for (i in grep("ferx-nlme\\.github\\.io/(model-dsl|learn|examples)/", lines)) note("links", sprintf("%s:%d: retired site link", f, i))
  for (i in grep(banned, strip_urls(lines), ignore.case = TRUE)) note("ferx-only", sprintf("%s:%d: %s", f, i, trimws(lines[i])))
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
