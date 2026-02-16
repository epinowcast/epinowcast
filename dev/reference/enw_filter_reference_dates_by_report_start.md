# Filter reference dates that precede the earliest report date

Removes observations where the `reference_date` is earlier than the
minimum `report_date` within each group. Rows with missing
`reference_date` are retained. This is useful for ensuring that
observations are only included from the first available report date
onwards.

This function is typically called before
[`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md)
so that the incidence calculation starts from a valid reporting window.
Without this step, reference dates that predate any report date produce
spurious leading entries in the incidence output.

## Usage

``` r
enw_filter_reference_dates_by_report_start(obs, by = NULL, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` with `reference_date` and `report_date` columns.

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

A `data.table` filtered so that each `reference_date` is on or after the
minimum `report_date` in its group. Rows with `NA` `reference_date` are
kept.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md),
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
library(data.table)
obs <- data.table(
  reference_date = as.IDate(c(
    "2021-10-01", "2021-10-02", "2021-10-03"
  )),
  report_date = as.IDate(c(
    "2021-10-02", "2021-10-02", "2021-10-03"
  ))
)
# The first row has reference_date before the minimum
# report_date, so it is removed
enw_filter_reference_dates_by_report_start(obs)
#>    reference_date report_date
#>            <IDat>      <IDat>
#> 1:     2021-10-02  2021-10-02
#> 2:     2021-10-03  2021-10-03
```
