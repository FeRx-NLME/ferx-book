#!/usr/bin/env Rscript
# Build tools/settings-docs.csv: allowed values, default and a short description
# for every `settings` key in tools/features.csv. Sources, pinned:
#   1. ferx-core docs/model-file/fit-options.qmd at ferx_core_sha (the tables
#      `| key | values | default | description |`), read with `git show`;
#   2. for keys that page does not tabulate, the `settings` item of the
#      installed ferx_fit() Rd (description only).
# Chapters render options tables from this file with book_settings_table(), so
# no default or description is typed by hand. Sentences naming other NLME
# software are dropped (ferx-only rule).
#
# Usage: Rscript tools/settings-docs.R [path/to/ferx-core]

args <- commandArgs(trailingOnly = TRUE)
core_dir <- if (length(args) >= 1) args[1] else "../ferx-core"
pin <- yaml::read_yaml("_variables.yml")
suppressMessages(library(ferx))
source("tools/pin-core.R")

# Fatal, not a warning: reading no fit-options page used to leave every
# ferx-core-sourced description blank in a file this script then overwrote.
core_dir <- require_ferx_core(core_dir, pin$ferx_core_sha)
doc <- git_show_at(core_dir, pin$ferx_core_sha, "docs/model-file/fit-options.qmd")

# Split a markdown table row on `|`, ignoring pipes inside backticks.
split_row <- function(line) {
  chars <- strsplit(line, "")[[1]]
  cells <- character(); cur <- ""; in_code <- FALSE
  for (ch in chars) {
    if (ch == "`") in_code <- !in_code
    if (ch == "|" && !in_code) { cells <- c(cells, cur); cur <- "" } else cur <- paste0(cur, ch)
  }
  cells <- c(cells, cur)
  trimws(cells[-c(1, length(cells))])
}

banned <- "\\b(NONMEM|Monolix|nlmixr2?|PsN|Pumas|Pharmpy|pyDarwin|Phoenix)\\b"
clean_desc <- function(x) {
  x <- gsub("\\[([^]]+)\\]\\([^)]*\\)", "\\1", x)          # markdown links -> text
  x <- gsub("\\s*\\(#[0-9]+\\)", "", x)                    # issue refs
  x <- gsub("<br\\s*/?>", " ", x)
  x <- gsub("\\s+", " ", x)
  # Remove parentheticals that name other software before splitting.
  x <- gsub("\\s*\\([^()]*\\b(NONMEM|Monolix|nlmixr2?|PsN|Pumas|Pharmpy|pyDarwin|Phoenix)\\b[^()]*\\)", "", x, ignore.case = TRUE)
  # Sentence split that does not break on "e.g." / "i.e." / "vs.".
  protected <- gsub("\\b(e\\.g|i\\.e|vs|approx|cf)\\.", "\\1<DOT>", x)
  sentences <- gsub("<DOT>", ".", unlist(strsplit(protected, "(?<=[.!?])\\s+(?=[A-Z`(*])", perl = TRUE)))
  ok <- !grepl(banned, sentences, ignore.case = TRUE)
  if (!length(sentences) || !ok[1]) return("")
  out <- sentences[1]
  # Add the original second sentence only when the first is very short and the
  # second survives the filter (never splice non-adjacent sentences).
  if (nchar(out) < 60 && length(sentences) > 1 && ok[2]) out <- paste(out, sentences[2])
  out
}

rows <- list()
for (line in grep("^\\| `[a-z][a-z0-9_]*` \\|", doc, value = TRUE)) {
  cells <- split_row(line)
  key <- gsub("`", "", cells[1])
  if (length(cells) >= 4) {
    rows[[key]] <- data.frame(key = key, values = cells[2], default = cells[3],
                              description = clean_desc(paste(cells[4:length(cells)], collapse = " ")),
                              source = "ferx-core fit-options", stringsAsFactors = FALSE)
  } else if (length(cells) == 3 && is.null(rows[[key]])) {
    rows[[key]] <- data.frame(key = key, values = "", default = cells[2],
                              description = clean_desc(cells[3]),
                              source = "ferx-core fit-options", stringsAsFactors = FALSE)
  }
}

# Fallback: ferx_fit() Rd settings items.
rd <- tools::Rd_db("ferx")[["ferx_fit.Rd"]]
rd_text <- function(x) paste(unlist(lapply(x, function(e) if (is.list(e)) rd_text(e) else as.character(e))), collapse = "")
rd_items <- list()
walk <- function(x) {
  if (!is.list(x)) return(invisible())
  if (identical(attr(x, "Rd_tag"), "\\item") && length(x) == 2) {
    head <- rd_text(x[[1]])
    for (k in regmatches(head, gregexpr("[a-z][a-z0-9_]+", head))[[1]]) {
      rd_items[[k]] <<- gsub("\\s+", " ", rd_text(x[[2]]))
    }
  }
  for (e in x) walk(e)
}
walk(rd)

features <- read.csv("tools/features.csv", stringsAsFactors = FALSE)
keys <- features$name[features$kind == "setting"]
out <- do.call(rbind, lapply(keys, function(k) {
  if (!is.null(rows[[k]]) && nzchar(rows[[k]]$description)) return(rows[[k]])
  if (!is.null(rows[[k]]) && !is.null(rd_items[[k]])) {
    r <- rows[[k]]; r$description <- clean_desc(rd_items[[k]]); r$source <- "ferx-core fit-options + ?ferx_fit"
    return(r)
  }
  if (!is.null(rows[[k]])) return(rows[[k]])
  if (!is.null(rd_items[[k]])) {
    return(data.frame(key = k, values = "", default = "", description = clean_desc(rd_items[[k]]),
                      source = "?ferx_fit", stringsAsFactors = FALSE))
  }
  data.frame(key = k, values = "", default = "", description = "", source = "undocumented",
             stringsAsFactors = FALSE)
}))
# The fit-options page is the source of most descriptions. None of them means
# the page was read but not parsed - a silent way to blank the whole file.
from_core <- sum(startsWith(out$source, "ferx-core"))
if (from_core == 0L) {
  stop("no setting description came from ferx-core's fit-options page at ",
       pin$ferx_core_sha_short, "; refusing to overwrite tools/settings-docs.csv",
       call. = FALSE)
}
write_csv_atomic(out, "tools/settings-docs.csv")
print(table(out$source))
if (any(out$source == "undocumented")) message("undocumented: ", paste(out$key[out$source == "undocumented"], collapse = ", "))
