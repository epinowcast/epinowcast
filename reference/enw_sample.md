# Fit a CmdStan model using NUTS

Fit a CmdStan model using NUTS

## Usage

``` r
enw_sample(
  data,
  model = epinowcast::enw_model(),
  init = NULL,
  init_method = c("prior", "pathfinder"),
  init_method_args = list(),
  diagnostics = TRUE,
  ...
)
```

## Arguments

- data:

  A list of data as produced by model modules (for example
  [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md),
  [`enw_obs()`](https://package.epinowcast.org/reference/enw_obs.md),
  etc.) and as required for use the `model` being used.

- model:

  A `cmdstanr` model object as loaded by
  [`enw_model()`](https://package.epinowcast.org/reference/enw_model.md)
  or as supplied by the user.

- init:

  A list of initial values or a function to generate initial values. If
  not provided, the model will attempt to generate initial values

- init_method:

  The method to use for initializing the model. Defaults to "prior"
  which samples initial values from the prior. "pathfinder", which uses
  the pathfinder algorithm
  ([`enw_pathfinder()`](https://package.epinowcast.org/reference/enw_pathfinder.md))
  to initialize the model.

- init_method_args:

  A list of additional arguments to pass to the initialization method.

- diagnostics:

  Logical, defaults to `TRUE`. Should fitting diagnostics be returned as
  a `data.frame`.

- ...:

  Additional parameters passed to the `sample` method of `cmdstanr`.

## Value

A `data.frame` containing the `cmdstanr` fit, the input data, the
fitting arguments, and optionally summary diagnostics.

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/reference/enw_priors_as_data_list.md),
[`enw_replace_priors()`](https://package.epinowcast.org/reference/enw_replace_priors.md),
[`enw_set_cache()`](https://package.epinowcast.org/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/reference/write_stan_files_no_profile.md)

## Examples

``` r
if (FALSE) { # interactive()
pobs <- enw_example("preprocessed")

nowcast <- epinowcast(pobs,
 expectation = enw_expectation(~1, data = pobs),
 fit = enw_fit_opts(enw_sample, pp = TRUE),
 obs = enw_obs(family = "poisson", data = pobs),
)

summary(nowcast)

# Use pathfinder initialization
nowcast_pathfinder <- epinowcast(pobs,
 expectation = enw_expectation(~1, data = pobs),
 fit = enw_fit_opts(enw_sample, pp = TRUE, init_method = "pathfinder"),
 obs = enw_obs(family = "poisson", data = pobs),
)

summary(nowcast_pathfinder)
}
```
