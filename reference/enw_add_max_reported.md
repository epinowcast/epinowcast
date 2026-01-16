# Add the maximum number of reported cases for each `reference_date`

This is a helper function which adds the maximum (in the sense of latest
observed) number of reported cases for each reference_date and computes
the proportion of already reported cases for each combination of
reference_date and report_date.

## Usage

``` r
enw_add_max_reported(obs, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

A data.table with new columns `max_confirm` and `cum_prop_reported`.
`max_confirm` is the maximum number of cases reported for a certain
reference_date. `cum_prop_reported` is the proportion of cases for a
certain reference_date that are reported until a given report_day,
relative to all cases so far observed for this reference_date.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/reference/enw_add_delay.md),
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
obs <- data.frame(report_date = as.Date("2021-01-01") + 0:2)
obs$reference_date <- as.Date("2021-01-01")
obs$confirm <- 1:3
enw_add_max_reported(obs)
#>    reference_date report_date .group max_confirm confirm cum_prop_reported
#>            <IDat>      <IDat>  <num>       <int>   <int>             <num>
#> 1:     2021-01-01  2021-01-01      1           3       1         0.3333333
#> 2:     2021-01-01  2021-01-02      1           3       2         0.6666667
#> 3:     2021-01-01  2021-01-03      1           3       3         1.0000000
```
