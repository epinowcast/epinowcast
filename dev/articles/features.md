# Model Features Summary

## Overview

This vignette provides a high-level summary of what `epinowcast` can do.
Rather than duplicating detailed documentation, we signpost to examples
and documentation for each capability.

For detailed model specification, see the [model definition
vignette](https://package.epinowcast.org/dev/articles/model.md). For
function-specific details, see `?function_name`.

## Core Capabilities

| Capability                | What it enables                            | Where to learn more                         |
|---------------------------|--------------------------------------------|---------------------------------------------|
| **Flexible timesteps**    | Daily, weekly, or custom aggregation       | [Different timesteps](#timesteps)           |
| **Multi-stratification**  | Age groups, regions, pathogens             | [Stratification](#stratification)           |
| **Mixed delay models**    | Parametric + non-parametric delays         | [Delay modelling](#delay-modelling)         |
| **Report date effects**   | Day-of-week patterns, structural reporting | [Report date effects](#report-date-effects) |
| **Latent process models** | Growth rates, renewal processes            | [Latent models](#latent-models)             |
| **Hierarchical effects**  | Random effects, random walks               | [Hierarchical structure](#hierarchical)     |
| **Missing data handling** | Missing reference dates                    | [Missing data](#missing-data)               |
| **Model comparison**      | LOO-CV, posterior predictive checks        | [Model evaluation](#model-evaluation)       |

## Different Timesteps and Timespans

`epinowcast` supports flexible temporal aggregation to match your data
structure and computational constraints.

| Timestep | Use case                     | How to specify               | Example                                                                               |
|----------|------------------------------|------------------------------|---------------------------------------------------------------------------------------|
| Daily    | High resolution surveillance | `timestep = "day"` (default) | [Getting started vignette](https://package.epinowcast.org/dev/articles/epinowcast.md) |
| Weekly   | Reduced computational cost   | `timestep = "week"`          | `enw_preprocess_data(..., timestep = "week")`                                         |
| Custom   | Any integer multiple of days | `timestep = 7`               | `enw_preprocess_data(..., timestep = 7)`                                              |

**Key functions:**

- [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md):
  Set timestep during preprocessing
- [`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md):
  Convert between timesteps

**Where to see it:** The [getting started
vignette](https://package.epinowcast.org/dev/articles/epinowcast.md)
uses daily data. For weekly or custom timesteps, simply change the
`timestep` argument in
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

## Stratified and Multi-Group Nowcasting

Nowcast across multiple groups simultaneously with hierarchical sharing
of information.

| Stratification type  | Use case                    | How to specify                  | Example                                                                                                             |
|----------------------|-----------------------------|---------------------------------|---------------------------------------------------------------------------------------------------------------------|
| Age groups           | Age-stratified surveillance | `by = c("age_group")`           | [Germany age-stratified vignette](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md) |
| Geographic regions   | Regional nowcasts           | `by = c("region")`              | Set `by` in [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)          |
| Multiple factors     | E.g., age × region          | `by = c("age_group", "region")` | Combine factors in `by` argument                                                                                    |
| Independent groups   | No sharing between groups   | Use `.group` in formulas        | Default behaviour                                                                                                   |
| Hierarchical sharing | Partial pooling             | Random effects in formulas      | `~1 + (1 | .group)`                                                                                                 |

**Key functions:**

- [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md):
  Specify grouping with `by` argument
- Formula interface: Control sharing via random effects

**Where to see it:** The [Germany age-stratified case
study](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md)
demonstrates multi-group nowcasting with age stratification and
hierarchical effects.

## Delay Modelling Approaches

Model reporting delays using parametric distributions, non-parametric
hazards, or combinations.

| Approach              | When to use                                            | How to specify                                                          | Example                          |
|-----------------------|--------------------------------------------------------|-------------------------------------------------------------------------|----------------------------------|
| Parametric only       | Sparse data (provides regularisation), faster fitting  | `enw_reference(parametric = ~1, distribution = "lognormal")`            | Default in vignettes             |
| Non-parametric only   | Multimodal or highly complex delay patterns            | `enw_reference(parametric = ~0, non_parametric = ~1 + (1 | delay))`     | Flexible hazard model            |
| Mixed model           | Parametric baseline + adjustments for complex patterns | `enw_reference(parametric = ~1, non_parametric = ~0 + (1 | delay_cat))` | Best of both                     |
| Time-varying delays   | Changing reporting over time                           | Include time effects in formulas                                        | `parametric = ~1 + week`         |
| Group-specific delays | Different delays by strata                             | Random effects by group                                                 | `parametric = ~1 + (1 | .group)` |

**Available distributions:** See the [distributions
vignette](https://package.epinowcast.org/dev/articles/distributions.md)
for details on the range of supported distributions.

**Key functions:**

- [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md):
  Specify delay model
- See
  [`?enw_reference`](https://package.epinowcast.org/dev/reference/enw_reference.md)
  for formula details

**Where to see it:** All vignettes use delay models. For non-parametric
approaches and mixed models, see
[`?enw_reference`](https://package.epinowcast.org/dev/reference/enw_reference.md)
examples.

## Report Date Effects and Structural Reporting

Model report date effects and known reporting structures.

| Approach                       | When to use                                 | How to specify                                                                                                                              | Example                           |
|--------------------------------|---------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|
| Non-parametric report effects  | Day-of-week or other report date patterns   | `enw_report(non_parametric = ~1 + (1 | day_of_week))`                                                                                       | Flexible report date effects      |
| Structural reporting schedules | Known fixed reporting cycles (e.g., weekly) | `enw_report(structural = structural_data)`                                                                                                  | Weekly reporting on specific days |
| Day-of-week structural         | Weekly reporting pattern                    | `enw_dayofweek_structural_reporting(pobs, "Monday")`                                                                                        | Monday-only reporting             |
| Custom structural patterns     | Complex reporting schedules                 | [`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md) with custom data | Flexible aggregation              |

**Key functions:**

- [`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md):
  Specify report date model
- [`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md):
  Helper for day-of-week patterns
- [`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md):
  Create custom structural reporting metadata
- [`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md):
  Aggregate observations over timesteps
- See
  [`?enw_report`](https://package.epinowcast.org/dev/reference/enw_report.md)
  for details

**Where to see it:** See
`inst/examples/germany_weekly_reporting_daily_process_model.R` for an
example with weekly reporting and a daily process model.

## Latent Process Models

Specify the generative model for the expected latent process (e.g.,
infections, hospitalisations).

| Model type            | What it assumes                             | How to specify (formulas for `r` unless stated) | Example                                                                                                  |
|-----------------------|---------------------------------------------|-------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| Daily random effects  | Flexible day-to-day changes                 | `~0 + (1 | day:.group)` (default)               | Most flexible                                                                                            |
| Weekly random walk    | Smooth week-to-week trends                  | `~1 + rw(week, by = .group)`                    | Smoother estimates                                                                                       |
| Growth rate           | Exponential growth/decline                  | `generation_time = 1` (default)                 | Simple trend                                                                                             |
| Renewal process       | Epidemic dynamics                           | `generation_time = c(0.2, 0.5, 0.3)`            | [Rt estimation vignette](https://package.epinowcast.org/dev/articles/single-timeseries-rt-estimation.md) |
| Fixed effects         | Covariates (e.g., interventions)            | `~1 + intervention + ...`                       | Include predictors                                                                                       |
| Observation modifiers | Ascertainment variation (e.g., day of week) | `observation = ~1 + day_of_week`                | Adjust for reporting patterns                                                                            |

**Key functions:**

- [`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md):
  Specify latent process model and observation modifiers
- See
  [`?enw_expectation`](https://package.epinowcast.org/dev/reference/enw_expectation.md)
  for details

**Where to see it:** The [Rt estimation
vignette](https://package.epinowcast.org/dev/articles/single-timeseries-rt-estimation.md)
demonstrates renewal process models with generation times.

## Hierarchical Structure

Build hierarchical models using the formula interface.

| Feature              | What it does           | Syntax                                                                                            | Use case                       |
|----------------------|------------------------|---------------------------------------------------------------------------------------------------|--------------------------------|
| Random intercepts    | Group-level variation  | `~1 + (1 | group)`                                                                                | Partial pooling between groups |
| Random slopes        | Group-specific effects | `~x + (x | group)`                                                                                | Effect varies by group         |
| Random walks         | Temporal smoothing     | `~rw(time)`                                                                                       | Smooth trends over time        |
| Grouped random walks | Group-specific trends  | `~rw(time, by = group)`                                                                           | Different trends per group     |
| Sparse design        | Memory efficient       | `sparse = TRUE` in [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md) | Large sparse matrices          |

**Key functions:**

- [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md):
  Unified formula interface
- [`rw()`](https://package.epinowcast.org/dev/reference/rw.md): Random
  walk helper
- See
  [`?enw_formula`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  for syntax details

**Where to see it:** The [Germany case
study](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md)
uses random effects for age groups. All model modules support the same
formula interface.

## Missing Data Handling

Handle two types of missing data: missing reference dates and missing
observations.

| Type                    | What it handles                                           | Use cases                                                                 | How to use                                                                                                                        |
|-------------------------|-----------------------------------------------------------|---------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| Missing reference dates | Reports with known report date but unknown reference date | Model partial reporting                                                   | `enw_missing(formula = ~1)`                                                                                                       |
| Missing observations    | Control which observations are used in the likelihood     | Forecasting, excluding outliers, handling NAs, testing parameter recovery | Set `.observed = FALSE` and use `observation_indicator` in [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md) |

**Common missing observation workflows:**

| Use case                | How to implement                                                                                                                                   |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Forecasting             | [`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md) to add future dates marked as unobserved                    |
| Exclude outliers        | Manually set `.observed = FALSE` for outlier observations                                                                                          |
| Handle NAs              | [`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md) marks NA values as unobserved |
| Test parameter recovery | Set `.observed = FALSE` for subset of data, check if model recovers parameters                                                                     |

**Key functions:**

- [`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md):
  Model for missing reference dates
- [`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md):
  Extend time series with unobserved dates
- [`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md):
  Flag observations based on NAs
- [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md):
  Use `observation_indicator` to control likelihood

**Notes:**

- The missing reference model assumes consistent reporting delay for
  observations with and without known reference dates
- Any observations marked with `.observed = FALSE` can be excluded from
  the likelihood whilst still generating posterior predictions

**Where to see it:**

- NA handling example: See
  [`?enw_flag_observed_observations`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md)
  and
  [`?enw_obs`](https://package.epinowcast.org/dev/reference/enw_obs.md)
  for examples
- Other use cases: See function documentation for `enw_missing`,
  `enw_extend_date`

## Model Evaluation

Assess model fit and compare models.

| Method                      | What it provides                  | How to use                                           | Where to learn                                                                                                    |
|-----------------------------|-----------------------------------|------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| Posterior predictive checks | Visual fit assessment             | `enw_fit_opts(pp = TRUE)`                            | [Model vignette](https://package.epinowcast.org/dev/articles/model.md)                                            |
| LOO-CV                      | Model comparison                  | `enw_fit_opts(output_loglik = TRUE)` + `loo` package | See [`?loo::loo`](https://mc-stan.org/loo/reference/loo.html)                                                     |
| Scoring rules               | Probabilistic forecast evaluation | `scoringutils` package                               | [Germany hierarchical vignette](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md) |
| Convergence diagnostics     | MCMC quality checks               | Check `$fit$summary()`                               | [Stan help vignette](https://package.epinowcast.org/dev/articles/stan-help.md)                                    |

**Key functions:**

- [`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md):
  Control outputs
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html): Visualise
  results
- External: `loo`, `scoringutils` packages

**Where to see it:** The [Rt estimation
vignette](https://package.epinowcast.org/dev/articles/single-timeseries-rt-estimation.md)
shows model scoring and evaluation.

## Computational Options

Control computational efficiency and parallelisation.

| Feature                   | What it does                                  | How to specify                               | When to use                                 |
|---------------------------|-----------------------------------------------|----------------------------------------------|---------------------------------------------|
| Within-chain threading    | Parallel likelihood calculation across strata | `threads_per_chain = 4`                      | Many strata, large datasets, complex models |
| Parallel chains           | Multiple chains simultaneously                | `parallel_chains = 4`                        | Multiple cores available                    |
| Sparse design matrices    | Memory reduction                              | `sparse_design = TRUE`                       | Very sparse designs                         |
| Likelihood aggregation    | Parallelisation level                         | `likelihood_aggregation = "snapshots"`       | Default usually best                        |
| Pathfinder                | Fast approximate inference                    | `sampler = enw_pathfinder`                   | Exploration/debugging                       |
| Pathfinder initialisation | Use pathfinder to initialise MCMC             | `init_method = "pathfinder"` in `enw_sample` | Improve MCMC convergence                    |

**Key functions:**

- [`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md):
  Specify computational options
- See
  [`?enw_fit_opts`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md)
  for details

**Where to see it:** See [Stan help
vignette](https://package.epinowcast.org/dev/articles/stan-help.md) for
guidance on computational settings.

## Data Handling

Prepare and process data for nowcasting.

| Task                    | Functions                                                                                                                                                                                                            | Purpose                     |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|
| Convert from line list  | [`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)                                                                                                           | Individual → aggregate data |
| Complete date sequences | [`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md)                                                                                                                         | Fill missing dates          |
| Filter by dates         | [`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md), [`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md) | Subset data                 |
| Add metadata            | [`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md)                                                                                                             | Day of week, holidays, etc. |
| Change timesteps        | [`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md)                                                                                                             | Daily → weekly, etc.        |
| Main preprocessing      | [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)                                                                                                                       | All-in-one wrapper          |

**Where to see it:** The [getting started
vignette](https://package.epinowcast.org/dev/articles/epinowcast.md)
demonstrates the full data preprocessing workflow.

## Current Limitations

The following features are not currently supported but may be of
interest. If you need any of these capabilities, please reach out via
our [community forum](https://community.epinowcast.org/) or [GitHub
discussions](https://github.com/epinowcast/epinowcast/discussions).

| Feature                         | Status        | Notes                                                                      |
|---------------------------------|---------------|----------------------------------------------------------------------------|
| Non-count data                  | Not supported | Currently limited to count data with Poisson/negative binomial likelihoods |
| Negative updates                | Not supported | Cannot handle reporting corrections that reduce previously reported counts |
| Delay-only or count-only models | Not supported | Currently requires joint modelling of delay and counts                     |
| Susceptibility depletion        | Not supported | Renewal process assumes constant susceptibility                            |
| Uncertain generation time       | Not supported | Generation time distribution treated as fixed and known                    |
| Forecasting examples            | Missing       | Functionality exists but lacks worked examples in vignettes                |

**Get involved:** We welcome contributions and discussions about
extending the package to support these features. See our [community
forum](https://community.epinowcast.org/) for ongoing discussions.

## Further Reading

- [Getting started
  vignette](https://package.epinowcast.org/dev/articles/epinowcast.md):
  Basic workflow
- [Model definition
  vignette](https://package.epinowcast.org/dev/articles/model.md):
  Mathematical details
- [Germany case
  study](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md):
  Age-stratified nowcasting
- [Rt estimation
  vignette](https://package.epinowcast.org/dev/articles/single-timeseries-rt-estimation.md):
  Renewal process models
- [Distributions
  vignette](https://package.epinowcast.org/dev/articles/distributions.md):
  Parametric distributions
- Function documentation: `?function_name` for detailed API
- Package website: <https://package.epinowcast.org>
