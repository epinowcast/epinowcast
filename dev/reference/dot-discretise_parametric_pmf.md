# Discretise a parametric delay distribution

Computes the discretised probability mass function of a parametric delay
distribution using primary-event censoring via
[`primarycensored::dprimarycensored()`](https://primarycensored.epinowcast.org/reference/dprimarycensored.html),
the same method `epinowcast` relies on for delay distributions. The PMF
is over delays `0:(max_delay - 1)`, truncated at `max_delay`. Parameters
use the distribution's natural parameterisation (e.g. `meanlog`/`sdlog`
for the lognormal); the `refp_mean_int`/`refp_sd_int` parameters are
mapped accordingly.

## Usage

``` r
.discretise_parametric_pmf(mu, sigma, max_delay, distribution = "lognormal")
```

## Arguments

- mu:

  Location parameter on the modelled scale (`refp_mean_int`).

- sigma:

  Scale parameter on the modelled scale (`refp_sd_int`). Ignored for the
  exponential distribution.

- max_delay:

  Maximum delay (number of delay slots, delays \`0:(max_delay

  - 1)\`).

- distribution:

  One of "lognormal", "gamma", "exponential", or "loglogistic".

## Value

A numeric vector of length `max_delay` summing to 1.

## See also

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/dev/reference/enw_posterior_delay.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)
