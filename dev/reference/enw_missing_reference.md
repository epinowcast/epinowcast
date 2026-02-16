# Extract reports with missing reference dates

Returns reports with missing reference dates as well as calculating the
proportion of reports for a given reference date that were missing.

## Usage

``` r
enw_missing_reference(obs)
```

## Arguments

- obs:

  A `data.frame` as produced by
  [`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md).
  Must contain the following variables: `report_date`, `reference_date`,
  `.group`, and `confirm`, and `new_confirm`.

## Value

A `data.table` of missing counts and proportions by report date and
group.

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
[`enw_obs_at_delay()`](https://package.epinowcast.org/dev/reference/enw_obs_at_delay.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- data.frame(
  report_date = c("2021-10-01", "2021-10-03"), reference_date = "2021-10-01",
  confirm = 1
)
obs <- rbind(
  obs,
  data.frame(report_date = "2021-10-04", reference_date = NA, confirm = 4)
)
obs <- enw_complete_dates(obs)
obs <- enw_assign_group(obs)
obs <- enw_add_incidence(obs)
enw_missing_reference(obs)
#> Key: <.group, report_date>
#>    report_date .group confirm prop_missing
#>         <IDat>  <num>   <num>        <num>
#> 1:  2021-10-01      1       0            0
#> 2:  2021-10-02      1       0          NaN
#> 3:  2021-10-03      1       0          NaN
#> 4:  2021-10-04      1       4            1
```
