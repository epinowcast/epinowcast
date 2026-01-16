# Add a delay variable to the observations

This helper function takes a `data.frame` or `data.table` of
observations and adds the delay (numeric, in days) between
`reference_date` and `report_date` for each observation.

## Usage

``` r
enw_add_delay(obs, timestep = "day", copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

A `data.table` of observations with a new column `delay`.

## See also

Preprocessing functions
[`enw_add_max_reported()`](https://package.epinowcast.org/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/reference/enw_complete_dates.md),
[`enw_construct_data()`](https://package.epinowcast.org/reference/enw_construct_data.md),
[`enw_extend_date()`](https://package.epinowcast.org/reference/enw_extend_date.md),
[`enw_filter_delay()`](https://package.epinowcast.org/reference/enw_filter_delay.md),
[`enw_filter_reference_dates()`](https://package.epinowcast.org/reference/enw_filter_reference_dates.md),
[`enw_filter_report_dates()`](https://package.epinowcast.org/reference/enw_filter_report_dates.md),
[`enw_flag_observed_observations()`](https://package.epinowcast.org/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- data.frame(report_date = as.Date("2021-01-01") + -2:0)
obs$reference_date <- as.Date("2021-01-01")
enw_add_delay(obs)
#>    report_date reference_date delay
#>         <IDat>         <IDat> <num>
#> 1:  2020-12-30     2021-01-01    -2
#> 2:  2020-12-31     2021-01-01    -1
#> 3:  2021-01-01     2021-01-01     0
```
