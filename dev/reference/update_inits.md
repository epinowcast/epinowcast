# Update initial values for model fitting

This function updates the initial values for model fitting based on the
specified initialization method.

## Usage

``` r
update_inits(
  data,
  model,
  init,
  init_method = c("prior", "pathfinder"),
  init_method_args = list(),
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

- init:

  A list of initial values or a function to generate initial values. If
  not provided, the model will attempt to generate initial values

- init_method:

  The method to use for initializing the model. Defaults to "prior"
  which samples initial values from the prior. "pathfinder", which uses
  the pathfinder algorithm
  ([`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md))
  to initialize the model.

- init_method_args:

  A list of additional arguments to pass to the initialization method.

- ...:

  Additional arguments passed to initialization methods.

## Value

A list containing updated initial values and method-specific output.
