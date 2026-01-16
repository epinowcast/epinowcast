# Extend a time series with additional dates

Extend a time series with additional dates. This is useful when
extending the report dates of a time series to include future dates for
nowcasting purposes or to include additional dates for backcasting when
using a renewal process as the expectation model.

## Usage

``` r
enw_extend_date(
  metaobs,
  days = 20,
  direction = c("end", "start"),
  timestep = "day"
)
```

## Arguments

- metaobs:

  A `data.frame` with a `date` column.

- days:

  Number of days to add to the time series. Defaults to 20.

- direction:

  Should new dates be added at the beginning or end of the data. Default
  is "end" with "start" also available.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

## Value

A data.table with the same columns as `metaobs` but with additional rows
for each date in the range of `date` to `date + days` (or `date - days`
if `direction = "start"`). An additional variable observed is added with
a value of FALSE for all new dates and TRUE for all existing dates.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/reference/enw_complete_dates.md),
[`enw_construct_data()`](https://package.epinowcast.org/reference/enw_construct_data.md),
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
metaobs <- data.frame(date = as.Date("2021-01-01") + 0:4)
enw_extend_date(metaobs, days = 2)
#> Key: <.group, date>
#>          date .group observed
#>        <Date>  <num>   <lgcl>
#> 1: 2021-01-01      1     TRUE
#> 2: 2021-01-02      1     TRUE
#> 3: 2021-01-03      1     TRUE
#> 4: 2021-01-04      1     TRUE
#> 5: 2021-01-05      1     TRUE
#> 6: 2021-01-06      1    FALSE
#> 7: 2021-01-07      1    FALSE
enw_extend_date(metaobs, days = 2, direction = "start")
#> Key: <.group, date>
#>          date .group observed
#>        <Date>  <num>   <lgcl>
#> 1: 2020-12-30      1    FALSE
#> 2: 2020-12-31      1    FALSE
#> 3: 2021-01-01      1     TRUE
#> 4: 2021-01-02      1     TRUE
#> 5: 2021-01-03      1     TRUE
#> 6: 2021-01-04      1     TRUE
#> 7: 2021-01-05      1     TRUE
```
