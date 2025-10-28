# Fit a CmdStan model using the pathfinder algorithm

For more information on the pathfinder algorithm see the [CmdStan
documentation](https://mc-stan.org/cmdstanr/reference/model-method-pathfinder.html).
\# nolint

## Usage

``` r
enw_pathfinder(
  data,
  model = epinowcast::enw_model(),
  diagnostics = TRUE,
  init = NULL,
  ...
)
```

## Arguments

- data:

  A list of data as produced by model modules (for example
  [`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md),
  [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md),
  etc.) and as required for use the `model` being used.

- model:

  A `cmdstanr` model object as loaded by
  [`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md)
  or as supplied by the user.

- diagnostics:

  Logical, defaults to `TRUE`. Should fitting diagnostics be returned as
  a `data.frame`.

- init:

  A list of initial values or a function to generate initial values. If
  not provided, the model will attempt to generate initial values

- ...:

  Additional parameters to be passed to `CmdStanModel$pathfinder()`.

## Value

A data.table containing the fit, data, and fit_args. If diagnostics is
TRUE, it also includes the run_time column with the timing information.

## Details

Note that the `threads_per_chain` argument is renamed to `num_threads`
to match the `CmdStanModel$pathfinder()` method.

This fitting method is faster but more approximate than the NUTS sampler
used in
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md)
and as such is recommended for use in exploratory analysis and model
development.

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md),
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
pobs <- enw_example("preprocessed")

nowcast <- epinowcast(pobs,
 expectation = enw_expectation(~1, data = pobs),
 fit = enw_fit_opts(enw_pathfinder, pp = TRUE),
 obs = enw_obs(family = "poisson", data = pobs),
)

summary(nowcast)
}
```
