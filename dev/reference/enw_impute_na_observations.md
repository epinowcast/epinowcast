# Impute NA observations

Imputes NA values in the 'confirm' column. NA values are replaced with
the last available observation or 0.

## Usage

``` r
enw_impute_na_observations(obs, by = NULL, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` with at least 'confirm' and 'reference_date' columns.

- by:

  A character vector of column names to group by. Defaults to an empty
  vector.

- copy:

  A logical; if `TRUE` (the default) creates a copy; otherwise, modifies
  `obs` in place.

## Value

A `data.table` with imputed 'confirm' column where NA values have been
replaced with zero.

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
[`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
dt <- data.frame(
  id = 1:3, confirm = c(NA, 1, 2),
  reference_date = as.Date("2021-01-01")
)
enw_impute_na_observations(dt)
#> Key: <reference_date>
#>       id confirm reference_date
#>    <int>   <num>         <Date>
#> 1:     1       0     2021-01-01
#> 2:     2       1     2021-01-01
#> 3:     3       2     2021-01-01
```
