# Extract metadata from raw data

Extract metadata from raw data, either by reference or by report date.
For the target date chosen (reference or report), `confirm`,
``` max_confirm``, and  ```cum_prop_reported\` are dropped and the first
observation for each group and date is retained.

## Usage

``` r
enw_metadata(obs, target_date = c("reference_date", "report_date"))
```

## Arguments

- obs:

  A `data.frame` or `data.table` with columns: `reference_date` and / or
  `report_date`; at least one must be provided, `.group`, a grouping
  column and a `date`, a [Date](https://rdrr.io/r/base/Dates.html)
  column.

- target_date:

  A character string, either "reference_date" or "report_date". The
  column corresponding to this string will be used as the target date
  for metadata extraction.

## Value

A data.table with columns:

- `date`, a [Date](https://rdrr.io/r/base/Dates.html) column

- `.group`, a grouping column

and the first observation for each group and date. The data.table is
sorted by `.group` and `date`.

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
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- data.frame(
  reference_date = as.Date("2021-01-01"),
  report_date = as.Date("2022-01-01"), x = 1:10
)
enw_metadata(obs, target_date = "reference_date")
#> Key: <.group, date>
#>          date .group     x
#>        <Date>  <num> <int>
#> 1: 2021-01-01      1     1
```
