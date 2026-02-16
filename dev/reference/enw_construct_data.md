# Construct preprocessed data

This function is used internally by
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
to combine various pieces of processed observed data into a single
object. It is exposed to the user in order to allow for modular data
preprocessing though this is not currently recommended. See
documentation and code of
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
for more on the expected inputs.

## Usage

``` r
enw_construct_data(
  obs,
  new_confirm,
  latest,
  missing_reference,
  reporting_triangle,
  metareport,
  metareference,
  metadelay,
  max_delay,
  timestep,
  by
)
```

## Arguments

- obs:

  Observations with the addition of empirical reporting proportions and
  and restricted to the specified maximum delay.

- new_confirm:

  Incidence of notifications by reference and report date. Empirical
  reporting distributions are also added.

- latest:

  The latest available observations.

- missing_reference:

  A `data.frame` of reported observations that are missing the reference
  date.

- reporting_triangle:

  Incident observations by report and reference date in the standard
  reporting triangle matrix format.

- metareport:

  Metadata for report dates.

- metareference:

  Metadata reference dates derived from observations.

- metadelay:

  Metadata for reporting delays produced using
  [`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md).

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

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

## Value

A data.table containing processed observations as a series of nested
data.frames as well as variables containing metadata. These are:

- `obs`: (observations with the addition of empirical reporting
  proportions and restricted to the specified maximum delay).

- `new_confirm`: Incidence of notifications by reference and report
  date. Empirical reporting distributions are also added.

- `latest`: The latest available observations.

- `missing_reference`: Observations missing reference dates.

- `reporting_triangle`: Incident observations by report and reference
  date in the standard reporting triangle matrix format.

- `metareference`: Metadata reference dates derived from observations.

- `metrareport`: Metadata for report dates.

- `metadelay`: Metadata for reporting delays produced using
  [`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md).

- `max_delay`: Maximum delay to be modelled by epinowcast.

- `time`: Numeric, number of timepoints in the data.

- `snapshots`: Numeric, number of available data snapshots to use for
  nowcasting.

- `groups`: Numeric, Number of groups/strata in the supplied
  observations (set using `by`).

- `max_date`: The maximum available report date.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md),
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
pobs <- enw_example("preprocessed")
enw_construct_data(
  obs = pobs$obs[[1]],
  new_confirm = pobs$new_confirm[[1]],
  latest = pobs$latest[[1]],
  missing_reference = pobs$missing_reference[[1]],
  reporting_triangle = pobs$reporting_triangle[[1]],
  metareport = pobs$metareport[[1]],
  metareference = pobs$metareference[[1]],
  metadelay = pobs$metadelay[[1]],
  max_delay = pobs$max_delay,
  timestep = pobs$timestep[[1]],
  by = c()
)
#>                    obs          new_confirm              latest
#>                 <list>               <list>              <list>
#> 1: <data.table[650x9]> <data.table[610x11]> <data.table[40x10]>
#>     missing_reference  reporting_triangle      metareference
#>                <list>              <list>             <list>
#> 1: <data.table[40x6]> <data.table[40x22]> <data.table[40x9]>
#>             metareport          metadelay max_delay  time snapshots     by
#>                 <list>             <list>     <num> <int>     <int> <list>
#> 1: <data.table[59x12]> <data.table[20x5]>        20    40        40 [NULL]
#>    groups   max_date timestep
#>     <int>     <IDat>   <char>
#> 1:      1 2021-08-22      day
```
