# Write copies of the .stan files of a Stan model and its \#include files with all profiling statements removed.

Write copies of the .stan files of a Stan model and its \#include files
with all profiling statements removed.

## Usage

``` r
write_stan_files_no_profile(
  stan_file,
  include_paths = NULL,
  target_dir = epinowcast::enw_get_cache()
)
```

## Arguments

- stan_file:

  The path to a .stan file containing a Stan program.

- include_paths:

  Paths to directories where Stan should look for files specified in
  \#include directives in the Stan program.

- target_dir:

  The path to a directory in which the manipulated .stan files without
  profiling statements should be stored. To avoid overriding of the
  original .stan files, this should be different from the directory of
  the original model and the `include_paths`.

## Value

A `list` containing the path to the .stan file without profiling
statements and the include_paths for the included .stan files without
profiling statements

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/reference/remove_profiling.md)
