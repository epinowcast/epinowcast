# epinowcast 0.2.3

This release is in development and not yet ready for production use.

## Contributors

@seabbs contributed code to this release.

@seabbs reviewed pull requests for this release.

@jbracher, @pearsonca, @bisaloo, @adrian-lison, and @seabbs reported bugs reported bugs, made suggestions, or contributed to discussions that led to improvements in this release.

## Bugs

- Fixed a bug identified by @jbracher where the `enw_expectation()` module was not appropriately defining initial conditions when multiple groups were present. This issue was related to recent changes in `cmdstan 2.32.1` and is required in order to use versions of `cmdstan` beyond `2.32.0` with models that contain multiple time series. See #282 by @seabbs and self-reviewed.

## Package

- Added additional tests to ensure that the `enw_expectation()` module is appropriately defining initial conditions when multiple groups are present. See #282 by @seabbs
- Added an integration test for `epinowcast()` to check models with multiple time series can be fit as expected on example data. See #282 by @seabbs and self-reviewed.
- Added a `{touchstone}` benchmark that includes multiple time-series to ensure that this functionality is appropriately tested. See #282 by @seabbs and self-reviewed.

# epinowcast 0.2.2

This is a minor release that fixes a bug in the handling of optional initial conditions that was introduced by a recent change in `cmdstan 2.32.1`. Upgrading is recommended for all users who wish to use versions of `cmdstan` beyond `2.32.0`. In addition to fixing this issue, the release also includes some minor documentation and vignette improvements, along with enhancements in input checking.

## Contributors

@sbfnk and @seabbs contributed code to this release.

@seabbs reviewed pull requests for this release.

@sbfnk and @seabbs reported bugs reported bugs, made suggestions, or contributed to discussions that led to improvements in this release.

## Bugs

- Improved the handling of optional initial conditions so that they are consistently passed as arrays to stan as required by `cmdstan 2.32.1`. This fix is required in order to use versions of `cmdstan` beyond `2.32.0`. See #276 by @seabbs and self-reviewed.

## Package

- Added input checking for `max_delay` in `enw_preprocess_data()` to ensure that the maximum delay is greater than or equal to 1 and that it can be coerced to be an integer. See #274 by @sbfnk and reviewed by @seabbs.

## Documentation

- Improved the discrete delay distributions vignette including escaping functions to improve readibility and right-closing discretised bins. See #275 by @sbfnk and reviewed by @seabbs.
- Improved the documentation for `max_delay` in `enw_preprocess_data()` and fixed a typo in the same documentation. See #274 by @sbfnk and reviewed by @seabbs.

# epinowcast 0.2.1

In this release, we focused on improving the internal code structure, documentation, and development infrastructure of the package to make it easier to maintain and extend functionality in the future. We also fixed a number of bugs and made some minor improvements to the interface. These changes included extending test and documentation coverage across all package functions, improving internal data checking and internalization, and removing some deprecated functions.

While these changes are not expected to impact most users, we recommend that all users upgrade to this version. We also suggest that users who have fitted models with both random effects and random walks should refit these models and compare the output to previous fits in order to understand the impact of a bug in the specification of these models that was fixed in this release.

This release lays the groundwork for planned features in [`0.3.0`](https://github.com/orgs/epinowcast/projects/1) and [`0.4.0`](https://github.com/orgs/epinowcast/projects/2) including: support for non-parametric delays, non-daily data with a non-daily process model (i.e. weekly data with a weekly process model), additional flexibility specifying generation times and latent reporting delays, improved case studies, and adding support for forecasting.

Full details on the changes in this release can be found in the following sections or in the [GitHub release notes](https://github.com/epinowcast/epinowcast/releases/tag/v0.2.1). To see the development timeline of this release see the [`0.2.1` project](https://github.com/orgs/epinowcast/projects/3).

## Contributors

@adrian-lison, @Bisaloo, @pearsonca, @FelixGuenther, @Lnrivas, @seabbs, @sbfnk, and @jhellewell14 made code contributions to this release.

@pearsonca, @Bisaloo, @adrian-lison, and @seabbs reviewed pull requests for this release.

@Gulfa, @WardBrian, @parkws3, @adrian-lison, @Bisaloo, @pearsonca, @FelixGuenther, @Lnrivas, @seabbs, @sbfnk and @jhellewell14 reported bugs, made suggestions, or contributed to discussions that led to improvements in this release.

## Potentially breaking changes

- `enw_add_pooling_effect()`: replaced `string` argument with `...` argument, to enable passing arbitrary arguments to the `finder_fn` argument. The same general usage is supported, but now e.g. the default argument to supply is `prefix = "somevalue"` vs `string = "somevalue"` and argument positions have changed. This function is primarily for internal use and we expect only a small subset of advanced users who are creating models outside the currently supported formula interface to be impacted See #222 by @pearsonca and reviewed by @seabbs.
- `enw_dates_to_factors()`: Deprecated and removed as no longer needed. We expect this function had little to no external use and so there should be little impact on users. See #216 by @seabbs and reviewed by @adrian-lison.

## Bugs

- Fixed a bug first highlighted by @Gulfa in #166 and localised during the investigation for #223 where random effects and random walks were being improperly constructed  in `enw_formula()` so that their variances parameters were not shared between the correct parameters when used together. This only impacts models that used formulas with both random effects and random walks and for these models appears to have led to increased run-times, fitting issues, and potentially unreliable posterior estimates but to have had a less significant  impact on actual nowcasts. We suggest refitting these models and comparing the output to previous fits in order to understand the impact on your usage. See #228 by @seabbs and self-reviewed.
- Fixed a bug in `enw_replace_priors()` where the function could not deal with `epinowcast` summarised posterior estimates due to the new use of the `pillar` class. Added tests to catch if this issue reoccurs in the future. See #228 by @seabbs and self-reviewed.
- Fixed an issue (#198) with the interface for `scoringutils`. For an unknown reason our example data contained `pillar` classes (likely due to an upstream change). This caused an issue with internal `scoringutils` that was using implicit type conversion (see [here](https://github.com/epiforecasts/scoringutils/pull/274)). See #201 by @seabbs and reviewed by @pearsonca.
- Fixed a bug in `enw_plot_quantiles()` where the documented default for `log` was `FALSE` but the actual default was `TRUE`. See #209 by @seabbs and self-reviewed.
- Fixed a bug in `enw_expectation()` where when models were specified with zero intercept a initial condition was still being specified for the intercept of the growth rate (`expr_r_int`, #246). This was not flagged as an issue by `cmdstan 2.31.0` but as of `cmdstan 2.32.0`, due to improvements in how initial conditions were being read in ([stan-dev/stan#3182](https://github.com/stan-dev/stan/issues/3182)), it throws an error causing models to fail. Solution suggested by @WardBrian, implemented in #255 by @seabbs, and reviewed by @pearsonca.

## Depreciations

- `enw_incidence_to_cumulative()`: Deprecated with a warning in favour of `enw_add_cumulative()`. This renaming is to better reflect the function's purpose. `enw_incidence_to_cumulative()` will be removed in `0.3.0`. See #247 by @seabbs and reviewed by @pearsonca.
- `enw_cumulative_to_incidence()`: Deprecated with a warning in favour of `enw_add_incidence()`. This renaming is to better reflect the function's purpose. `enw_cumulative_to_incidence()` will be removed in `0.3.0`. See #247 by @seabbs and reviewed by @pearsonca.

## Package

- Fixed some typos in `README.md`, `NEWS.md`, the `model.Rmd` vignette and `convolution_matrix()` documentation. The `WORDLIST` used by spelling has also been updated by eliminate false positives. See #221 by @Bisaloo and reviewed by @seabbs and @adrian-lison.
- Added more non-default linters in `.lintr` configuration file. This file is used when `lintr::lint_package()` is run or in the new `lint-changed-files.yaml` GitHub Actions workflow. See #220 by @Bisaloo and reviewed by @pearsonca and @seabbs.
- Switched to the `lint-changed-files.yaml` GitHub Actions workflow instead of the regular `lint.yaml` to avoid annotations unrelated to the changes made in the PR. See #220 by @Bisaloo and reviewed by @pearsonca and @seabbs.
- Added tests for `summary.epinowcast()` and `plot.epinowcast()` methods. See #209 by @seabbs and reviewed by @pearsonca.
- Added tests for `enw_plot_obs()` where not otherwise covered by `plot.epinowcast()` tests. See #209 by @seabbs and reviewed by @pearsonca.
- Refactored to consolidate data checking and internalization into a single internal function `coerce_dt()`, addressing issues #242, #241, #214, and #149. This eliminates the need for `add_group()`, `check_by()`, and `check_dates()` (and associated documentation, tests - some of these were intermediate capabilities introduced within this minor version; see #208) which have all been removed. Also starts to enable internal versus external use of exposed methods with the `copy = ...` argument. See #239 by @pearsonca, reviewed by @seabbs.
- Resolved the spurious test warnings for snapshot tests which were linked to unstated formatting requirements. See #208 by @seabbs and reviewed by @pearsonca.
- Removed unused internal plot helpers. See #217 by @seabbs and reviewed by @adrian-lison.
- Added tests for all internal `check_` functions used to check inputs. See #217 by @seabbs and reviewed by @adrian-lison.
- Removed the problematic double specification of default arguments for `target_date` in `enw_metadata()` as flagged in #212 by @pearsonca using `formals()` to instead detect the default values from the function specification. See #232 by @seabbs and self-reviewed.
- In the words of Jenny Bryan: "there is no else, there is only if." Having else after `return()` of `stop()` increases the number of branches in the code, which makes it harder to read. It also translates into a higher cyclomatic complexity. We have removed all else statements after `return()` and `stop()` in the package. See #229 by @Bisaloo and reviewed by @seabbs.
- Removed the internal definition of `no_contrasts` in `enw_formula()` as this was unused. Identified by @bisaloo in #220 and raised in #223. See #228 by @seabbs and self-reviewed.
- Added tests for `enw_replace_priors()` to check that it can handle `epinowcast` summarised posterior estimates. See #228 by @seabbs and self-reviewed.
- Added a prefix (`rw__`) in `enw_formula()` and `construct_rw()` to indicate when a random effect variance is a random walk versus a random effect. See #228 by @seabbs and reviewed by.
- Added support for using the same variable as both a random effect and a random walk. In most settings this is not advised. See #228 by @seabbs and self-reviewed.
- Added an error message to `construct_rw()` when a random walk is specified for a variable that is not a numeric variable. See #228 by @seabbs and self-reviewed.
- Added support for preprocessing and model fitting benchmarking using `touchstone` based on the implementation in `EpiNow2` by @sbfnk. See #200 by @seabbs, @adrian-lison, @sbfnk, and self-reviewed.
- Added a complete set of data converters to map between line list (i.e. each row is a case) and count data (i.e incidence and cumulative counts by reference and report date). In particular, this will help workflows where individual line list data is available as it can now be formatted ready for preprocessing using a single call to `enw_linelist_to_incidence()` which previously took several steps. See #247 by @seabbs and @jhellewell14 and reviewed by @pearsonca.
- Dropped the use of the `develop` branch for development versions of the package. This change was discussed in #250 with the major motivator being that since the introduction of release only builds to R Universe we no longer need to have a stable `main` branch of GitHub to control our releases. See #256 by @seabbs and reviewed by @Bisaloo and @pearsonca.
- Cleaned enw_formula_as_data_list() to better align with DRY principles. See #245 by @Lnrivas, reviewed by @pearsonca, @Bisaloo, and @seabbs.

## Documentation

- Added examples for `summary.epinowcast()` and `plot.epinowcast()` methods to the documentation. See #209 by @seabbs and reviewed by @pearsonca.
- Extended documentation, examples, and tests for internal, preprocessing, and postprocessing functions. See #208 by @seabbs and reviewed by @pearsonca.
- Added examples for all plot functions. See #209 by @seabbs and reviewed by @pearsonca.
- Added an example for `enw_replace_priors()` showing how to use a nowcast posterior to update the default priors. See #228 by @seabbs and self-reviewed.
- Updated the package citation and documentation to include all new authors as of the `0.2.1` release and to use the recommended `bibentry()` approach. See #236 and #237 by @seabbs and reviewed by @Bisaloo.
- Added a package style guide (`STYLE_GUIDE.md`) to document the style conventions used in the package. See #64 by @seabbs and reviewed by @pearsonca and @Bisaloo.
- Improved and extended documentation of discretized, parametric delay distributions. Changed structure of package vignettes (into two categories, model definition vignettes and case study vignettes). See #265 by @FelixGuenther and @adrian-lison and reviewed by @seabbs.
- Improved and extended the README quick start after feedback from @parksw3 in #260. See #267 by @seabbs and reviewed by @adrian-lison and @parksw3.

# epinowcast 0.2.0

This release adds several extensions to our modelling framework, including modelling of missing data, flexible modelling of the generative process underlying case counts, an optional renewal equation-based generative process (enabling direct estimation of the effective reproduction number), and convolution-based latent reporting delays (enabling the modelling of both directly observed and unobserved delays as well as partial ascertainment). Much of the methodology used in these extensions is based on [work done by Adrian Lison](https://github.com/adrian-lison/nowcast-transmission) and is currently being evaluated.

On top of model extensions this release also adds a range of quality of life features, such as a helper functions for constructing convolution matrices and combining probability mass functions. It also comes with improved computational efficiency, thanks to a refactoring of the hazard model computations to the log scale and extended parallelisation of the likelihood that is optimised for the structure of the input data. We have also extended the package documentation and streamlined the contribution process.

As a large-scale project, the package remains in an experimental state, though it is sufficiently stable for both research and production usage. More core development is needed to improve post-processing, pre-processing, documentation coverage, and evaluate optimal configurations in different settings) please see our [community site](https://community.epinowcast.org/), [contributing guide](https://github.com/epinowcast/epinowcast/blob/main/CONTRIBUTING.md), and list of [issues/proposed features](https://github.com/epinowcast/epinowcast/issues) if interested in being involved (any scale of contribution is warmly welcomed including user feedback, requests to extend our functionality to cover your setting, and evaluating the package for your context). This is a community project that needs support from its users in order to provide improved tools for real-time infectious disease surveillance.

We thank @adrian-lison, @choi-hannah, @sbfnk, @Bisaloo, @seabbs, @pearsonca, and @pratikunterwegs for code contributions to this release. We also thank all [community members](https://community.epinowcast.org/) for their contributions including @jhellewell14, @FelixGuenther, @parksw3, and @jbracher.

Full details on the changes in this release can be found in the following sections.

## Package

- Added `.Rhistory` to the `.gitignore` file. See #132 by @choi-hannah.
- Fixed indentations for authors and contributors in the `DESCRIPTION` file. See #132 by @choi-hannah.
- Renamed `enw_new_reports()` to `enw_cumulative_to_incidence()` and added the reverse function `enw_incidence_to_cumulative()` both functions use a `by` argument to allow specification of variable groupings. See #157 by @seabbs.
- Switched class checking to `inherits(x, "class")` rather than `class(x) %in% "class"`. See #155 by @Bisaloo.
- Changed `enw_add_metaobs_features()` interface to have `holidays` argument as
a series of dates. Changed interface of `enw_preprocess_data()` to pass `...` to `enw_add_metaobs_features()`. Interface changes come with internal rewrite and unit tests. As part of internal rewrite, introduces `coerce_date()` to `R/utils.R`, which wraps `data.table::as.IDate()` with error handling. See #151 by @pearsonca.
 - Changed the style of using `match.arg` for validating inputs. Briefly, the preference is now to define options via function arguments and validate with automatic `match.arg` idiom with corresponding enumerated documentation of the options. For this idiom, the first item in the definition is the default. This approach only applies to string-based arguments; different types of arguments cannot be matched this way, nor can arguments that allow for vector-valued options (e.g., if `somearg = c("option1", "option2")` were a legal argument indicating to use both options). See #162 by @pearsonca addressing issue #156 by @Bisaloo.
- Refined the use of data ordering throughout the preprocessing functions. See #147 by @seabbs.
- Skipped tests that use `cmdstan` locally to improve the developer/contributor experience. See #147 by @seabbs and @adrian-lison.
- Added a basic simulator function for missing reference data. See #147 by @seabbs and @adrian-lison.
- Added support for right hand side interactions as syntax sugar for random effects. This allows the specification of, for example, independent random effects by day for each strata of another variable. See #169 by @seabbs.
- Added support for passing `cpp_options` to `cmdstanr::cmdstan_model()`. See #182 by @seabbs.
- Add a function, `convolution_matrix()` for constructing convolution matrices. See #183 by @seabbs.
- Add a pass through from `enw_model()` to `write_stan_files_no_profile()` for the `target_dir` argument. This allows users to compile the model once and then share the compiled model across sessions rather than having to recompile each time the temporary directory is cleared. See #185 by @seabbs.
- Added `add_pmfs()`, to sum probability mass functions into a new probability mass function. Initial implementation by @seabbs in #183, refactored by @pratikunterwegs in #187, following a suggestion in issue #186 by @pearsonca.
- Added a warning when the observed empirical maximum delay is less than the specified maximum delay. See #190 by @seabbs.
- Added nested support for converting array syntax in `convert_cmdstan_to_rstan`. See #192 by @sbfnk.

## Model

- Added support for parametric log-logistic delay distributions. See #128 by @adrian-lison.
- Implemented direct specification of parametric baseline hazards. See #134 by @adrian-lison.
- Refactored the observation model, the combination of logit hazards, and the effects priors to be contained in generic functions to make extending package functionality easier. See #137 by @seabbs.
- Implemented specification of the parametric baseline hazards and probabilities on the log scale to increase robustness and efficiency. Also includes refactoring of these functions and reorganisation of `inst/stan/epinowcast.stan` to increase modularity and clarity. See #140 by @seabbs.
- Introduced two new delay likelihoods `delay_snap_lmpf` and `delay_group_lmpf`. These stratify by either snapshots or groups. This is helpful for some models (such as the missingness module). The ability to choose which function is used has been exposed to the user in `enw_fit_opts()` via the `likelihood_aggregation` argument. Both of these functions rely on a newly added `expected_obs_from_snaps` function which vectorises `expected_obs_from_index`. See #138 by @seabbs and @adrian-lison.
- Added support for supplying missingness model parameters to the model as well as optional priors and effect estimation. See #138 by @seabbs and @adrian-lison.
- Refactored model generated quantities to be functional. See #138 by @seabbs and @adrian-lison.
- Added support for modelling missing reference dates to the likelihood. See #147 by @seabbs and @adrian-lison.
- Added additional functionality to `delay_group_lmpf` to support modelling observations missing reference dates. Also updated the generated quantities to support this mode. See #147 by @seabbs and @adrian-lison based on #64 by @adrian-lison.
- Added a flexible expectation process on the growth rate scale. The default expectation model has been updated to a group-wise random walk on the growth rate. See #152 by @seabbs and @adrian-lison.
- Added a deterministic renewal equation, and latent reporting process. See #152 and #183 by @seabbs and @adrian-lison.
- Added support for no intercept in the expectation model and more general formula support to enable this as a feature in other modules going forward. See #170 by @seabbs.

## Documentation

- Removed explicit links to authors and issues in the `NEWS.md` file. See #132 by @choi-hannah.
- Added a new example using simulated data and the `enw_missing()` model module. See #138 by @seabbs and @adrian-lison.
- Update the model definition vignette to include the missing reference date model. See #147 by @seabbs and @adrian-lison.
- Added the use of an expectation model to the "Hierarchical nowcasting of age stratified COVID-19 hospitalisations in Germany" vignette. See #193 by @seabbs.

## Bugs

- The probability-only model (i.e only a parametric distribution is used and hence the hazard scale is not needed) was not used due to a mistake specifying `ref_as_p` in the stan code. There was an additional issue in that the `enw_report()` module currently self-declares as on regardless of it is or not. This bug had no impact on results but would have increased runtimes for simple models. Both of these issues were fixed in #142 by @seabbs.
- The addition of meta features week and month did not properly sequentially number weeks and months when time series crossed year boundaries. This would impact models that included effects expecting those to in fact be sequentially numbered (e.g. random walks). Fixed in #151 by @pearsonca.
 - #151 also corrects a minor issue with `enw_example()` pointing at an old file name when `type="script"`. By @pearsonca.

# epinowcast 0.1.0

This is a major release focusing on improving the user experience, and preparing for future package extensions, with an increase in modularity, development of a flexible and full-featured formula interface, and hopefully future-proofing as far as possible. This prepares the ground for future model extensions which will allow a broad range of real-time infectious disease questions to be better answered. These extensions include:

* Modelling missing data (#43).
* Non-parametric modelling of delay and reference date logit hazard (#4).
* Flexible expectation modelling (#5).
* Forecasting beyond the horizon of the data (#3).
* Known reporting structures (#33).
* Renewal equation-based reproduction number estimation (potentially part of #5).
* Latent infections (i.e as implemented in other packages such as `EpiNow2`, `epidemia`, etc.).
* Convolution-based delay models (i.e hospitalisations and deaths) with partially reported data.
* Additional observation models.

If interested in contributing to these features, or other aspects of package development (for example improving post-processing, the coverage of documentation, or contributing case studies) please see our [contributing guide](https://package.epinowcast.org/dev/CONTRIBUTING.html) and/or just reach out. This is a community project that needs support from its users in order to provide improved tools for real-time infectious disease surveillance.

This release contains multiple breaking changes. If needing the old interface please install [`0.0.7` from GitHub](https://github.com/epinowcast/epinowcast/releases/tag/v0.0.7). For ease, we have stratified changes below into interface, package, documentation, and model changes. Note the package is still flagged as experimental but is in regular use by the authors.

@adrian-lison, @sbfnk, and @seabbs contributed to this release.

## Interface

* A fully featured and flexible formula interface has been added that allows the specification of fixed effects, `lme4` random effects, and random walks. See #27 by @seabbs.
* A major overhaul, as described in #57, to the interface of `epinowcast()` with a particular focus on improving the modularity of the model components (described as modules in the documentation). All of the package documentation and vignettes have been updated to reflect this new interface. See #112 by @seabbs.

## Package

* Renamed the package and updated the description to give more clarity about the problem space it focusses on. See #110 by @seabbs.
* A new helper function `enw_delay_metadata()` has been added. This produces metadata about the delay distribution vector that may be helpful in future modelling. This prepares the way for #4 where this `data.frame` will be combined with the reference metadata in order to build non-parametric hazard reference and delay-based models. In addition to adding this function, it has also been added to the output of `enw_preprocess_data()` in order to make the metadata readily available to end-users. See #80 by @seabbs.
* Two new helper functions `enw_filter_reference_dates()` and `enw_filter_report_dates()` have been added. These replace `enw_retrospective_data()` but allow users to similarly construct retrospective data. Splitting these functions out into components also allows for additional use cases that were not previously possible. Note that by definition it is assumed that a report date for a given reference date must be equal or greater (i.e a report cannot happen before the event being reported occurs). See #82 by @sbfnk and @seabbs.
* The internal grouping variables have been refactored to reduce the chance of clashes with columns in the data.frames supplied by the user. There will also be an error thrown in case of a variable clash, making preprocessing safer. See #102 by @adrian-lison and @seabbs, which solves #99.
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

* Array declarations in the stan model have been updated. To maintain compatibility with `expose_stan_fns()` (which itself depends on `rstan`), additional functionality has been added to parse stan code in this function. See #74, #85, and #93 by @sbfnk and @seabbs.
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
* Updated to use the `inv_sqrt` stan function (see #60 by @seabbs).
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
