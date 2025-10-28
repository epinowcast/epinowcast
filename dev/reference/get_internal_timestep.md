# Get internal timestep

This function converts the string representation of the timestep to its
corresponding numeric value or returns the numeric input (if it is a
whole number). For "day", "week", it returns 1 and 7 respectively.
"month" is not supported and will throw an error. If the input is a
numeric whole number, it is returned as is.

## Usage

``` r
get_internal_timestep(timestep)
```

## Arguments

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

## Value

A numeric value representing the number of days for "day" and "week", or
the input value if it is a numeric whole number.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md),
[`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)
