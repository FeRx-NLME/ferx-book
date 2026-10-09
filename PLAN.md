# PLAN.md — ferx-book v2: an analysis-workflow tutorial for ferx-r

Status: **Steps 0–6.3 done.** #23 squash-merged into book/v2-workflow as `47204e5`, which carried the whole #16–#21 stack with it; those PRs are closed as superseded. The pin bump to ferx-r `078e489` / ferx-core `8372248c` is open as #24. Part II + Part III + reference chapter written; audit --strict 737/737 covered. **Next: Step 6.4** (started 2026-09-11). Revision 2, after scrutiny
round 1 (§1b). Supersedes `PLAN-v1-archive.md`.

Model: [PKNCA book](https://humanpred.github.io/pknca-book/). This is a guided, fully
runnable book on **using ferx-r in an R modeling analysis**. Technical detail (DSL
grammar, estimator math, exhaustive option semantics) lives in the
[ferx-core docs](https://ferx-nlme.org/ferx-core/) and is linked, not copied.
The book is about ferx. Another NLME engine may be named in an analogy that shows what a ferx example or feature corresponds to, **never in a comparison that says ferx is better** (rule 8, softened by the owner 2026-10-02).

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
8. **Analogies, not claims** (softened by the owner 2026-10-02; was "ferx only: no
   comparisons to or translations from other NLME software").
   - Another engine may be named in an analogy that shows a reader what a ferx example or
     feature corresponds to. Never name one in a comparison that says ferx is better,
     faster or improved.
   - Describe the data format as "the ferx data format" and link ferx-core
     `data-format`.
   - The audit flags a sentence (outside URLs) that names NONMEM, Monolix, nlmixr, PsN,
     Pumas, Pharmpy, pyDarwin, Phoenix NLME, NLMIXED, WinBUGS or Stan together with
     comparative wording (better, faster, improved, outperform, superior, ...). Whether a
     sentence that passes is an analogy is for review to judge.
   - `ferx_xpose(backend = "xpose4")` is a ferx argument and is allowed.
9. **Link, don't copy.** Each chapter ends with a Reference callout (`?fn` +
   `https://ferx-nlme.org/ferx-core/<path>.html`). Never link to stale
   `ferx-nlme.org/model-dsl|learn|examples` pages.
10. **Report behaviour as it is.** If a fit doesn't converge or warns, show that
    honestly. Never tune settings to hide it without saying so.

---

## 3. Baseline facts (verified 2026-09-11)

**ferx-r**
- `origin/main` = `078e489` (pin at the time of writing `846aa4b`): 54 exports, 28 S3 methods, 67 examples, 7 `.ferxsearch`.
- ferx-core is locked at `8372248c` in `src/rust/Cargo.lock`.
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
| covsearch, modelsearch, ruvsearch, iivsearch, iovsearch, amd, search config/space/coverage/results | globalsearch (ferx-core CLI) |
| covariance step, SIR, bootstrap (**verified seed-deterministic**; only `seconds`/timing and the printed directory differ), bayes posterior, `ferx_simulate_with_uncertainty` | — |
| `ferx_simulate_adaptive` + `[adaptive_dosing]` | MAP-Bayesian dose individualisation (doesn't exist) |
| TTE (exp/Weibull/Gompertz/competing risks), joint PK-TTE, `ferx_predict_survival`, binary | `[markov_model]`/CTMM (feature not built) |
| built-in absorption inputs, per-route lag, analytic transit/IG | — |
| SDE, `[covariate_nn]` (**verified**: warfarin_dcm fits, 32 s) | `[dynamics_nn]` (design only) |
| compartment-free models, weighted kappa, residual `weight =`, theta level blocks (ch24 MBMA, bundled `mbma_placebo` from ferx-r `6c7d02a`) | `mbma_naproxen` (ferx-core only, CC BY-NC data) |
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
     pin), plus a link to `https://ferx-nlme.org/ferx-core/warnings.html#codes-<group>`;
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
| G Meta-analysis | 24 | Model-based meta-analysis | `ferx_mbma_data()` (+print); arm-level data; `weight =` on the error model and on a kappa; theta level blocks, `sum_to_zero_within`, `fit$theta_levels`; `.fitrx` round trip; `ferx_sir()` / `ferx_covariance()` on the fit | mbma_placebo |
| F Experimental | 25 | Experimental features | `[diffusion]` SDE; `[covariate_nn]` (+`nn_*`) | warfarin_sde, warfarin_dcm |

**Renumbering (2026-10-09, ferx-book#34).** The MBMA chapter took number 24, so experimental moved to 25 and the reference to 26; `aliases:` keep the published `24-experimental.html` and `25-reference.html` URLs. Entries in §7 written before then say "ch24" for the experimental chapter and "ch25" for the reference.

Example count: 02:1, 03:2, 04:1, 06:2, 12:1, 14:15, 15:18, 16:6, 17:1, 18:5, 19:1,
20:3, 21:1, 22:5, 23:2, 24:2 = **66** (at the time; ch24 MBMA adds mbma_placebo, and the pin now bundles 69).

### Part IV: Reference

| Ch | Title | Content |
|---|---|---|
| 25 | Function, option and example index | Generated from `tools/features.csv`: every export, S3 method, argument, settings key, DSL block, example → chapter link. Maturity table. "Not available from R" table. ferx-core page map |

---

## 6. Coverage guarantee: the feature inventory

`tools/inventory.R` builds `tools/features.csv` **from pinned sources only**: the
installed pinned package, plus ferx-core at the locked SHA via `git show <ferx_core_sha>:...`.

| kind | Source (as implemented) | Rows | Coverage rule (`tools/audit.R`) |
|---|---|---|---|
| export | `getNamespaceExports` | 54 | `name(` in home chapter |
| s3method | NAMESPACE `S3method` | 28 | generic + class named in home chapter |
| argument | `formals()` of every export | 296 | parent fn named + `` `arg` `` or `arg =` |
| setting | pinned ferx-core `apply_fit_option()` match arms, minus keys reserved for `ferx_fit()` arguments | 107 | `` `key` `` or `key =` |
| example | `ferx_example()` | 67 | `ferx_example("name")` |
| searchfile | `inst/examples/search/` | 7 | `ferx_example("name")` + `$search` in ch 09 |
| dsl_block | pinned `BLOCK_REGISTRY` | 22 | `[block]` mentioned |
| data_column | pinned `DATA_BLOCK_ROLES` | 14 | column named |
| warning_code | pinned `WarningCode::as_str()` (`src/types.rs`) | 34 | `` `token` `` in home chapter's "Warnings you may see here" |
| fit_slot | `names()` of a real warfarin fit | 108 | named in home chapter (ch 25 generated table) |
| unavailable | §3 right column | ~10 | ch 25 table + pointer at point of need |

**Validation and parse diagnostics** (`E_*` / `W_*` codes from `ferx_model_validate()`,
~128 at the pin) are *not* tracked per code, because they are error messages rather
than features. Ch 04 explains the diagnostics list that `ferx_model_validate()`
returns and links ferx-core `file-formats/check-report.html`. Experimental-feature
codes (`W_EXPERIMENTAL_SDE`, `W_EXPERIMENTAL_NN`) are shown live in ch 25.

**Statement modifiers** (`weight =` on an error model or a kappa, `iiv_on_ruv`, `contrast =` on a level block, `FIX`, the `(sd)` / `(variance)` tags, inline `prior()`) are *not* tracked either (decided 2026-10-09, ferx-book#34). ferx-core keeps no registry of them: each is recognised by its own parser code, so `inventory.R` could only list them by hand, which §6 rules out. Their coverage is unenforced and kept by review; `weight =` is covered in ch16 (pointer) and ch24. If ferx-core adds a `MODIFIER_REGISTRY` beside `BLOCK_REGISTRY`, add a `dsl_modifier` kind that reads it. Not filed upstream: it is a feature request, not a defect.

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

**Gate 4:** 67/67 examples executed (or eval-reason = smoke error).

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
  - ~~Still true and still shown: the partial block's two structural zeros make ferx-r
    warn that the correlation matrix of the estimates has non-positive diagonal
    elements.~~ Gone at `161d28a`: a FIX parameter's SE is `NA` (ferx-r #451), and the warning no longer fires; the same applies to the fixed-parameter R warnings ch15, ch17 and ch22 explained. Their prose now says the SE is `NA`.
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
- ~~**ferx-r bug (found reviewing the 078e489 bump, ch16):** `fit$cov_matrix` labels its
  omega rows and columns row-major while ordering their values column-major, so for a
  3×3 block two labels are wrong (positions 3 and 4 swap).~~ **Fixed** by
  [ferx-r #378](https://github.com/FeRx-NLME/ferx-r/pull/378) (closing
  [#367](https://github.com/FeRx-NLME/ferx-r/issues/367)), in the pin from `6e2f701`.
  Nothing in the book changed: no chapter prints these labels for a block model.
  - On `warfarin_block_omega` the two zero-variance diagonal entries — the held
    covariances — are labelled `ETA_V,ETA_V` and `ETA_KA,ETA_V`. But `ETA_V,ETA_V` is
    estimated: `se_omega` gives it 0.004298, and in the full-block twin its `cov_matrix`
    entry is 0.0347. The zeros sit at positions 3 and 5, which column-major are (3,1)
    and (3,2), matching the zeros in `se_omega` (documented column-major in `?ferx_fit`).
  - `cor_matrix` inherits the same dimnames, and the Rd for `cov_matrix` does not state
    an ordering for block omega elements.
  - Not reader-visible: no chapter prints `cov_matrix` or `cor_matrix` for a block model.
    Nothing to remove from the book when this is fixed; recheck the labels then.
- **Process finding (found at the `a961146` bump):** `_variables.yml` carried a stale
  `ferx_core_sha` (`8372248c`) while its `ferx_r_sha` (`70f7fe3`) actually built ferx-core
  `7abf4235`. `tools/inventory.R` reads ferx-core with `git show <ferx_core_sha>:…`, so the
  whole feature inventory at that pin was taken against the wrong engine revision, and the
  `[priors]` DSL block — present at `7abf4235`, absent at `8372248c` — was missing from
  `features.csv` and therefore never had to be covered. Read the ferx-core SHA out of the
  ferx-r commit's `src/rust/Cargo.lock` at every bump (D1); `src/rust/Cargo.toml` says
  `branch = "main"` and reads as unpinned. `tools/features-pin.yml` guards a stale
  `features.csv`, but nothing guards a `_variables.yml` whose two SHAs disagree.
- ~~**ferx-core bug (found writing the ch16 scales section), important:** `(sd)` on a
  `block_omega`, `block_kappa` or `block_sigma` is silently ignored instead of rejected.~~
  **Fixed** by ferx-core [#1377](https://github.com/FeRx-NLME/ferx-core/issues/1377)
  (PR [#1388](https://github.com/FeRx-NLME/ferx-core/pull/1388)), in the pin from ferx-core
  `d66046e`.
  - Was: `docs/model-file/parameters.qmd` said the tag "is not accepted there because the
    lower-triangle list mixes variances and covariances and a single tag would be
    ambiguous", but the build neither rejected nor applied it. `warfarin_block_omega` with
    `[0.07, 0.02, 0.02] (sd)` validated as `VALID` with zero diagnostics, fitted to the same
    OFV (−280.4858) as without the tag, and left `init_as_sd` `FALSE` for every omega row.
    All three block forms behaved the same way: `block_kappa` gave OFV 202.186055 tagged and
    untagged, and `block_sigma` gave −280.751039 both ways with 9 parameters each. So a user
    who wrote SDs in a block got them read as variances with no warning.
  - Verified at `d66046e`: the tagged file is `INVALID`, one diagnostic,
    `code = E_BLOCK_VARIANCE_ONLY`, and `ferx_fit()` refuses it with the same message
    (without the code — see the ch25 usability gap below). The repair rides along in
    `suggestion` and depends on the tag: after `(sd)`, "square each SD into a variance and
    write the off-diagonals as covariances"; after `(variance)` / `(var)`, "delete the tag:
    the lower triangle is already variances and covariances, so the numbers do not change".
    The `block` and `line` fields of the diagnostic are `NA` for this code, so ch16 prints
    only `code` and `suggestion`.
  - ch16's callout is gone. The section is ordinary content (`block-sd-rejected`,
    `block-sd-fit`, `block-variance-tag`) showing the refusal, the code and both repairs.
    The generalisation to `block_kappa` / `block_sigma` is stated as the engine's documented
    rule with a link, not as a measured claim: only `block_omega` is exercised live, because
    the chapter's `block_kappa` and `block_sigma` models are built further down the page.
  - Still true and still shown: diagonal `omega`/`sigma` take `(sd)` correctly —
    `omega ETA_CL ~ 0.07` and `~ 0.2645751 (sd)` both give OFV −280.364, as do
    `sigma PROP_ERR ~ 0.01 (sd)` and `~ 0.0001`.
- ~~**ferx-r / ferx-core bug (found covering `[priors]` at the `a961146` bump), important:**~~
  **Fixed** by [ferx-r #379](https://github.com/FeRx-NLME/ferx-r/issues/379), in the pin from `5c9cc7a` (v0.4.0). ch24 now runs `[priors] from_fit` as ordinary content (`priors-from-fit`, `priors-from-fit-compare`: a fit to warfarin subjects 1-5 as the prior for subjects 6-10); the refusal chunk, its paragraph and the pitfall are gone. Original finding:
  the `.fitrx` bundle `ferx_save_fit()` writes cannot be read back by ferx-core, so
  `[priors] from_fit` — the model-updating import, and the block's only key — is unreachable
  from R.
  - `fit.json` inside the bundle records `"method_chain": "foce"`, a string;
    `src/io/fitrx.rs` declares `method_chain: Vec<String>`. Fitting a model with
    `[priors] from_fit = <that file>` stops at parse time with
    ``failed to read … JSON error: invalid type: string "foce", expected a sequence at line 3
    column 24``. `ferx_model_validate()` reports it as `E_PARSE`.
  - `ferx_save_fit()`'s Rd says the schema "is shared with the ferx-core Rust crate", so this
    is drift, not a documented limitation. `ferx_load_fit()` round-trips inside R, which is
    why it went unnoticed; only the Rust reader rejects the file.
  - Not a book blocker: the inline `prior(value, rse = …)` form on a `[parameters]` row does
    work from R, and ch24 shows it. ch24 also shows the `from_fit` refusal as the reason the
    block is not demonstrated further. Remove that paragraph once the schemas agree.
  - ~~Also missing from the R fit object: the `ofv_data` / `ofv_prior` split ferx-core's priors
    page documents. ch24 infers the penalty from `aic - 2k` instead, and says so.~~ **Fixed** by
    [ferx-r #383](https://github.com/FeRx-NLME/ferx-r/pull/383) (closing
    [#366](https://github.com/FeRx-NLME/ferx-r/issues/366)), in the pin from `6e2f701`. ch24's
    `prior-objective` chunk now prints `ofv_data` and `ofv_prior`, and `prior-print` and
    `prior-summary` show the annotated OFV line and `fit$prior_summary`; the "at this build"
    sentence is gone. The `from_fit` refusal (ferx-r #379) is still open and still shown.
  - **Found alongside, and a trap for any reader on macOS:** `//` starts a comment in a
    `.ferx` file, and R's `tempdir()` contains one (`/var/folders/…/T//Rtmp…`). A path value
    written into a block from `book_tempdir()` is therefore truncated at the `//` before the
    engine sees it, and the error names the truncated path rather than the real problem —
    ``[priors] from_fit: `/var/folders/…/T`: unsupported fit file extension `` instead of the
    schema mismatch above. ch24 wraps the path in `normalizePath()` with a comment saying
    why. Worth an upstream look: a path is the one place `//` is likely to appear innocently.
- ~~**ferx-r bug (found reviewing PR #26), important:** a `logit_probability` theta is
  back-transformed twice.~~ **Fixed** by [ferx-r #372](https://github.com/FeRx-NLME/ferx-r/pull/372),
  in the pin from `c08673d`. The ch05 callout and its `logit-probability-bug` chunk are
  replaced by a section on the two intervals (`logit-probability-interval`) and a runnable
  comparison with the same model declared on a `logit` theta (`logit-twin`). The ch16
  clause stays: it describes which scale each transform is reported on, which the fix
  does not change. Original finding: `.ferx_est_row()` handles `logit` and `logit_probability` in one
  branch and applies `inv_logit()` to both, but the engine returns a `logit_probability`
  theta already on (0, 1).
  - Measured: on `warfarin_logit_f`, reconstructing each subject's `F` from `estimate`
    matches the engine to 5.2e-18, while treating it as a logit is off by 0.53.
    `estimate_natural` reads 0.5032 where the individual `F` run 0.0105-0.0151, and
    `print()` tags the row `[logit scale]` with a `(typical)` line forty times the real
    value. `lower_95`/`upper_95` are the symmetric Wald and are not affected.
  - ferx-core is correct and correctly labelled; the same model parameterised as `logit`
    gives the same typical F (0.7923, both ways, from two independent fits) and a correct
    natural column.
  - Fix in [ferx-r #372](https://github.com/FeRx-NLME/ferx-r/pull/372), which
    also gives such a theta a natural-scale CI formed on the logit scale, so the two
    parameterisations agree on every natural column (to first order: the two fits differ
    by under 0.001). At the `c08673d` bump the ch05 callout and `logit-probability-bug`
    chunk came out; the ch05 table row, `logit-probability-check` and the ch16 clause stayed,
    since they describe the transform, not the defect.
- ~~**ferx-r usability gap (found reviewing the ch25 lookup tables):** a refused `ferx_fit()`
  drops the stable check-report code.~~ **Fixed** by ferx-r #378, in the pin from `6e2f701`:
  the refusal is a `ferx_engine_error` condition carrying `code`, `block`, `line` and
  `suggestion`, with the code appended to the message. Verified on `[not_a_block]`
  (`E_UNKNOWN_BLOCK`, line 30); the ch25 sentence in `tools/make-reference.R` now says so.
  Was: `ferx_model_validate()` returns `E_UNKNOWN_BLOCK` in
  `$diagnostics$code`, but fitting the same file raises only
  ``Error parsing model: Unknown block `[not_a_block]` (line 30). ...`` — same prose, no
  identifier. The stable code is therefore unavailable on the path most users hit first, and
  a script cannot branch on it without validating separately. ch25 says so; if the fit error
  gains the code, drop that sentence.
- **Book prose defect (found at the `6e2f701` bump, ch24):** the SDE section said system noise
  "is meant for residuals that are correlated in time within a subject". The engine at the pin
  (`src/ode/ekf.rs`) applies the Kalman update to the state covariance only; the state mean
  stays the ODE solution, so a `[diffusion]` fit is the ODE prediction with an inflated
  observation variance and cannot follow a subject's drift
  ([ferx-core #1285](https://github.com/FeRx-NLME/ferx-core/issues/1285)). The sentence is
  replaced by what the term does and does not do. ferx-core's own docs at `d66046e` still
  carry the old recommendation (fix open as ferx-core #1426; the website twin is
  [ferx-nlme.github.io #30](https://github.com/FeRx-NLME/ferx-nlme.github.io/issues/30), whose
  "ferx-book is clean" line missed this sentence). When #1426 is in the pin, link its
  "What the filter does not do" section from ch24.
- **Process finding (found at the `6e2f701` bump): prose that quotes a result can be true on
  one platform only.** Diffing the local macOS render against the live Linux render, with all
  numbers masked, showed two cases with the same engine on both sides:
  - ch05 `maxiter-stop` used `maxiter = 5`, which sits on the edge for warfarin FOCEI: macOS
    stops unconverged, the live site printed `converged TRUE` with no `convergence` warning
    under a sentence saying the fit is unconverged. Now `maxiter = 2` (unconverged up to 5
    locally, converged from 8) with a `stopifnot()` guard.
  - ch09 `ferx_globalsearch()`: the sentence "the runner-up has the better OFV and still ranks
    second" holds on the live Linux render (winner `CL-WT=none`) and not on macOS (winner
    `CL-WT=power`, which also has the best OFV). Left as is because CI is what publishes;
    a robust version needs the point made from the table by code, not by a fixed sentence.
  - The `W_DESIGN_DV` / `W_NO_DOSES` warnings `ferx_predict()` now passes on (ferx-r #283) are
    explained in ch11 and referenced from ch15 (muffled in the nine-model loop), ch18 and ch20.
  - `tools/make-reference.R` now escapes `<placeholder>` text in table cells; `model <name>` in
    the `model_name` row had been swallowed as an HTML tag.
- **ferx-r usability gap (found in the adversarial review of the `6e2f701` bump):** on a refused
  model `ferx_predict()` and `ferx_simulate()` print the engine's parse error and return
  `NULL` without raising an R error; only `ferx_fit()` raises `ferx_engine_error`. Verified on
  `[not_a_block]`. A script that checks for an error therefore continues with `NULL`. Filed as
  [ferx-r #385](https://github.com/FeRx-NLME/ferx-r/issues/385). **Fixed** in the pin from `5c9cc7a`:
  `ferx_fit()`, `ferx_predict()`, `ferx_simulate()` and `ferx_inits_from_nca()` all raise
  `ferx_engine_error` with `code = E_UNKNOWN_BLOCK` on `[not_a_block]`; the ch25 sentence in
  `tools/make-reference.R` now names the entry points. ch11 and ch22 `try()` chunks print a real error.
- **ferx-core doc imprecision (same review):** `maxiter` is documented as "maximum outer loop
  iterations", but the engine sets an evaluation budget, `maxiter * (n + 1)` on the NLopt gradient path
  and a separate value for BOBYQA (`outer_optimizer.rs`, `set_maxeval`); `n_iterations` was 8, 16, 24 for `maxiter` 1, 2, 3 on
  warfarin (n = 7). ch05 now says so. Filed as
  [ferx-core #1430](https://github.com/FeRx-NLME/ferx-core/issues/1430).
- **ferx-core doc gap (found building the ch25 lookup tables):** `docs/data-format.qmd` at
  `8372248c` never mentions `ADDL`, `FREMTYPE` or `TENTRY`, although the engine reads all
  three and the book fits `warfarin_addl`, FREM datasets and `TENTRY` delayed entry. They
  are the only three of the book's 14 data columns with no type and no description in the
  generated reference table, which leaves those cells blank by design rather than by
  invention. Adding them to the data-format table upstream fills the table automatically.
- **ferx-r doc bug (found reviewing the 078e489 bump; fixed by ferx-r #378 in the pin from
  `6e2f701` — the name is declared by a bare top-level `model <name>` line):** `?ferx_fit` says `model_name` is
  the "Model name from the `.ferx` file", falling back to the basename "when the file
  declares no name" — but no model-file syntax for declaring a name exists. ferx-core's
  block list is closed-world with no `[model]`/`[metadata]` block, and
  `.ferx_fit_from_raw()` falls back to the basename whenever the engine returns empty or
  `"Unnamed"`. Either the sentence is stale or the key is undocumented.
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

  The book shows only the first sentence of those errors (ch16, ch18) and does not print those model comments. `ferx_get_columns()` output is left as is (ch03). Under the softened rule (2026-10-02) all of these are analogies and may be printed; the cuts stay because they also keep the output short.
- ferx-core/ferx-r (found in 4.4, ch20), to check:
  - **`NaN` for zero time above MEC:** `integral(1.0, IPRED > MEC, window=24, …)` returns `NaN`, not 0, for windows where the condition never holds (`warfarin_derived_pkpd` with MEC 8, days 3–5).
  - **Bundled examples are weak demos:** `warfarin_derived_pkpd` uses MEC 0.5, below every warfarin concentration, so time above MEC is always 24 h. `emax_pkpd` has only 3 subjects, so the PD parameters are unidentifiable (RSE up to 5e4%).
  - **What ch20 does:** it shows both, plus a 30-subject simulation–estimation run.
- ferx-r/ferx-core (found in 4.4, ch21), to check:
  - **`print()` of a binary fit:** says "Obs: 0", "Structural: 1-cpt IV" and "Residual: per-CMT ()" for `binary_logistic`.
  - **Misclassified notice:** the finite-difference inner-gradient notice is categorised `data_quality` (warning).
  - **FOCE runs without complaint:** the docs say FOCE is biased for binary endpoints, but `method = "foce"` on the random-intercept model runs silently with the same OFV as FOCEI.
  - ~~**SAEM default seed:** on that model the default seed ends at a degenerate point (RSE 2e6%), while seeds 1–3 agree.~~ Gone at `5c9cc7a` with the new SAEM defaults (`scale_adaptation = robbins_monro`, `n_mh_steps = auto`): no seed needs a regularized covariance step, but the four runs now scatter (`ETA_I` 0.39-0.56). ch21 reports the spread, and how many runs needed a regularized covariance step, with inline numbers.
- ferx-r/ferx-core (found in 4.4, ch22), to check:
  - **Empty `sdtab`:** TTE-only fits return an empty `sdtab` (0 rows).
  - **Stale model comment:** the `tte_exponential` comment says `[event_model]` cannot reference individual parameters; the docs now say it can.
  - **`ferx_simulate()` without `horizon`:** it prints "Error simulating: …" and returns NULL rather than raising an R error.
- ferx-core/ferx-r (found in 4.5, ch24), to check:
  - **`warfarin_dcm`:** the fitted network (141 weights, FOCEI/lbfgs, 27 s) outputs a constant clearance multiplier (1.0319 for all 30 subjects, sd 8e-9), reaching the base-model OFV (−1185.46 vs −1185.40). The explicit covariate model reaches −1199.33.
  - ~~**Regularised DCM:** `settings = list(nn_l2 = 0.01)` did not finish within 10 min with bobyqa, or within about 25 min with lbfgs. The book documents `nn_l2`/`nn_smooth` without running them.~~ At `5c9cc7a` it finishes in about 10 s (the unregularized DCM fit takes 0.3 s on the analytic gradient), so ch24 runs it (`dcm-regularized`). It exposes the next item.
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

- **Found at the `5c9cc7a` (v0.4.0) bump.** Every chapter re-rendered from an empty cache and diffed
  against the `6e2f701` render, with numbers masked; every changed claim was rewritten from the output
  and backed by a `stopifnot()` guard. Upstream items:
  - **ferx-core: two new messages arrive as `general`.** The engine classifies warnings by message text
    (`src/types.rs`), and neither new message matches an arm: the `W_AUTO_OPTIMIZER_FOLLOWS_GRADIENT`
    fit note ("gradient = fd also changed the outer optimizer", on every `gradient = fd` model with
    `optimizer = auto` -- `two_cpt_oral_base`, `emax_pkpd`) and the #1154 outer-gradient note ("N of M
    subjects could not be given the exact analytic outer gradient", on `two_cpt_oral_cov`,
    `warfarin_ode`, `mm_oral`, `warfarin_if`, `warfarin_dcm`, ...). `gradient_fallback` /
    `optimizer_config` would fit. Filed as [ferx-core #1618](https://github.com/FeRx-NLME/ferx-core/issues/1618). The book explains both as `general` notes (ch05 list and
    `warnings` chunk, ch06 `gradient-moves-optimizer` / `outer-gradient-note`, pointers in ch07, ch17, ch20);
    when they get a category, the guards in ch05, ch07, ch17 and ch20 stop the render.
  - **ferx-core docs gap:** `docs/warnings.qmd` at `2a6076af` has no row for `init_not_representable`, so
    its severity and description are blank in the generated ch25 table. Already tracked: ferx-core #1436, closed into #1439 (docs drift, item 4). ch06 documents and runs it
    (`init-not-representable`).
  - **ferx-core bug, important: a fit whose every outer trial is guard-rejected reports convergence at
    the midpoint of its bounds.** Investigated at the `5c9cc7a` bump. When more than
    `max_unconverged_frac` (default 0.1) of the subjects' inner loops fail, `ebe_guard_rejects()`
    (`src/estimation/outer_optimizer.rs`) rejects the trial and returns `1e12` plus a centre-push term
    `100·(xs − c)`, `c` = scaled bound midpoint. If every trial is rejected, NLopt L-BFGS minimises the
    penalty and returns `Success` (warfarin, `inner_maxiter = 5`: evals 1-3 all ≥ 1e12, eval 3 exactly
    `1e12` at the centre). The fit then "restores the best-seen point (OFV = 1e12)", the final inner loop
    scores it (220.52, a true objective there: an evaluation-only refit with the default inner budget
    gives 220.54), and the result is `converged = TRUE` with no `convergence` warning. The
    `ebe_start_dependent` check cannot fire, because the cold solve (220.5) beats the best-seen 1e12.
    Measured: warfarin at `inner_maxiter` 3/5/6 lands on the geometric bound midpoints (TVCL 0.1,
    TVV 7.071, TVKA 0.7071, omegas 1) to 3e-9, OFV ≈ 220.5 against -280.36; `mm_oral` at 10 to 2e-8
    (OFV 442 against -453). Under `bobyqa` (or `two_cpt_oral_base`'s `gradient = fd`) the optimizer
    stalls at the initial values instead, which `stalled_at_init` reports. Default-budget fits from bad
    initial values did not trigger it. **Not a regression:** the `6e2f701` engine (built into a scratch
    library) gives the same midpoints at k ≤ 6; 0.4.0 improved k = 7 and 10, which used to report a fit
    at the optimum as unconverged with `ebe_start_dependent` -- which is why ch06's old demo stopped
    triggering. **At `161d28a` (core `826d3bb9`)** the defect is still there at `inner_maxiter = 3` (exact
    midpoints, `converged = TRUE`, OFV 223.35, no `convergence` warning) and on `mm_oral` at 10, but 5, 6 and 7 now
    end `converged = FALSE` with a critical `convergence` warning, so ch06's demo moved from 5 to 3.
    Fix direction: treat "no feasible evaluation" as non-convergence (critical
    `convergence` naming the guard) instead of restoring a penalty point. Filed as [ferx-core #1617](https://github.com/FeRx-NLME/ferx-core/issues/1617). ch06
    (`starved-inner-loop`) shows it in an "at this build" callout whose guard stops the render once the
    engine reports it. Replaces the old
    `ebe-start-dependent` demo (`inner_maxiter = 10` on warfarin), which no longer raises the warning;
    `warfarin_sde` is now the only bundled example that does, and ch06 uses it.
  - **ferx-core: a fit restarted at its own optimum.** `bobyqa` and `nlopt_lbfgs` now report
    `converged = FALSE` with a critical `convergence` warning beside `stalled_at_init`; `slsqp` reports
    `converged = TRUE`. The `W_STALLED_AT_INIT` text still says "`converged` may be true". ch06
    (`stalled-at-init`) shows both optimizers.
  - **ferx-core: DCM fits stop far from their optimum** ([#1561](https://github.com/FeRx-NLME/ferx-core/issues/1561),
    known issue of the release). Unpenalized OFV of `warfarin_dcm` (FOCEI, no covariance step): no
    penalty -1185.46 (constant multiplier, sd 7e-9); `reconverge_gradient_interval = 1` -1160.47;
    `optimizer = bobyqa` -1178.81; `nn_l2` 0.001 -1210.39, 0.01 -1393.12, 0.1 -1513.90. A heavier
    penalty cannot legitimately reach a better unpenalized objective, so the unpenalized fit converges at
    least 330 above its optimum. `two_cpt_oral_cov` gives -1199.33. ch24 now says so, runs the `nn_l2 =
    0.01` fit, and keeps the AIC comparison (the explicit model still wins, -1173 vs -1089).
  - **ferx-core: `block_sigma` correlation (#847).** ch16's `correlated_combined` fit now estimates the
    residual correlation and ends at OFV -280.308, 0.06 above the nested `combined` fit (-280.363), with
    rho 0.995 (SE 29) and `covariance_regularized`; `ADD_ERR` collapses to 3e-4, so rho is unidentified.
    The chapter's claim (extra parameters not supported) holds; not reported further.
  - **Behaviour changes absorbed in prose:** `ferx_inits_from_nca()` reads through the engine reader
    (ferx-r #391), and the NCA-start FD fit of `two_cpt_oral_base` now ends 33 above the model-file fit
    with only `warning`-level notes and passes every strictness gate (ch05, ch09 `strictness-fail`, ch10
    now uses `emax_pkpd` as its bad-covariance example); the `warfarin_block_omega` iivsearch now selects
    the diagonal structure and the `algorithm = "skip"` candidate no longer stalls (ch09); both ruvsearch
    prescreen passes pick `time_varying1` (ch09); reloaded fits keep their warning categories (ferx-r
    #308, ch13); `ferx_simulate()`/`ferx_predict()` pass on `W_CMT_DEFAULTED` and model notes (ch20,
    ch22); the `multi_start` note appears only when a start other than the first wins (ch06). The
    `emax_pkpd` numbers changed as well; ch20 now fits with `gradient = "auto"` (below).
  - **ferx-core bug: a covariate exponent shared by two typical values drifts to its lower bound
    under SAEM.** Filed as [ferx-core #1620](https://github.com/FeRx-NLME/ferx-core/issues/1620).
    **Fixed** by core 956e7951 (#1632), in the pin from `161d28a`: the shared exponent takes one joint
    M-step, every SAEM variant lands within 2 MC errors of FOCEI on the importance-sampled objective, and
    ch06's callout, its check and the separate-exponent remedy are gone; a "Changed after ferx-r 0.4.0"
    callout tells 0.4.0 readers about the drift.
    Found while moving ch06's M-step demo off `warfarin_saem` (every theta there has an eta, so
    `mstep_draws = 4` was bit-identical and the demo showed nothing). In `two_cpt_oral_cov`,
    `THETA_WT` scales CL and V1; #619 records both covariate mu-references and declines V1's ("THETA_WT
    already belongs to another covariate mu-reference"). THETA_WT then joins only CL's group step (the
    numerical M-step pins it; the engine note saying it "stays on the numerical M-step" is wrong for
    it) and drifts: seed 1, default solver, 0.151 at 150/250 and 0.010 (the bound) at 300/700, 300/1500
    and 600/3000; `score_sa` reaches 0.010 within 150/250 on seeds 1-3. Importance-sampled -2 log L at
    the final estimates (MC error about 0.3): FOCEI -1199.38 (0.653); SAEM default 150/250 -1194.9 to
    -1197.4; 300/700 -1192.4 to -1194.3. Controls: `mu_referencing = false` (no groups) is noisy but
    does not drift; the exponent routed through an `if` local (plain no-ETA theta) does not drift and
    `score_sa` is close to FOCEI there; one exponent per typical value stays at FOCEI's optimum
    (0.73, IS -1199.4 to -1199.5) at every schedule for both solvers. Data simulated with 0.75.
    So it is not a `score_sa` defect: `score_sa` only gets to the bound sooner. ch06 shows the default,
    both settings, the longer-schedule drift (`saem-shared-exponent-drift`, "at this build" callout,
    guarded) and the remedy (`saem-mstep-remedy`).
  - **Book prose defect (pre-existing, fixed at this bump):** ch16 said a refused `ferx_fit()` carries
    "the message but not the code"; since ferx-r #378 the refusal appends `[E_BLOCK_VARIANCE_ONLY]` and
    carries `$code`. `block-sd-fit` now shows and guards the code.
  - **Still open, rechecked:** `ferx_model_validate()` still reports compact TTE models invalid (ch22
    callout stays). The SDE docs fix (ferx-core #1426) is in the pin; ch24 links its "What the filter
    does not do" section.
  - **Link host:** ferx-r moved its links to `ferx-nlme.org` after the release (9c62b18). The book
    followed in this PR (9a55b6b), and `tools/audit.R` now flags the old host. Two old-host links remain
    in generated output (the `library(ferx)` package link from the installed `DESCRIPTION`, a URL inside
    a ch09 engine message); both redirect.
  - **ferx-r/ferx-core: `emax_pkpd`'s `gradient = fd` stops short of the optimum, and ch20's old
    "recovery" was an artifact of it.** The model file sets `gradient = fd  # required: per-CMT / Form C
    readout`, but at `5c9cc7a` ferx has an analytic gradient for it (`gradient_used` "analytic" under
    `gradient = "auto"`). On ch20's 30-subject simulation at 100 (seed 42) the FD fits converge near
    their start, which in a simulation-estimation run is the simulation truth: FD/bobyqa -247.77
    (EMAX 38.9, EC50 5.27, regularized covariance, RSE to 66,606%), FD/slsqp -246.45 (34.2, 4.23, clean
    covariance), FD/nlopt_lbfgs -245.93. The analytic gradient reaches -256.88 (EMAX 10.8, EC50 0.90),
    also when started at the truth, and the truth itself scores -233.10. The objective agrees between
    paths (the analytic optimum scores -256.877 on the FD path with `maxiter = 0`). The design is the
    real problem: the concentration never exceeds 2.9, below EC50 = 5, and across seeds 42/1/2/3 the
    analytic optimum puts EMAX at 10.8 / 200 (bound) / 17.7 / 135. With ten subjects each on
    100/300/1000 every seed recovers EMAX 36.7-42.3, EC50 4.25-5.48 with RSE <= 28%, and the FD fits
    still stop 2.7-11 above the optimum there. The `6e2f701` build (scratch library) reaches the same FD
    point (-247.77) on identical simulated data; its render printed RSEs of 3-28% at a nearby point, so
    the old sentence "all parameters are recovered with moderate standard errors" described a fit that
    had stopped near its starting values. ch20 now fits with `gradient = "auto"` (main fit included,
    3-subject analytic -36.94 vs FD -34.13), shows the 100 design missing EMAX/EC50 against the
    objective at the simulation values (`maxiter = 0`), a dose-range design recovering them, and the FD
    fits in an "at this build" callout (`pkpd-sim-fd`) whose hidden check also verifies the objective
    agreement. ch09/ch10 keep the model-file fit as their unreliable-fit example (still condition number
    > 1000 and |r| > 0.95 at the analytic optimum). Filed as
    [ferx-core #1625](https://github.com/FeRx-NLME/ferx-core/issues/1625): the example lives in ferx-core
    and ferx-r mirrors it byte for byte (plus line 6 of ferx-r's `ex_emax_pkpd.R`); ferx-core's own
    `scaling_multi_analyte.ferx` already says per-CMT Form C readouts are analytic since #439. The FD gap
    itself is [ferx-core #520](https://github.com/FeRx-NLME/ferx-core/issues/520) (FD stencils reading ODE
    integration noise at the default tolerances), where the v0.4.0 sweep is posted (comment 2026-10-02):
    the model-file fit gives -34.133 / -24.001 / -35.694 / -36.775 at `ode_reltol` 1e-4 / 1e-6 / 1e-8 /
    1e-10, so the level #520 proposes for FD fits (1e-6 / 1e-8) makes this one worse. ch20 links #1625.
  - **ferx-core: Bayes does not converge on the two-compartment models.** Default `method = "bayes"`:
    `two_cpt_oral_base` max R-hat 1.194, `two_cpt_oral_cov` 2.735. Longer chains do not help: base
    1.188 / 1.197 and cov 3.047 / 7.158 at 3000 / 6000 warmup and draws per chain (the cov value grows).
    The engine message recommends longer chains. Not a regression (`6e2f701` gave the same 2.735 on the
    covariate model). `warfarin` converges under the defaults (max R-hat 1.003, min bulk ESS 742). ch06
    now demonstrates Bayes on warfarin and shows the base-model failure in an "at this build" callout
    (`bayes-base`); ch10 shows the covariate model at both chain lengths and leaves Bayes out of the
    interval comparison. Filed as [ferx-core #1626](https://github.com/FeRx-NLME/ferx-core/issues/1626)
    after isolating three causes (2026-10-02; `bayes.rs` unchanged on main): (1) base model, the block-MH
    eta kernel stalls: max R-hat 1.194 / 1.197 / 1.201 at 1,000 / 6,000 / 20,000 draws per chain, bulk ESS
    of OMEGA(2,2) 9 / 7 / 6, `n_mh_steps = 50` no better (1.41 at 6,000), while HMC proposals
    (`n_leapfrog = 10`) converge at 4,000 (max R-hat 1.003; with 5 leapfrog steps 1.039, at 2,000 draws
    1.876); (2) covariate model, the random-walk theta block ignores declared bounds (`log = theta_lower
    >= 0`, no bound check, while the mu-ref move clamps) and the exponents drift towards zero, 2.5%
    quantiles ~1e-8 against the 0.01 bound (HMC at 4,000: max R-hat 7.33); (3) covariate coefficients
    barely move at fixed eta even sampled on the natural scale (R-hat ~2 at 6,000). Not #1620's
    shared-exponent mechanism: separate exponents on CL and V1 do no better. ch06's callout now also runs
    the base model with HMC proposals (converged); ch10's Bayes section is an "at this build" callout that
    adds the HMC run and the exponents' 2.5% quantiles below their bound.
  - **ferx-core: the bundled `warfarin_sde` fit stops at a saddle point.** Found while answering why
    ch24's SDE standard errors run to 255,000%. `[diffusion]` needs finite differences
    (`gradient_method = fd`), so `optimizer = auto` resolves to bobyqa, which stops at OFV -279.15 with
    `covariance_regularized` reporting negative curvature (min eigenvalue -413 of max 7163): not a
    minimum, so every standard error is meaningless. `nlopt_lbfgs` reaches -279.55 with DIFF_CENTRAL 6e-8
    and ordinary standard errors (max 40%); slsqp -274.66. The model without `[diffusion]` stops short
    with its FD settings too (bobyqa -277.24, slsqp -275.74, nlopt_lbfgs -271.88, all regularized) and
    reaches -280.36 with the analytic gradient (max RSE 46%, = the analytical warfarin model). The SDE
    model with DIFF fixed at 1e-12, evaluated at that optimum, scores -280.37, so the models coincide
    there and even the nlopt_lbfgs SDE fit is 0.8 short. FOCEI: bobyqa -276.10 (DIFF 5.3e-5);
    nlopt_lbfgs does not leave the starting DIFF 0.01 (OFV -125.0). ch24 now explains the saddle, shows the
    nlopt_lbfgs refit and the four-way comparison (`sde-lbfgs`, `sde-vs-ode`, checks hidden), and drops
    the FOCE-vs-FOCEI variant, which compared two fits that had stopped short. ch06 keeps the bundled fit
    for its `ebe_start_dependent` demo and says it stops at a saddle. Not filed: it is
    [ferx-core #520](https://github.com/FeRx-NLME/ferx-core/issues/520) (FD stencils at the default ODE
    tolerances), and the fit's own `covariance_regularized` message already names the remedy (#1508). The
    v0.4.0 sweep is posted on #520 (2026-10-02): -279.152 (saddle) / -280.147 / -279.264 / -280.184 at
    `ode_reltol` 1e-4 / 1e-6 / 1e-8 / 1e-10, so the FD/bobyqa stop is not monotone in the tolerance. At the
    tolerances the message names (1e-6 / 1e-8) the model file's bobyqa fit reaches -280.147, below
    nlopt_lbfgs (-279.55), with no regularization, DIFF_CENTRAL 2e-6 (RSE 302%) and ordinary structural
    RSEs. ch24 now prints that sentence of the message and runs the refit (`sde-tolerance`), uses it as
    the furthest SDE fit in `sde-vs-ode` and for the simulation variant, and links #520.
  - **Platform dependence (2026-10-03): the first Linux CI run of #33 failed.** CI had never run on
    this PR: it conflicted with `main` (#32) from the start. Its first run (`f37b181`) stopped at ch06
    `check-ebe-start-dependent`. A local x86_64 Linux container that mirrors the workflow (R 4.4.3,
    stable Rust, Quarto 1.10.18, ferx-r at the pin) rendered every chapter with failing checks logged
    instead of fatal. Seven checks failed, all on fits whose stopping point depends on rounding:
    ch06 `ebe_start_dependent` on the SDE fit (macOS raises it, Linux not) and the `multi_start` note
    (the single start and the best of 8 agree to 2.7e-07 at -453.3985; Linux's note names start 3); ch20 a regularized covariance on one FD fit (not
    stated in the prose); ch24 the SDE fit (model-file OFV -279.15 macOS / -276.31 Linux, both at negative
    curvature; `nlopt_lbfgs` clean on macOS, regularized with RSEs to 628,000% on Linux; the FD ODE fit
    3.1 / 0.34 above the analytic one) and the DCM network (penalized fit 208 OFV below the unpenalized
    one on macOS, 11 above it on Linux, where the unpenalized fit learns a covariate effect). What holds
    on both: negative curvature at the model-file SDE fit and the FD ODE fit, the tolerance refit (1e-6 /
    1e-8: -280.15 / -280.24, clean covariance), the analytic ODE fit (-280.36 on both), every analytic
    PK/PD fit to the printed digit. The chapters now rest only on those: ch06 explains
    `ebe_start_dependent` without a live fit and reads the multi-start note from the fit; ch24 builds the
    SDE story on the tolerance refit (the `nlopt_lbfgs` refit is gone), states that the model-file fit
    and the unpenalized network differ between machines, and its DCM prose and checks hold either way.
    The probe logged only the first failing condition of each check, so a second render found one more:
    the SDE model evaluated at the ODE optimum with the diffusion fixed near zero scores -280.48 on
    Linux at the default tolerances (macOS -280.37, ODE optimum -280.36); at 1e-6 / 1e-8 both give
    -280.3639, so `check-sde-vs-ode` now evaluates there.
    Lesson: render on Linux before calling a PR ready; the site is built there.
  - **Review round 4 (2026-10-02): reader-facing fixes.** A review of what a reader can run and learn,
    chapter by chapter, found (a) visible code calling `book_tempdir()` and relying on packages attached
    only by the hidden `_common.R` -- now every chapter loads ferx, dplyr and ggplot2 in a visible
    `packages` chunk, writes to a directory under `tempdir()` created in visible code, and `_common.R`
    attaches nothing (CLAUDE.md rule 8, enforced by the audit); (b) `book_settings_table()` calls and
    render-check `stopifnot()`s with maintainer comments in reader code -- the tables are `echo: false`
    with captions, the checks moved to `include: false` chunks labelled `check-<label>`; (c) a global
    `options(scipen = 100)` that reformatted printed output -- now applied only inside the inline hook;
    (d) prose contradicted by its own output: ch20's simulation-estimation (above), ch24 "with FOCEI the
    diffusion variance is even smaller" (it was about 4x larger; wrong at `6e2f701` too; the variant is now
    gone, see the `warfarin_sde` entry above), ch24's SDE standard errors (above), ch14
    `[initial_conditions]` described as an ODE feature (it is analytical-only and a parse error on an
    ODE model; ch14 now runs both forms); (e) examples that showed little: ch11 `match` (now compared
    subject by subject with plain simulation), ch19 ULOQ and ch23 strategy tables (now read in computed
    prose), ch06 `final_gradient` (now beside a gradient-based fit), ch05 EBE fallbacks (explained),
    unexplained warnings in ch15 (the inverse-Gaussian `general` note) and ch17, ch20 and ch22 (R warnings
    from fixed parameters), now explained and checked; (f) a deprecated
    `geom_errorbarh()` (ch10) and a misplaced ruvsearch paragraph (ch09, now computed).

- **ferx-r, found 2026-10-09 (ch24, at `161d28a`), not filed:** `print.ferx_fit` collapses a level block of 20 or more free coefficients into a THETA BLOCKS line (#413), but the `Structural:` line under MODEL STRUCTURE (`.ferx_format_structural()`, `R/internal-fit-format.R:131`) still lists every level by name, so for an MBMA block with hundreds of levels that line is the long one. ferx-core has no such line. ch24 shows it in an "At this build" callout; remove it when fixed.

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
| D1 | Pin | **Decided:** ferx-r `origin/main`, bumped as upstream fixes land: `846aa4b` -> `67357e8` -> `078e489` -> `c08673d` -> `70f7fe3` (ferx-core `7abf4235`) -> `a961146` (ferx-core `d66046e`) -> `6e2f701` (ferx-core `d66046e`, unchanged) -> `5c9cc7a`, the ferx-r **v0.4.0 release tag** (ferx-core `2a6076af`, its v0.4.0 tag; read from `src/rust/Cargo.lock`); re-pin to the next release tag when cut. -> `161d28a` (ferx-core `826d3bb9`; 2026-10-09, ferx-book#34: `fit$theta_levels$value` and the compact level print, `.fitrx` level layouts, data selection and settings followed by `ferx_covariance()` / `ferx_sir()`). Not a release tag, so `ferx_r_tag` and its ch01 sentence are gone. `_variables.yml` carries `ferx_r_tag` while the pin is a tagged release (ch01 offers it as the install ref); drop it if a later pin is not. Read the ferx-core SHA out of that ferx-r commit's `src/rust/Cargo.lock`; never infer it from `src/rust/Cargo.toml`, which says `branch = "main"` and reads as unpinned. `_variables.yml` carried a stale `ferx_core_sha` (`8372248c`) through the `70f7fe3` bump for exactly that reason |
| D2 | xpose | **Decided:** mention only; `ferx_xpose` eval-reason |
| D3 | Branching | **Decided:** WIP snapshot + `book/v2-workflow` from main |
| D3b | Examples | **Decided (revised by owner 2026-09-11):** run every example that can run; variants via live loops; list only smoke failures with the recorded error |
| D7 | Other NLME software | **Decided:** ferx only; no comparison chapter or text. **Revised by owner 2026-10-02:** an analogy to another engine is allowed when it shows what an example or feature corresponds to; no named comparison claiming ferx is better or improved (CLAUDE.md rule 6) |
| D4 | Mirror ferx-core examples into ferx-r for features that fit from R but have no bundled example: `[covariate_model]` (two_cpt_oral_covmodel), repeated TTE (rtte_exponential, rtte_weibull_reset), fixed-rate infusion (dose_rate, one_cpt_infusion) | **Decided (2026-09-11):** the book gives **mention + link only** for now. Bundling these examples is an **open ferx-r follow-up** (Step 7). Once a ferx-r release bundles them: re-pin (rerun Step 0.2/0.5/0.7), then run them in their home chapters (17 covariates, 22 TTE, 18 dosing) |
| D6 | Part II thread = two_cpt_oral_base → two_cpt_oral_cov | **Confirmed on timing (0.5):** base fit 0.9 s, cov fit 0.5 s, covsearch 78 s, bootstrap 50 in 13 s. The covsearch selection outcome is reported as the run gives it in ch 09 |
| D8 | Readers on the last release vs a pin past it | **Decided by the owner (2026-10-09, ferx-book#34):** the pin may run ahead of the release, and the book says what needs more. Rows of `features.csv` missing from the release inventory (`tools/features-release.csv`) are named in a "Needs ferx-r newer than" callout in their home chapter (audit-enforced, and stale callouts fail); changed behaviour gets a hand-written "Changed after ferx-r" callout; ch01 `#sec-versions` lists both; ch26 lists the newer rows. Preferred end state: re-pin to a release tag (0.4.1) when ferx-r cuts one, which empties both callout kinds (CLAUDE.md "Versions") |
