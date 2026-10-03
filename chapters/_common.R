# Shared setup sourced by every chapter:
#   ```{r}
#   #| label: setup
#   #| include: false
#   #| cache: false   # never cache: knitr does not replay side effects
#   source(if (file.exists("_common.R")) "_common.R" else "chapters/_common.R")
#   ```
# Helpers defined here are named book_*() so tools/audit.R never mistakes them
# for ferx exports. None of them may appear in code a reader sees: chunks that
# call one are `echo: false`.
#
# This file attaches no packages. Each chapter loads ferx, dplyr and ggplot2 in
# a visible chunk, so a reader running the chapter from a fresh session has
# everything the code uses, and a chunk that relies on a package the chapter
# never loads fails the render instead of passing on this file's behalf.

# Renders must run in a UTF-8 locale (gt and ggplot2 labels use non-ASCII
# characters); a bare shell with no LANG gives R the "C" locale.
if (!isTRUE(l10n_info()$`UTF-8`)) {
  for (loc in c("C.UTF-8", "en_US.UTF-8")) {
    if (nzchar(suppressWarnings(Sys.setlocale("LC_CTYPE", loc)))) break
  }
}

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

ggplot2::theme_set(ggplot2::theme_minimal(base_size = 12))

# Code autolinks: point ferx functions at the site's reference rather than the
# URL in the installed package's DESCRIPTION (downlit appends /reference).
# Set here as well as in .Rprofile, because chapters may render from chapters/.
options(downlit.local_packages = c(ferx = "https://ferx-nlme.org"))

# Inline `r x` numbers: plain notation (knitr otherwise prints 11610 as
# 1.161^{4}). Only while the inline hook formats a value: a global
# options(scipen = 100) also reformats every printed result, so the book's
# output would differ from what a reader's session prints.
local({
  inline_default <- knitr::knit_hooks$get("inline")
  knitr::knit_hooks$set(inline = function(x) {
    old <- options(scipen = 100)
    on.exit(options(old))
    inline_default(x)
  })
})

# Options table for `settings` keys. Values, defaults and descriptions come from
# tools/settings-docs.csv, generated from the pinned ferx-core fit-options docs
# and ?ferx_fit (tools/settings-docs.R) -- never typed by hand.
book_settings_docs <- function() {
  path <- if (file.exists("tools/settings-docs.csv")) "tools/settings-docs.csv" else
    file.path("..", "tools", "settings-docs.csv")
  read.csv(path, stringsAsFactors = FALSE)
}

book_settings_table <- function(keys, caption = NULL) {
  docs <- book_settings_docs()
  missing <- setdiff(keys, docs$key)
  if (length(missing)) stop("not a settings key on the pinned build: ", paste(missing, collapse = ", "))
  rows <- docs[match(keys, docs$key), ]
  rows$description[!nzchar(rows$description)] <- "See `?ferx_fit` and the ferx-core fit options page."
  tab <- data.frame(Setting = paste0("`", rows$key, "`"), Values = rows$values,
                    Default = rows$default, Description = rows$description)
  gt::gt(tab, caption = caption) |>
    gt::fmt_markdown(columns = gt::everything()) |>
    gt::cols_width(Setting ~ gt::pct(22), Values ~ gt::pct(18), Default ~ gt::pct(12)) |>
    gt::tab_options(table.font.size = gt::px(13), table.width = gt::pct(100))
}

# Default of one `settings` key, for inline use in prose, from the same generated
# file as book_settings_table() (never typed by hand). Backticks are stripped.
book_setting_default <- function(key) {
  docs <- book_settings_docs()
  if (!key %in% docs$key) stop("not a settings key on the pinned build: ", key)
  gsub("`", "", docs$default[docs$key == key])
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
