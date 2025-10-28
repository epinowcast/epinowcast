# Create structural reporting metadata grid

Creates a base metadata grid for structural reporting patterns by
generating all combinations of reference dates, delays, and report
dates. This grid serves as the foundation for defining custom reporting
patterns.

## Usage

``` r
enw_structural_reporting_metadata(pobs)
```

## Arguments

- pobs:

  A preprocessed observation list from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

## Value

A `data.table` with columns:

- `.group`: Group identifier

- `date`: Reference date

- `report_date`: Report date (reference date + delay)

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/dev/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/dev/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/dev/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/dev/reference/enw_reps_with_complete_refs.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/dev/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/dev/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/dev/reference/latest_obs_as_matrix.md)

## Examples

``` r
if (FALSE) { # \dontrun{
pobs <- enw_preprocess_data(obs, max_delay = 30)
metadata <- enw_structural_reporting_metadata(pobs)

# Add custom reporting pattern (e.g., only report on first day of month)
metadata[, report := as.integer(format(report_date, "%d") == "01")]
} # }
```
