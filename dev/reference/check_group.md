# Check observations for reserved grouping variables

Check observations for reserved grouping variables

## Usage

``` r
check_group(obs)
```

## Arguments

- obs:

  An object that will be `coerce_dt`d in place, that does not contain
  `.group`, `.old_group`, or `.new_group`. These are reserved names.

## Value

The `obs` object, which will be modifiable in place.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md),
[`check_group_date_unique()`](https://package.epinowcast.org/dev/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/dev/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/dev/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)
