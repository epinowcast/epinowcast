# Read in a stan function file as a character string

Read in a stan function file as a character string

## Usage

``` r
stan_fns_as_string(files, include)
```

## Arguments

- files:

  A character vector specifying the names of Stan files to be exposed.
  These must be in the `include` directory. Defaults to all Stan files
  in the `include` directory. Note that the following files contain
  overloaded functions and cannot be exposed: "delay_lpmf.stan",
  "allocate_observed_obs.stan", "obs_lpmf.stan", and
  "effects_priors_lp.stan".

- include:

  A character string specifying the directory containing Stan files.
  Defaults to the 'stan/functions' directory of the
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
  package.

## Value

A character string in the of stan functions.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md),
[`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md),
[`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md)
