# Calculate reporting delay metadata for a given maximum delay

Calculate delay metadata based on the supplied maximum delay and
independent of other metadata or date indexing. These data are meant to
be used in conjunction with metadata on the date of reference. Users can
build additional features with this `data.frame` or regenerate it using
this function in the output of
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

## Usage

``` r
enw_metadata_delay(max_delay = 20, breaks = 4, timestep = "day")
```

## Arguments

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

- breaks:

  Numeric, defaults to 4. The number of breaks to use when constructing
  a categorised version of numeric delays.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

## Value

A `data.frame` of delay metadata. This includes:

- `delay`: The numeric delay from reference date to report.

- `delay_cat`: The categorised delay. This may be useful for model
  building.

- `delay_week`: The numeric week since the delay was reported. This
  again may be useful for model building.

- `delay_head`: A logical variable defining if the delay is in the lower
  25% of the potential delays. This may be particularly useful when
  building models that assume a parametric distribution in order to
  increase the weight of the head of the reporting distribution in a
  pragmatic way.

- `delay_tail`: A logical variable defining if the delay is in the upper
  75% of the potential delays. This may be particularly useful when
  building models that assume a parametric distribution in order to
  increase the weight of the tail of the reporting distribution in a
  pragmatic way.

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
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
enw_metadata_delay(max_delay = 20, breaks = 4)
#>     delay delay_cat delay_week delay_head delay_tail
#>     <int>    <fctr>      <int>     <lgcl>     <lgcl>
#>  1:     0     [0,5)          0       TRUE      FALSE
#>  2:     1     [0,5)          0       TRUE      FALSE
#>  3:     2     [0,5)          0       TRUE      FALSE
#>  4:     3     [0,5)          0       TRUE      FALSE
#>  5:     4     [0,5)          0       TRUE      FALSE
#>  6:     5    [5,10)          0      FALSE      FALSE
#>  7:     6    [5,10)          0      FALSE      FALSE
#>  8:     7    [5,10)          1      FALSE      FALSE
#>  9:     8    [5,10)          1      FALSE      FALSE
#> 10:     9    [5,10)          1      FALSE      FALSE
#> 11:    10   [10,15)          1      FALSE      FALSE
#> 12:    11   [10,15)          1      FALSE      FALSE
#> 13:    12   [10,15)          1      FALSE      FALSE
#> 14:    13   [10,15)          1      FALSE      FALSE
#> 15:    14   [10,15)          2      FALSE      FALSE
#> 16:    15   [15,20)          2      FALSE       TRUE
#> 17:    16   [15,20)          2      FALSE       TRUE
#> 18:    17   [15,20)          2      FALSE       TRUE
#> 19:    18   [15,20)          2      FALSE       TRUE
#> 20:    19   [15,20)          2      FALSE       TRUE
#>     delay delay_cat delay_week delay_head delay_tail
```
