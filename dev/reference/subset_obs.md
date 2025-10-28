# Subset observations data table for either modelled dates or not-modelled earlier dates.

Subset observations data table for either modelled dates or not-modelled
earlier dates.

## Usage

``` r
subset_obs(ord_obs, max_delay, internal_timestep, reference_subset)
```

## Arguments

- ord_obs:

  The observations `data.table` to be subset, as pulled from the result
  of calling
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
  and coerced to a data table.

- max_delay:

  Whole number representing the maximum delay in units of the timestep.

- internal_timestep:

  A numeric value representing the number of days in the timestep, e.g.
  7 when the timesteps are weeks.

- reference_subset:

  String giving a relational operator to subset ord_obs by reference
  date; e.g. `>` to keep the modelled reference dates from after the
  max_delay.

## Value

A `data.frame` subset for the desired observations

## See also

Functions used for postprocessing of model fits
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md)
