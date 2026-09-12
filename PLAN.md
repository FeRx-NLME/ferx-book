# PLAN.md — ferx-book v2: an analysis-workflow tutorial for ferx-r

Status: **Steps 0–5 done, Step 6.2–6.3 done** (PRs #16–#21 open, stacked into book/v2-workflow; owner merges). Part II + Part III + reference chapter written; audit --strict 672/672 covered. **Next: Step 6 (finalise)** (started 2026-09-11). Revision 2, after scrutiny
round 1 (§1b). Supersedes `PLAN-v1-archive.md`.

Model: [PKNCA book](https://humanpred.github.io/pknca-book/). This is a guided, fully
runnable book on **using ferx-r in an R modeling analysis**. Technical detail (DSL
grammar, estimator math, exhaustive option semantics) lives in the
[ferx-core docs](https://ferx-nlme.github.io/ferx-core/) and is linked, not copied.
The book is about ferx only: **no comparison text to other NLME software.**

---

## 1. Evaluation of the v1 plan

v1 got the approach right (PKNCA principles, one warfarin thread, a coverage map,
maturity callouts). What went wrong:

| # | Problem | Evidence (audit 2026-09-11) |
|---|---|---|
| 1 | **Stale baseline.** Written against ferx 0.1.6; ferx-r 0.2.0 renamed or removed ~15 functions with no aliases | ~12 evaluated chunks now error: `ferx_estimates`, `ferx_eta_cov`, `ferx_to_frem`, `ferx_selection`, `ferx_model_new`, `ferx_plot_trace` |
| 2 | **"Executed" never verified.** Global `cache: true` replays 0.1.6 output, so renders look green | 19 `*_cache/` dirs, May–June 2026 |
| 3 | **Organised by feature, not by analysis workflow.** No data-management chapter, no tables chapter, reporting is a stub | 04-fitting is a 675-line option dump |
| 4 | **Mostly not run.** 54 `eval:false` chunks, no reasons given; stale "not bundled" claims | ch 07, 12, 18, 20 almost entirely non-evaluated |
| 5 | **Wrong content** | `bloq_method="drop"` does not remove rows; `is_*` keys are rejected (now `imp_*`); invented DW/condition-number output; a `[bloq]` block that doesn't exist |
| 6 | **Coverage gaps** | 22 of 47 exports and 39 of 66 examples unused; no adaptive dosing, search, bootstrap, allometry, binary, joint PK-TTE, Bayes, Laplace |
| 7 | **No execution gates** | no clean-render check, so drift went unnoticed |

## 1b. Scrutiny round 1: defects found in revision 1 of this plan, now fixed

| # | Defect in revision 1 | Fix in revision 2 |
|---|---|---|
| S1 | **CI ignored.** `.github/workflows/render.yml` renders and deploys the book with `pak::pkg_install('FeRx-NLME/ferx-r')` (unpinned main HEAD). The "pin" was local only, so CI and readers get a different build | Step 0.3: pin CI to `@<sha>`; the installation chapter tells readers the same `@<sha>` |
| S2 | **Live site is frozen.** `main` chapters still use the removed names, and its last green CI run was 2026-06-21. Any push to `main` now fails | Any hotfix to `main` is out of scope. v2 replaces it; state this in the final PR |
| S3 | **Coverage only counted exports and examples.** ~90 `settings` keys, function arguments, DSL blocks, data columns and output columns were untracked, so "every option" couldn't be guaranteed | Step 0.6: machine-generated feature inventory from pinned sources; audit fails on any uncovered row (§6) |
| S4 | **Examples were listed but not run** | Every runnable example is executed (§5). Variants run in loops producing live comparison tables. Only examples that fail the smoke test are listed, with the smoke error |
| S5 | **Cross-chapter object reuse.** Ch 11 "reuses fits from 05–10", but Quarto renders each chapter in its own R session | Every chapter is self-contained; refits are cached |
| S6 | **Stage order inconsistent.** Banner said EVALUATE→SIMULATE, but chapters went 07 EVALUATE, 08 SIMULATE, 09–10 EVALUATE | Part II reordered to follow a real project (§5) |
| S7 | **Warfarin can't carry Part II.** 10 subjects, no covariate columns (`ID,TIME,DV,EVID,AMT,CMT,RATE,MDV`), so no covariate step and a meaningless bootstrap | Part II thread = `two_cpt_oral_base` → `two_cpt_oral_cov` (30 subjects, WT/CRCL, bundled `.ferxsearch`). Warfarin stays for the ch 02 tour. Verified in Step 0 (D6) |
| S8 | **Cache still unsafe.** The knitr cache key ignores the package version | `_common.R` sets `cache.extra` = pinned ferx SHA; CI renders with no cache |
| S9 | **Step 0 order would lose work.** Hygiene deleted files before the WIP snapshot commit | Branch and snapshot first (0.1), then hygiene |
| S10 | **Doc drift.** Linked ferx-core docs track engine main (16 commits past the pin) | Preface callout: ferx-core docs may describe newer engine features. Book prose is based on the pinned build only |
| S11 | **Comparison text.** Revision 1 had a "For NONMEM users" chapter and NONMEM-parity notes | Chapter dropped; audit bans other-software names (§2 rule 8) |
| S12 | **No PR slicing or render budget** | PRs into `book/v2-workflow` at each gate, with CI as the clean-render gate; per-chapter time budget from smoke timings (Step 0.5) |
| S13 | **No pilot of a non-standard chapter shape** | Step 2 also pilots ch 23 (adaptive dosing), which has no fit and 4 outputs |

---

## 2. Ground rules (non-negotiable)

1. **One pinned ferx-r build.** Local install, CI and reader install instructions all
   use the same commit. The preface prints version + commit.
2. **Every ferx call is real.** Only exports, arguments, settings keys and
   `ferx_example()` names present in the pinned build. Plain R (dplyr, ggplot2, gt)
   for plots and tables is fine. Nothing ferx-side is invented.
3. **Every chunk runs.**
   - `eval: false` needs `#| eval-reason:`.
   - It is allowed only for:
     - `ferx_xpose()` (xpose not a dependency, D2);
     - interactive-only job handling: `ferx_collect()`, `ferx_stop()`,
       `print`/`plot`/`$` on `ferx_job`. In knitr, `ferx_fit_async()` falls back to
       a synchronous fit (verified 0.6), so no job handle exists. Show the fallback
       executed; the job calls get the eval-reason;
     - an example that fails the smoke test (reason = the recorded error).
4. **No hand-written output.** Prose numbers use inline R. Tables of options,
   columns and slots are generated from live objects where possible (`names(fit)`,
   `names(sim)`, `formals()`).
5. **Done = clean render.** A green CI render (fresh environment, no cache) plus a
   green `tools/audit.R`.
6. **Self-contained chapters.** No object from another chapter.
7. **Not available from R? Say so and point elsewhere.** Never imply availability.
8. **ferx only.** No comparisons to or translations from other NLME software.
   - Describe the data format as "the ferx data format" and link ferx-core
     `data-format`.
   - Audit bans (case-insensitive, outside URLs): NONMEM, Monolix, nlmixr, PsN,
     Pumas, pyDarwin, Phoenix, NLME software names.
   - `ferx_xpose(backend = "xpose4")` is a ferx argument and is allowed.
9. **Link, don't copy.** Each chapter ends with a Reference callout (`?fn` +
   `https://ferx-nlme.github.io/ferx-core/<path>.html`). Never link to stale
   `ferx-nlme.github.io/model-dsl|learn|examples` pages.
10. **Report behaviour as it is.** If a fit doesn't converge or warns, show that
    honestly. Never tune settings to hide it without saying so.

---

## 3. Baseline facts (verified 2026-09-11)

**ferx-r**
- `origin/main` = `846aa4b`: 50 exports, 22 S3 methods, 66 examples, 4 `.ferxsearch`.
- ferx-core is locked at `8694824` in `src/rust/Cargo.lock`.
- Makevars builds `ci,nn,survival`; `lto = "thin"`.
- Installed "0.3.0" is a post-release snapshot lacking `ferx_coef`, `ferx_se`,
  `ferx_ruvsearch`. Not usable as the pin.
- Local `../ferx-r` is on `feat/sim-horizon-526` (0.1.6) with uncommitted files.
  Never install from it or touch it; use `git archive origin/main`.

**CI** (`.github/workflows/render.yml`)
- ubuntu, R 4.4, Rust stable, unpinned ferx-r, installs `vpc`.
- Dead `_freeze` cache step (config has `freeze: false`); stale `FERX_NO_AUTODIFF`.
- Last run ~8 min, 2026-06-21.

**Datasets** (subjects / key columns)

| Dataset | Subjects | Key columns |
|---|---|---|
| warfarin | 10 | base only |
| two_cpt_oral_cov | 30 | + WT, CRCL |
| warfarin_bloq | 10 | + CENS |
| warfarin_iov | 10 | + OCC |
| emax_pkpd | 3 | — |
| adaptive_tdm | 5 | — |
| tte_weibull | 30 | — |

**Local R packages:** ggplot2, dplyr, tidyr, knitr, gt, patchwork, survival,
rmarkdown present. xpose, vpc, npde, flextable absent.

**ferx-core docs:** live at `/ferx-core/<path>.html` (all sidebar pages 200). They
track engine main, ahead of the pin.

### Availability from R (the book claims only the left column)

| Available (pinned ferx-r) | Not available from R: mention + pointer |
|---|---|
| methods foce, focei, laplace (+`n_agq`), saem, gn, gn_hybrid, imp, impmap, bayes; chains | `vi`: the `method` argument rejects it, **but `method = vi` in `[fit_options]` runs from R** (corrected in Step 5: two_cpt_oral_base, 19 s, estimates ≈ FOCEI; `ofv` NaN unless `vi_final_ofv = laplace`). Covered in ch06; `vi_*` rows re-homed to ch06 |
| covsearch, modelsearch, ruvsearch, search config/space/coverage/results | iivsearch, iovsearch, amd, globalsearch (ferx-core CLI) |
| covariance step, SIR, bootstrap (**verified seed-deterministic**; only `seconds`/timing and the printed directory differ), bayes posterior, `ferx_simulate_with_uncertainty` | — |
| `ferx_simulate_adaptive` + `[adaptive_dosing]` | MAP-Bayesian dose individualisation (doesn't exist) |
| TTE (exp/Weibull/Gompertz/competing risks), joint PK-TTE, `ferx_predict_survival`, binary | `[markov_model]`/CTMM (feature not built) |
| built-in absorption inputs, per-route lag, analytic transit/IG | — |
| SDE, `[covariate_nn]` (**verified**: warfarin_dcm fits, 32 s) | `[dynamics_nn]` (design only) |
| compartment-free models, weighted kappa | `mbma_naproxen` (ferx-core only) |
| FREM (`ferx_model_to_frem`) | — |
| **Fits from R but no bundled ferx-r example** (verified 0.6 with ferx-core pin files): `[covariate_model]` (two_cpt_oral_covmodel, 0.7 s), repeated TTE (rtte_exponential, 0.5 s), fixed-rate infusions (dose_rate, one_cpt_infusion) | Can't be run in the book without bundling (rule 2) → **D4** |
| — | `[mixture]`, `RATE = -1/-2` modelled rate/duration: no example anywhere (ferx-core docs only) → mention + link |

**Other verified facts (0.6):**
- CWRES at the pin uses the new definition (ferx-core CHANGELOG Unreleased #1182).
- A warfarin `ferx_fit()` result has 108 slots (`tools/features.csv`, kind
  `fit_slot`).
- `ferx_fit(verbose = NULL)` is the default. Chapters pass `verbose = FALSE`
  unless showing the optimizer log; check the Rd for what `NULL` resolves to
  before describing it.

---

## 4. The workflow the book teaches

```
 DATA ─► MODEL ─► ESTIMATE ⇄ EVALUATE ─► SIMULATE ─► REPORT
                   └─ revise model ─┘
```

- Data management = DATA.
- Analysis = MODEL, ESTIMATE, EVALUATE (diagnostics, VPC, selection, uncertainty),
  SIMULATE.
- Outputs & reporting = REPORT.

Every Part II chapter opens with the banner, active stage bolded. Part III chapters
run the same loop compactly for one scenario.

**Chapter template:**
1. Where you are
2. The data
3. Minimal runnable call
4. Reading the result
5. Options that matter (the chapter's **home options table**: every option assigned
   to this chapter by the inventory, with default + one line + link)
6. Variants (live loop over bundled variants → comparison table)
7. Pitfalls (verified only), ending with **"Warnings you may see here"**:
   - the fit-warning `category` tokens whose home is this chapter
     (`tools/homes.csv`, kind `warning_code`);
   - for each: severity and what it flags (from ferx-core `warnings.qmd` at the
     pin), plus a link to `https://ferx-nlme.github.io/ferx-core/warnings.html#codes-<group>`;
   - show a warning live only when a bundled example in the chapter actually
     triggers it. Never build a broken model just to provoke one.
8. Summary → next
9. Reference callout (+ maturity callout if beta/experimental)

---

## 5. Target structure (25 chapters + preface)

Part II thread: **`two_cpt_oral_base` → `two_cpt_oral_cov`**. Confirm in Step 0; if
it's too slow or doesn't converge, fall back to warfarin and note it. **All 66
examples are placed and run**; each has one home chapter.

### Part I: Getting started

| Ch | Title | Content | Examples run |
|---|---|---|---|
| index | Preface | audience; workflow diagram; ferx-r vs ferx-core; pinned-build box; R deps; datasets | — |
| 01 | Installing ferx | `pak::pak("FeRx-NLME/ferx-r@<sha>")`, toolchain, verify install, threads, Ctrl-C | — |
| 02 | A complete analysis in one chapter | warfarin: data → model → fit → estimates → GOF → VPC → table → save; each section links to Part II | warfarin |

### Part II: The analysis workflow

| Ch | Stage | Title | Functions / features (home) | Examples run |
|---|---|---|---|---|
| 03 | DATA | Preparing and checking the analysis dataset | data format and reserved columns (table from inventory); exploratory plots; covariate summaries; `ferx_get_columns`; `ferx_apply_selection` (+`excluded`), `print.ferx_data`; `ferx_fit(ignore, accept, ignore_ids)`; `[data]`, `[data_selection]` | two_cpt_oral_cov (data), warfarin_data_selection |
| 04 | MODEL | Writing and managing model files | `ferx_model` (templates, `print.ferx_model`), `_show`, `_inspect`, `_validate`, `_get_section`, `_set_section`, `_edit` (eval-reason); DSL block map → ferx-core | two_cpt_oral_base |
| 05 | ESTIMATE | Initial estimates and a first fit | `ferx_inits_from_nca` (`print.ferx_inits`), `ferx_check_init`, `ferx_fit` core args, `print`/`summary.ferx_fit`, fit-object slots (live `names(fit)`), `ferx_coef`, `ferx_se`, `ferx_get_warnings`, `check_diagnostics` | (thread) |
| 06 | ESTIMATE | Estimation methods and controlling the fit | all methods + when to use; chains; `settings` run-control / optimizer / inner-loop / covariance groups; multi-start; `threads`; `ferx_fit_async`, `ferx_collect`, `ferx_stop`, `plot.ferx_job`, `print.ferx_job`, `$.ferx_job`; `ferx_trace`, `plot.ferx_fit`, `ferx_runlog`, `ferx_runlog_iters`, `ferx_conddist` (`print.ferx_conddist`) | warfarin_saem, mm_multistart |
| 07 | EVALUATE | Diagnosing the model | GOF from `fit$sdtab`; individual fits; ETA distributions, shrinkage, `fit$eta_cov`, `fit$cor_matrix`; `ferx_calc_npde` (+`npde_*` settings); `ferx_xpose` (eval-reason) | (thread) |
| 08 | EVALUATE | Simulation-based evaluation: VPC | `ferx_simulate` (`n_sim`, `seed`, `match`) for VPC; ggplot VPC (ferx provides simulations, not a VPC function) | (thread) |
| 09 | EVALUATE | Model development and selection | ΔOFV, AIC/BIC, `ferx_bic`, `check_strictness`; `ferx_search_config` / `_space` / `_coverage` / `_results` (+print methods); `ferx_modelsearch`, `ferx_covsearch`, `ferx_ruvsearch` (+print/summary); CLI-only tools pointer | warfarin `$search` (modelsearch), two_cpt_oral_base `$search` (covsearch → two_cpt_oral_cov), one_cpt_transit `$search` (ruvsearch) |
| 10 | EVALUATE | Parameter uncertainty of the final model | covariance settings, `ferx_covariance`; `ferx_sir` + inline `sir` (+`sir_*`); `ferx_bootstrap`, `ferx_bootstrap_summarize`, `print`/`plot.ferx_bootstrap`; `method="bayes"` (+`bayes_*`); CI comparison table | two_cpt_oral_cov |
| 11 | SIMULATE | Simulating scenarios | `ferx_predict`; design datasets (empty DV); alternative regimens / populations; `match` options; `ferx_simulate_with_uncertainty` | (thread) |
| 12 | REPORT | Tables and figures | parameter table (values as ferx reports them), run table, exposure table via `[derived]`/`[output]`, figure set | two_cpt_oral_derived |
| 13 | REPORT | Reproducibility and sharing | `ferx_save_fit` / `ferx_load_fit` (.fitrx), `ferx_fit(output, include_data)`, seeds, `checkpoint`, `sessionInfo` + ferx SHA, project layout, Quarto report skeleton | (thread) |

### Part III: Modeling scenarios, by category

Pattern: scenario → data → model (live `ferx_model_get_section`) → fit → key
diagnostic → simulate/output. Variants run in a loop.

| Cat | Ch | Title | Home features | Examples run |
|---|---|---|---|---|
| A General PK | 14 | Structural models: analytical and ODE | 1/2/3-cpt IV/oral; analytic↔ODE; `ode_template`; `ode_*` settings; TIME/TAD in `[odes]`; nonlinear elimination; pooled fits; `[scaling]` | one_cpt_iv, one_cpt_iv_ode, two_cpt_iv, two_cpt_iv_ode, three_cpt_iv, three_cpt_iv_ode, three_cpt_oral, three_cpt_oral_ode, warfarin_ode, two_cpt_oral_cov_ode, two_cpt_oral_cov_ode_template, warfarin_ode_time, mm_oral, one_cpt_iv_pooled, warfarin_scaled |
| A | 15 | Absorption and bioavailability | lag (ODE, per-route); `transit()`; analytic transit/IG; IG, biphasic IG, Weibull, zero-order, parallel/mixed/sequential; F (logit, analytic vs ODE) | warfarin_ode_lagtime, per_route_lag_absorption, transit_savic, transit_2cpt, one_cpt_transit, two_cpt_transit, igd_inverse_gaussian, one_cpt_ig, two_cpt_ig, biphasic_igd_absorption, weibull_absorption, zero_order_absorption, parallel_absorption, mixed_absorption, sequential_absorption, bioavailability, bioavailability_ode, warfarin_logit_f |
| A | 16 | Variability: random effects, residual error, IOV | transforms, mu-referencing (`mu_referencing`, `scale_params`); block omega; error models, LTBS, per-CMT; IOV (`iov_*`) | warfarin_block_omega, warfarin_additive_eta, warfarin_ltbs, warfarin_iov, warfarin_iov_saem, one_cpt_transit_iov |
| B Covariates | 17 | Covariate modeling toolbox | ETA-vs-covariate plots; `ferx_cov_screen`, `ferx_gam_screen`; if/else effects; `ferx_allometry` (+print); FREM `ferx_model_to_frem(output_dir = tempdir())` (+`frem_*`); covsearch recap → ch 09 | warfarin_if (+ two_cpt_oral_base/cov reused, refit) |
| C Dosing & data | 18 | Dosing regimens and exposure metrics | SS, ADDL/II, RATE/infusions, EVID resets, dosing into absorption cpt; `[derived]`/`[output]` | warfarin_ss, warfarin_addl, ss_absorption, infusion_absorption, warfarin_derived |
| C | 19 | Censored observations | `bloq_method` m3 vs drop (drop keeps rows at the limit); `ignore="CENS==1"`; CENS=-1 | warfarin_bloq |
| D Endpoints | 20 | PK/PD models | multi-endpoint per CMT, per-CMT error, derived PD readouts, compartment-free time-course | emax_pkpd, emax_timecourse, warfarin_derived_pkpd |
| D | 21 | Binary endpoints | `[binary_model]`, simulating binary outcomes | binary_logistic |
| D | 22 | Time-to-event | TTE data; hazards; competing risks; `ferx_predict_survival(model, data, times, fit)`; `ferx_simulate(horizon)`; KM overlay (survival); joint PK-TTE | tte_exponential, tte_weibull, tte_gompertz, tte_competing_risks, pktte_joint |
| E Adaptive dosing | 23 | Simulating adaptive dosing and TDM strategies | `[adaptive_dosing]` concepts; `ferx_simulate_adaptive(n_sim, seed, verify, max_decisions)`; `trajectories` / `doses` / `decisions` / `metrics`; target attainment; base regimen + loading; unsupported combinations; not MAP dosing | adaptive_tdm, adaptive_vanco_loading |
| F Experimental | 24 | Experimental features | `[diffusion]` SDE; `[covariate_nn]` (+`nn_*`) | warfarin_sde, warfarin_dcm |

Example count: 02:1, 03:2, 04:1, 06:2, 12:1, 14:15, 15:18, 16:6, 17:1, 18:5, 19:1,
20:3, 21:1, 22:5, 23:2, 24:2 = **66**.

### Part IV: Reference

| Ch | Title | Content |
|---|---|---|
| 25 | Function, option and example index | Generated from `tools/features.csv`: every export, S3 method, argument, settings key, DSL block, example → chapter link. Maturity table. "Not available from R" table. ferx-core page map |

---

## 6. Coverage guarantee: the feature inventory

`tools/inventory.R` builds `tools/features.csv` **from pinned sources only**: the
installed pinned package, plus ferx-core at the locked SHA via `git show 8694824:...`.

| kind | Source (as implemented) | Rows | Coverage rule (`tools/audit.R`) |
|---|---|---|---|
| export | `getNamespaceExports` | 50 | `name(` in home chapter |
| s3method | NAMESPACE `S3method` | 22 | generic + class named in home chapter |
| argument | `formals()` of every export | 245 | parent fn named + `` `arg` `` or `arg =` |
| setting | pinned ferx-core `apply_fit_option()` match arms, minus keys reserved for `ferx_fit()` arguments | 107 | `` `key` `` or `key =` |
| example | `ferx_example()` | 66 | `ferx_example("name")` |
| searchfile | `inst/examples/search/` | 4 | `ferx_example("name")` + `$search` in ch 09 |
| dsl_block | pinned `BLOCK_REGISTRY` | 22 | `[block]` mentioned |
| data_column | pinned `DATA_BLOCK_ROLES` | 14 | column named |
| warning_code | pinned `WarningCode::as_str()` (`src/types.rs`) | 34 | `` `token` `` in home chapter's "Warnings you may see here" |
| fit_slot | `names()` of a real warfarin fit | 108 | named in home chapter (ch 25 generated table) |
| unavailable | §3 right column | ~10 | ch 25 table + pointer at point of need |

**Validation and parse diagnostics** (`E_*` / `W_*` codes from `ferx_model_validate()`,
~128 at the pin) are *not* tracked per code, because they are error messages rather
than features. Ch 04 explains the diagnostics list that `ferx_model_validate()`
returns and links ferx-core `file-formats/check-report.html`. Experimental-feature
codes (`W_EXPERIMENTAL_SDE`, `W_EXPERIMENTAL_NN`) are shown live in ch 24.

**Warning system placement:**
- ch 05 introduces fit warnings: the two channels `fit$warnings` /
  `fit$warnings_structured`, `ferx_get_warnings()`, severity levels, stable
  `category` tokens, and the extra lines `summary()` adds (e.g. EBE fallbacks
  from `fit$total_ebe_fallbacks`).
- ch 07 covers acting on diagnostic warnings.
- ch 09 covers gating candidate models on severity with `check_strictness()`.
- ch 25 holds the full table.

Every row has a `home` chapter (assigned in Step 1). `tools/audit.R` fails if a row
has no home or its name doesn't occur in its home chapter. Each audit prints
"covered X/Y" per kind. Residual risk: the audit proves presence, not correctness.
That is mitigated by the per-chapter loop (read the Rd, run first, write prose from
real output).

---

## 7. Stepwise execution

Each step ends at a **gate**. A gate is a PR into `book/v2-workflow` that is green on
CI and on `tools/audit.R`. Don't start the next step before the gate passes.

### Step 0: Baseline, pin, guardrails (no chapter writing)

- [x] **0.1 Branch.** (snapshot d7c05bf; plan 36194c0)
  - Commit WIP on `restructure/workflow-tutorial` as a reference snapshot (exclude
    `.DS_Store`, `*.knit.md`).
  - Create `book/v2-workflow` from `main`; add PLAN files.
- [x] **0.2 Pin locally.** (built from git archive; cargo used ferx-core #86948249; 50 exports, 22 S3, 66 examples)
  - `git archive` ferx-r `846aa4b` → scratch → `R CMD INSTALL`.
  - Confirm the engine SHA = `8694824` from the build's Cargo.lock.
  - Confirm 50 exports / 66 examples.
  - Write `_variables.yml` (`ferx_r_sha`, `ferx_core_sha`, version).
- [x] **0.3 Pin CI.** (71dba43; audit step added before render)
  - `render.yml`: `FeRx-NLME/ferx-r@846aa4b`; add gt + survival; drop vpc,
    `FERX_NO_AUTODIFF`, the dead `_freeze` step.
  - Add a `pull_request` trigger for `book/v2-workflow`.
- [x] **0.4 Hygiene.**
  - Delete `chapters/*_cache`, `*_files`, `_freeze/`, `_book/`, `*.knit.md`,
    `.DS_Store`, empty `data/`.
  - `.gitignore` additions.
- [x] **0.5 Smoke all 66 examples.** Result (`tools/example-status.csv`):
  - **66/66 run**: 62 fits (all converged), 2 adaptive simulations, 2
    prediction-only examples.
  - 395 s sequential locally.
  - Slowest: two_cpt_oral_cov_ode (89 s), _ode_template (87 s),
    three_cpt_oral_ode, warfarin_dcm, three_cpt_iv_ode and warfarin_sde (~30 s each).
  - Thread tool timings (`tools/out/time-thread.txt`, local):

    | Tool | Time |
    |---|---|
    | covsearch (two_cpt_oral_base `$search`) | 78 s |
    | ruvsearch (one_cpt_transit `$search`) | 34 s |
    | bootstrap (50 samples, two_cpt_oral_cov) | 13 s |
    | bayes | 10 s |
    | allometry | 3.2 s (emits a cor-matrix warning; show it honestly) |
    | modelsearch (warfarin `$search`) | 2.8 s |
    | SIR | 1.7 s |
    | gam_screen | 0.7 s |
    | NPDE (nsim=200) | 0.4 s |

  - Render budget: all book compute ≈ 10–15 min locally. CI is assumed to be
    2–3× slower. No example needs an eval-reason.
  - `tools/smoke-examples.R` fits each one (adaptive: `ferx_simulate_adaptive`) and
    writes `tools/example-status.csv` (ok, converged, warnings, seconds, error).
  - Output: the render-time budget and the list of eval-reason candidates.
  - Also time the thread: base fit, covsearch, bootstrap (small `samples`),
    modelsearch, ruvsearch.
- [x] **0.6 Verify open items** (results in §3; tools/verify-availability.R), then update §3:
  - `vi` from R; `[covariate_model]` and mixture at the pin; RTTE from R
  - RATE −1/−2; CWRES definition
  - determinism of bootstrap/search with fixed seed and threads
  - whether `ferx_stop` can be demoed reliably
- [x] **0.7 Inventory.** (530 rows + 108 fit slots) `tools/inventory.R` → `tools/features.csv`; check the row
  counts are plausible.
- [x] **0.8 Audit.** `tools/audit.R` checks:
  - (a) exports exist; (b) example names exist; (c) coverage per §6;
  - (d) eval-reason present; (e) no `#>` outside executed chunks;
  - (f) stale links; (g) banned other-software names; plus pin consistency
    (`_variables.yml` = `render.yml` = installed `RemoteSha`).
  - (h) cross-chapter objects: **dropped**. Each chapter renders in its own R
    session, so a foreign object already fails the render, and CI catches it.
  - Home assignment: `tools/assign-homes.R` seeds `tools/homes.csv` (638 rows,
    0 unassigned) from the §5 rules. Hand edits survive re-seeding.
  - Verified: the audit fails on the old `main` chapters as expected.

**Gate 0:** pinned install; CI pinned; smoke CSV; inventory; audit runs.

**Gate 0 status (2026-09-11): passed locally.** The CI half is folded into Gate 1:
the CI audit step fails on the old `main` chapters until the Step 1 skeleton
replaces them, so the first PR into `book/v2-workflow` carries Step 0 + Step 1.
Pushing and opening that PR needs owner OK.

### Step 1: Skeleton and conventions

- [x] 1.1 `_quarto.yml` tree. Parts: Getting started / The analysis workflow /
  one Part per scenario category (general PK, covariates, dosing and data,
  endpoints beyond PK, adaptive dosing, experimental) / Reference. Navbar
  unchanged. Old `main` chapters removed (their prose is still available on the
  WIP snapshot branch and in `main` history).
- [x] 1.2 `chapters/_common.R`: libraries, `theme_minimal`, knitr options
  (`comment="#>"`, `collapse`), `cache.extra = ferx_r_sha`, `book_tempdir()`.
  - Dropped from the plan: global `set.seed`. Seeds go into the ferx calls
    themselves (`seed =`).
  - Dropped from the plan: a global thread cap. No ferx option for it exists;
    pass `threads =` where it matters.
  - Helpers are named `book_*()` so the audit never confuses them with exports.
- [x] 1.3 Stage banner via `book_stage_banner()` (chunk `output: asis`), with
  light and dark SCSS; pinned version via `{{< var ferx_r_sha_short >}}`
  (`_variables.yml`). Callout conventions (maturity / reference / not-from-R) are
  plain Quarto callouts, defined by the pilot chapters in Step 2 rather than
  includes.
- [x] 1.4 `tools/homes.csv` assigns all 638 rows. All 25 chapters + preface are
  stubbed with template headings.
  - The feature lists stay out of the chapter source, so stubs can't fake
    coverage (the audit also ignores HTML comments).
  - Per-chapter to-do list: `Rscript tools/audit.R --chapter=NN-slug`.

**Gate 1:** CI renders the skeleton; audit coverage shows every row assigned (0
covered).

**Gate 1 status (2026-09-11):** local render green (81 s); `tools/audit.R` OK
(638/638 assigned, 0 covered). CI run pending: needs push + PR (owner OK).

### Step 2: Pilot (index, 01, 02, 23)

- [x] 2.1 Preface and 01 installation. Install commands are plain (non-chunk)
  code blocks; the pinned SHA comes in via `{{< var >}}` shortcodes, which do
  resolve inside code blocks.
- [x] 2.2 02 complete warfarin analysis: data → model → fit → GOF → VPC (ggplot)
  → gt table → `.fitrx`.
- [x] 2.3 23 adaptive dosing: 0 uncovered rows; two strategies compared on an
  edited *copy* of the model; loading-dose variant.

**Conventions fixed by the pilot** (apply to every later chapter):
- Setup chunk has `#| cache: false`. knitr does not replay side effects
  (`theme_set`, `library`, options) from a cached chunk.
- `_common.R` forces a UTF-8 locale and `scipen`. A local
  `_environment.local` (gitignored) sets `LANG`, because a C-locale render spews
  gt encoding warnings.
- Chapter title line: `# Title {#sec-<slug>}`. Cross-references use `@sec-<slug>`.
- **Never pass a bundled example path to `ferx_model_set_section()`.** It edits
  a plain path in place (Rd), and that path is the installed package. Copy into
  `book_tempdir()` first.
- Callouts:
  - Maturity: `callout-warning` titled "Maturity: beta" or "Maturity:
    experimental", linking ferx-core `maturity.html`.
  - Closing `callout-tip` titled "Reference": R help + ferx-core pages.
- Prose numbers via inline R. Every non-obvious behaviour is checked against
  output before it is stated. Examples: the first adaptive dose ≠
  `start_dose`; a bolus at the decision time appears in `trajectories` but not
  in `SIGNAL`; `PCT_TIME_IN_WINDOW` is a fraction.
- Full clean local render: 107 s (Parts I pilot + stubs).

**Gate 2:** CI + audit green for these files. **Owner review of voice, depth and
format before scaling out.**

**Gate 2 status (2026-09-11):** local clean render + audit green.
- Owner **approved the pilot** style.
- Owner OK'd the push + first PR (Steps 0–2) into `book/v2-workflow`.
- D4 decided (§8).
- **CI green on PR #16** (runs 34615680841 @79d59ef and 34615913286 @82608fe, 13m39s: pinned install, audit, full render). Gates 0–2 passed.

### Step 3: Part II, in order 03 → 13 (owner decision 2026-09-11: chapters 03–09 go up as one PR, stacked on #16; owner merges PRs)

Per-chapter loop:
1. Read the Rd (pinned) + linked ferx-core pages.
2. Run the code in R first.
3. Write prose from the real output, using inline R numbers.
4. Build the home options table.
5. Delete the chapter cache and render locally.
6. Run the audit for that chapter's rows.
7. Open the PR; CI green.

| Chapter | WIP source to mine | Known traps |
|---|---|---|
| 03 data | WIP 17 | `ferx_apply_selection` returns data with an `exclusions` attribute |
| 04 model | WIP 03 | `ferx_model(template=, path=)` returns an object; `_validate` returns a list |
| 05 first fit | WIP 04 (top) | default method focei; `fit$estimates` |
| 06 methods | WIP 04 (rest) | `imp_*` keys; imp = MC-EM by default; SAEM `n_mh_steps`=20; `lbfgs` is an alias |
| 07 diagnostics | WIP 05 | drop the fabricated DW output; `gradient_tol` default 0.1 |
| 08 VPC | WIP 06 | sim columns `DRAW`/`CMT`/`OBSERVED` |
| 09 selection | new | tools write directories: `tempdir()`; runtime |
| 10 uncertainty | WIP 07 | `sir_keep_samples`; bootstrap size vs budget |
| 11 scenarios | WIP 06 | design datasets with empty DV |
| 12 tables | new | report values as ferx gives them; state any derived formula |
| 13 reproducibility | WIP 20 | `.fitrx` paths |

**Gate 3:** Part II coverage 100% for its home rows.

**Gate 3 status (2026-09-11):** every Part II chapter 0 uncovered rows; full clean local render green (10m54s); PR #17 CI green; PR #18 CI pending.

### Step 4: Part III, by category, one PR per chapter

- [x] 4.1 A: 14 structural (WIP 11), 15 absorption (WIP 10), 16 variability (WIP 09 + 13) — local branches v2/ch14…ch16 (88ba40e), not pushed
  - Done: ch14 (95bd795 + e2e9011: `[scaling]` section `#sec-scaling`, `[derived]`
    states `#sec-derived-states`, ch12 pointer) and ch15 (a31fa16). The owner notes
    below are resolved in e2e9011.
  - Owner notes (2026-09-11), to do after ch15, before ch16:
    - **Scaling**: check whether `[scaling]` needs its own section (now a ch14
      subsection). Cover every form the ferx-core scaling page lists, each with a run.
    - **`[derived]` for analytic vs ODE models**: in ch14, add compartment states in
      `[derived]` (analytic fixed layout `compartments[i]`, central in concentration;
      named ODE states, unscaled amounts; `integral` over states) and how to turn them
      into analysis outputs. ch12 gets a pointer. ch15 uses `[derived]` exposure
      metrics across absorption models.
- [x] 4.2 B: 17 covariates (WIP 08) — local branch v2/ch17-covariates, not pushed
- [x] 4.3 C: 18 dosing (WIP 15 + 16), 19 censoring (WIP 14; rewrite drop semantics) — local branches v2/ch18-dosing, v2/ch19-censoring, not pushed
- [x] 4.4 D: 20 PK/PD (WIP 12), 21 binary (new), 22 TTE (WIP 18; fix the signature) — local branches v2/ch20…ch22, not pushed
- [x] 4.5 F: 24 experimental (WIP 21) — local branch v2/ch24-experimental, not pushed

**Gate 4:** 66/66 examples executed (or eval-reason = smoke error).

### Step 5: Part IV

- [x] 25 index generated from `features.csv` by `tools/make-reference.R` (static markdown: functions, S3, settings, blocks, columns, examples, search files, warning categories, fit slots with `?ferx_fit` descriptions, not-available-from-R, maturity from ferx-core at the pin). Regenerate at a pin bump with `LANG=en_US.UTF-8 Rscript tools/make-reference.R`.

**Gate 5:** audit coverage 100% on every kind.

### Step 6: Finalise

- [x] 6.1 Full CI render and local clean render (2026-09-11): CI on #21 (all 25 chapters, audit --strict) 28m44s; #20 23m50s; #19 20m. Local clean render from empty caches 36m (2159 s), exit 0, no Quarto warnings or unresolved cross-references.
- [x] 6.2 Link check: all 87 external URLs return 200 and every `#anchor` exists (GitHub README anchors use the `user-content-` prefix). curl-based; Python urllib fails locally on SSL.
- [x] 6.3 Rewrite `CLAUDE.md` (also: CI runs `tools/audit.R --strict`):
  - chapter table and the pin procedure
  - inventory + smoke + audit procedure
  - the ferx-only rule
  - remove stale ferx-site cross-link and `ferx_estimates` guidance
- [ ] 6.4 PR `book/v2-workflow` → `main` (template filled; note S2 live-site
  freeze). Merging deploys.

### Step 7: Upstream issues (separate, already queued as tasks)

- ferx-r (owner: **to resolve in ferx-r**, D4): bundle ferx-core examples for
  features that fit from R but aren't bundled:
  - `[covariate_model]`: `two_cpt_oral_covmodel`
  - repeated TTE: `rtte_exponential`, `rtte_weibull_reset`
  - fixed-rate infusion: `dose_rate`, `one_cpt_infusion`
- ferx-r:
  - docs claim nn is off by default
  - `ferx_model_validate` rejects compact TTE models
  - pkgdown omits post-0.3.0 exports
- ferx-core:
  - docs reference non-export R names (`ferx_selection`, `ferx_to_frem`,
    `ferx_mbma_data`, `ferx_search`)
  - examples reference missing data files (`mm_sparse.csv`, `warfarin_cov.csv`)
- ferx-core (found in 4.1), to check: on `warfarin_ode` with the model's own
  tolerances (`ode_reltol 1e-10`, `ode_abstol 1e-12`), `ode_method = rosenbrock23`
  took 440 s and ended unconverged (OFV 17.7; critical `convergence` +
  `ode_solver`). At 1e-6/1e-8 it converges in 9 s. The book shows only the
  moderate-tolerance comparison.
- ~~**ferx-r bug (found in 4.1, ch15), important:** `fit$individual_estimates` is wrong
  for ODE models.~~ **Fixed**; in the pin from 078e489.
  - `build_individual_estimates()` in `src/rust/src/lib.rs` read `pk.values[i]`
    sequentially for ODE models, but the engine's slot layout differs.
  - Was: `warfarin_ode_lagtime` gave KA = LAGTIME = 0; `warfarin_ode` gave
    KA = 0; `transit_savic` gave KA = TVN, MTT = 0 and NTR = TVKA;
    `sequential_absorption` gave KA = TVDUR and DUR = 0.
  - Verified at 078e489: all four report the same values as `[output]` in sdtab and as
    the analytical twin. ch15's callout and its `[output]` workaround framing are gone;
    the `[output]` chunk stays as a table recipe.
- ~~**Engine bug (found in 4.1, ch16), important:** `block_omega (ETA_CL, ETA_V)` plus a
  diagonal `omega ETA_KA` (`warfarin_block_omega`) fits the same model as a full 3×3
  block.~~ **Fixed** by ferx-core #1018 (PR #1364), in the pin from ferx-core 8372248c.
  - Was: identical OFV (−283.3167 FOCE) and identical omega matrix to the full block,
    including non-zero ETA_KA covariances, although `n_parameters` said 8 vs 10 — so the
    reported AIC and BIC were two parameters short.
  - Verified at 8372248c: the partial block gives OFV −280.4858 with the ETA_KA
    covariances and their standard errors exactly 0; the full-block twin gives
    −283.3167 with 10 parameters. dOFV 2.83 on 2 df, and both criteria prefer the
    partial block. ch16 now shows that contrast as ordinary content, no callout.
  - Still true and still shown: the partial block's two structural zeros make ferx-r
    warn that the correlation matrix of the estimates has non-positive diagonal
    elements.
  - Also: `warfarin_iov` / `warfarin`, as bundled, use `method = foce`
  with proportional error. FOCE gives biased IOV estimates (TVCL 0.32) vs
  FOCEI/SAEM/chain (0.17); ch16 shows this. Consider changing the bundled examples
  to focei (ferx-r).
- ~~**ferx-r bug (found in 4.2, ch17):** `ferx_model_to_frem()` ignores `output_dir`
  (never passed to Rust). Without `output_model`/`output_data` it writes next to the
  model, i.e. into the installed package for `ferx_example()` models.~~ **Fixed** in
  [ferx-r #360](https://github.com/FeRx-NLME/ferx-r/pull/360) (merged), in the pin from
  078e489. Verified: both calls use `output_dir`, the files land in the temp directory
  and the installed `examples/models` directory stays clean.
- ~~**ferx-r bug (found in 4.2, ch17):** `print()` of the generated FREM `ferx_model`
  says "IIV: none" although the model has a 7×7 block.~~ **Fixed** in
  [ferx-r #362](https://github.com/FeRx-NLME/ferx-r/pull/362) (merged, closing
  [#358](https://github.com/FeRx-NLME/ferx-r/issues/358)), in the pin from 078e489.
  Verified: the FREM model prints all seven etas, and `warfarin_block_omega` prints
  `ETA_CL, ETA_V, ETA_KA`. Sourcing the pre-fit structure from the engine instead of
  the R parser is [ferx-r #363](https://github.com/FeRx-NLME/ferx-r/issues/363), open.
- ferx-r/ferx-core (found in 4.2, ch17), to check: `ferx_allometry()` on a model
  with inline `(WT/70)^THETA_WT` (`two_cpt_oral_cov`) adds WT scaling again with no
  note. Only `[covariate_model]` relations are detected. The Rd says "a parameter
  that already carries a relation on the size covariate is left alone". The book
  shows it as a pitfall. The bundled `two_cpt_oral_base.ferxsearch` `[allometry]`
  section cannot be used with `ferx_allometry(config=)`: its space has no
  `ALLOMETRY` statement, so it errors.
- ferx-r/ferx-core wording (found in 4.3): some output of ferx names other software, which the ferx-only book then renders:
  - `ferx_get_columns()` prints "Required NONMEM:" / "Optional NONMEM:" (ch03);
  - the `iiv_on_ruv` FOCE error and the `omega ~ 0.0` not-FIX error end with sentences naming it;
  - bundled model comments (`ss_absorption`, `infusion_absorption`).

  The book shows only the first sentence of those errors (ch16, ch18) and does not print those model comments. `ferx_get_columns()` output is left as is (ch03).
- ferx-core/ferx-r (found in 4.4, ch20), to check:
  - **`NaN` for zero time above MEC:** `integral(1.0, IPRED > MEC, window=24, …)` returns `NaN`, not 0, for windows where the condition never holds (`warfarin_derived_pkpd` with MEC 8, days 3–5).
  - **Bundled examples are weak demos:** `warfarin_derived_pkpd` uses MEC 0.5, below every warfarin concentration, so time above MEC is always 24 h. `emax_pkpd` has only 3 subjects, so the PD parameters are unidentifiable (RSE up to 5e4%).
  - **What ch20 does:** it shows both, plus a 30-subject simulation–estimation run.
- ferx-r/ferx-core (found in 4.4, ch21), to check:
  - **`print()` of a binary fit:** says "Obs: 0", "Structural: 1-cpt IV" and "Residual: per-CMT ()" for `binary_logistic`.
  - **Misclassified notice:** the finite-difference inner-gradient notice is categorised `data_quality` (warning).
  - **FOCE runs without complaint:** the docs say FOCE is biased for binary endpoints, but `method = "foce"` on the random-intercept model runs silently with the same OFV as FOCEI.
  - **SAEM default seed:** on that model the default seed ends at a degenerate point (RSE 2e6%), while seeds 1–3 agree.
- ferx-r/ferx-core (found in 4.4, ch22), to check:
  - **Empty `sdtab`:** TTE-only fits return an empty `sdtab` (0 rows).
  - **Stale model comment:** the `tte_exponential` comment says `[event_model]` cannot reference individual parameters; the docs now say it can.
  - **`ferx_simulate()` without `horizon`:** it prints "Error simulating: …" and returns NULL rather than raising an R error.
- ferx-core/ferx-r (found in 4.5, ch24), to check:
  - **`warfarin_dcm`:** the fitted network (141 weights, FOCEI/lbfgs, 27 s) outputs a constant clearance multiplier (1.0319 for all 30 subjects, sd 8e-9), reaching the base-model OFV (−1185.46 vs −1185.40). The explicit covariate model reaches −1199.33.
  - **Regularised DCM:** `settings = list(nn_l2 = 0.01)` did not finish within 10 min with bobyqa, or within about 25 min with lbfgs. The book documents `nn_l2`/`nn_smooth` without running them.
  - **`warfarin_sde`:** the diffusion variance collapses (RSE 113%), with OFV −279.27 vs −280.32 without `[diffusion]` (FOCE).
  - **Bundled model comments:** the `warfarin_dcm` comment names other software, so ch24 prints its blocks without comments.
- ferx-r (found in Step 5): `ferx_fit(method = "vi")` is rejected by `match.arg`, although `method = vi` in the model file runs. The VI ELBO (`vi.neg_two_elbo`, `vi.elbo_trace`, `vi.n_fd_subjects`) is not on the R fit object. `[markov_model]` is rejected at parse time (`E_BLOCK_FEATURE_DISABLED`, since ferx-r does not build the `markov` feature).
- ferx-r doc typos (found in Step 5):
  - the `?ferx_fit` value entry for `cov_matrix` reads "matrix (params ? params)", a lost ×; `tools/make-reference.R` corrects it;
  - the `?ferx_get_columns` and `?ferx_runlog` titles name other software; the generator drops that word.
- ferx-core docs (found in 4.1, ch16), minor:
  - error-model/iov docs claim `shrinkage_kappa` is a placeholder, but ferx-r
    returns `shrinkage_kappa` and `shrinkage_kappa_by_occ` populated.
  - fit-options docs claim `nlopt_lbfgs` unscaled stalls near −1165 on
    `two_cpt_oral_cov`; at the pin all `parameter_scaling` values reach −1199.326.
- ferx-core docs (found in 4.1, ch14), minor: derived.qmd says named state access
  in `integral()` is not available for analytical models (use `compartments[i]`).
  At the pin, `integral(central, from=0, to=24, step=0.5)` on analytical `warfarin`
  works and equals the `compartments[1]` result (232.4958). The book uses
  `compartments[i]` as documented.
- ferx-core docs wording (found in 4.1, ch15), minor: the `flip_flop` heads-up
  (`W_TRANSIT_FLIP_FLOP` / `W_IG_FLIP_FLOP`, `api/validation.rs`) is a fit-start check
  on the **starting** typical values, by design; its message says "check the …
  starting estimates". absorption.qmd says "at the typical-value estimates", which
  reads like final estimates. In practice:
  - A fit that starts in-domain and ends in flip-flop gets no note, because the
    reroute is correct anyway.
  - `one_cpt_ig` with TVMAT 15 FIX took 158 s on that path.
- ferx-r (found in 3.10–3.13), to check:
  - `ferx_load_fit()` returns a fit without ~30 R-side fields
    (`individual_estimates`, `condition_number`, `eigenvalues`, `exclusions`,
    `warnings_structured`, …).
  - Warning categories come back as `general` after a `.fitrx` round-trip
    (e.g. `dw_autocorrelation` → `general`).
  - ferx-r's `ferx_simulate()` ignores the `[simulation]` block. Without `data` it
    errors "No data supplied" (the block is CLI simulation-estimation only). The
    book says so.
  - SIR ESS is highly seed-dependent on `two_cpt_oral_cov` (17.9 vs 68 vs 139 at
    1000/250).
  - Bayes on `two_cpt_oral_cov` does not converge (max R-hat 2.7 default, 4.8 with
    2000/2000).
- ferx-r (found in 3.7), to check: `?ferx_search_results` says the candidate table
  is "written by every tool". But `ferx_covsearch()` and `ferx_modelsearch()` runs
  (bundled configs, `directory` set) wrote no `candidates.csv`, so the default
  `type = "candidates"` errors ("No candidate table"). The book passes `type`.
- Book narrative note (3.7): the bundled covsearch (`two_cpt_oral_base.ferxsearch`,
  p_forward 0.01 / p_backward 0.001) adds `CL~CRCL` (p = 0.0084) and removes it
  again in the backward step. The final model is the base. The prespecified
  `two_cpt_oral_cov` beats the base (ΔOFV 13.9, 2 df, p = 0.00095), and Part II
  continues with it. Search tools are labelled *alpha* in the ferx-core docs.
- ferx-core/ferx-r (found in 3.3), to check:
  - On `two_cpt_oral_base` (fd gradient → bobyqa) the fit runs 98 objective
    evaluations and converges identically for `maxiter` = 5, 20 and 500.
    `maxiter` does not limit it, although the engine's own message calls
    `maxiter` "the evaluation budget". On warfarin (analytic → nlopt_lbfgs)
    `maxiter = 5` does stop the fit (critical `convergence`). As a result
    `ferx_check_init()` ("short pilot") is a full fit on the base model.
  - `ferx_inits_from_nca()` returns identical thetas for `nca`, `nca_sweep` and
    `nca_ebe` on both `two_cpt_oral_base` and warfarin. The Rd says `nca` leaves
    `Q`/`V2` at model defaults, but the returned `TVQ`/`TVV2` differ from the
    model defaults.
  - On `two_cpt_oral_base`, `inits_from_nca` + fd/bobyqa "converges" to OFV
    24422 (vs −1185). The book shows this honestly as a pitfall.
- ferx-r (found in 3.2): `print.ferx_model` and `print.ferx_conddist` are exported S3
  methods with no help page (`help()` finds nothing). `ferx_model_validate()`
  reporting compact TTE models INVALID is confirmed on the pin (`tte_weibull`:
  "Missing required section" ×3, although it fits); ch 22 must say so.
- ferx-core docs vs behaviour (found in 3.1), to check: `model-file/data.qmd` says an
  explicit data path that differs from `[data]` records a warning. From R
  (`ferx_fit(model, data = other)`) the explicit path is used but no warning
  appears in `fit$warnings`.
- ferx-core docs vs behaviour (found in 2.3), to check:
  - `adaptive-dosing.qmd` says `start_dose` is "the dose issued at the first
    decision". But in `adaptive_tdm` the first rule already fires at t=0 (trough
    0), so the first issued dose is 1250, not 1000. Either the doc wording or the
    behaviour needs a look.
  - Also: `trajectories$DV_SIM` equals `IPRED` exactly in `adaptive_tdm`,
    although it runs `with_assay_error` with sigma 0.1. Whether trajectories are
    meant to carry residual error is unverified; the book does not claim either
    way.
- ferx-r (found in 0.5): the `ss_absorption` / `infusion_absorption` model headers
  and `ex_*.R` say "a fit works identically (raise the omega…)". As shipped,
  `ferx_fit()` errors (`omega ETA_CL ~ 0.0` not FIX). They are prediction examples;
  the book runs them with `ferx_predict()`. Their scripts also frame DV as
  another engine's prediction; the book must not repeat that (rule 8).
- Any example failing the smoke test → ferx-r issue.

### Maintenance: pin bump

1. Diff NAMESPACE, `formals`, settings keys, example registry (rerun
   `inventory.R` and diff the CSV).
2. Read NEWS.
3. Rerun smoke + audit.
4. Bump `_variables.yml` + CI SHA.
5. Clean render.

---

## 8. Decisions

| # | Decision | Outcome |
|---|---|---|
| D1 | Pin | **Decided:** ferx-r `origin/main` `846aa4b`; re-pin to next release tag when cut |
| D2 | xpose | **Decided:** mention only; `ferx_xpose` eval-reason |
| D3 | Branching | **Decided:** WIP snapshot + `book/v2-workflow` from main |
| D3b | Examples | **Decided (revised by owner 2026-09-11):** run every example that can run; variants via live loops; list only smoke failures with the recorded error |
| D7 | Other NLME software | **Decided:** ferx only; no comparison chapter or text |
| D4 | Mirror ferx-core examples into ferx-r for features that fit from R but have no bundled example: `[covariate_model]` (two_cpt_oral_covmodel), repeated TTE (rtte_exponential, rtte_weibull_reset), fixed-rate infusion (dose_rate, one_cpt_infusion) | **Decided (2026-09-11):** the book gives **mention + link only** for now. Bundling these examples is an **open ferx-r follow-up** (Step 7). Once a ferx-r release bundles them: re-pin (rerun Step 0.2/0.5/0.7), then run them in their home chapters (17 covariates, 22 TTE, 18 dosing) |
| D6 | Part II thread = two_cpt_oral_base → two_cpt_oral_cov | **Confirmed on timing (0.5):** base fit 0.9 s, cov fit 0.5 s, covsearch 78 s, bootstrap 50 in 13 s. The covsearch selection outcome is reported as the run gives it in ch 09 |
