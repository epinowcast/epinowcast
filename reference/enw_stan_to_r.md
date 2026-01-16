# Expose `epinowcast` stan functions in R

This function facilitates the exposure of Stan functions from the
[epinowcast](https://package.epinowcast.org/reference/epinowcast)
package in R. It utilizes the
[expose_functions](https://mc-stan.org/cmdstanr/reference/model-method-expose_functions.html)
method of
[cmdstanr::CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html)
for this purpose. This function is useful for developers and
contributors to the
[epinowcast](https://package.epinowcast.org/reference/epinowcast.md)
package, as well as for users interested in exploring and prototyping
with model functionalities.

## Usage

``` r
enw_stan_to_r(
  files = list.files(include),
  include = system.file("stan", "functions", package = "epinowcast"),
  global = TRUE,
  verbose = TRUE,
  ...
)
```

## Arguments

- files:

  A character vector specifying the names of Stan files to be exposed.
  These must be in the `include` directory. Defaults to all Stan files
  in the `include` directory. Note that the following files contain
  overloaded functions and cannot be exposed: "delay_lpmf.stan",
  "allocate_observed_obs.stan", "obs_lpmf.stan", and
  "effects_priors_lp.stan".

- include:

  A character string specifying the directory containing Stan files.
  Defaults to the 'stan/functions' directory of the
  [`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md)
  package.

- global:

  A logical value indicating whether to expose the functions globally.
  Defaults to `TRUE`. Passed to the
  [expose_functions](https://mc-stan.org/cmdstanr/reference/model-method-expose_functions.html)
  method of
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html).

- verbose:

  Logical, defaults to `TRUE`. Should verbose messages be shown.

- ...:

  Additional arguments passed to
  [enw_model](https://package.epinowcast.org/reference/enw_model).

## Value

An object of class `CmdStanModel` with functions from the model exposed
for use in R.

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
[`enw_unset_cache()`](https://package.epinowcast.org/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/reference/write_stan_files_no_profile.md)

## Examples

``` r
if (FALSE) { # interactive()
# Compile functions in stan/functions/hazard.stan
stan_functions <- enw_stan_to_r("hazard.stan")
# These functions can now be used in R
stan_functions$functions$prob_to_hazard(c(0.5, 0.1, 0.1))
# or exposed globally and used directly
prob_to_hazard(c(0.5, 0.1, 0.1))
}
```
