#!/usr/bin/env Rscript
# Build tools/features.csv: the closed list of user-facing ferx features the
# book must cover, generated ONLY from the pinned sources:
#   * the installed ferx R package (must be the ferx_r_sha in _variables.yml)
#   * ferx-core at ferx_core_sha (read with `git show`, never the working tree)
#
# Run locally after every pin bump; commit the CSV. tools/audit.R (which also
# runs in CI) checks the book against it. Chapter assignments live separately
# in tools/homes.csv so regenerating this file never loses them.
#
# Usage: Rscript tools/inventory.R [path/to/ferx-core]

args <- commandArgs(trailingOnly = TRUE)
core_dir <- if (length(args) >= 1) args[1] else "../ferx-core"

pin <- yaml::read_yaml("_variables.yml")
suppressMessages(library(ferx))

git_show <- function(path) {
  out <- system2("git", c("-C", core_dir, "show", paste0(pin$ferx_core_sha, ":", path)),
                 stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) stop("git show failed for ", path, ": ", paste(out, collapse = "\n"))
  out
}

rows <- list()
add <- function(kind, name, parent = "", detail = "") {
  rows[[length(rows) + 1]] <<- data.frame(kind = kind, name = name, parent = parent,
                                          detail = detail, stringsAsFactors = FALSE)
}

# ---- exports and their arguments --------------------------------------------
exports <- sort(getNamespaceExports("ferx"))
exports <- exports[!startsWith(exports, ".")]
for (fn in exports) {
  add("export", fn)
  f <- get(fn, envir = asNamespace("ferx"))
  if (is.function(f)) {
    for (a in setdiff(names(formals(f)), "...")) add("argument", a, parent = fn)
  }
}

# ---- S3 methods ---------------------------------------------------------------
s3 <- getNamespaceInfo("ferx", "S3methods")
for (i in seq_len(nrow(s3))) {
  add("s3method", paste0(s3[i, 1], ".", s3[i, 2]), parent = s3[i, 1], detail = s3[i, 2])
}

# ---- bundled examples and search configs -----------------------------------------
for (ex in ferx_example()) add("example", ex)
search_dir <- system.file("examples", "search", package = "ferx")
for (f in sort(list.files(search_dir, pattern = "\\.ferxsearch$"))) {
  add("searchfile", sub("\\.ferxsearch$", "", f))
}

# ---- ferx_fit(settings = ) keys: ferx-core apply_fit_option() match arms ----------
parser <- git_show("src/parser/model_parser.rs")
start <- grep("^pub fn apply_fit_option", parser)[1]
end <- start + which(parser[(start + 1):length(parser)] == "}")[1]
body <- parser[start:end]
arms <- grep('^        "[a-z0-9_]+"(\\s*\\|\\s*"[a-z0-9_]+")*\\s*=>', body, value = TRUE)
# Keys with a dedicated ferx_fit() argument are rejected inside settings by the
# ferx-r glue (src/rust/src/lib.rs RESERVED); they are covered as arguments.
reserved <- c("method", "covariance", "verbose", "bloq_method", "bloq", "threads",
              "sir", "gradient", "gradient_method")
for (arm in arms) {
  lhs <- sub("=>.*$", "", arm)
  keys <- regmatches(lhs, gregexpr('"[a-z0-9_]+"', lhs))[[1]]
  keys <- gsub('"', "", keys)
  if (any(keys %in% reserved)) next
  add("setting", keys[1], parent = "ferx_fit",
      detail = if (length(keys) > 1) paste("aliases:", paste(keys[-1], collapse = " ")) else "")
}

# ---- DSL blocks: BLOCK_REGISTRY ----------------------------------------------------
reg_start <- grep("^const BLOCK_REGISTRY", parser)[1]
reg_end <- reg_start + which(parser[(reg_start + 1):length(parser)] == "];")[1]
for (line in parser[reg_start:reg_end]) {
  m <- regmatches(line, regexec('\\("([a-z_]+)", BlockForm::[A-Za-z]+, (None|Some\\("([a-z]+)"\\))\\)', line))[[1]]
  if (length(m)) add("dsl_block", m[2], detail = if (nzchar(m[4])) paste("feature:", m[4]) else "")
}

# ---- reserved data columns: DATA_BLOCK_ROLES -------------------------------------
roles_start <- grep("^const DATA_BLOCK_ROLES", parser)[1]
roles_txt <- paste(parser[roles_start:(roles_start + 4)], collapse = " ")
roles_txt <- sub("\\];.*$", "", roles_txt)
for (r in gsub('"', "", regmatches(roles_txt, gregexpr('"[a-z0-9_]+"', roles_txt))[[1]])) {
  add("data_column", toupper(r))
}

# ---- fit object slots: names() of a real fit on the pinned build -------------------
ex <- ferx_example("warfarin")
fit <- suppressMessages(ferx_fit(ex$model, ex$data, verbose = FALSE))
for (s in names(fit)) add("fit_slot", s, parent = "ferx_fit")

features <- do.call(rbind, rows)
features <- features[!duplicated(features[c("kind", "name", "parent")]), ]
write.csv(features, "tools/features.csv", row.names = FALSE)

counts <- table(features$kind)
message("ferx ", as.character(packageVersion("ferx")), " / ferx-core ", pin$ferx_core_sha_short)
print(counts)
