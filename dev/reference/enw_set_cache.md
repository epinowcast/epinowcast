# Set caching location for Stan models

This function allows the user to set a cache location for Stan models
rather than a temporary directory. This can reduce the need for model
compilation on every new model run across sessions or within a session.
For R version 4.0.0 and above, it's recommended to use the persistent
cache as shown in the example.

## Usage

``` r
enw_set_cache(path, type = c("session", "persistent", "all"))
```

## Arguments

- path:

  A valid filepath representing the desired cache location. If the
  directory does not exist it will be created.

- type:

  A character string specifying the cache type. It can be one of
  "session", "persistent", or "all". Default is "session". "session"
  sets the cache for the current session, "persistent" writes the cache
  location to the user's `.Renviron` file, and "all" does both.

## Value

The string of the filepath set.

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)

## Examples

``` r
if (FALSE) { # interactive()
# Set to local directory
my_enw_cache <- enw_set_cache(file.path(tempdir(), "test"))
enw_get_cache()
if (FALSE) { # \dontrun{
# Use the package cache in R >= 4.0
if (R.version.string >= "4.0.0") {
 enw_set_cache(
   tools::R_user_dir(package = "epinowcast", "cache"), type = "all"
 )
}

} # }
}
```
