# Warn about insufficient data for coverage check

Warn about insufficient data for coverage check

## Usage

``` r
.warn_insufficient_coverage_data(
  latest_obs_count,
  max_delay_obs_q,
  timestep,
  internal_timestep,
  warn_internal
)
```

## Arguments

- latest_obs_count:

  Number of observations in filtered data

- max_delay_obs_q:

  Quantile-based maximum delay

- timestep:

  Timestep specification

- internal_timestep:

  Internal timestep multiplier

- warn_internal:

  Whether function is called internally
