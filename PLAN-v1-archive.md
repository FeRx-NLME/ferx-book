# PLAN.md — Restructure ferx-book into a PKNCA-style workflow tutorial

Status: **executed** (branch `restructure/workflow-tutorial`, no PR yet). Owner: TeunP.

## 0. Build status (2026-06-27)

Full restructure built and rendered with execution on. Structure now:
**Getting started** (01 installation · 02 workflow · 03 model-file) ·
**The core loop** (04 fitting · 05 diagnostics · 06 simulation-vpc · 07 uncertainty) ·
**Modeling scenarios** (08 covariates · 09 transforms · 10 absorption · 11 ode ·
12 pkpd · 13 iov · 14 bloq · 15 dosing · 16 custom-readouts · 17 record-selection ·
18 time-to-event) · **Context & reference** (20 reproducibility · 21 experimental ·
22 for-nonmem-users · 23 reference).

### Deviations from the proposed plan (all for runnability/integrity)
- **No separate `19-scaling-up`.** `04-fitting` kept comprehensive (multistart/async/
  optimizer already render well there); carving it out was the riskiest edit for the
  least reader gain. Left as a future split.
- **TTE folded into Modeling scenarios, not its own Part, and is non-runnable.**
  ferx-r ships no TTE dataset/model/example; `18-time-to-event.qmd` is honest
  illustrative DSL (non-executed) + a clear "not yet runnable" banner.
- **Weibull absorption is illustrative only** — not in the installed registry
  (`ferx 0.1.6`); `transit_2cpt` and `igd_inverse_gaussian` are the runnable ones.
- **LTBS** lives in `09-transforms` (`{#sec-ltbs}`), not its own slot.
- Every relocated chunk kept its original `eval:` status verbatim — the existing
  `eval: false` fits (derived/ss/data-selection/sde/frem) stay non-executed; no fits
  were fabricated.



## 1. Goal

Turn ferx-book from a **feature reference** (one chapter per feature, mirroring the
ferx-core book) into a **workflow tutorial** in the style of the
[PKNCA book](https://humanpred.github.io/pknca-book/): a reader who follows the
steps top to bottom learns every feature in the order a real project needs them.
The pkgdown reference and the ferx-core DSL book remain the place for exhaustive
lookups; the book is the guided narrative.

### Done means
- A short **Workflow Overview** chapter teaches the whole loop with one minimal,
  complete, runnable example.
- Deep **concept** chapters (model file, fitting, diagnostics, simulation,
  uncertainty) follow, each organized by sub-topic with reference tables embedded.
- A catalogue of **task/scenario** chapters with how-to titles, each
  self-contained and runnable.
- **TTE**, **scaling/advanced estimation**, and **context + reference** close the book.
- **Every exported ferx-r function and every stable/beta ferx-core feature is
  covered somewhere** (see §5 coverage map).
- Every code chunk runs against the installed ferx-r (CLAUDE.md audit + a full
  `quarto render` pass green), with maturity respected (NN/DCM is pointer-only).

## 2. Principles (borrowed from the PKNCA book)

1. **Name the steps once, repeat them everywhere.** ferx's five steps:
   **data → specify → fit → diagnose → simulate**. A banner atop each Part-1
   chapter shows which step it covers.
2. **Lead chapter = whole loop, minimal.** One end-to-end runnable example, then
   variations of each step.
3. **Concept chapters embed their reference tables**, they don't defer everything.
4. **Task-oriented titles**, not feature names ("Handling data below the limit of
   quantification", not "BLOQ/M3").
5. **Voice change per chapter:** kill every `## Overview` + bare option-table dump.
   Replace with "where you are → the problem → the move → the result."
6. **Defer exhaustive lookups** to pkgdown + DSL book with one-line callouts.
7. **Respect maturity.** Each scenario chapter opens with a maturity callout.
   Experimental features are clearly labelled; NN/DCM is not runnable in the
   default build and is pointer-only (see §6).

## 3. The warfarin thread

Warfarin is the single thread. It works across the whole book because ferx-r
ships warfarin **variants** purpose-built for each feature:

| Feature | Dataset | Warfarin variant? |
|---|---|---|
| Core loop / covariates / transforms | `warfarin`, `warfarin_additive_eta`, `warfarin_logit_f` | yes |
| Inter-occasion variability | `warfarin_iov`, `warfarin_iov_saem` | yes |
| Below limit of quantification | `warfarin_bloq` | yes |
| Dosing (SS / ADDL / lag) | `warfarin_ss`, `warfarin_addl`, `warfarin_ode_lagtime` | yes |
| Custom readouts (scaling/derived) | `warfarin_scaled`, `warfarin_derived` | yes |
| Record selection | `warfarin_if`, `warfarin_data_selection` | yes |
| SDE (experimental) | `warfarin_sde` | yes |
| Multi-start / SAEM | `mm_multistart`, `warfarin_saem` | mostly |
| **Nonlinear / ODE (Michaelis-Menten)** | `mm_oral` | **no — feature needs nonlinear data** |
| **Multiple endpoints (PK/PD)** | `emax_pkpd` | **no — feature needs a PD endpoint** |
| **Built-in absorption (transit/igd/weibull)** | `transit_2cpt`, `igd_oral` | **no — needs absorption-shaped data** |
| **Time-to-event** | TTE dataset (TTE-only or PK-joined) | **no — feature needs events** |
| Bioavailability | `bioavailability` | independent |

Exceptions are deliberate and called out in-chapter ("warfarin has no PD endpoint,
so this chapter switches to the bundled `emax_pkpd` data").

## 4. Target structure (old → new)

### Part 1 — Foundations
| New | Title | Maturity | Source |
|---|---|---|---|
| `index.qmd` | Preface (+ "The core workflow" box, intro warfarin) | — | rewrite |
| `01-installation.qmd` | Installation | — | keep `01` |
| `02-workflow.qmd` | **Workflow Overview** (5-step + minimal warfarin run + per-step variations) | stable | merge `02-quickstart` + narrative of `03-model-workflow` |
| `03-model-file.qmd` | The model file (DSL essentials + structural reference) | stable | `03-model-workflow` + DSL essentials |
| `04-fitting.qmd` | Fitting: methods & options (FOCE/FOCEI core; intro to chains) | stable | `04-fitting` (trim; tuning → ch20) |
| `05-diagnostics.qmd` | Diagnostics (GOF, shrinkage, residuals, warnings, **NPDE**) | stable | `05-diagnostics` + `ferx_npde` |
| `06-simulation-vpc.qmd` | Simulation & VPC | stable | `06-simulation-vpc` |
| `07-uncertainty.qmd` | Quantifying uncertainty (covariance, **SIR**, **IMP/impmap**, sim-with-uncertainty) | beta | `08-uncertainty` |

### Part 2 — Building the model (scenarios)
| New | Title | Maturity | Source |
|---|---|---|---|
| `08-covariates.qmd` | Adding covariates (+ `cov_screen`, `eta_cov`, **FREM** via `ferx_to_frem`) | stable | new (pull cov screen out of `05`) |
| `09-transforms.qmd` | Parameter transforms & bounded parameters | stable | `07-parameter-transforms` |
| `10-absorption.qmd` | **Modeling absorption: transit, inverse-Gaussian, Weibull, lag time** | beta | NEW (`transit_2cpt`, `igd_oral`, `warfarin_ode_lagtime`) |
| `11-ode-models.qmd` | Fitting nonlinear ODE models | beta | `08-ode-models` (`mm_oral`) |
| `12-pkpd.qmd` | Modeling multiple endpoints (PK/PD) | stable | `12-multi-endpoint-pkpd` (`emax_pkpd`) |
| `13-iov.qmd` | Inter-occasion variability | stable | `10-iov` |
| `14-bloq.qmd` | Handling data below the limit of quantification | beta | `09-bloq-m3` |
| `15-dosing.qmd` | Dosing scenarios: steady-state, ADDL, bioavailability | stable | split from `14-special-features` |
| `16-custom-readouts.qmd` | Custom readouts: scaling, `[derived]`, `[output]` | beta | split from `14-special-features` |
| `17-record-selection.qmd` | Selecting & excluding records | beta | split from `14-special-features` |

### Part 3 — Time-to-event
| New | Title | Maturity | Source |
|---|---|---|---|
| `18-time-to-event.qmd` | Time-to-event models (data format, exponential/Weibull/Gompertz hazards, censoring + `TENTRY`, `ferx_predict_survival`, PK-driven hazards) | beta | split from `14-special-features` + ferx-core `estimation/tte.qmd` |

### Part 4 — Scaling & advanced estimation
| New | Title | Maturity | Source |
|---|---|---|---|
| `19-scaling-up.qmd` | Scaling up fits: method **chains**, **SAEM**, multi-start, **async** (`ferx_fit_async`/`ferx_collect`), optimizer/GN tuning | beta | heavy parts of `04-fitting` + `mm_multistart`, `warfarin_saem` |

### Part 5 — Context & reference
| New | Title | Source |
|---|---|---|
| `20-reproducibility.qmd` | Reproducibility & reporting (`save_fit`/`load_fit`, **`ferx_xpose`**, `ferx_runlog`) | from `04`/`14` |
| `21-experimental.qmd` | Experimental features: **SDE** (runnable, `warfarin_sde`, with `W_EXPERIMENTAL_SDE` callout); **Neural networks / DCM** (pointer-only — needs `--features nn`, not in default build) | split from `14` + ferx-core NN docs |
| `22-for-nonmem-users.qmd` | For NONMEM users — short translation guide | NEW (confirm wanted) |
| `23-reference.qmd` | Reference appendix — consolidated option tables, maturity table, pkgdown/DSL pointers | new |

Net: today's 19 KB `14-special-features` grab-bag becomes ch15–18 + ch21; heavy
fitting tuning leaves ch04 for ch19; three previously-uncovered areas get homes
(absorption, FREM, NPDE, xpose, full estimation roster).

## 5. Function → chapter coverage map (no orphans)

| Function(s) | Chapter |
|---|---|
| `ferx_example`, `ferx_columns` | 02 |
| `ferx_model*`, `ferx_get/set_section` | 02–03 |
| `ferx_inits_from_nca`, `ferx_check_init` | 03–04 |
| `ferx_fit` | 02, 04 |
| `ferx_estimates`, `ferx_cor_matrix` | 04 |
| `check_diagnostics`, `ferx_warnings`, `ferx_npde`, `ferx_eta_cov`, `ferx_cov_screen` | 05, 08 |
| `ferx_runlog`, `ferx_runlog_iters`, `ferx_trace`, `ferx_plot_trace` | 04, 20 |
| `ferx_predict`, `ferx_simulate` | 06 |
| `ferx_sir`, `ferx_simulate_with_uncertainty` | 07 |
| `ferx_to_frem` | 08 |
| `ferx_predict_survival` | 18 |
| `ferx_fit_async`, `ferx_collect` | 19 |
| `ferx_save_fit`, `ferx_load_fit`, `ferx_xpose` | 20 |
| `ferx_selection`, `ferx_selection_excluded` | 17 |

## 6. Maturity & runnability rules

- **stable/beta features:** runnable chapters with a one-line maturity callout
  (beta only). Pull exact output from a live render.
- **experimental — SDE:** runnable (`warfarin_sde`) but wrap in a
  `::: {.callout-warning}` noting `W_EXPERIMENTAL_SDE` and that syntax may change.
- **experimental — NN / DCM:** **NOT runnable** in the book build (`warfarin_dcm`
  needs ferx-r compiled with `--features nn`; default build omits it, and the
  example self-detects this). Chapter 21 documents it conceptually and links to
  ferx-core `model-file/neural-networks.qmd` + the bundled `ex_warfarin_dcm.R`,
  with NO executed chunks.

## 7. Recurring conventions to build first

- **Step banner** include `chapters/_step-banner.qmd` + `.step-banner` rule in
  `assets/ferx.scss` / `ferx-dark.scss`; active step bolded.
- **Maturity callout** snippet reused across beta/experimental chapters.
- **"Where you are" opener** + **handoff footer** on every Part-1 chapter.
- **Reference callout** pattern for deferred lookups (pkgdown / DSL book).

## 8. Execution sequence (branch: `restructure/workflow-tutorial`)

Waves; render after each chapter so caches/examples stay green.

1. **Scaffold:** branch, step-banner include + SCSS, rewrite `_quarto.yml` tree
   incrementally (keep old entries until each new file renders clean; flip last).
2. **Wave A — spine:** `index` box → `02-workflow` (linchpin) → `03-model-file`.
3. **Wave B — concept:** `04`–`07` (fitting trim, diagnostics + NPDE, sim/VPC,
   uncertainty).
4. **Wave C — scenarios:** `08`–`14` (covariates+FREM, transforms, absorption,
   ode, pkpd, iov, bloq).
5. **Wave D — split special-features:** `15`–`18` + `21` from old
   `14-special-features`; delete the old file once all sections rehomed.
6. **Wave E — advanced + context:** `19` (carve from `04`), `20`, `22`, `23`.
7. **Finalize:** full `quarto render`; drop stale `*_cache`/`*_files` for renamed
   chapters; update CLAUDE.md chapter↔feature table + audit section.

## 9. Per-PR checklist (from CLAUDE.md — do not skip)

- Rebuild ferx-r if engine changed: `cd ../ferx-r && FERX_NO_AUTODIFF=1 R CMD INSTALL .`
- `grep -r 'ferx_example' chapters/` — every name exists in `../ferx-r/R/example.R`.
- `grep -r 'read.csv\|ex\$data\|ex\$model' chapters/` — every file exists.
- `[fit_options]` keys match `../ferx-core/docs/src/model-file/fit-options.md`.
- **No fabricated R output** — derive every `#>`/`#` line from a live render or
  `../ferx-r/R/` source (esp. `fit.R`, `diagnostics.R`).
- `quarto render chapters/<chapter>.qmd` per chapter; full render before PR.
- Preserve every `#| label:` and `#| cache: true` when relocating chunks.

## 10. Feature watchlist (capture-now, add-when-landed)

### ⚠️ Pending: re-verify against a fresh ferx-r build (BLOCKER before publishing)
The book was rendered against **installed `ferx 0.1.6`, which is stale** vs the
`../ferx-r` source tree (same version string, but source has later commits). The
*installation chapter is already current*; the *example outputs are not*. Action:
**reinstall ferx-r from `main`** (NOT the `feat/sim-horizon-526` branch the checkout
is currently on — that's in-progress simulation work that could skew ch06 VPC/sim),
then **full `quarto render`** to regenerate all fits and unlock the runnable Weibull.

Known 0.1.6 → latest drifts (prose already fixed; outputs/runnability pending rebuild):
| Drift | Source commit | Chapter | Status |
|---|---|---|---|
| `auto` is now the default optimizer (resolves `nlopt_lbfgs` / `bobyqa`) | `412f162` (#490) | `04-fitting`, `23-reference` | prose fixed; **fit outputs still from bobyqa-default 0.1.6** — re-render |
| `weibull` is now a bundled example | `f1d8476` (#497) | `10-absorption` | prose fixed; chunk `eval:false` — **drop it & run after rebuild** |
| `ferx_predict_survival` adds competing-risks `cif`/`survival_all` | `87b7333` | `18-time-to-event` | prose fixed (chapter is non-runnable anyway) |
| **NEW `transit_savic` bundled example** (built-in `transit()`) added to ferx-r working tree (`inst/examples/models/transit_savic.ferx` + `data/transit_oral.csv` + `R/example.R` + `ex_transit_savic.R`; mirrors ferx-core `examples/transit_savic.ferx`) | this session (uncommitted) | `10-absorption` | engine already supports `transit()`; example fits (OFV −1069, recovers TVCL/V/KA/MTT/N). Chunk `eval:false` — **commit the ferx-r files, reinstall, then drop `eval:false`** |
| **NEW full TTE example set bundled** — `tte_exponential`, `tte_weibull`, `tte_gompertz`, `tte_competing_risks` added to ferx-r working tree (`inst/examples/models/tte_*.ferx` + `data/tte_*.csv` + `R/example.R` roxygen + `ex_tte_*.R`; mirror ferx-core `examples/tte_*.ferx`) | this session (uncommitted) | `18-time-to-event` | all hazards verified in 0.1.6 (exponential direct OFV 1761.84; weibull/gompertz/competing-risks via dummy-block proxies — recover TVSCALE=20/TVSHAPE=1.5, TVALPHA=0.002/TVGAMMA=0.05, TVLAMBDA_A=0.10/TVLAMBDA_B=0.06). Chunks `eval:false` — **commit + reinstall, then drop `eval:false`**. `tte_exponential` = legacy dummy-PK-block form (fits on 0.1.6); the other three = compact TTE-only form (need current ferx-r; 0.1.6 rejects). `ferx_predict_survival()` (incl. `cif`/`survival_all`) also needs the reinstall. **Full TTE catalogue now bundled — nothing left in ferx-core to mirror for TTE.** |

On rebuild also re-run the CLAUDE.md audit — newer ferx-r may have added example
names (a TTE dataset would make `18-time-to-event` runnable; see TTE row below).
**ferx-r working-tree files added this session are NOT committed** — commit them on
the appropriate ferx-r branch before they ship in an install.

Living backlog so no ferx feature slips through the restructure. When a feature's
**trigger** is met, write the chapter/section and move the row to "Landed" (or
delete it once §4/§5 cover it). **Recheck procedure each PR:** diff
`../ferx-r/NAMESPACE` for new exports, re-read `../ferx-core/docs/maturity.qmd`
for maturity bumps, and skim the [Roadmap](https://ferx-nlme.github.io/roadmap.html).

### Known features waiting on maturity / build support
| Feature | Current state | Trigger to add | Target chapter |
|---|---|---|---|
| Neural networks — `[covariate_nn]` (DCM) | experimental; needs `--features nn` (off in default build) | Default build enables `nn`, OR book CI builds with `--features nn` | `21-experimental` → promote to own chapter |
| Neural networks — `[dynamics_nn]` (low-dim Neural ODE) | experimental / incremental (ferx-core `plans/dcm-and-low-dim-node.md`) | Block lands + a bundled runnable example exists | `21-experimental` |
| SDE — `[diffusion]` | experimental (runnable, `W_EXPERIMENTAL_SDE`) | Maturity → beta | promote from `21-experimental` to own Part-2 chapter |
| TTE — `[event_model]` | beta (Phase 1: exp/Weibull/Gompertz) | New hazard families / repeated-TTE / interval-cens. expand | extend `18-time-to-event` |
| Built-in absorption | beta; transit Phase-0 limits (see absorption.qmd "Not yet supported") | Phase-0 limitations lifted | update `10-absorption` |
| FREM (`ferx_to_frem`) | present; no bundled R example | Bundled example added | deepen `08-covariates` |
| Bayes / HMC (`method` path) | beta-ish, sparsely documented | Stabilises + exposed cleanly | section in `19-scaling-up` |
| FRAME / `impmap` | beta | — | `07-uncertainty` (already slotted) |

### Capture template — copy a row when you spot something new
| Feature | Current state | Trigger to add | Target chapter |
|---|---|---|---|
| `<name / DSL block / function>` | `<stable\|beta\|experimental\|planned>` + how discovered | `<condition: maturity bump / new export / example lands>` | `<chapter or "new">` |

### Unresolved / needs owner input
| Item | Note |
|---|---|
| **"TTR"** | Not found in ferx-r or ferx-core (grepped TTR / RTTE / therapeutic-range / time-to-recovery / repeated-time). Awaiting clarification — if it's repeated-TTE → `18`; if an INR/PD example → `12-pkpd`. |

### Landed (move rows here, then fold into §4/§5)
| Feature | Date landed | Chapter | Status |
|---|---|---|---|
| _(none yet)_ | | | |

## 11. Open questions / risks

- **`22-for-nonmem-users`** is net-new content — confirm wanted or drop.
- **`_quarto.yml` migration:** renaming many files risks a broken mid-wave render;
  mitigate by migrating file-by-file, flipping the tree last.
- **Cache invalidation:** renamed chapters lose `*_cache`; first render of each is
  slow (some fits take minutes). Acceptable; `cache: true` re-warms.
- **Size:** 23 chapters is large. Could merge `15`+`16`+`17` (dosing / readouts /
  selection) into one "Data & output handling" chapter if we want ~20 total.
- **"TTR"** (raised in discussion) does not exist in either repo — confirm intent.
- Keep the navbar (external ferx-site links) untouched.
</content>
