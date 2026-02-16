# Extract latest observations at a given maximum delay

Filter observations to a maximum delay and then extract the latest
observations. This is useful for model evaluation where you want to
assess performance against the data as the model would have seen it.

## Usage

``` r
enw_obs_at_delay(obs, max_delay, timestep = "day")
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

A `data.table` of observations filtered for the latest available data
for each reference date at the specified maximum delay.

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
obs <- enw_example("preprocessed")$obs[[1]]
enw_obs_at_delay(obs, max_delay = 2)
#>     reference_date .group report_date max_confirm location age_group confirm
#>             <IDat>  <num>      <IDat>       <int>   <fctr>    <fctr>   <int>
#>  1:     2021-07-14      1  2021-07-15          72       DE       00+      34
#>  2:     2021-07-15      1  2021-07-16          69       DE       00+      43
#>  3:     2021-07-16      1  2021-07-17          47       DE       00+      32
#>  4:     2021-07-17      1  2021-07-18          65       DE       00+      27
#>  5:     2021-07-18      1  2021-07-19          50       DE       00+      15
#>  6:     2021-07-19      1  2021-07-20          36       DE       00+      19
#>  7:     2021-07-20      1  2021-07-21          94       DE       00+      55
#>  8:     2021-07-21      1  2021-07-22          91       DE       00+      46
#>  9:     2021-07-22      1  2021-07-23          99       DE       00+      53
#> 10:     2021-07-23      1  2021-07-24          86       DE       00+      42
#> 11:     2021-07-24      1  2021-07-25          93       DE       00+      39
#> 12:     2021-07-25      1  2021-07-26          74       DE       00+      12
#> 13:     2021-07-26      1  2021-07-27          28       DE       00+      15
#> 14:     2021-07-27      1  2021-07-28          78       DE       00+      46
#> 15:     2021-07-28      1  2021-07-29         156       DE       00+      79
#> 16:     2021-07-29      1  2021-07-30         135       DE       00+      84
#> 17:     2021-07-30      1  2021-07-31         114       DE       00+      56
#> 18:     2021-07-31      1  2021-08-01         126       DE       00+      54
#> 19:     2021-08-01      1  2021-08-02          77       DE       00+      12
#> 20:     2021-08-02      1  2021-08-03          59       DE       00+      26
#> 21:     2021-08-03      1  2021-08-04         149       DE       00+      94
#> 22:     2021-08-04      1  2021-08-05         166       DE       00+      94
#> 23:     2021-08-05      1  2021-08-06         133       DE       00+      66
#> 24:     2021-08-06      1  2021-08-07         137       DE       00+      78
#> 25:     2021-08-07      1  2021-08-08         139       DE       00+      55
#> 26:     2021-08-08      1  2021-08-09          97       DE       00+      27
#> 27:     2021-08-09      1  2021-08-10          58       DE       00+      37
#> 28:     2021-08-10      1  2021-08-11         175       DE       00+     121
#> 29:     2021-08-11      1  2021-08-12         233       DE       00+     133
#> 30:     2021-08-12      1  2021-08-13         237       DE       00+     137
#> 31:     2021-08-13      1  2021-08-14         204       DE       00+     130
#> 32:     2021-08-14      1  2021-08-15         189       DE       00+     115
#> 33:     2021-08-15      1  2021-08-16         125       DE       00+      46
#> 34:     2021-08-16      1  2021-08-17          98       DE       00+      55
#> 35:     2021-08-17      1  2021-08-18         242       DE       00+     181
#> 36:     2021-08-18      1  2021-08-19         223       DE       00+     178
#> 37:     2021-08-19      1  2021-08-20         202       DE       00+     171
#> 38:     2021-08-20      1  2021-08-21         171       DE       00+     159
#> 39:     2021-08-21      1  2021-08-22         112       DE       00+     112
#> 40:     2021-08-22      1  2021-08-22          45       DE       00+      45
#>     reference_date .group report_date max_confirm location age_group confirm
#>             <IDat>  <num>      <IDat>       <int>   <fctr>    <fctr>   <int>
#>     cum_prop_reported delay
#>                 <num> <num>
#>  1:         0.4722222     1
#>  2:         0.6231884     1
#>  3:         0.6808511     1
#>  4:         0.4153846     1
#>  5:         0.3000000     1
#>  6:         0.5277778     1
#>  7:         0.5851064     1
#>  8:         0.5054945     1
#>  9:         0.5353535     1
#> 10:         0.4883721     1
#> 11:         0.4193548     1
#> 12:         0.1621622     1
#> 13:         0.5357143     1
#> 14:         0.5897436     1
#> 15:         0.5064103     1
#> 16:         0.6222222     1
#> 17:         0.4912281     1
#> 18:         0.4285714     1
#> 19:         0.1558442     1
#> 20:         0.4406780     1
#> 21:         0.6308725     1
#> 22:         0.5662651     1
#> 23:         0.4962406     1
#> 24:         0.5693431     1
#> 25:         0.3956835     1
#> 26:         0.2783505     1
#> 27:         0.6379310     1
#> 28:         0.6914286     1
#> 29:         0.5708155     1
#> 30:         0.5780591     1
#> 31:         0.6372549     1
#> 32:         0.6084656     1
#> 33:         0.3680000     1
#> 34:         0.5612245     1
#> 35:         0.7479339     1
#> 36:         0.7982063     1
#> 37:         0.8465347     1
#> 38:         0.9298246     1
#> 39:         1.0000000     1
#> 40:         1.0000000     0
#>     cum_prop_reported delay
#>                 <num> <num>
```
