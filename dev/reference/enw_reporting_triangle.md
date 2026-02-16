# Construct the reporting triangle

Constructs the reporting triangle with each row representing a reference
date and columns being observations by report date

## Usage

``` r
enw_reporting_triangle(obs)
```

## Arguments

- obs:

  A `data.frame` as produced by
  [`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md).
  Must contain the following variables: `reference_date`, `.group`,
  `delay`.

## Value

A `data.frame` with each row being a reference date, and columns being
observations by reporting delay.

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
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
obs <- enw_example("preprocessed")$new_confirm
enw_reporting_triangle(obs)
#> Key: <.group, reference_date>
#>     .group reference_date     0     1     2     3     4     5     6     7     8
#>      <num>         <IDat> <int> <int> <int> <int> <int> <int> <int> <int> <int>
#>  1:      1     2021-07-14    22    12     4     5     0     1    10     2     5
#>  2:      1     2021-07-15    28    15     3     3     0     1     3     2     3
#>  3:      1     2021-07-16    19    13     0     0     0     4     2     2     2
#>  4:      1     2021-07-17    20     7     1     3    10     3     0     4     3
#>  5:      1     2021-07-18     9     6     6     0     4     5     4     0     1
#>  6:      1     2021-07-19     3    16     4     4     1     1     2     0     0
#>  7:      1     2021-07-20    36    19    10     4     2     3     0     3     2
#>  8:      1     2021-07-21    28    18     8     4     1     2     3     6     1
#>  9:      1     2021-07-22    34    19     2     1     5     2     4     3     7
#> 10:      1     2021-07-23    30    12     4     1    10     6     0     2     2
#> 11:      1     2021-07-24    31     8     4     9     8     2     5     2     1
#> 12:      1     2021-07-25     8     4    14     8     6     5     1     3     0
#> 13:      1     2021-07-26     9     6     2     3     0     0     0     0     1
#> 14:      1     2021-07-27    35    11     6     4     4     1     0     2     2
#> 15:      1     2021-07-28    51    28    25     3     5     2     3     5     5
#> 16:      1     2021-07-29    47    37     9     2     2     3     4     4     4
#> 17:      1     2021-07-30    36    20     2     4    11     8     8     3     5
#> 18:      1     2021-07-31    38    16     3    15    14     7     5     5     0
#> 19:      1     2021-08-01     7     5     5    11     7     5     1     3     1
#> 20:      1     2021-08-02    13    13     8     6     1     3     2     0     0
#> 21:      1     2021-08-03    51    43     6     4     4     3     1     6     4
#> 22:      1     2021-08-04    51    43    18     5     6     1     2     8     7
#> 23:      1     2021-08-05    45    21     6     2     2    11    17     5     7
#> 24:      1     2021-08-06    47    31     5     4    20     6     1     9     3
#> 25:      1     2021-08-07    40    15     6    23    14    13     8     9     0
#> 26:      1     2021-08-08    13    14    27    14     7     7     0     0     0
#> 27:      1     2021-08-09    14    23    11     3     1     1     0     0     0
#> 28:      1     2021-08-10    78    43    23    11     5     1     0     5     2
#> 29:      1     2021-08-11    80    53    17    15     7     3    14    12    13
#> 30:      1     2021-08-12    89    48    28     8     1    14    13    13    10
#> 31:      1     2021-08-13    86    44     9     3    27    13     7    11     4
#> 32:      1     2021-08-14    79    36     7    16    19    13     8     8     3
#> 33:      1     2021-08-15    22    24    35    18    10     4     7     5     0
#> 34:      1     2021-08-16    23    32    22    10     8     2     1     0     0
#> 35:      1     2021-08-17    96    85    30    18    10     3     0     0     0
#> 36:      1     2021-08-18    92    86    23    18     4     0     0     0     0
#> 37:      1     2021-08-19    84    87    27     4     0     0     0     0     0
#> 38:      1     2021-08-20    98    61    12     0     0     0     0     0     0
#> 39:      1     2021-08-21    69    43     0     0     0     0     0     0     0
#> 40:      1     2021-08-22    45     0     0     0     0     0     0     0     0
#>     .group reference_date     0     1     2     3     4     5     6     7     8
#>      <num>         <IDat> <int> <int> <int> <int> <int> <int> <int> <int> <int>
#>         9    10    11    12    13    14    15    16    17    18    19
#>     <int> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
#>  1:     3     0     1     0     3     1     0     1     0     0     0
#>  2:     2     1     0     2     3     0     3     0     0     0     0
#>  3:     1     1     1     0     1     0     0     1     0     0     0
#>  4:     3     2     0     1     2     0     1     2     1     0     0
#>  5:     4     0     0     1     1     1     2     0     0     0     2
#>  6:     0     0     1     1     1     1     0     0     0     1     0
#>  7:     3     0     2     1     1     2     2     0     0     1     0
#>  8:     5     2     2     3     0     2     0     1     0     0     0
#>  9:     3     1     0     4     3     3     1     2     0     0     1
#> 10:     1     2     1     4     0     2     3     0     0     4     0
#> 11:     1     2     4     1     3     1     0     1     2     2     2
#> 12:     4     1     2     4     2     0     1     2     2     2     0
#> 13:     2     4     1     0     0     0     0     0     0     0     0
#> 14:     2     2     0     0     1     4     1     0     0     0     0
#> 15:     7     1     0     0     4     5     5     1     1     0     0
#> 16:     3     0     2     0    10     4     3     0     0     0     0
#> 17:     2     0     2     4     4     0     2     2     0     0     1
#> 18:     0     5     0     5     1     6     0     0     3     1     0
#> 19:     6     3     3     4     1     1     7     2     3     2     0
#> 20:     2     0     2     0     5     3     0     0     0     0     1
#> 21:     5     5     4     0     4     5     0     2     2     0     0
#> 22:     7     6     1     0     4     3     1     3     0     0     0
#> 23:     4     1     0     5     3     0     2     2     0     0     0
#> 24:     1     0     2     1     5     2     0     0     0     0     0
#> 25:     1     3     3     2     0     1     1     0     0     0     0
#> 26:     7     1     4     2     1     0     0     0     0     0     0
#> 27:     1     0     2     2     0     0     0     0     0     0     0
#> 28:     2     1     4     0     0     0     0     0     0     0     0
#> 29:    13     6     0     0     0     0     0     0     0     0     0
#> 30:    12     1     0     0     0     0     0     0     0     0     0
#> 31:     0     0     0     0     0     0     0     0     0     0     0
#> 32:     0     0     0     0     0     0     0     0     0     0     0
#> 33:     0     0     0     0     0     0     0     0     0     0     0
#> 34:     0     0     0     0     0     0     0     0     0     0     0
#> 35:     0     0     0     0     0     0     0     0     0     0     0
#> 36:     0     0     0     0     0     0     0     0     0     0     0
#> 37:     0     0     0     0     0     0     0     0     0     0     0
#> 38:     0     0     0     0     0     0     0     0     0     0     0
#> 39:     0     0     0     0     0     0     0     0     0     0     0
#> 40:     0     0     0     0     0     0     0     0     0     0     0
#>         9    10    11    12    13    14    15    16    17    18    19
#>     <int> <int> <int> <int> <int> <int> <int> <int> <int> <int> <int>
```
