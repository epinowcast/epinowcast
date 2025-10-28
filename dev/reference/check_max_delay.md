# Check appropriateness of maximum delay

Check if maximum delay specified by the user is long enough and raise
potential warnings. This is achieved by computing the share of reference
dates where the cumulative case count is below some aspired coverage.

## Usage

``` r
check_max_delay(
  data,
  max_delay = data$max_delay,
  cum_coverage = 0.8,
  maxdelay_quantile_outlier = 0.97,
  warn = TRUE,
  warn_internal = FALSE
)
```

## Arguments

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- max_delay:

  The maximum delay to model in the delay distribution, specified in
  units of the timestep (e.g., if `timestep = "week"`, then
  `max_delay = 3` means 3 weeks). If not specified the maximum observed
  delay is assumed to be the true maximum delay in the model. Otherwise,
  an integer greater than or equal to 1 can be specified. Observations
  with delays larger than the maximum delay will be dropped. If the
  specified maximum delay is too short, nowcasts can be biased as
  important parts of the true delay distribution are cut off. At the
  same time, computational cost scales non-linearly with this setting,
  so you want the maximum delay to be as long as necessary, but not much
  longer.

  Steps to take to determine the maximum delay:

  - Consider what is realistic and relevant for your application.

  - Check the proportion of observations reported (`prop_reported`) by
    delay in the `new_confirm` output of `enw_preprocess_obs`.

  - Use `check_max_delay()` to check the coverage of a candidate
    `max_delay`.

  - If in doubt, check if increasing the maximum delay noticeably
    changes the delay distribution or nowcasts as estimated by
    `epinowcast`. If it does, your maximum delay may still be too short.

  Note that delays are zero indexed and so include the reference date
  and `max_delay - 1` other intervals (i.e. a `max_delay` of 1
  corresponds to no delay).

- cum_coverage:

  The aspired percentage of cases that the maximum delay should cover.
  Defaults to 0.8 (80%).

- maxdelay_quantile_outlier:

  Only reference dates sufficiently far in the past, determined based on
  the maximum observed delay, are included (see details). Instead of the
  overall maximum observed delay, a quantile of the maximum observed
  delay over all reference dates is used. This is more robust against
  outliers. Defaults to 0.97 (97%).

- warn:

  Should a warning be issued if the cumulative case count is below
  `cum_coverage` for the majority of reference dates?

- warn_internal:

  Should only be `TRUE` if this function is called internally by another
  `epinowcast` function. Then, warnings are adjusted to avoid confusing
  the user.

## Value

A `data.table` with the share of reference dates where the cumulative
case count is below `cum_coverage`, stratified by group.

## Details

When data is very sparse (e.g., predominantly zero counts), the function
may not be able to compute meaningful coverage statistics. In such
cases, a warning is issued and the function treats the data as having no
coverage issues. This typically occurs when groups have very few
non-zero observations or when the specified `max_delay` is too large
relative to available data.

The coverage is with respect to the maximum observed case count for the
corresponding reference date. As the maximum observed case count is
likely smaller than the true overall case count for not yet fully
observed reference dates (due to right truncation), only reference dates
that are more than the maximum observed delay ago are included. Still,
because we can only use the maximum observed delay, not the unknown true
maximum delay, the computed coverage values should be interpreted with
care, as they are only proxies for the true coverage.

## See also

Functions used for checking inputs
[`check_design_matrix_sparsity()`](https://package.epinowcast.org/dev/reference/check_design_matrix_sparsity.md),
[`check_group()`](https://package.epinowcast.org/dev/reference/check_group.md),
[`check_group_date_unique()`](https://package.epinowcast.org/dev/reference/check_group_date_unique.md),
[`check_module()`](https://package.epinowcast.org/dev/reference/check_module.md),
[`check_modules_compatible()`](https://package.epinowcast.org/dev/reference/check_modules_compatible.md),
[`check_numeric_timestep()`](https://package.epinowcast.org/dev/reference/check_numeric_timestep.md),
[`check_observation_indicator()`](https://package.epinowcast.org/dev/reference/check_observation_indicator.md),
[`check_quantiles()`](https://package.epinowcast.org/dev/reference/check_quantiles.md),
[`check_timestep()`](https://package.epinowcast.org/dev/reference/check_timestep.md),
[`check_timestep_by_date()`](https://package.epinowcast.org/dev/reference/check_timestep_by_date.md),
[`check_timestep_by_group()`](https://package.epinowcast.org/dev/reference/check_timestep_by_group.md)

## Examples

``` r
pobs <- enw_example(type = "preprocessed_observations")
check_max_delay(pobs, max_delay = 20, cum_coverage = 0.8)
#>    .group coverage below_coverage
#>    <char>    <num>          <num>
#> 1:      1      0.8              0
#> 2:    all      0.8              0
```
