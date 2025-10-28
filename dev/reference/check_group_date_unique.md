# Check observations for uniqueness of grouping variables with respect to `reference_date` and `report_date`

This function checks that the input data is stratified by
`reference_date`, `report_date`, and `.group.` It does this by counting
the number of observations for each combination of these variables, and
throwing a warning if any combination has more than one observation.

## Usage

``` r
check_group_date_unique(obs)
```

## Arguments

- obs:

  An object that will be `coerce_dt`d in place, that contains `.group`,
  `reference_date`, and `report_date` columns.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/dev/reference/check_group.md),
[`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/dev/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/dev/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)
