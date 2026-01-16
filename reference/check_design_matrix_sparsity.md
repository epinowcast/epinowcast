# Check design matrix sparsity

This function checks the sparsity of a design matrix and provides a
recommendation if the matrix is considered sparse.

## Usage

``` r
check_design_matrix_sparsity(
  matrix,
  sparsity_threshold = 0.9,
  min_matrix_size = 50,
  name = "checked"
)
```

## Arguments

- matrix:

  A numeric matrix to be checked for sparsity.

- sparsity_threshold:

  A numeric value between 0 and 1 indicating the threshold for
  considering a matrix sparse. Default is 0.9.

- min_matrix_size:

  An integer indicating the minimum size of the matrix for which to
  perform the sparsity check. Default is 50.

- name:

  A character string specifying the name of the design matrix. Default
  is "checked".

## Value

This function is used for its side effect of providing an informational
message if the matrix is sparse. It returns NULL invisibly.

## See also

Functions used for checking inputs
[`check_group()`](https://package.epinowcast.org/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/reference/check_group_date_unique.md),
[`check_max_delay()`](https://package.epinowcast.org/reference/check_max_delay.md),
[`check_module()`](https://package.epinowcast.org/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/reference/check_timestep_by_group.md)
