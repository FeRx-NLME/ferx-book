<!-- Title format: type(scope): short description  [closes #N] -->
<!--
  type  : feat | fix | content | refactor
  scope : chapter number or topic, e.g. ch02 | bloq | iov | simulation | installation
  e.g.  : content(ch09): update M3 BLOQ example to match ferx 0.4 output
-->

## Why
<!-- What prompted this change? Link to a ferx-r or ferx-core PR if this follows a code change. -->

## Cross-repo dependency
| Repo | PR | Status |
|------|----|--------|
| ferx-r | FeRx-NLME/ferx-r#___ | open / merged / not needed |
| ferx-core | FeRx-NLME/ferx-core#___ | open / merged / not needed |
| ferx-site | FeRx-NLME/ferx-site#___ | open / merged / not needed |

## What changed
<!-- Which chapters, what content, why. -->

## Example audit
- [ ] All `ferx_example("name")` calls in changed chapters use names present in the current ferx-r bundle
- [ ] All `.ferx` model snippets in changed chapters are valid against the current DSL (no removed/renamed options)
- [ ] All data files referenced in changed chapters exist in `../ferx-r/inst/examples/data/`
- [ ] Cross-links to ferx-site example pages are still valid

### Example execution (run locally on your CPU before marking ready for review)
- [ ] Installed ferx-r from local build: `cd ../ferx-r && FERX_NO_AUTODIFF=1 R CMD INSTALL .`
- [ ] All changed chapters render cleanly: `quarto render chapters/<chapter>.qmd`
- [ ] Full book renders without error: `quarto render`
- [ ] No execution needed (structural / cross-link / non-code change)

## Checklist
- [ ] `data/` directory in ferx-book contains any new data files needed, or they are sourced via `ferx_example()`
- [ ] New chapters added to `_quarto.yml`

## Reviewer hints
<!-- Where to focus. What can be skimmed. -->
