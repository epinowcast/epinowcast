# Recast the reporting triangle from wide to long format

Recast the reporting triangle from wide to long format

## Usage

``` r
enw_reporting_triangle_to_long(obs)
```

## Arguments

- obs:

  A `data.frame` in the format produced by
  [`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md).

## Value

A long format reporting triangle as a `data.frame` with additional
variables `new_confirm` and `delay`.

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
[`enw_obs_at_delay()`](https://package.epinowcast.org/dev/reference/enw_obs_at_delay.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md)

## Examples

``` r
obs <- enw_example("preprocessed")$new_confirm
rt <- enw_reporting_triangle(obs)
enw_reporting_triangle_to_long(rt)
#> Key: <.group, reference_date, delay>
#>      reference_date .group  delay new_confirm
#>              <IDat>  <num> <fctr>       <int>
#>   1:     2021-07-14      1      0          22
#>   2:     2021-07-14      1      1          12
#>   3:     2021-07-14      1      2           4
#>   4:     2021-07-14      1      3           5
#>   5:     2021-07-14      1      4           0
#>  ---                                         
#> 796:     2021-08-22      1     15           0
#> 797:     2021-08-22      1     16           0
#> 798:     2021-08-22      1     17           0
#> 799:     2021-08-22      1     18           0
#> 800:     2021-08-22      1     19           0
```
