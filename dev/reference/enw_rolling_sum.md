# Perform rolling sum aggregation

This function takes a data.table and applies a rolling sum over a given
timestep, aggregating by specified columns. It's particularly useful for
aggregating observations over certain periods.

## Usage

``` r
enw_rolling_sum(dt, internal_timestep, by = NULL, value_col = "confirm")
```

## Arguments

- dt:

  A `data.table` to be aggregated.

- internal_timestep:

  An integer indicating the period over which to aggregate.

- by:

  A character vector specifying the columns to aggregate by.

- value_col:

  A character string specifying the column to aggregate. Defaults to
  "confirm".

## Value

A modified data.table with aggregated observations.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md),
[`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)
