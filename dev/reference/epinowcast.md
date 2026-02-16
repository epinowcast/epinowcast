# Nowcast using partially observed data

Provides a user friendly interface around package functionality to
produce a nowcast from observed preprocessed data, and a series of user
defined models. By default a model that assumes a fixed parametric
reporting distribution with a flexible expectation model is used.
Explore the individual model components for additional documentation and
see the package case studies for example model specifications for
different tasks.

## Usage

``` r
epinowcast(
  data,
  reference = epinowcast::enw_reference(parametric = ~1, distribution = "lognormal",
    non_parametric = ~0, data = data),
  report = epinowcast::enw_report(non_parametric = ~0, structural = NULL, data = data),
  expectation = epinowcast::enw_expectation(r = ~0 + (1 | day:.group), generation_time =
    1, observation = ~1, latent_reporting_delay = 1, data = data),
  missing = epinowcast::enw_missing(formula = ~0, data = data),
  obs = epinowcast::enw_obs(family = "negbin", data = data),
  fit = epinowcast::enw_fit_opts(sampler = epinowcast::enw_sample, nowcast = TRUE, pp =
    FALSE, likelihood = TRUE, debug = FALSE, output_loglik = FALSE),
  model = epinowcast::enw_model(),
  priors,
  ...
)
```

## Arguments

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- reference:

  The reference date indexed reporting process model specification as
  defined using
  [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md).

- report:

  The report date indexed reporting process model specification as
  defined using
  [`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md).

- expectation:

  The expectation model specification as defined using
  [`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md).
  By default this is set to be a highly flexible random effect by
  reference date for each group and thus weakly informed. Depending on
  your context (and in particular the density of data reporting) other
  choices that enforce more assumptions may be more appropriate (for
  example a weekly random walk (specified using
  `rw(week, by = .group)`)).

- missing:

  The missing reference date model specification as defined using
  [`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md).
  By default this is set to not be used.

- obs:

  The observation model as defined by
  [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md).
  Observations are also processed within this function for use in
  modelling.

- fit:

  Model fit options as defined using
  [`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md).
  This includes the sampler function to use (with the package default
  being
  [`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md)),
  whether or now a nowcast should be used, etc. See
  [`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md)
  for further details.

- model:

  The model to use within `fit`. By default this uses
  [`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md).

- priors:

  A `data.frame` with columns `variable`, `mean`, and `sd` describing
  normal priors that replace the module defaults. Custom priors are
  merged with the defaults automatically. See Details for how to inspect
  and modify priors.

- ...:

  Additional model modules to pass to `model`. User modules may be used
  but currently require the supplied `model` to be adapted.

## Value

A object of the class "epinowcast" which inherits from
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
and `data.table`, and combines the input data, priors, and output from
the sampler specified in
[`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md).

## Details

### Priors

Each model module defines its own default priors. To inspect them, call
the module function and access the `$priors` element. See
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md),
[`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md),
[`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md),
and
[`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md)
for the prior variables available in each module.

To replace specific defaults, pass a `data.frame` to the `priors`
argument. Vectorised prior names (e.g. `"refp_mean_int[1]"`) are matched
after stripping the index. See
[`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md)
for details on the merging behaviour.

## See also

Other epinowcast:
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

## Examples

``` r
if (FALSE) { # interactive()
# Load data.table and ggplot2
library(data.table)
library(ggplot2)

# Use 2 cores
options(mc.cores = 2)
# Load and filter germany hospitalisations
nat_germany_hosp <-
  germany_covid19_hosp[location == "DE"][age_group == "00+"]
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-10-01"
)
# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group")
)
# Make a retrospective dataset
retro_nat_germany <- enw_filter_report_dates(
  nat_germany_hosp,
  remove_days = 40
)
retro_nat_germany <- enw_filter_reference_dates(
  retro_nat_germany,
  include_days = 40
)
# Get latest observations for the same time period
latest_obs <- nat_germany_hosp |>
  enw_obs_at_delay(max_delay = 20) |>
  enw_filter_reference_dates(
    remove_days = 40, include_days = 20
  )
# Preprocess observations (note this maximum delay is likely too short)
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)

# Fit with custom priors
my_priors <- data.frame(
  variable = "refp_mean_int", mean = 2, sd = 0.5
)
nowcast <- epinowcast(pobs,
  priors = my_priors,
  fit = enw_fit_opts(
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 500, iter_sampling = 500
  )
)
nowcast
# plot the nowcast vs latest available observations
plot(nowcast, latest_obs = latest_obs)

# plot posterior predictions for the delay distribution by date
plot(nowcast, type = "posterior") +
  facet_wrap(vars(reference_date), scale = "free")
}
```
