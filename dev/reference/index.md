# Package index

## Nowcast

Functions for nowcasting.

- [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
  : Nowcast using partially observed data
- [`plot(`*`<epinowcast>`*`)`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)
  : Plot method for epinowcast
- [`summary(`*`<epinowcast>`*`)`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)
  : Summary method for epinowcast

## Data converters

Functions for converting between data formats

- [`enw_add_cumulative()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative.md)
  : Calculate cumulative reported cases from incidence of new reports
- [`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md)
  : Calculate incidence of new reports from cumulative reports
- [`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md)
  : Aggregate observations over a given timestep for both report and
  reference dates.
- [`enw_incidence_to_linelist()`](https://package.epinowcast.org/dev/reference/enw_incidence_to_linelist.md)
  : Convert Aggregate Counts (Incidence) to a Line List
- [`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)
  : Convert a Line List to Aggregate Counts (Incidence)

## Preprocess

Functions for preprocessing observations

- [`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md)
  : Add a delay variable to the observations

- [`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md)
  :

  Add the maximum number of reported cases for each `reference_date`

- [`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md)
  : Add common metadata variables

- [`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md)
  : Assign a group to each row of a data.table

- [`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md)
  : Complete missing reference and report dates

- [`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md)
  : Construct preprocessed data

- [`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md)
  : Extend a time series with additional dates

- [`enw_filter_delay()`](https://package.epinowcast.org/dev/reference/enw_filter_delay.md)
  : Filter observations to have a consistent maximum delay period

- [`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md)
  : Filter by reference dates

- [`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md)
  : Filter by report dates

- [`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md)
  : Flag observed observations

- [`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md)
  : Impute NA observations

- [`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md)
  : Filter observations to the latest available reported

- [`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md)
  : Extract metadata from raw data

- [`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md)
  : Calculate reporting delay metadata for a given maximum delay

- [`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md)
  : Extract reports with missing reference dates

- [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  : Preprocess observations

- [`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md)
  : Construct the reporting triangle

- [`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)
  : Recast the reporting triangle from wide to long format

## Model modules

Modular model components

- [`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md)
  : Expectation model module
- [`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md)
  : Format model fitting options for use with stan
- [`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md)
  : Missing reference data model module
- [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md)
  : Setup observation model and data
- [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md)
  : Reference date logit hazard reporting model module
- [`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md)
  : Report date logit hazard reporting model module

## Helpers for defining model modules

Functions that help with the setup of model modules and that may be
specific to individual modules

- [`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md)
  : Add maximum observed delay
- [`add_pmfs()`](https://package.epinowcast.org/dev/reference/add_pmfs.md)
  : Add probability mass functions
- [`convolution_matrix()`](https://package.epinowcast.org/dev/reference/convolution_matrix.md)
  : Construct a convolution matrix
- [`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md)
  : Create day-of-week structural reporting pattern
- [`enw_reference_by_report()`](https://package.epinowcast.org/dev/reference/enw_reference_by_report.md)
  : Construct a lookup of references dates by report
- [`enw_reps_with_complete_refs()`](https://package.epinowcast.org/dev/reference/enw_reps_with_complete_refs.md)
  : Identify report dates with complete (i.e up to the maximum delay)
  reference dates
- [`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md)
  : Create structural reporting metadata grid
- [`extract_obs_metadata()`](https://package.epinowcast.org/dev/reference/extract_obs_metadata.md)
  : Extract observation metadata
- [`extract_sparse_matrix()`](https://package.epinowcast.org/dev/reference/extract_sparse_matrix.md)
  : Extract sparse matrix elements
- [`latest_obs_as_matrix()`](https://package.epinowcast.org/dev/reference/latest_obs_as_matrix.md)
  : Convert latest observed data to a matrix

## Model tools

Generic functions that assist with combining and using modular models

- [`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md)
  : Format formula data for use with stan

- [`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md)
  : Retrieve Stan cache location

- [`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md)
  : Load and compile the nowcasting model

- [`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md)
  : Fit a CmdStan model using the pathfinder algorithm

- [`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md)
  :

  Convert prior `data.frame` to list

- [`enw_replace_priors()`](https://package.epinowcast.org/dev/reference/enw_replace_priors.md)
  : Replace default priors with user specified priors

- [`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md)
  : Fit a CmdStan model using NUTS

- [`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md)
  : Set caching location for Stan models

- [`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md)
  :

  Expose `epinowcast` stan functions in R

- [`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md)
  : Unset Stan cache location

- [`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md)
  : Remove profiling statements from a character vector representing
  stan code

- [`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)
  : Write copies of the .stan files of a Stan model and its \#include
  files with all profiling statements removed.

## Postprocess

Functions for postprocessing model output

- [`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md)
  :

  Build the ord_obs `data.table`.

- [`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md)
  : Add latest observations to nowcast output

- [`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md)
  : Extract posterior samples for the nowcast prediction

- [`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md)
  : Summarise the posterior nowcast prediction

- [`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md)
  : Summarise the posterior

- [`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md)
  : Posterior predictive summary

- [`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md)
  : Convert summarised quantiles from wide to long format

- [`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md)
  : Summarise posterior samples

- [`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)
  : Subset observations data table for either modelled dates or
  not-modelled earlier dates.

## Plot

Functions for plotting postprocessed nowcast model output

- [`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_nowcast_quantiles.md)
  : Plot nowcast quantiles
- [`enw_plot_obs()`](https://package.epinowcast.org/dev/reference/enw_plot_obs.md)
  : Generic quantile plot
- [`enw_plot_pp_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_pp_quantiles.md)
  : Plot posterior prediction quantiles
- [`enw_plot_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_quantiles.md)
  : Generic quantile plot
- [`enw_plot_theme()`](https://package.epinowcast.org/dev/reference/enw_plot_theme.md)
  : Package plot theme
- [`plot(`*`<epinowcast>`*`)`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)
  : Plot method for epinowcast

## Model validation

Functions for validating model fits

- [`as_forecast_sample(`*`<epinowcast>`*`)`](https://package.epinowcast.org/dev/reference/as_forecast_sample.epinowcast.md)
  : Convert an epinowcast object to a forecast_sample object

## Formula design tools

Functions that assist with interpreting model formulas

- [`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md)
  : Converts formulas to strings
- [`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md)
  : Constructs random effect terms
- [`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md)
  : Constructs random walk terms
- [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  : Define a model using a formula interface
- [`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md)
  : Define a model manually using fixed and random effects
- [`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md)
  : Parse a formula into components
- [`re()`](https://package.epinowcast.org/dev/reference/re.md) : Defines
  random effect terms using the lme4 syntax
- [`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md)
  : Remove random walk terms from a formula object
- [`rw()`](https://package.epinowcast.org/dev/reference/rw.md) : Adds
  random walks with Gaussian steps to the model.
- [`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md)
  : Finds random walk terms in a formula object
- [`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)
  : Split formula into individual terms

## Model design tools

Functions that assist with designing models

- [`enw_add_cumulative_membership()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative_membership.md)
  :

  Add a cumulative membership effect to a `data.frame`

- [`enw_add_pooling_effect()`](https://package.epinowcast.org/dev/reference/enw_add_pooling_effect.md)
  : Add a pooling effect to model design metadata

- [`enw_design()`](https://package.epinowcast.org/dev/reference/enw_design.md)
  : A helper function to construct a design matrix from a formula

- [`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md)
  : Extracts metadata from a design matrix

- [`enw_one_hot_encode_feature()`](https://package.epinowcast.org/dev/reference/enw_one_hot_encode_feature.md)
  : One-hot encode a variable and column-bind it to the original
  data.table

## Datasets

Package datasets used in examples and by users to explore the package
functionality

- [`enw_example()`](https://package.epinowcast.org/dev/reference/enw_example.md)
  : Load a package example
- [`germany_covid19_hosp`](https://package.epinowcast.org/dev/reference/germany_covid19_hosp.md)
  : Hospitalisations in Germany by date of report and reference

## Simulate Datasets

Tools for simulating datasets

- [`enw_simulate_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_simulate_missing_reference.md)
  : Simulate observations with a missing reference date.

## Check inputs

Functions to check the structure of user inputs

- [`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md)
  : Check design matrix sparsity

- [`check_group()`](https://package.epinowcast.org/dev/reference/check_group.md)
  : Check observations for reserved grouping variables

- [`check_group_date_unique()`](https://package.epinowcast.org/dev/reference/check_group_date_unique.md)
  :

  Check observations for uniqueness of grouping variables with respect
  to `reference_date` and `report_date`

- [`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md)
  : Check appropriateness of maximum delay

- [`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md)
  : Check a model module contains the required components

- [`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md)
  : Check that model modules have compatible specifications

- [`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md)
  : Check Numeric Timestep

- [`check_observation_indicator()`](https://package.epinowcast.org/dev/reference/check_observation_indicator.md)
  : Check observation indicator

- [`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md)
  : Check required quantiles are present

- [`check_timestep()`](https://package.epinowcast.org/dev/reference/check_timestep.md)
  : Check timestep

- [`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md)
  : Check timestep by date

- [`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)
  : Check timestep by group

## Utilities

Utility functions

- [`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md)
  : Coerce Dates

- [`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md)
  :

  Coerce `data.table`s

- [`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md)
  : Convert date column to numeric and calculate its modulus with given
  timestep.

- [`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md)
  : Perform rolling sum aggregation

- [`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md)
  : Get internal timestep

- [`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md)
  : Check an object is a Date

- [`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)
  : Read in a stan function file as a character string
