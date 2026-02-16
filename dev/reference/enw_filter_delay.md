# Filter observations to have a consistent maximum delay period

Filter observations to have a consistent maximum delay period

## Usage

``` r
enw_filter_delay(obs, max_delay, timestep = "day")
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- max_delay:

  The maximum delay to model in the delay distribution, specified in
  units of the timestep (e.g., if `timestep = "week"`, then
  `max_delay = 3` means 3 weeks). If not specified the maximum observed
  delay is assumed to be the true maximum delay in the model. Otherwise,
  an integer greater than or equal to 1 can be specified. Observations
  with delays larger than the maximum delay will be dropped. If the
  specified maximum delay is too short, nowcasts can be biased as
  important parts of the true delay distribution are cut off. At the
  same time, computational cost scales non-linearly with this setting,
  so you want the maximum delay to be as long as necessary, but not much
  longer.

  Steps to take to determine the maximum delay:

  - Consider what is realistic and relevant for your application.

  - Check the proportion of observations reported (`prop_reported`) by
    delay in the `new_confirm` output of `enw_preprocess_obs`.

  - Use
    [`check_max_delay()`](https://package.epinowcast.org/dev/reference/check_max_delay.md)
    to check the coverage of a candidate `max_delay`.

  - If in doubt, check if increasing the maximum delay noticeably
    changes the delay distribution or nowcasts as estimated by
    `epinowcast`. If it does, your maximum delay may still be too short.

  Note that delays are zero indexed and so include the reference date
  and `max_delay - 1` other intervals (i.e. a `max_delay` of 1
  corresponds to no delay).

- timestep:

  The timestep to used in the process model (i.e. the reference date
  model). This can be a string ("day", "week", "month") or a numeric
  whole number representing the number of days. If your data does not
  have this timestep then you may wish to make use of
  [`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md)
  to aggregate your data to the desired timestep.

## Value

A `data.frame` filtered so that dates by report are less than or equal
the reference date plus the maximum delay.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md),
[`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md),
[`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md),
[`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md),
[`enw_filter_reference_dates_by_report_start()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates_by_report_start.md),
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
obs <- enw_example("preprocessed")$obs[[1]]
enw_filter_delay(obs, max_delay = 2)
#>      reference_date .group report_date max_confirm location age_group confirm
#>              <IDat>  <num>      <IDat>       <int>   <fctr>    <fctr>   <int>
#>   1:           <NA>      1  2021-07-14           0       DE       00+       0
#>   2:           <NA>      1  2021-07-15           0       DE       00+       0
#>   3:           <NA>      1  2021-07-16           0       DE       00+       0
#>   4:           <NA>      1  2021-07-17           0       DE       00+       0
#>   5:           <NA>      1  2021-07-18           0       DE       00+       0
#>  ---                                                                         
#> 115:     2021-08-20      1  2021-08-20         171       DE       00+      98
#> 116:     2021-08-20      1  2021-08-21         171       DE       00+     159
#> 117:     2021-08-21      1  2021-08-21         112       DE       00+      69
#> 118:     2021-08-21      1  2021-08-22         112       DE       00+     112
#> 119:     2021-08-22      1  2021-08-22          45       DE       00+      45
#>      cum_prop_reported delay
#>                  <num> <num>
#>   1:               NaN    NA
#>   2:               NaN    NA
#>   3:               NaN    NA
#>   4:               NaN    NA
#>   5:               NaN    NA
#>  ---                        
#> 115:         0.5730994     0
#> 116:         0.9298246     1
#> 117:         0.6160714     0
#> 118:         1.0000000     1
#> 119:         1.0000000     0
```
