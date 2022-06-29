# epinowcast 0.1.0

This is a major release and contains breaking changes. If needing the old interface please install `0.0.7` from GitHub. A major focus of this release has been improving the user interface with an increase in modularity, development of a flexible and full featured formula interface, and hopefully future proofing this interface. For ease we have stratified changes below into interface, package, and model changes.

## Interface

* A full featured and flexible formula interface has been added that allows the specification of fixed effects, `lme4` random effects, and random walks. See [#27](https://github.com/epiforecasts/epinowcast/pull/27) by [@seabbs](https://github.com/seabbs).

## Package

* A new helper function `enw_delay_metadata()` has been added. This produces metadata about the delay distribution vector that may be helpful in future modelling. This prepares the way for [#4](https://github.com/epiforecasts/epinowcast/issues/4) where this data frame with be combined with the reference metadata in order to build non-parametric hazard reference and delay based models. In addition to adding this function it has also been added to the output of `enw_preprocess_data()` in order to make the metadata readily available to end-users. See [#80](https://github.com/epiforecasts/epinowcast/pull/80) by [@seabbs](https://github.com/seabbs).

## Model

# epinowcast 0.0.7

* Adds additional quality of life data processing so that the maximum number (`max_confirm`) of notifications is available in every row (for both cumulative and incidence notifications) and the cumulative and daily empirical proportion reported are calculated for the user during pre-processing (see [#62](https://github.com/epiforecasts/epinowcast/pull/62) by [@seabbs](https://github.com/seabbs)). 
* The default approach to handling reported notifications beyond the maximum delay has been changed. In `0.0.6` and previous versions notifications beyond the maximum delay were silently dropped. In `0.0.7` this is now optional behaviour (set using `max_delay_strat` in [enw_preprocess_data()]) and the default is instead to add these notifications to the last included delay were present. This should produce more accurate long-term nowcasts when data is available but means that reported notifications for the maximum delay need to be interpreted with this in mind. See [#62](https://github.com/epiforecasts/epinowcast/pull/62)by [@seabbs](https://github.com/seabbs).
* Adds some basic testing and documentation for preprocessing functions. See [#62](https://github.com/epiforecasts/epinowcast/pull/62)by [@seabbs](https://github.com/seabbs).
* Stabilises calculation of expected observations by increasing the proportion of the calculation performed on the log scale. This results in reduced computation time with the majority of this coming from switching to using the `neg_binomial_2_log` family of functions (over their natural scale counterparts). See [#65](https://github.com/epiforecasts/epinowcast/pull/65)by [@seabbs](https://github.com/seabbs)

# epinowcast 0.0.6

* Simplifies and optimises the internal functions used to estimate the parametric daily reporting probability. These are now exposed to the user via the `distribution` parameter with both the Lognormal and Gamma families being tested to work. Note that both parameterisations use their standard parameterisations as given in the stan manual (see [#42](https://github.com/epiforecasts/epinowcast/pull/42) by [@adrian-lison](https://github.com/adrian-lison) and [@seabbs](https://github.com/seabbs))
* Add profiling switch to model compilation, allowing to toggle profiling (https://mc-stan.org/cmdstanr/articles/profiling.html) on/off in the same model. Also supports .stan files found in `include_paths` (see [#41](https://github.com/epiforecasts/epinowcast/pull/41) and [#54](https://github.com/epiforecasts/epinowcast/pull/54) by [@adrian-lison](https://github.com/adrian-lison)).
* Fully vectorise the likelihood by flattening observations and pre-specify expected observations into a vector before calculating the log-likelihood (see [#40](https://github.com/epiforecasts/epinowcast/pull/40) by [@seabbs](https://github.com/seabbs)).
* Adds vectorisation of zero truncated normal distributions (see [#38](https://github.com/epiforecasts/epinowcast/pull/38) by [@seabbs](https://github.com/seabbs))
* `hazard_to_prob` has been optimised using vectorisation (see [#53] by [@adrian-lison](https://github.com/adrian-lison) and [@seabbs](https://github.com/seabbs)).
* `prob_to_hazard` has been optimised so that only required cumulative probabilities are calculated (see [#53] by [@adrian-lison](https://github.com/adrian-lison) and [@seabbs](https://github.com/seabbs)).
* Updated to use  the `inv_sqrt` stan function (see [#60](https://github.com/epiforecasts/epinowcast/pull/60) by @seabbs).
* Added support for `scoringutils 1.0.0` (see [#61](https://github.com/epiforecasts/epinowcast/pull/61) by @seabbs). 
* Added a basic example helper function, `enw_example()`, to power examples and tests based on work done in [`forecast.vocs`](https://epiforecasts.io/forecast.vocs/) (see [#61](https://github.com/epiforecasts/epinowcast/pull/61) by @seabbs).

# epinowcast 0.0.5

* Convert retrospective data date fields to class of `IDate` when utilising `enw_retrospective_data` to solve esoteric error.
* Added full argument name for `include_paths` to avoid console chatter
* Adds a `stanc_options` argument to `enw_model()` and specifies a new default of `list("01")` which enables simple pre-compilation optimisations. See [here](https://blog.mc-stan.org/2022/02/15/release-of-cmdstan-2-29/) of these optimisation for details.
* Remove `inv_logit` and `logit` as may instead use base R `plogit` and `qlogit`.

# epinowcast 0.0.4

* Add support for extracting and summarising posterior nowcast samples
* Package spell check
* Update read me quick start to use 40 days of delay vs 30
* Add a section to the read me quick start showing an example of handling nowcast samples.
* Add support for passing custom models and included files to `enw_model()`.
* Fix a bug where `enw_summarise_samples()` returned duplicate samples.
* Add support for passing holidays as a variable and then adjusting by converting the holiday day into a custom day of the week (by default Sunday but this is set by the user).
* Added support for scoring on both the natural and log scale. This represents absolute and relative scoring respectively.

# epinowcast 0.0.3

* Add support for passing in priors
* Add case study vignette
* Add model definition and implementation details.
* Add support for out of sample scoring (using `scoringutils`).

# epinowcast 0.0.2

* Initial version of the package with broadly working functionality and first draft vignettes.

# epinowcast 0.0.1

* Initial package version with development code
