# Check required quantiles are present

Check required quantiles are present

## Usage

``` r
check_quantiles(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8))
```

## Arguments

- posterior:

  A `data.table` that will be
  [`coerce_dt()`](https://package.epinowcast.org/reference/coerce_dt.md)d
  in place; must contain quantiles identified using the `q5` naming
  scheme.

- req_probs:

  A numeric vector of required probabilities. Default: c(0.5, 0.95, 0.2,
  0.8).

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
[`check_timestep()`](https://package.epinowcast.org/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/reference/check_timestep_by_group.md)
