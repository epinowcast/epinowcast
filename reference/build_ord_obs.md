# Build the ord_obs `data.table`.

Build the ord_obs `data.table`.

## Usage

``` r
build_ord_obs(obs, max_delay, internal_timestep, timestep, nowcast = NULL)
```

## Arguments

- obs:

  Observations as pulled from `nowcast$latest[[1]]`.

- max_delay:

  Whole number representing the maximum delay in units of the timestep.

- internal_timestep:

  The internal timestep in days.

- timestep:

  The timestep to be used. This can be a string ("day", "week", "month")
  or a numeric whole number representing the number of days.

- nowcast:

  If getting posterior samples, a data frame with a \`.draws“ column to
  get the draws from, as pulled from the fit attribute of a nowcast.

## Value

A `data.table`.

## See also

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/reference/dot-discretise_parametric_pmf.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/reference/enw_posterior_delay.md),
[`enw_pp_summary()`](https://package.epinowcast.org/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/reference/subset_obs.md)
