# Complete missing reference and report dates

Ensures that all reference and report dates are present for all groups
based on the maximum and minimum dates found in the data. This function
may be of use to users when preprocessing their data. In general all
features that you may consider using as grouping variables or as
covariates need to be included in the `by` variable.

## Usage

``` r
enw_complete_dates(
  obs,
  by = NULL,
  max_delay,
  min_date = min(obs$reference_date, na.rm = TRUE),
  max_date = max(obs$report_date, na.rm = TRUE),
  timestep = "day",
  missing_reference = TRUE,
  completion_beyond_max_report = FALSE,
  flag_observation = FALSE
)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

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

  - Use
    [`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md)
    to check the coverage of a candidate `max_delay`.

  - If in doubt, check if increasing the maximum delay noticeably
    changes the delay distribution or nowcasts as estimated by
    `epinowcast`. If it does, your maximum delay may still be too short.

  Note that delays are zero indexed and so include the reference date
  and `max_delay - 1` other intervals (i.e. a `max_delay` of 1
  corresponds to no delay).

- min_date:

  The minimum date to include in the data. Defaults to the minimum
  reference date found in the data.

- max_date:

  The maximum date to include in the data. Defaults to the maximum
  report date found in the data.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

- missing_reference:

  Logical, should entries for cases with missing reference date be
  completed as well?, Default: TRUE

- completion_beyond_max_report:

  Logical, should entries be completed beyond the maximum date found in
  the data? Default: FALSE

- flag_observation:

  Logical, should observations that have been imputed as missing be
  flagged as not observed?. Makes use of
  [`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md)
  to add a `.observed` logical vector which indicates if observations
  have been imputed. This vector can then be passed to the
  `observation_indicator` argument of
  [`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md)
  to control if these observations are used in the likelihood. Default:
  FALSE

## Value

A `data.table` with completed entries for all combinations of reference
dates, groups and possible report dates.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md),
[`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md),
[`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md),
[`enw_filter_delay()`](https://package.epinowcast.org/dev/reference/enw_filter_delay.md),
[`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md),
[`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md),
[`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- data.frame(
  report_date = c("2021-10-01", "2021-10-03"), reference_date = "2021-10-01",
  confirm = 1
)
enw_complete_dates(obs)
#> Key: <reference_date, report_date>
#>    report_date reference_date confirm
#>         <IDat>         <IDat>   <num>
#> 1:  2021-10-01           <NA>       0
#> 2:  2021-10-02           <NA>       0
#> 3:  2021-10-03           <NA>       0
#> 4:  2021-10-01     2021-10-01       1
#> 5:  2021-10-02     2021-10-01       1
#> 6:  2021-10-03     2021-10-01       1
#> 7:  2021-10-02     2021-10-02       0
#> 8:  2021-10-03     2021-10-02       0
#> 9:  2021-10-03     2021-10-03       0

# Allow completion beyond the maximum date found in the data
enw_complete_dates(obs, completion_beyond_max_report = TRUE, max_delay = 10)
#> Key: <reference_date, report_date>
#>     report_date reference_date confirm
#>          <IDat>         <IDat>   <num>
#>  1:  2021-10-01           <NA>       0
#>  2:  2021-10-02           <NA>       0
#>  3:  2021-10-03           <NA>       0
#>  4:  2021-10-01     2021-10-01       1
#>  5:  2021-10-02     2021-10-01       1
#>  6:  2021-10-03     2021-10-01       1
#>  7:  2021-10-04     2021-10-01       1
#>  8:  2021-10-05     2021-10-01       1
#>  9:  2021-10-06     2021-10-01       1
#> 10:  2021-10-07     2021-10-01       1
#> 11:  2021-10-08     2021-10-01       1
#> 12:  2021-10-09     2021-10-01       1
#> 13:  2021-10-10     2021-10-01       1
#> 14:  2021-10-11     2021-10-01       1
#> 15:  2021-10-02     2021-10-02       0
#> 16:  2021-10-03     2021-10-02       0
#> 17:  2021-10-04     2021-10-02       0
#> 18:  2021-10-05     2021-10-02       0
#> 19:  2021-10-06     2021-10-02       0
#> 20:  2021-10-07     2021-10-02       0
#> 21:  2021-10-08     2021-10-02       0
#> 22:  2021-10-09     2021-10-02       0
#> 23:  2021-10-10     2021-10-02       0
#> 24:  2021-10-11     2021-10-02       0
#> 25:  2021-10-12     2021-10-02       0
#> 26:  2021-10-03     2021-10-03       0
#> 27:  2021-10-04     2021-10-03       0
#> 28:  2021-10-05     2021-10-03       0
#> 29:  2021-10-06     2021-10-03       0
#> 30:  2021-10-07     2021-10-03       0
#> 31:  2021-10-08     2021-10-03       0
#> 32:  2021-10-09     2021-10-03       0
#> 33:  2021-10-10     2021-10-03       0
#> 34:  2021-10-11     2021-10-03       0
#> 35:  2021-10-12     2021-10-03       0
#> 36:  2021-10-13     2021-10-03       0
#>     report_date reference_date confirm
#>          <IDat>         <IDat>   <num>
```
