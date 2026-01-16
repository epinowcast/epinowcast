# Unset Stan cache location

Optionally removes the `enw_cache_location` environment variable from
the user .Renviron file and/or removes it from the local environment. If
you unset the local cache and want to switch back to using the
persistent cache, you can reload the `.Renviron` file using
`readRenviron("~/.Renviron")`.

## Usage

``` r
enw_unset_cache(type = c("session", "persistent", "all"))
```

## Arguments

- type:

  A character string specifying the type of cache to unset. It can be
  one of "session", "persistent", or "all". Default is "session".
  "session" unsets the cache for the current session, "persistent"
  removes the cache location from the user's `.Renviron` file,and "all"
  does all options.

## Value

The prior cache location, if it existed otherwise `NULL`.

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
[`remove_profiling()`](https://package.epinowcast.org/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/reference/write_stan_files_no_profile.md)

## Examples

``` r
if (FALSE) { # interactive()
enw_unset_cache()
}
```
