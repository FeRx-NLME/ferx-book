#!/usr/bin/env Rscript
# Step 0.5: time the heavy Part II tools on the bundled configs, to set render
# budgets (PLAN.md §7 Step 0.5 / D6). Output: tools/out/time-thread.txt

suppressMessages(library(ferx))
out <- character()
time_it <- function(label, expr) {
  t0 <- Sys.time()
  res <- tryCatch({ force(expr); "OK" }, error = function(e) paste("ERROR:", conditionMessage(e)))
  line <- sprintf("%-45s %8.1fs  %s", label, as.numeric(difftime(Sys.time(), t0, units = "secs")),
                  gsub("\\s+", " ", substr(res, 1, 300)))
  message(line)
  out <<- c(out, line)
}
td <- function(x) file.path(tempdir(), x)

base <- ferx_example("two_cpt_oral_base")
cov <- ferx_example("two_cpt_oral_cov")
warf <- ferx_example("warfarin")
trans <- ferx_example("one_cpt_transit")

time_it("covsearch: two_cpt_oral_base $search", ferx_covsearch(config = base$search, directory = td("cs"), progress = FALSE))
time_it("modelsearch: warfarin $search", ferx_modelsearch(config = warf$search, directory = td("ms"), progress = FALSE))
time_it("ruvsearch: one_cpt_transit $search", ferx_ruvsearch(config = trans$search, directory = td("rs"), progress = FALSE))
time_it("bootstrap two_cpt_oral_cov samples=50", ferx_bootstrap(cov$model, cov$data, samples = 50, seed = 1, directory = td("b50"), progress = FALSE, verbose = FALSE))
time_it("sir two_cpt_oral_cov", ferx_sir(ferx_fit(cov$model, cov$data, verbose = FALSE), verbose = FALSE))
time_it("bayes two_cpt_oral_cov", ferx_fit(cov$model, cov$data, method = "bayes", verbose = FALSE))
time_it("npde two_cpt_oral_cov nsim=200", ferx_calc_npde(ferx_fit(cov$model, cov$data, verbose = FALSE), nsim = 200, seed = 1))
time_it("gam_screen two_cpt_oral_base", ferx_gam_screen(ferx_fit(base$model, base$data, verbose = FALSE)))
time_it("allometry two_cpt_oral_base", ferx_allometry(base$model, base$data, directory = td("al")))

dir.create("tools/out", showWarnings = FALSE)
writeLines(out, "tools/out/time-thread.txt")
