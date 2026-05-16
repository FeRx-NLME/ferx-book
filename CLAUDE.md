# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## What this is

ferx-book is the Quarto book for the ferx R package — a guided narrative from installation through advanced modeling. It is the companion to [ferx-site](../ferx-site), which hosts the reference docs and standalone examples.

The book's code chunks execute against the installed ferx R package, which wraps the ferx-core Rust engine. **All code in the book must run correctly against the current ferx-r and ferx-core.** When either sibling repo changes, book chapters may need updating.

## Sibling repositories

- `../ferx-r` — R package: user API, bundled examples (`inst/examples/`), roxygen docs
- `../ferx-core` — Rust engine: `.ferx` DSL, fit options, estimators
- `../ferx-site` — Website: standalone example pages (cross-link target for book callouts)

## Repository layout

```
chapters/       # One .qmd per chapter (numbered 01–NN)
data/           # Data files used directly in chapters (prefer ferx_example() over copies here)
_quarto.yml     # Book structure — new chapters must be registered here
```

## Chapter ↔ feature mapping

| Chapter | Primary ferx-r functions | Key ferx-core features |
|---------|--------------------------|------------------------|
| 01 | installation | — |
| 02 | `ferx_fit()`, `ferx_example()` | basic 1-cpt oral |
| 03 | — | model DSL syntax |
| 04 | `ferx_fit()`, `ferx_estimates()`, `ferx_cor_matrix()` | FOCE/FOCEI, fit options |
| 05 | `ferx_predict()`, `ferx_simulate()`, diagnostic plots | sdtab, CWRES/IWRES |
| 06 | `ferx_simulate()` | simulation, VPC |
| 07 | — | parameter transforms, mu-referencing |
| 08 | `ferx_fit()` | ODE models |
| 09 | `ferx_fit()` | BLOQ M3 method |
| 10 | `ferx_fit()` | IOV |

Update this table when new chapters are added.

## Keeping chapters in sync with ferx-r and ferx-core

### Audit procedure (run before any PR touching code chunks)

1. Grep all `ferx_example("...")` calls: `grep -r 'ferx_example' chapters/`
   - Each name must exist in `../ferx-r/R/example.R` (or wherever the registry lives)
2. Grep all data file references: `grep -r 'read.csv\|ex\$data\|ex\$model' chapters/`
   - Each file must exist in `../ferx-r/inst/examples/data/` or `data/`
3. Grep all `[fit_options]` keys used in `.ferx` snippets: compare against `../ferx-core/docs/src/model-file/fit-options.md`
4. Check that function signatures in narrative prose match current roxygen docs in `../ferx-r/man/`

### Example execution

All chapters use knitr R chunks. Before rendering:

1. Rebuild ferx-r (compiles ferx-core Rust via Enzyme): `cd ../ferx-r && FERX_NO_AUTODIFF=1 R CMD INSTALL .`
2. Render a single chapter: `quarto render chapters/<chapter>.qmd`
3. Render the full book: `quarto render`

Run on the local CPU build. Do not assume cached outputs are valid after ferx-r or ferx-core changes.

### When ferx-r adds a new feature

- If the feature has a corresponding `inst/examples/*.R` script, check whether an existing chapter covers it or a new chapter is warranted
- If a new bundled example name is added to `ferx_example()`, update the chapter that introduces `ferx_example()` usage (ch02 or the relevant feature chapter)
- Update the chapter ↔ feature mapping table above

### When ferx-core adds a new DSL feature or fit option

- Update the model DSL chapter (ch03) or the relevant feature chapter
- Check that any `.ferx` snippets in other chapters that use changed syntax are still valid

## Cross-links to ferx-site

Chapters may link to ferx-site example pages for extended worked examples. Use the pattern:

```markdown
::: {.callout-tip}
For a full worked example, see [Example: IOV](https://ferx-nlme.github.io/ferx-site/examples/iov.html) on the ferx website.
:::
```

Verify that linked pages exist in `../ferx-site/examples/` before merging.

## Pull Requests

When creating a PR in this repo, always read `.github/PULL_REQUEST_TEMPLATE.md` and fill every section before calling `gh pr create`.
