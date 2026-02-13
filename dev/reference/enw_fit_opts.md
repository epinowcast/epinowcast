# Format model fitting options for use with stan

Format model fitting options for use with stan

## Usage

``` r
enw_fit_opts(
  sampler = epinowcast::enw_sample,
  nowcast = TRUE,
  pp = FALSE,
  likelihood = TRUE,
  likelihood_aggregation = c("snapshots", "groups"),
  threads_per_chain = 1L,
  debug = FALSE,
  output_loglik = FALSE,
  sparse_design = FALSE,
  ...
)
```

## Arguments

- sampler:

  A function that creates an object that be used to extract posterior
  samples from the specified model. By default this is
  [`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md)
  which makes use of
  [`cmdstanr::sample()`](https://mc-stan.org/cmdstanr/reference/model-method-sample.html).

- nowcast:

  Logical, defaults to `TRUE`. Should a nowcast be made using posterior
  predictions of the unobserved future reported notifications.

- pp:

  Logical, defaults to `FALSE`. Should posterior predictions be made for
  observed data. Useful for evaluating the performance of the model.

- likelihood:

  Logical, defaults to `TRUE`. Should the likelihood be included in the
  model

- likelihood_aggregation:

  Character string, aggregation over which stratify the likelihood when
  `threads_per_chain` is greater than 1; enforced by
  [`base::match.arg()`](https://rdrr.io/r/base/match.arg.html).
  Currently supported options:

  - "snapshots" which aggregates over report dates and groups (i.e the
    lowest level that observations are reported at),

  - "groups" which aggregates across user defined groups.

  Note that some model modules override this setting depending on model
  requirements. For example, the
  [`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md)
  module model forces "groups" option. Generally, Users should typically
  want the default "snapshots" aggregation.

- threads_per_chain:

  Integer, defaults to `1`. The number of threads to use within each
  MCMC chain. If this is greater than `1` then components of the
  likelihood will be calculated in parallel within each chain.

- debug:

  Logical, defaults to `FALSE`. Should within model debug information be
  returned.

- output_loglik:

  Logical, defaults to `FALSE`. Should the log-likelihood be output.
  Disabling this will speed up fitting if evaluating the model fit is
  not required.

- sparse_design:

  Logical, defaults to `FALSE`. Should a sparse design matrices be used
  for all design matrices. This reduces memory requirements and may
  reduce computation time when fitting models with very sparse design
  matrices (90% or more zeros).

- ...:

  Additional arguments to pass to the fitting function being used by
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md).
  By default this will be
  [`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md)
  and so `cmdstanr` options should be used.

## Value

A list containing the specified sampler function, data as a list
specifying the fitting options to use, and additional arguments to pass
to the sampler function when it is called.

## See also

Model modules
[`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md),
[`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md),
[`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md),
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md)

## Examples

``` r
# Default options along with settings to pass to enw_sample
enw_fit_opts(iter_sampling = 1000, iter_warmup = 1000)
#> $sampler
#> function (data, model = epinowcast::enw_model(), init = NULL, 
#>     init_method = c("prior", "pathfinder"), init_method_args = list(), 
#>     diagnostics = TRUE, ...) 
#> {
#>     init_method <- rlang::arg_match(init_method)
#>     updated_inits <- update_inits(data, model, init, init_method, 
#>         init_method_args, ...)
#>     cli::cli_alert_info("Fitting the model using NUTS")
#>     fit <- model$sample(data = data, init = updated_inits$init, 
#>         ...)
#>     out <- data.table(fit = list(fit), data = list(data), fit_args = list(list(...)), 
#>         init_method_output = list(updated_inits$method_output))
#>     if (diagnostics) {
#>         fit <- out$fit[[1]]
#>         diag <- fit$sampler_diagnostics(format = "df")
#>         diagnostics <- data.table(samples = nrow(diag), max_rhat = round(max(fit$summary(variables = NULL, 
#>             posterior::rhat, .args = list(na.rm = TRUE))$`posterior::rhat`, 
#>             na.rm = TRUE), 2), divergent_transitions = sum(diag$divergent__), 
#>             per_divergent_transitions = sum(diag$divergent__)/nrow(diag), 
#>             max_treedepth = max(diag$treedepth__))
#>         diagnostics[, `:=`(no_at_max_treedepth, sum(diag$treedepth__ == 
#>             max_treedepth))]
#>         diagnostics[, `:=`(per_at_max_treedepth, no_at_max_treedepth/nrow(diag))]
#>         out <- cbind(out, diagnostics)
#>         timing <- round(fit$time()$total, 1)
#>         out[, `:=`(run_time, timing)]
#>     }
#>     out[]
#> }
#> <bytecode: 0x5558b5aba4c8>
#> <environment: namespace:epinowcast>
#> 
#> $data
#> $data$debug
#> [1] 0
#> 
#> $data$likelihood
#> [1] 1
#> 
#> $data$likelihood_aggregation
#> [1] 0
#> 
#> $data$parallelise_likelihood
#> [1] 0
#> 
#> $data$pp
#> [1] 0
#> 
#> $data$cast
#> [1] 1
#> 
#> $data$ologlik
#> [1] 0
#> 
#> $data$sparse_design
#> [1] 0
#> 
#> 
#> $args
#> $args$threads_per_chain
#> [1] 1
#> 
#> $args$iter_sampling
#> [1] 1000
#> 
#> $args$iter_warmup
#> [1] 1000
#> 
#> 
```
