# Shared setup sourced by every chapter:
#   ```{r}
#   #| label: setup
#   #| include: false
#   #| cache: false   # never cache: knitr does not replay side effects
#   source(if (file.exists("_common.R")) "_common.R" else "chapters/_common.R")
#   ```
# Helpers defined here are named book_*() so tools/audit.R never mistakes them
# for ferx exports.

# Renders must run in a UTF-8 locale (gt and ggplot2 labels use non-ASCII
# characters); a bare shell with no LANG gives R the "C" locale.
if (!isTRUE(l10n_info()$`UTF-8`)) {
  for (loc in c("C.UTF-8", "en_US.UTF-8")) {
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", loc)))) break
  }
}

suppressPackageStartupMessages({
  library(ferx)
  library(ggplot2)
  library(dplyr)
})

book_pin <- yaml::read_yaml(
  if (file.exists("_variables.yml")) "_variables.yml" else file.path("..", "_variables.yml")
)

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  fig.width = 7,
  fig.height = 4.5,
  dpi = 120,
  fig.align = "center",
  # Invalidate every cached chunk when the pinned ferx-r build changes; the
  # knitr cache key otherwise ignores the package version.
  cache.extra = book_pin$ferx_r_sha
)

theme_set(theme_minimal(base_size = 12))

# Scratch directory for tools that write run directories (bootstrap, search,
# FREM, allometry). Never write into the book tree.
book_tempdir <- function(name) {
  path <- file.path(tempdir(), name)
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

# Workflow banner for Part II chapters. Call from a chunk with
# `#| echo: false` and `#| output: asis`.
book_stage_banner <- function(active) {
  stages <- c("DATA", "MODEL", "ESTIMATE", "EVALUATE", "SIMULATE", "REPORT")
  stopifnot(active %in% stages)
  seps <- c(" &rarr; ", " &rarr; ", " &#8644; ", " &rarr; ", " &rarr; ", "")
  items <- vapply(seq_along(stages), function(i) {
    cls <- if (stages[i] == active) "stage active" else "stage"
    sprintf('<span class="%s">%s</span>%s', cls, stages[i],
            if (nzchar(seps[i])) sprintf('<span class="sep">%s</span>', seps[i]) else "")
  }, character(1))
  cat(sprintf('<div class="workflow-banner" role="note" aria-label="Workflow stage: %s">%s</div>\n',
              active, paste(items, collapse = "")))
}
