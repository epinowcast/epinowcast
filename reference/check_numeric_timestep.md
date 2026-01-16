# Check Numeric Timestep

This function verifies if the difference in numeric dates in the
provided observations corresponds to the provided timestep.

## Usage

``` r
check_numeric_timestep(dates, date_var, timestep, exact = TRUE)
```

## Arguments

- dates:

  Vector of Date class representing dates.

- date_var:

  The variable in `obs` representing dates.

- timestep:

  Numeric timestep for date difference.

- exact:

  Logical, if `TRUE`, checks if all differences exactly match the
  timestep. If `FALSE`, checks if the sum of the differences modulo the
  timestep equals zero. Default is `TRUE`.

## Value

This function is used for its side effect of stopping if the check
fails. If the check passes, the function returns invisibly.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/reference/check_modules_compatible.md),
[`check_observation_indicator()`](https://package.epinowcast.org/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/reference/check_timestep_by_group.md)
