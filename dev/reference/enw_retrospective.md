# Convert preprocessed data to retrospective format

Takes output of
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
and returns a new preprocessed dataset with `max_delay = 1`, suitable
for retrospective Rt estimation without delay modelling. Observations
are taken at the specified delay (or the latest available) and treated
as final counts. In the returned data, `report_date` is set equal to
`reference_date` for all rows (i.e. all observations appear to be
reported on the same day they occurred).

## Usage

``` r
enw_retrospective(data, max_delay = NULL)
```

## Arguments

- data:

  Output of
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- max_delay:

  Integer delay at which to freeze observations. If `NULL` (default),
  the latest available observation for each reference date is used.

## Value

A preprocessed data object (as from
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md))
with `max_delay = 1`.

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
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
pobs <- enw_example("preprocessed")
enw_retrospective(pobs)
#> ── Preprocessed nowcast data ─────────────────────────────────────────────────── 
#> Groups: 1 | Timestep: day | Max delay: 1 
#> Observations: 40 timepoints x 40 snapshots 
#> Max date: 2021-08-22 
#> 
#> Datasets (access with `enw_get_data(x, "<name>")`): 
#>   obs                :      40 x 7 
#>   new_confirm        :      40 x 9 
#>   latest             :      40 x 8 
#>   missing_reference  :       0 x 4 
#>   reporting_triangle :      40 x 3 
#>   metareference      :      40 x 7 
#>   metareport         :      40 x 10 
#>   metadelay          :       1 x 5 
```
