# Warn about max delay exceeding observed delay

Warn about max delay exceeding observed delay

## Usage

``` r
.warn_max_delay_exceeds_observed(
  max_delay,
  timestep,
  daily_max_delay,
  max_delay_obs,
  internal_timestep
)
```

## Arguments

- max_delay:

  Maximum delay in timestep units

- timestep:

  Timestep specification

- daily_max_delay:

  Specified maximum delay in daily units

- max_delay_obs:

  Maximum observed delay in daily units

- internal_timestep:

  Internal timestep multiplier
