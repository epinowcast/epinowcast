# CRAN submission comments

## Submission type

This is a new submission.
`epinowcast` has not previously been published on CRAN.

## Test environments

- Local: macOS 26 (Tahoe), R 4.6.0 (aarch64-apple-darwin23)
- GitHub Actions: ubuntu-latest, R release, oldrel-1, and 4.3 (the package's stated minimum)
- Not yet run: win-builder, R-hub, and a macOS CI job.
  The package's GitHub Actions matrix currently only covers Ubuntu.
  Running `devtools::check_win_devel()` and an R-hub Windows/macOS check before submission is recommended.

## R CMD check results

0 errors | 0 warnings | 1 note

The single NOTE is the expected "CRAN incoming feasibility" NOTE for a new submission.
It records that `cmdstanr` (Suggests) is not in a mainstream repository and is available via the `Additional_repositories` field (https://stan-dev.r-universe.dev).

## Downstream dependencies

This is a new submission, so there are no reverse dependencies to check.

## Additional notes for CRAN

- `cmdstanr` is used to compile and fit the package's Stan models but is
  listed under Suggests, not Imports.
  Functions that need it call `rlang::check_installed()` (or an internal
  equivalent) first and fail informatively if it is missing, and its
  non-CRAN location is declared via `Additional_repositories`
  (https://stan-dev.r-universe.dev), matching the pattern used by other
  cmdstanr-based CRAN packages.
- The Stan model is compiled at first use via `cmdstanr::cmdstan_model()`
  (see `enw_model()`), not at package install time, so a working CmdStan
  installation is only required when a user actually fits a model, not to
  install or load the package.
- Examples and tests that fit Stan models are wrapped in
  `@examplesIf interactive()` or guarded with `testthat::skip_on_cran()`
  respectively, so CRAN's check machines do not need CmdStan installed and
  do not incur MCMC runtime.
- The heavier vignettes (`epinowcast.Rmd`, `delay-estimation.Rmd`,
  `inference-methods.Rmd`, `latent-processes.Rmd`,
  `single-timeseries-rt-estimation.Rmd`, `temporal-aggregation.Rmd`,
  `germany-age-stratified-nowcasting.Rmd`) are precompiled from `.Rmd.orig`
  sources with `knitr::knit()` ahead of time and checked in as static
  `.Rmd` files, so `R CMD check` does not refit any models while building
  vignettes.
