# Convert prior `data.frame` to list

Converts priors defined in a `data.frame` into a list format for use by
stan. In addition it adds "\_p" to all variable names in order too allow
them to be distinguished from their standard usage within modelling
code.

## Usage

``` r
enw_priors_as_data_list(priors)
```

## Arguments

- priors:

  A `data.frame` with the following variables: `variable`, `mean`, `sd`
  describing normal priors. Priors in the appropriate format are
  returned by
  [`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)
  as well as by other similar model specification functions.

## Value

A named list with each entry specifying a prior as a length two vector
(specifying the mean and standard deviation of the prior).

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/reference/enw_pathfinder.md),
[`enw_replace_priors()`](https://package.epinowcast.org/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/reference/write_stan_files_no_profile.md)

## Examples

``` r
priors <- data.frame(variable = "x", mean = 1, sd = 2)
enw_priors_as_data_list(priors)
#> $x_p
#>      [,1]
#> mean    1
#> sd      2
#> 
```
