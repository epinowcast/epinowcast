# Assign a group to each row of a data.table

Assign a group to each row of a data.table. If `by` is specified, then
each unique combination of the columns in `by` will be assigned a unique
group. If `by` is not specified, then all rows will be assigned to the
same group.

## Usage

``` r
enw_assign_group(obs, by = NULL, copy = TRUE)
```

## Arguments

- obs:

  A `data.table` or `data.frame` without a `.group` column.

- by:

  A character vector of column names to group by. Defaults to an empty
  vector.

- copy:

  A logical; make a copy (default) of `obs` or modify it in place?

## Value

A `data.table` with a `.group` column added ordered by `.group` and the
existing key of `obs`.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
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
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- data.frame(x = 1:3, y = 1:3)
enw_assign_group(obs)
#> Key: <.group>
#>        x     y .group
#>    <int> <int>  <num>
#> 1:     1     1      1
#> 2:     2     2      1
#> 3:     3     3      1
enw_assign_group(obs, by = "x")
#> Key: <.group>
#>        x     y .group
#>    <int> <int>  <int>
#> 1:     1     1      1
#> 2:     2     2      2
#> 3:     3     3      3
```
