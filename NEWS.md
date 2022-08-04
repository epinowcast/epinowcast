# epinowcast 0.2.0

## Package
- Added `.Rhistory` to the `.gitignore` file. See #132 by @choi-hannah.
- Fixed indentations for authors and contributors in the `DESCRIPTION` file. See #132 by @choi-hannah.

## Model
- Added support for parametric log-logistic delay distributions. See #128 by @adrian-lison.
- Implemented direct specification of parametric baseline hazards. See #134 by @adrian-lison.
- Refactored the observation model, the combination of logit hazards, and the effects priors to be contained in generic functions to make extending package functionality easier. See #137 by @seabbs.
- Implemented specification of the parametric baseline hazards and probabilities on the log scale to increse robustness and efficiency. Also includes refactoring of these functions and reorganisation of `inst/stan/epinowcast.stan` to increase modularity and clarity. See #140 by @seabbs.

## Documentation
- Removed explicit links to authors and issues in the `NEWS.md` file. See #132 by @choi-hannah.

## Bugs

- The probability-only model (i.e only a parametric distribution is used and hence the hazard scale is not needed) was not used due to a mistake specifying `ref_as_p` in the stan code. There was an additional issue in that the `enw_report()` module currently self-declares as on regardless of it is or not. This bug had no impact on results but would have increased runtimes for simple models. Both of these issues were fixed in #142 by @seabbs.

# epinowcast 0.1.0

This is a major release focusing on improving the user experience, and preparing for future package extensions, with an increase in modularity, development of a flexible and full-featured formula interface, and hopefully future-proofing as far as possible. This prepares the ground for future model extensions which will allow a broad range of real-time infectious disease questions to be better answered. These extensions include:

* Modelling missing data (#43).
* Non-parametric modelling of delay and reference day logit hazard (#4).
* Flexible expectation modelling (#5).
* Forecasting beyond the horizon of the data (#3).
* Known reporting structures (#33).
* Renewal equation-based reproduction number estimation (potentially part of #5).
* Latent infections (i.e as implemented in other packages such as `EpiNow2`, `epidemia`, etc.).
* Convolution-based delay models (i.e hospitalisations and deaths) with partially reported data.
* Additional observation models.

If interested in contributing to these features, or other aspects of package development (for example improving post-processing, the coverage of documentation, or contributing case studies) please see our [contributing guide](https://epiforecasts.io/epinowcast/dev/CONTRIBUTING.html) and/or just reach out. This is a community project that needs support from its users in order to provide improved tools for real-time infectious disease surveillance. 

This release contains multiple breaking changes. If needing the old interface please install [`0.0.7` from GitHub](https://github.com/epiforecasts/epinowcast/releases/tag/v0.0.7). For ease, we have stratified changes below into interface, package, documentation, and model changes. Note the package is still flagged as experimental but is in regular use by the authors.

@adrian-lison, @sbfnk, and @seabbs contributed to this release. 

## Interface

* A fully featured and flexible formula interface has been added that allows the specification of fixed effects, `lme4` random effects, and random walks. See #27 by @seabbs.
* A major overhaul, as described in #57, to the interface of `epinowcast()` with a particular focus on improving the modularity of the model components (described as modules in the documentation). All of the package documentation and vignettes have been updated to reflect this new interface. See #112 by @seabbs.

## Package

* Renamed the package and updated the description to give more clarity about the problem space it focusses on. See #110 by @seabbs.
* A new helper function `enw_delay_metadata()` has been added. This produces metadata about the delay distribution vector that may be helpful in future modelling. This prepares the way for #4 where this data frame will be combined with the reference metadata in order to build non-parametric hazard reference and delay-based models. In addition to adding this function, it has also been added to the output of `enw_preprocess_data()` in order to make the metadata readily available to end-users. See #80 by @seabbs.
* Two new helper functions `enw_filter_reference_dates()` and `enw_filter_report_dates()` have been added. These replace `enw_retrospective_data()` but allow users to similarly construct retrospective data. Splitting these functions out into components also allows for additional use cases that were not previously possible. Note that by definition it is assumed that a report date for a given reference date must be equal or greater (i.e a report cannot happen before the event being reported occurs). See #82 by @sbfnk and @seabbs.
* The internal grouping variables have been refactored to reduce the chance of clashes with columns in the data frames supplied by the user. There will also be an error thrown in case of a variable clash, making preprocessing safer. See #102 by @adrian-lison and @seabbs, which solves #99.
* Support for preprocessing observations with missing reference dates has been added along with a new data object returned by `enw_preprocess_data()` that highlights this information to the user (alternatively can be accessed by users using `enw_missing_reference()`). In addition, these missing observations have been setup to be passed to stan in order to allow their use in modelling. This feature is in preparation of adding full support for missing observations (see #43). See 
#106 by @adrian-lison and @seabbs.
* The discretised reporting probability function has been extended to handle delays beyond the maximum delay in three different ways: ignore, add to maximum, or normalize. The nowcasting model uses "normalise" though work on this is ongoing. See #113 by @adrian-lison and #121 by @seabbs.
* Fixed an issue (#105) with `cmdstan 2.30.0` where passing optimisation flags to `stanc_options` by default was causing a compilation error by not passing these flags by default. See #117 by @sbfnk and @seabbs.
* Addition of regression/integration tests against example data for `epinowcast()` and `enw_preprocess_data()` with convergence checking for several example nowcasting models. Lower level tests for model tools and model modules have also been added. See #112 by @seabbs.

## Model

* Added support for parametric exponential delay distributions (note that this is comparable to an intercept-only non-parametric hazard model) and potentially no parametric delay (though this will currently throw an error due to the lack of appropriate non-parametric hazard). See #84 by @seabbs.
* Added support for a Poisson observation model though it is recommended that most users make use of the default negative binomial model. See #120 by @seabbs.
* Updated the expectation random walk model to use a more efficient `cumulative_sum` implementation suggested by @adrian-lison in #98. See #103 by @seabbs.
* Aligned the implementation of the overdispersion prior with the prior choice recommendations from the [stan wiki](https://github.com/stan-dev/stan/wiki/Prior-Choice-Recommendations). See #111 by @adrian-lison.

## Documentation

* The model description has been updated to reflect the currently implemented model and to improve readability. The use of reference and report date nomenclature has also been standardised across the package. See #71 by @sbfnk and @seabbs.

## Internals

* Array declarations in the stan model have been updated. To maintain compatibility with `expose_stan_fns()` (which itself depends on `rstan`), additional functionality has been added to parse stan code in this function. See #74, [#85](https://github.com/epiforecasts/epinowcast/pull/85#issuecomment-1172010003), and #93 by @sbfnk and @seabbs.
* Remove spurious warnings due to missing initial values for optional parameters. See #76 by @sbfnk and @seabbs.

# epinowcast 0.0.7

* Adds additional quality of life data processing so that the maximum number (`max_confirm`) of notifications is available in every row (for both cumulative and incidence notifications) and the cumulative and daily empirical proportion reported are calculated for the user during pre-processing (see #62 by @seabbs). 
* The default approach to handling reported notifications beyond the maximum delay has been changed. In `0.0.6` and previous versions notifications beyond the maximum delay were silently dropped. In `0.0.7` this is now optional behaviour (set using `max_delay_strat` in `enw_preprocess_data()`) and the default is instead to add these notifications to the last included delay were present. This should produce more accurate long-term nowcasts when data is available but means that reported notifications for the maximum delay need to be interpreted with this in mind. See #62 by @seabbs.
* Adds some basic testing and documentation for preprocessing functions. See #62 by @seabbs.
* Stabilises calculation of expected observations by increasing the proportion of the calculation performed on the log scale. This results in reduced computation time with the majority of this coming from switching to using the `neg_binomial_2_log` family of functions (over their natural scale counterparts). See #65 by @seabbs

# epinowcast 0.0.6

* Simplifies and optimises the internal functions used to estimate the parametric daily reporting probability. These are now exposed to the user via the `distribution` parameter with both the Lognormal and Gamma families being tested to work. Note that both parameterisations use their standard parameterisations as given in the stan manual (see #42 by @adrian-lison and @seabbs)
* Add profiling switch to model compilation, allowing to toggle profiling (https://mc-stan.org/cmdstanr/articles/profiling.html) on/off in the same model. Also supports .stan files found in `include_paths` (see #41 and #54 by @adrian-lison).
* Fully vectorise the likelihood by flattening observations and pre-specify expected observations into a vector before calculating the log-likelihood (see #40 by @seabbs).
* Adds vectorisation of zero truncated normal distributions (see #38 by @seabbs)
* `hazard_to_prob` has been optimised using vectorisation (see #53 by @adrian-lison and @seabbs).
* `prob_to_hazard` has been optimised so that only required cumulative probabilities are calculated (see #53 by @adrian-lison and @seabbs).
* Updated to use  the `inv_sqrt` stan function (see #60 by @seabbs).
* Added support for `scoringutils 1.0.0` (see #61 by @seabbs). 
* Added a basic example helper function, `enw_example()`, to power examples and tests based on work done in [`forecast.vocs`](https://epiforecasts.io/forecast.vocs/) (see #61 by @seabbs).

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
