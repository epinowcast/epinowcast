# Check timestep

This function verifies if the difference in dates in the provided
observations corresponds to the provided timestep. If the `exact`
argument is set to TRUE, the function checks if all differences exactly
match the timestep; otherwise, it checks if the sum of the differences
modulo the timestep equals zero. If the check fails, the function stops
and returns an error message.

## Usage

``` r
check_timestep(
  obs,
  date_var,
  timestep = "day",
  exact = TRUE,
  check_nrow = TRUE
)
```

## Arguments

- obs:

  Any of the types supported by
  [`data.table::as.data.table()`](https://rdatatable.gitlab.io/data.table/reference/as.data.table.html).

- date_var:

  The variable in `obs` representing dates.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

- exact:

  Logical, if `TRUE`, checks if all differences exactly match the
  timestep. If `FALSE`, checks if the sum of the differences modulo the
  timestep equals zero. Default is `TRUE`.

- check_nrow:

  Logical, if `TRUE`, checks if there are at least two observations.
  Default is `TRUE`. If `FALSE`, the function returns invisibly if there
  is only one observation.

## Value

This function is used for its side effect of stopping if the check
fails. If the check passes, the function returns invisibly.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/dev/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/dev/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/dev/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)
