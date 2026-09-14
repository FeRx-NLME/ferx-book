#!/usr/bin/env Rscript
# Generate chapters/25-reference.qmd: the function, option and example index.
#
# Sources, all tied to the pinned build:
#   - tools/features.csv (inventory) and tools/homes.csv (chapter of each row);
#   - the installed ferx package's Rd pages (function titles, fit slot descriptions);
#   - tools/settings-docs.csv (values and defaults of settings);
#   - ferx-core docs/maturity.qmd at ferx_core_sha (read with `git show`).
# The chapter is written as static markdown so that tools/audit.R can check it
# like any other chapter. Regenerate it after a pin bump; do not edit it by hand.
#
# Usage: LANG=en_US.UTF-8 Rscript tools/make-reference.R [path/to/ferx-core]
# (a UTF-8 locale is required, or non-ASCII characters in help pages become "?")

args <- commandArgs(trailingOnly = TRUE)
core_dir <- if (length(args) >= 1) args[1] else "../ferx-core"
pin <- yaml::read_yaml("_variables.yml")
suppressMessages(library(ferx))
source("tools/pin-core.R")
core_dir <- require_ferx_core(core_dir, pin$ferx_core_sha)
if (!l10n_info()$`UTF-8`) stop("run in a UTF-8 locale, e.g. LANG=en_US.UTF-8")
stopifnot(identical(as.character(packageVersion("ferx")), pin$ferx_r_version))

features <- read.csv("tools/features.csv", stringsAsFactors = FALSE)
homes <- read.csv("tools/homes.csv", stringsAsFactors = FALSE)
inv <- merge(features, homes, by = c("kind", "name", "parent"), all.x = TRUE)
settings_docs <- read.csv("tools/settings-docs.csv", stringsAsFactors = FALSE)
# settings-docs.R escapes pipes for markdown; md_table() escapes again, so undo it here
# and keep every cell as raw text until it is written.
settings_docs[] <- lapply(settings_docs, function(x) if (is.character(x)) gsub("\\\\\\|", "|", x) else x)

# ---- chapter links ------------------------------------------------------------------
chapter_ids <- list()
for (f in list.files("chapters", pattern = "^[0-9]{2}-.*\\.qmd$", full.names = TRUE)) {
  # Search the whole file, not its first few lines: front matter (e.g. `aliases:` for a
  # redirected page) pushes the heading down, and a missed id renders as `@NA`.
  heading <- grep("^# .*\\{#sec-[a-z-]+\\}", readLines(f), value = TRUE)[1]
  if (is.na(heading)) stop("no `# Title {#sec-...}` heading in ", f)
  chapter_ids[[sub("\\.qmd$", "", basename(f))]] <- sub(".*\\{#(sec-[a-z-]+)\\}.*", "\\1", heading)
}
chapter_link <- function(home) {
  vapply(home, function(h) if (is.na(h) || !nzchar(h)) "" else if (h == "index") "Preface" else
    paste0("@", chapter_ids[[h]]), character(1))
}

# ---- Rd helpers -----------------------------------------------------------------------
banned <- "\\b(NONMEM|Monolix|nlmixr2?|PsN|Pumas|Pharmpy|pyDarwin|Phoenix|NLMIXED|WinBUGS|Stan|Xpose4?)\\b"
db <- tools::Rd_db("ferx")
rd_text <- function(x) paste(unlist(lapply(x, function(e) if (is.list(e)) rd_text(e) else as.character(e))), collapse = "")
rd_tag <- function(x) attr(x, "Rd_tag") %||% ""
first_sentence <- function(x) {
  x <- gsub("\\s+", " ", trimws(x))
  x <- gsub("\\s*\\([^()]*\\b(NONMEM|Monolix|nlmixr2?|Pharmpy|Xpose4?)\\b[^()]*\\)", "", x, ignore.case = TRUE)
  # Same for a parenthetical aside naming an engine-internal identifier such as
  # read_nonmem_csv(), where the underscore hides the word boundary. The aside can
  # itself contain `fn()` calls, so allow one level of nested parentheses.
  inner <- "(?:[^()]|\\([^()]*\\))*"
  x <- gsub(paste0("\\s*\\(", inner, "(NONMEM|Monolix|nlmixr|Pharmpy)", inner, "\\)"),
            "", x, ignore.case = TRUE, perl = TRUE)
  # A parenthetical that translates another tool's control record is a comparison.
  x <- gsub("\\s*\\(`\\$[A-Z]+`[^)]*\\)", "", x)
  # Links in ferx-core docs are relative to ferx-core, so they cannot survive the move;
  # keep the link text only.
  x <- gsub("\\[([^]]+)\\]\\([^)]*\\)", "\\1", x)
  protected <- gsub("\\b(e\\.g|i\\.e|vs|approx|cf)\\.", "\\1<DOT>", x)
  sentences <- gsub("<DOT>", ".", unlist(strsplit(protected, "(?<=[.!?])\\s+(?=[A-Z`(*])", perl = TRUE)))
  sentences <- sentences[!grepl(banned, sentences, ignore.case = TRUE)]
  if (!length(sentences)) return("")
  out <- sentences[1]
  # A short opener ("Infusion rate.", "Integer.") carries no information on its own:
  # take the next sentence too, which is where the convention or the range lives.
  if (nchar(out) < 80 && length(sentences) > 1) out <- paste(out, sentences[2])
  # ferx-r's roxygen for cov_matrix has "params ? params" (a lost multiplication sign).
  out <- sub("(params) \\? (params)", "\\1 × \\2", out)
  out
}
# Help-page titles that name other software lose that word (ferx-only rule).
clean_title <- function(x) {
  x <- gsub("\\b(NONMEM|Monolix|nlmixr2?|Pharmpy|Xpose4?)([- ](style|format(ted)?))?\\s*", "", x, ignore.case = TRUE, perl = TRUE)
  x <- gsub("\\s+", " ", trimws(x))
  paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
}
alias_title <- list()
for (rd in db) {
  tags <- vapply(rd, rd_tag, "")
  title <- gsub("\\s+", " ", trimws(rd_text(rd[[which(tags == "\\title")[1]]])))
  for (a in which(tags == "\\alias")) alias_title[[trimws(rd_text(rd[[a]]))]] <- clean_title(title)
}
value_items <- list()
walk_value <- function(x) {
  if (!is.list(x)) return(invisible())
  if (identical(rd_tag(x), "\\item") && length(x) == 2) {
    head <- trimws(rd_text(x[[1]]))
    for (k in trimws(strsplit(head, ",")[[1]])) value_items[[k]] <<- rd_text(x[[2]])
  }
  for (e in x) walk_value(e)
}
fit_rd <- db[["ferx_fit.Rd"]]
walk_value(fit_rd[[which(vapply(fit_rd, rd_tag, "") == "\\value")]])

md_table <- function(df) {
  # Cells hold raw text: escape pipes here, once, rather than at each call site.
  esc <- function(x) gsub("\\|", "\\\\|", gsub("\n", " ", as.character(x)))
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(esc(r), collapse = " | "), " |")), "")
}
code <- function(x) paste0("`", x, "`")

# ---- ferx-core doc tables -------------------------------------------------------------
# Split one markdown table row into cells, ignoring pipes inside `code spans`.
split_row <- function(line) {
  # A backslash-escaped pipe is content, not a separator. Hide it while splitting.
  line <- gsub("\\\\\\|", "\001", line)
  chars <- strsplit(line, "")[[1]]; cells <- character(); cur <- ""; in_code <- FALSE
  for (ch in chars) {
    if (ch == "`") in_code <- !in_code
    if (ch == "|" && !in_code) { cells <- c(cells, cur); cur <- "" } else cur <- paste0(cur, ch)
  }
  gsub("\001", "|", trimws(c(cells, cur)[-1]))
}
core_doc <- function(path) {
  txt <- system2("git", c("-C", core_dir, "show", paste0(pin$ferx_core_sha, ":docs/", path)),
                 stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(txt, "status"))) {
    stop("git show ", pin$ferx_core_sha_short, ":docs/", path, " failed in '", core_dir, "':\n  ",
         paste(txt, collapse = "\n  "), call. = FALSE)
  }
  txt
}
# Every pipe table in a doc, as a character matrix carrying its own header names.
# Anchoring on the header is what keeps a column selection meaningful: several ferx-core
# pages hold more than one table whose first cell is a code span, and the same key can
# appear in two of them with different meanings.
core_tables <- function(lines) {
  is_sep <- grepl("^\\|[-: |]+\\|?\\s*$", lines)
  tabs <- list(); i <- 1L
  while (i <= length(lines)) {
    if (grepl("^\\|", lines[i]) && i + 1L <= length(lines) && is_sep[i + 1L]) {
      hdr <- split_row(lines[i]); j <- i + 2L; body <- list()
      while (j <= length(lines) && grepl("^\\|", lines[j]) && !is_sep[j]) {
        body[[length(body) + 1L]] <- split_row(lines[j]); j <- j + 1L
      }
      if (length(body)) {
        m <- do.call(rbind, lapply(body, function(x) {
          length(x) <- length(hdr); x[is.na(x)] <- ""; x
        }))
        colnames(m) <- hdr
        tabs[[length(tabs) + 1L]] <- m
      }
      i <- j
    } else i <- i + 1L
  }
  tabs
}
core_key <- function(x) gsub("`", "", x)
# A description cell, reduced to its first sentence and stripped of other software.
desc_cell <- function(x) vapply(x, first_sentence, "")
# Fail loudly rather than emitting a table of blanks.
# Values of `value_col` for `keys`, read from whichever tables carry both named columns.
# Stops rather than guessing when the columns are gone or two tables disagree.
lookup <- function(tabs, keys, key_col, value_col, what) {
  has <- function(m, p) any(grepl(p, colnames(m)))
  hit <- Filter(function(m) has(m, key_col) && has(m, value_col), tabs)
  if (!length(hit)) {
    stop("no ferx-core table at the pin has both a '", key_col, "' and a '", value_col,
         "' column for ", what, "; the documentation layout changed", call. = FALSE)
  }
  k <- unlist(lapply(hit, function(m) core_key(m[, grep(key_col, colnames(m))[1]])))
  v <- unlist(lapply(hit, function(m) m[, grep(value_col, colnames(m))[1]]))
  keep <- k %in% keys
  k <- k[keep]; v <- v[keep]
  clash <- unique(k[duplicated(k) & !duplicated(paste(k, v))])
  if (length(clash)) {
    stop("ferx-core gives conflicting '", value_col, "' values for ", what, ": ",
         paste(clash, collapse = ", "), " at the pin", call. = FALSE)
  }
  m <- setNames(v, k)
  if (!any(keys %in% names(m))) {
    stop("none of the ", what, " keys matched the ferx-core '", key_col, "' column at the pin",
         call. = FALSE)
  }
  out <- unname(m[keys]); out[is.na(out)] <- ""
  out
}

# ---- sections -----------------------------------------------------------------------
out <- c(
  "# Function, option and example index {#sec-reference}",
  "",
  "<!-- Generated by tools/make-reference.R from the pinned build. Do not edit by hand. -->",
  "",
  "This chapter lists every ferx-r function, setting, model file block, data column, bundled example, warning category and fit object slot in the pinned build ({{< var ferx_r_sha_short >}}), with the chapter that covers it. It is generated from the book's feature inventory, the package's help pages and the ferx-core documentation of the pinned engine.",
  "")

# Functions
ex <- inv[inv$kind == "export", ]
ex <- ex[order(ex$name), ]
# Arguments as `name`, or `name = default` when the default is a constant.
default_label <- function(d) {
  if (identical(d, quote(expr = ))) return(NA_character_)
  if (is.null(d)) return("NULL")
  if (is.atomic(d) && length(d) == 1 && !is.na(d)) return(deparse(d))
  NA_character_
}
formals_of <- function(fn) {
  f <- try(formals(get(fn, envir = asNamespace("ferx"))), silent = TRUE)
  if (inherits(f, "try-error")) NULL else f
}
args_of <- function(fn) {
  a <- features$name[features$kind == "argument" & features$parent == fn]
  if (!length(a)) return("")
  f <- formals_of(fn)
  labels <- vapply(a, function(one) {
    if (is.null(f) || !one %in% names(f)) return(code(one))
    d <- default_label(f[[one]])
    if (is.na(d)) code(one) else code(paste0(one, " = ", d))
  }, "")
  paste(labels, collapse = ", ")
}
fun_tab <- data.frame(
  Function = paste0(code(paste0(ex$name, "()"))),
  Description = vapply(ex$name, function(n) alias_title[[n]] %||% "", ""),
  Arguments = vapply(ex$name, args_of, ""),
  Chapter = chapter_link(ex$home), check.names = FALSE)
s3 <- inv[inv$kind == "s3method", ]
s3 <- s3[order(s3$name), ]
out <- c(out, "## Functions", "",
  "Help pages: `?name`. Function reference on the web: [ferx-r reference](https://ferx-nlme.github.io/ferx-r/reference/).", "",
  md_table(fun_tab),
  "### S3 methods", "",
  md_table(data.frame(Method = code(s3$name), Chapter = chapter_link(s3$home), check.names = FALSE)))

# Settings
st <- inv[inv$kind == "setting", ]
st <- st[order(st$name), ]
st <- merge(st, settings_docs, by.x = "name", by.y = "key", all.x = TRUE)
st[is.na(st)] <- ""
out <- c(out, "## Fit settings", "",
  "Keys for `ferx_fit(settings = list(...))` and the `[fit_options]` block. The chapter column points at the section that uses the key; the ferx-core [fit options](https://ferx-nlme.github.io/ferx-core/model-file/fit-options.html) page gives the full semantics. A blank *Values* cell means the key takes a free value (a number, a name or a list) rather than a fixed set; a blank *Meaning* means the pinned engine documents the key only in terms of other software, which this book does not quote.", "",
  md_table(data.frame(Setting = code(st$name), Values = st$values, Default = st$default,
                      Meaning = desc_cell(st$description), Chapter = chapter_link(st$home),
                      check.names = FALSE)))

# Model file blocks
block_pages <- c(
  parameters = "model-file/parameters", individual_parameters = "model-file/individual-parameters",
  structural_model = "model-file/structural-model", odes = "model-file/ode-models",
  error_model = "model-file/error-model", fit_options = "model-file/fit-options",
  derived = "model-file/derived", output = "model-file/output", scaling = "model-file/scaling",
  covariates = "model-file/covariates", covariate_model = "model-file/covariate-model",
  covariate_nn = "model-file/covariate-nn", diffusion = "model-file/diffusion",
  event_model = "model-file/event-model", binary_model = "model-file/categorical",
  markov_model = "model-file/markov-model", adaptive_dosing = "model-file/adaptive-dosing",
  data = "model-file/data", data_selection = "model-file/data-selection",
  simulation = "model-file/simulation", initial_conditions = "model-file/initial-conditions",
  mixture = "estimation/mixture")
core_files <- system2("git", c("-C", core_dir, "ls-tree", "-r", "--name-only", pin$ferx_core_sha, "docs"),
                      stdout = TRUE, stderr = TRUE)
if (!is.null(attr(core_files, "status"))) {
  stop("git ls-tree ", pin$ferx_core_sha_short, ":docs failed in '", core_dir, "':\n  ",
       paste(core_files, collapse = "\n  "), call. = FALSE)
}
bl <- inv[inv$kind == "dsl_block", ]
bl <- bl[order(bl$name), ]
missing_pages <- setdiff(paste0("docs/", block_pages[bl$name], ".qmd"), core_files)
if (length(missing_pages)) stop("ferx-core pages not found at the pin: ", paste(missing_pages, collapse = ", "))
block_tabs <- core_tables(core_doc("model-file/index.qmd"))
# A block that takes an instance name is listed as `[covariate_nn NAME]` upstream.
block_named <- unlist(lapply(Filter(function(m) any(grepl("^Block", colnames(m))), block_tabs),
                             function(m) core_key(m[, grep("^Block", colnames(m))[1]])))
block_keys <- vapply(bl$name, function(n) {
  plain <- paste0("[", n, "]")
  if (plain %in% block_named) return(plain)
  named <- grep(paste0("^\\[", n, " [A-Z]+\\]$"), block_named, value = TRUE)
  if (length(named)) named[1] else plain
}, "")
out <- c(out, "## Model file blocks", "",
  "The blocks a `.ferx` model file can contain. *Required* and *Purpose* are the ferx-core block overview at the pinned engine, and are blank for a block that overview does not list; the chapter column covers those. Block names are closed-world, so a header outside this table is an error.", "",
  md_table(data.frame(Block = code(block_keys),
                      Required = lookup(block_tabs, block_keys, "^Block", "^Required", "model file block"),
                      Purpose = desc_cell(lookup(block_tabs, block_keys, "^Block", "^Purpose", "model file block")),
                      Chapter = chapter_link(bl$home),
                      `ferx-core page` = sprintf("[%s](https://ferx-nlme.github.io/ferx-core/%s.html)",
                                                 basename(block_pages[bl$name]), block_pages[bl$name]),
                      check.names = FALSE)))

# Data columns
dc <- inv[inv$kind == "data_column", ]
# data-format.qmd uses two table shapes: Column|Type|Description and
# Column|Type|Default|Description. The description is the last filled cell of a row.
dc_tabs <- core_tables(core_doc("data-format.qmd"))
out <- c(out, "## Data columns", "",
  "Columns the ferx data format recognises. *Type* and *Meaning* are taken from the ferx-core [data format](https://ferx-nlme.github.io/ferx-core/data-format.html) page at the pinned engine, and are blank for the columns that page does not list; the chapter column covers those.", "",
  md_table(data.frame(Column = code(dc$name),
                      Type = lookup(dc_tabs, dc$name, "^Column", "^Type", "data column"),
                      Meaning = desc_cell(lookup(dc_tabs, dc$name, "^Column", "^Description", "data column")),
                      Chapter = chapter_link(dc$home), check.names = FALSE)))

# Examples and search files
eg <- inv[inv$kind == "example", ]
eg <- eg[order(eg$name), ]
sf <- inv[inv$kind == "searchfile", ]
out <- c(out, "## Bundled examples", "",
  "Every example is available with `ferx_example()` and its name, which returns the paths of its model and data (and `$search` for a search configuration).", "",
  md_table(data.frame(Example = code(eg$name), Chapter = chapter_link(eg$home), check.names = FALSE)),
  "### Search configurations", "",
  md_table(data.frame(`Example with $search` = code(sf$name), Chapter = chapter_link(sf$home), check.names = FALSE)))

# Warning categories
wc <- inv[inv$kind == "warning_code", ]
wc <- wc[order(wc$name), ]
warn_tabs <- core_tables(core_doc("warnings.qmd"))
out <- c(out, "## Warning categories", "",
  "Categories of `ferx_get_warnings(fit, as_df = TRUE)$category`, collected by a fit that ran, with the severity and meaning ferx-core gives them at the pinned engine. **Critical** means the result is untrustworthy as it stands; **Warning** means it stands with a caveat; **Info** implies no action. A model that never ran fails with a check report code instead, listed under *Check report codes* below. Each chapter's *Warnings you may see here* section covers the ones it meets, and the ferx-core [warnings](https://ferx-nlme.github.io/ferx-core/warnings.html) page describes them all.", "",
  md_table(data.frame(Category = code(wc$name),
                      Severity = lookup(warn_tabs, wc$name, "^Code", "^Severity", "warning category"),
                      Meaning = desc_cell(lookup(warn_tabs, wc$name, "^Code", "^Flags", "warning category")),
                      Chapter = chapter_link(wc$home), check.names = FALSE)))

# Check report codes (E_* and W_*). Not in features.csv, and a different channel from the
# warning categories above: these come from the parser and the pre-fit checks.
err_tabs <- Filter(function(m) all(c("Code", "Severity", "Meaning") %in% colnames(m)),
                   core_tables(core_doc("file-formats/check-report.qmd")))
if (!length(err_tabs)) {
  stop("no Code/Severity/Meaning table in the ferx-core check report at the pin", call. = FALSE)
}
err_rows <- do.call(rbind, lapply(err_tabs, function(m) m[, c("Code", "Severity", "Meaning")]))
err_rows <- err_rows[grepl("^`[EW]_[A-Z_]+`$", err_rows[, "Code"]), , drop = FALSE]
if (!nrow(err_rows)) stop("no E_/W_ codes parsed from the ferx-core check report at the pin", call. = FALSE)
err_rows <- err_rows[order(core_key(err_rows[, "Code"])), , drop = FALSE]
err_tab <- data.frame(Code = code(core_key(err_rows[, "Code"])), Severity = err_rows[, "Severity"],
                      Meaning = desc_cell(err_rows[, "Meaning"]), check.names = FALSE)
err_tab <- err_tab[nzchar(err_tab$Meaning), ]
n_err <- sum(startsWith(err_tab$Code, "`E_"))
out <- c(out, "## Check report codes", "",
  sprintf("Stable identifiers from the model file parser and the pre-fit checks: `E_*` stops the model from running, `W_*` is a check-time note that does not. `ferx_model_validate()` returns them in `$diagnostics`, with the severity, block and line (@sec-model-files). A refused `ferx_fit()` raises the same message but without the code, so validate the model when you want the identifier rather than the prose. These are a different channel from the *Warning categories* above, which a completed fit collects in `fit$warnings`. The %d codes below (%d errors, %d warnings) are the check report of the pinned engine, one sentence each; the ferx-core [check report](https://ferx-nlme.github.io/ferx-core/file-formats/check-report.html) page gives the full text.",
          nrow(err_tab), n_err, nrow(err_tab) - n_err), "",
  md_table(err_tab))

# Fit slots
fs <- inv[inv$kind == "fit_slot", ]
fs <- fs[order(tolower(fs$name)), ]
out <- c(out, "## Fit object slots", "",
  "Elements of the list `ferx_fit()` returns, for a fit of the warfarin example. Some slots are `NULL` unless the corresponding step or model feature is used. Descriptions are the first sentence of the entry in `?ferx_fit`, where it has one.", "",
  md_table(data.frame(Slot = code(fs$name),
                      Description = vapply(fs$name, function(n) if (is.null(value_items[[n]])) "" else first_sentence(value_items[[n]]), ""),
                      check.names = FALSE)))

# Not available from R
na_tab <- data.frame(
  Feature = c("Variational inference as `ferx_fit(method = \"vi\")`",
              "`[markov_model]` (continuous-time Markov endpoints)",
              "Global search (`globalsearch`)",
              "`[simulation]` block",
              "`[dynamics_nn]` (neural-network ODE terms)",
              "Hand-written `[covariate_model]` relations, repeated time-to-event, fixed-rate infusions into the central compartment",
              "`[mixture]` models, modelled infusion rate or duration (`RATE = -1`, `-2`)",
              "VI's ELBO and per-subject posterior summaries"),
  `Status at the pinned build` = c(
    "The `method` argument rejects it; `method = vi` in `[fit_options]` runs",
    "Rejected at parse time: ferx-r does not build the engine's `markov` feature",
    "ferx-core command line only",
    "Read by the ferx-core command line only; ferx-r's simulation functions need a dataset",
    "Not implemented (design only)",
    "Fit from R, but no bundled ferx-r example",
    "No bundled example",
    "Not on the R fit object"),
  `Where to look` = c("@sec-estimation-methods",
                      "[Markov models](https://ferx-nlme.github.io/ferx-core/model-file/markov-model.html)",
                      "@sec-model-selection",
                      "@sec-simulation",
                      "[Neural networks](https://ferx-nlme.github.io/ferx-core/model-file/neural-networks.html)",
                      "@sec-covariates, @sec-time-to-event, @sec-dosing",
                      "@sec-variability, [data format](https://ferx-nlme.github.io/ferx-core/data-format.html)",
                      "[Variational inference](https://ferx-nlme.github.io/ferx-core/estimation/vi.html)"),
  check.names = FALSE)
out <- c(out, "## Not available from R", "",
  "Features documented for ferx-core that the pinned ferx-r build cannot run, or runs only partly:", "",
  md_table(na_tab))

# Maturity
mat <- system2("git", c("-C", core_dir, "show", paste0(pin$ferx_core_sha, ":docs/maturity.qmd")), stdout = TRUE)
rows <- grep("^\\| .* \\| \\*\\*(stable|beta|experimental|alpha)\\*\\* \\|", mat, value = TRUE)
mat_rows <- do.call(rbind, lapply(rows, function(r) {
  cells <- split_row(r)
  page <- sub(".*\\]\\(([^)]+)\\.qmd[^)]*\\).*", "\\1", cells[3])
  label <- sub(".*\\[([^]]+)\\].*", "\\1", cells[3])
  data.frame(Feature = cells[1], Maturity = gsub("\\*", "", cells[2]),
             `ferx-core page` = if (grepl("\\.qmd", cells[3])) sprintf("[%s](https://ferx-nlme.github.io/ferx-core/%s.html)", label, page) else "",
             check.names = FALSE)
}))
mat_rows <- mat_rows[!grepl(banned, mat_rows$Feature, ignore.case = TRUE), ]
out <- c(out, "## Feature maturity", "",
  "The maturity label of each ferx-core feature at the pinned engine (ferx-core {{< var ferx_core_sha_short >}}). **stable** features are well tested across datasets and estimation options; **beta** features are stable in limited testing; **experimental** features have been tested on a few examples and may change. See the ferx-core [feature maturity](https://ferx-nlme.github.io/ferx-core/maturity.html) page.", "",
  md_table(mat_rows))

writeLines(out, "chapters/25-reference.qmd")
cat(sprintf("wrote chapters/25-reference.qmd (%d lines)\n", length(out)))
