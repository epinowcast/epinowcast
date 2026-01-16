# Convert date column to numeric and calculate its modulus with given timestep.

This function processes a date column in a `data.table`, converting it
to a numeric representation and then computing the modulus with the
provided timestep.

## Usage

``` r
date_to_numeric_modulus(dt, date_column, timestep)
```

## Arguments

- dt:

  A data.table.

- date_column:

  A character string representing the name of the date column in dt.

- timestep:

  An integer representing the internal timestep.

## Value

A modified data.table with two new columns: one for the numeric
representation of the date minus the minimum date and another for its
modulus with the timestep.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/reference/coerce_date.md),
[`coerce_dt()`](https://package.epinowcast.org/reference/coerce_dt.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/reference/enw_rolling_sum.md),
[`get_internal_timestep()`](https://package.epinowcast.org/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/reference/stan_fns_as_string.md)
