#!/usr/bin/env Rscript
# Step 0.6: verify availability from R of features the plan marks "verify".
# Uses ferx-core example models/data at the pinned SHA (extracted with git show
# into a temp dir) for features ferx-r does not bundle. Results go to
# tools/out/verify-availability.txt; conclusions are copied into PLAN.md §3.
#
# Usage: Rscript tools/verify-availability.R [path/to/ferx-core]

args <- commandArgs(trailingOnly = TRUE)
core_dir <- if (length(args) >= 1) args[1] else "../ferx-core"
pin <- yaml::read_yaml("_variables.yml")
suppressMessages(library(ferx))

tmp <- file.path(tempdir(), "ferx-core-pin")
dir.create(file.path(tmp, "examples"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(tmp, "data"), recursive = TRUE, showWarnings = FALSE)
extract <- function(path) {
  dest <- file.path(tmp, path)
  out <- system2("git", c("-C", core_dir, "show", paste0(pin$ferx_core_sha, ":", path)), stdout = dest, stderr = FALSE)
  if (!identical(out, 0L)) stop("cannot extract ", path)
  dest
}

run <- function(label, expr) {
  t0 <- Sys.time()
  res <- tryCatch({ force(expr); "OK" }, error = function(e) paste("ERROR:", conditionMessage(e)))
  line <- sprintf("%-42s %-6.1fs %s", label, as.numeric(difftime(Sys.time(), t0, units = "secs")), gsub("\\s+", " ", substr(res, 1, 300)))
  cat(line, "\n")
  line
}

ex <- ferx_example("warfarin")
fit <- ferx_fit(ex$model, ex$data, verbose = FALSE)
out <- c(
  sprintf("ferx %s, pinned ferx-r %s / ferx-core %s", packageVersion("ferx"), pin$ferx_r_sha_short, pin$ferx_core_sha_short),
  sprintf("fit slots: %s", paste(names(fit), collapse = " ")),
  run("method = 'vi' via ferx_fit", ferx_fit(ex$model, ex$data, method = "vi", verbose = FALSE)),
  run("[covariate_model] two_cpt_oral_covmodel", {
    m <- extract("examples/two_cpt_oral_covmodel.ferx")
    ferx_fit(m, ferx_example("two_cpt_oral_cov")$data, verbose = FALSE)
  }),
  run("repeated TTE rtte_exponential", {
    m <- extract("examples/rtte_exponential.ferx"); d <- extract("data/rtte_exponential.csv")
    ferx_fit(m, d, verbose = FALSE)
  }),
  run("RATE column dose_rate", {
    m <- extract("examples/dose_rate.ferx"); d <- extract("data/dose_rate.csv")
    ferx_fit(m, d, verbose = FALSE)
  }),
  run("infusion one_cpt_infusion", {
    m <- extract("examples/one_cpt_infusion.ferx"); d <- extract("data/one_cpt_infusion.csv")
    ferx_fit(m, d, verbose = FALSE)
  }),
  run("warfarin_dcm fits (nn feature built)", {
    e <- ferx_example("warfarin_dcm"); f <- ferx_fit(e$model, e$data, verbose = FALSE)
    stopifnot(!is.null(f$neural_networks))
  }),
  run("ferx_fit_async + ferx_stop", {
    job <- ferx_fit_async(ex$model, ex$data)
    Sys.sleep(0.5)
    ferx_stop(job)
  })
)

# Determinism of resampling tools with a fixed seed.
base <- ferx_example("two_cpt_oral_base")
boot <- function() ferx_bootstrap(base$model, base$data, samples = 5, seed = 1,
                                   directory = tempfile("boot"), progress = FALSE, verbose = FALSE)
out <- c(out, run("bootstrap seed-deterministic (5 samples x2)", {
  b1 <- boot(); b2 <- boot()
  s1 <- capture.output(print(b1)); s2 <- capture.output(print(b2))
  if (!identical(s1, s2)) stop("bootstrap print output differs between identical seeded runs")
}))

dir.create("tools/out", showWarnings = FALSE)
writeLines(out, "tools/out/verify-availability.txt")
