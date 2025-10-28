# Create day-of-week structural reporting pattern

Creates a structural reporting pattern for cases where reporting only
occurs on specific days of the week (e.g., Wednesday-only reporting).
This is a convenience function that builds on
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md).

## Usage

``` r
enw_dayofweek_structural_reporting(pobs, day_of_week)
```

## Arguments

- pobs:

  A preprocessed observation list from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- day_of_week:

  Character vector of weekday names when reporting occurs (e.g.,
  `"Wednesday"` or `c("Monday", "Wednesday")`).

## Value

A `data.table` with columns:

- `.group`: Group identifier

- `date`: Reference date

- `report_date`: Report date

- `report`: Binary indicator (1 = reporting occurs, 0 = no reporting)

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/dev/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/dev/reference/convolution_matrix.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/dev/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/dev/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/dev/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/dev/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/dev/reference/latest_obs_as_matrix.md)

## Examples

``` r
if (FALSE) { # \dontrun{
pobs <- enw_preprocess_data(obs, max_delay = 30)

# Wednesday-only reporting
enw_dayofweek_structural_reporting(
  pobs, day_of_week = "Wednesday"
)

# Multiple reporting days
enw_dayofweek_structural_reporting(
  pobs, day_of_week = c("Monday", "Wednesday", "Friday")
)
} # }
```
