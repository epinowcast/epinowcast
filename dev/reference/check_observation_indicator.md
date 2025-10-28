# Check observation indicator

This function verifies if the `observation_indicator` within the
provided `new_confirm` observations is logical. The check is performed
to ensure that the `observation_indicator` is of the correct type.

## Usage

``` r
check_observation_indicator(new_confirm, observation_indicator = NULL)
```

## Arguments

- new_confirm:

  A data frame containing the observations to be checked.

- observation_indicator:

  A character string specifying the column name in `new_confirm` that
  represents the observation indicator. This column should be of logical
  type. If NULL, no check is performed.

## Value

This function is used for its side effect of checking the observation
indicator in `new_confirm`. If the check passes, the function returns
invisibly. Otherwise, it stops and returns an error message.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/dev/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/dev/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md),
[`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/dev/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)
