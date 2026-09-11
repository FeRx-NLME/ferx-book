#!/usr/bin/env Rscript
# Smoke-run every bundled ferx example against the installed (pinned) build.
#
# Each example runs in a fresh R process (callr) with a timeout, so a crash or a
# hang in one example cannot take the others down. Adaptive-dosing examples are
# simulated with ferx_simulate_adaptive(); every other example is fitted with
# ferx_fit(model, data) using the model file's own [fit_options].
#
# Output: tools/example-status.csv
#   name, kind, ok, converged, ofv, method, n_warnings, seconds, error
#
# Usage: Rscript tools/smoke-examples.R [timeout_seconds] [name ...]

args <- commandArgs(trailingOnly = TRUE)
timeout <- if (length(args) >= 1) as.numeric(args[1]) else 1800
only <- if (length(args) >= 2) args[-1] else NULL

suppressMessages(library(ferx))
names_all <- ferx_example()
if (!is.null(only)) names_all <- intersect(names_all, only)

run_one <- function(name) {
  suppressMessages(library(ferx))
  ex <- ferx_example(name)
  model_txt <- paste(readLines(ex$model, warn = FALSE), collapse = "\n")
  adaptive <- grepl("\\[adaptive_dosing\\]", model_txt)
  t0 <- Sys.time()
  if (adaptive) {
    res <- ferx_simulate_adaptive(ex$model, ex$data, n_sim = 2L, seed = 1L)
    list(kind = "adaptive", converged = NA, ofv = NA_real_, method = NA_character_,
         n_warnings = NA_integer_,
         seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  } else {
    fit <- ferx_fit(ex$model, ex$data, verbose = FALSE)
    w <- tryCatch(nrow(ferx_get_warnings(fit, as_df = TRUE)), error = function(e) NA_integer_)
    list(kind = "fit",
         converged = if (!is.null(fit$converged)) isTRUE(fit$converged) else NA,
         ofv = if (!is.null(fit$ofv)) as.numeric(fit$ofv) else NA_real_,
         method = if (!is.null(fit$method)) paste(fit$method, collapse = ">") else NA_character_,
         n_warnings = w,
         seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  }
}

rows <- lapply(names_all, function(name) {
  message(sprintf("[%s] %s ...", format(Sys.time(), "%H:%M:%S"), name))
  t0 <- Sys.time()
  out <- tryCatch(
    callr::r(run_one, args = list(name = name), timeout = timeout),
    error = function(e) e
  )
  if (inherits(out, "error")) {
    msg <- conditionMessage(out)
    if (!is.null(out$parent)) msg <- paste(msg, conditionMessage(out$parent))
    data.frame(name = name, kind = NA, ok = FALSE, converged = NA, ofv = NA,
               method = NA, n_warnings = NA,
               seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
               error = gsub("[\r\n]+", " ", substr(msg, 1, 500)))
  } else {
    data.frame(name = name, kind = out$kind, ok = TRUE, converged = out$converged,
               ofv = out$ofv, method = out$method, n_warnings = out$n_warnings,
               seconds = round(out$seconds, 1), error = "")
  }
})

status <- do.call(rbind, rows)
dir.create("tools", showWarnings = FALSE)
out_file <- if (is.null(only)) "tools/example-status.csv" else "tools/out/example-status-partial.csv"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
write.csv(status, out_file, row.names = FALSE)
message(sprintf("wrote %s: %d ok / %d total, %.0f s", out_file,
                sum(status$ok), nrow(status), sum(status$seconds)))
