# Vendored Stan functions

`primarycensored.stan` is vendored from the
[primarycensored](https://github.com/epinowcast/primarycensored) R package
(epinowcast organisation, MIT licensed).

| Item | Value |
|---|---|
| Upstream repository | https://github.com/epinowcast/primarycensored |
| Release tag | `v1.5.0` |
| Git commit | `1ea1d80af02c8f51d1d2cd698876f1f4f402b74a` |
| Source path | `inst/stan/functions/` |
| Licence | MIT (see `LICENSE.primarycensored`) |

## Files copied

The following upstream files were concatenated into
`primarycensored.stan`, in this order:

- `primarycensored.stan`
- `primarycensored_ode.stan`
- `primarycensored_analytical_cdf.stan`
- `expgrowth.stan`

The function bodies are reproduced verbatim from the tagged release, with two
changes: the file header and the `// ===== <file> =====` section markers were
added, and a few non-ASCII characters in the `log_weibull_g` documentation
comment (the Greek letters lambda and gamma) were transliterated to ASCII.
The non-ASCII characters are transliterated because `enw_stan_to_r()`
concatenates every `inst/stan/functions/*.stan` file into a single Stan
program, and some `stanc` versions raise a lexing error on non-ASCII bytes in
that combined block.

`primarycensored_pmf.stan` is **not** vendored.
It is an epinowcast wrapper that translates epinowcast's `model_refp`
distribution ids and parameters to the primarycensored convention and exposes
`discretised_pcens_logit_hazard()` as a drop-in alternative to
`discretised_logit_hazard()`.

## Refreshing the copy

To update to a newer primarycensored release, re-concatenate the four files
above from the corresponding upstream tag, keep the header and section
markers, and update the tag/commit recorded here and in the
`primarycensored.stan` header. Then re-run the recovery tests in
`tests/testthat/test-stan_primarycensored_pmf.R` against
`primarycensored::dprimarycensored()`.
