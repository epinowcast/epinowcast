# Load and compile the nowcasting model

Load and compile the nowcasting model

## Usage

``` r
enw_model(
  model = system.file("stan", "epinowcast.stan", package = "epinowcast"),
  include = system.file("stan", package = "epinowcast"),
  compile = TRUE,
  threads = TRUE,
  profile = FALSE,
  target_dir = epinowcast::enw_get_cache(),
  stanc_options = list(),
  cpp_options = list(),
  verbose = TRUE,
  ...
)
```

## Arguments

- model:

  A character string indicating the path to the model. If not supplied
  the package default model is used.

- include:

  A character string specifying the path to any stan files to include in
  the model. If missing the package default is used.

- compile:

  Logical, defaults to `TRUE`. Should the model be loaded and compiled
  using
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html).

- threads:

  Logical, defaults to `TRUE`. Should the model compile with support for
  multi-thread support in chain. Note that setting this will produce a
  warning that `threads_to_chain` is set and ignored. Changing this to
  `FALSE` is not expected to yield any performance benefits even when
  not using multithreading and thus not recommended.

- profile:

  Logical, defaults to `FALSE`. Should the model be profiled? For more
  on profiling see the [`cmdstanr`
  documentation](https://mc-stan.org/cmdstanr/articles/profiling.html).
  \# nolint

- target_dir:

  The path to a directory in which the manipulated .stan files without
  profiling statements should be stored. To avoid overriding of the
  original .stan files, this should be different from the directory of
  the original model and the `include_paths`.

- stanc_options:

  A list of options to pass to the `stanc_options` of
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html).
  By default nothing is passed but potentially users may wish to pass
  optimisation flags for example. See the documentation for
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html)
  for further details.

- cpp_options:

  A list of options to pass to the `cpp_options` of
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html).
  By default nothing is passed but potentially users may wish to pass
  optimisation flags for example. See the documentation for
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html)
  for further details. Note that the `threads` argument replaces
  `stan_threads`.

- verbose:

  Logical, defaults to `TRUE`. Should verbose messages be shown.

- ...:

  Additional arguments passed to
  [`cmdstanr::cmdstan_model()`](https://mc-stan.org/cmdstanr/reference/cmdstan_model.html).

## Value

A `cmdstanr` model.

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md),
[`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md),
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)

## Examples

``` r
if (FALSE) { # interactive()
mod <- enw_model()
}
```
