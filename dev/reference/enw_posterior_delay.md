# Posterior samples of the parametric reporting-delay distribution

Extracts posterior draws of the parametric reporting-delay distribution
from a fit (e.g. a delay-only fit, see the delay estimation vignette)
and returns the discretised delay probability mass function for each
draw. This supports comparing the estimated distribution against a known
truth and plotting posterior samples rather than only summaries.

## Usage

``` r
enw_posterior_delay(fit, max_delay, distribution = "lognormal", draws = NULL)
```

## Arguments

- fit:

  A `cmdstanr` fit object (the `fit[[1]]` element of an `epinowcast`
  output).

- max_delay:

  Maximum delay (number of delay slots, delays `0:(max_delay - 1)`).

- distribution:

  The parametric distribution used in
  [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
  one of "lognormal", "gamma", "exponential", or "loglogistic". Defaults
  to "lognormal". A `cmdstanr` fit does not record which distribution
  was used (the `model_refp` id is Stan data, not saved to the draws),
  so this must match the distribution passed to
  [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md).
  An incorrect value silently yields the wrong PMF.

- draws:

  Optional integer; if supplied, a random subset of this many posterior
  draws is returned (useful for plotting). The same draws are used
  across all reference-design rows.

## Value

A long `data.table` with columns `.draw`, `delay`, and `pmf`, plus an
integer `row` column when the delay model has more than one
reference-design row.

## Details

The function reads the full `refp_mean` and `refp_sd` vectors saved by
the Stan model (one entry per unique combination of parametric
reference-date covariates) and discretises a delay PMF for each. For an
intercept-only delay (the common case, `refp_mean` of length one) the
output is a long `data.table` with columns `.draw`, `delay`, and `pmf`.
For a delay model with reference-date covariates, random effects, or
time- or group-varying delays (`refp_mean` of length greater than one)
an additional integer `row` column identifies the reference-design row,
and each row may have a different PMF. The mapping from `row` to
reference date and group is set by the reference module's fixed-effect
design (see
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md)
and
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md)'s
`refp_findex`); it is not recovered here because a `cmdstanr` fit does
not retain that design on its own.

## See also

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/dev/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
if (FALSE) { # interactive()
fit <- enw_example("nowcast")
# Intercept-only delay
enw_posterior_delay(fit$fit[[1]], max_delay = 20, draws = 50)

# A delay model with a reference-date covariate yields one PMF per
# reference-design row, identified by the `row` column:
if (FALSE) { # \dontrun{
pobs <- enw_example("preprocessed")
covariate_fit <- epinowcast(
  pobs,
  reference = enw_reference(~ 1 + day_of_week, data = pobs),
  obs = enw_obs(delay_only = TRUE, data = pobs)
)
enw_posterior_delay(covariate_fit$fit[[1]], max_delay = 20, draws = 50)
} # }
}
```
