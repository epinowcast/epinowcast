# Check timestep by group

This function verifies if the difference in dates within each group in
the provided observations corresponds to the provided timestep. This
check is performed for the specified `date_var` and for each group in
`obs`.

## Usage

``` r
check_timestep_by_group(obs, date_var, timestep = "day", exact = TRUE)
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

## Value

This function is used for its side effect of checking the timestep by
group in `obs`. If the check passes for all groups, the function returns
invisibly. Otherwise, it stops and returns an error message.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/reference/check_timestep_by_date.md)
