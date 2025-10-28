# Retrieve Stan cache location

Retrieves the user set cache location for Stan models. This path can be
set through the `enw_cache_location` function call. If no environmental
variable is available the output from
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) will be returned.

## Usage

``` r
enw_get_cache()
```

## Value

A string representing the file path for the cache location

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md),
[`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)
