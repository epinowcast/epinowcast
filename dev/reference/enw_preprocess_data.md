# Preprocess observations

This function preprocesses raw observations under the assumption they
are reported as cumulative counts by a reference and report date and is
used to assign groups. It also constructs data objects used by
visualisation and modelling functions including the observed empirical
probability of a report on a given day, the cumulative probability of
report, the latest available observations, incidence of observations,
and metadata about the date of reference and report (used to construct
models). This function wraps other preprocessing functions that may be
instead used individually if required. Note that internally reports
beyond the user specified delay are dropped for modelling purposes with
the `cum_prop_reported` and `max_confirm` variables allowing the user to
check the impact this may have (if `cum_prop_reported` is significantly
below 1 a longer `max_delay` may be appropriate). Also note that if
missing reference or report dates are suspected to occur in your data
then these need to be completed with
[`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md).

## Usage

``` r
enw_preprocess_data(
  obs,
  by = NULL,
  max_delay,
  timestep = "day",
  set_negatives_to_zero = TRUE,
  ...,
  copy = TRUE
)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference_date` (index date of interest), `report_date` (report date
  for observations), `confirm` (cumulative observations by reference and
  report date).

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

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

- set_negatives_to_zero:

  Logical, defaults to TRUE. Should negative counts (for calculated
  incidence of observations) be set to zero? Currently downstream
  modelling does not support negative counts and so setting must be TRUE
  if intending to use
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md).

- ...:

  Other arguments to
  [`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
  e.g. `holidays`, which sets commonly used metadata (e.g. day of week,
  days since start of time series)

- copy:

  A logical; if `TRUE` (the default) creates a copy; otherwise, modifies
  `obs` in place.

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

## Details

If `max_delay` is numeric, it will be internally coerced to integer
using [`as.integer()`](https://rdrr.io/r/base/integer.html)).

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
[`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_obs_at_delay()`](https://package.epinowcast.org/dev/reference/enw_obs_at_delay.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
library(data.table)

# Filter example hospitalisation data to be national and over all ages
nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
nat_germany_hosp <- nat_germany_hosp[age_group == "00+"]

# Preprocess with default settings
pobs <- enw_preprocess_data(nat_germany_hosp)
#> Using the maximum observed delay of 82 days. You may want to specify a shorter
#> (or, in special cases, longer) maximum delay via the `max_delay` argument. See
#> help(enw_preprocess_data) (`?epinowcast::enw_preprocess_data()`) for details.
pobs
#>                      obs            new_confirm               latest
#>                   <list>                 <list>               <list>
#> 1: <data.table[12915x9]> <data.table[12915x11]> <data.table[198x10]>
#>    missing_reference   reporting_triangle       metareference
#>               <list>               <list>              <list>
#> 1: <data.table[0x6]> <data.table[198x84]> <data.table[198x9]>
#>              metareport          metadelay max_delay  time snapshots     by
#>                  <list>             <list>     <num> <int>     <int> <list>
#> 1: <data.table[279x12]> <data.table[82x5]>        82   198       198 [NULL]
#>    groups   max_date timestep
#>     <int>     <IDat>   <char>
#> 1:      1 2021-10-20      day
```
