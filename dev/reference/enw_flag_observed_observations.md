# Flag observed observations

Flags observations based on the 'confirm' column. If the '.observed'
column does not exist, it is created. Observations are flagged as
observed (`TRUE`) if 'confirm' is not NA.

## Usage

``` r
enw_flag_observed_observations(obs, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` with at least a have `confirm` column.

- copy:

  A logical; if `TRUE` (the default) creates a copy; otherwise, modifies
  `obs` in place.

## Value

A `data.table` with an additional column '.observed' indicating observed
observations.

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
[`enw_filter_reference_dates_by_report_start()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates_by_report_start.md),
[`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_obs_at_delay()`](https://package.epinowcast.org/dev/reference/enw_obs_at_delay.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
dt <- data.frame(id = 1:3, confirm = c(NA, 1, 2))
enw_flag_observed_observations(dt)
#>       id confirm .observed
#>    <int>   <num>    <lgcl>
#> 1:     1      NA     FALSE
#> 2:     2       1      TRUE
#> 3:     3       2      TRUE
```
