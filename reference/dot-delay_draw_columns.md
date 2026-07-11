# Extract the index-ordered draw columns for a delay vector parameter

Extract the index-ordered draw columns for a delay vector parameter

## Usage

``` r
.delay_draw_columns(fit, var)
```

## Arguments

- fit:

  A `cmdstanr` fit object.

- var:

  A scalar string naming the vector variable (e.g. `"refp_mean"`).

## Value

A list with `draws` (a `draws_df`, or `NULL` if `var` is absent) and
`cols` (the matching column names in index order).

## See also

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/reference/dot-check_primarycensored.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/reference/enw_posterior_delay.md),
[`enw_pp_summary()`](https://package.epinowcast.org/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/reference/subset_obs.md)
