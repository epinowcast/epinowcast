# Convert latest observed data to a matrix

Convert latest observed data to a matrix

## Usage

``` r
latest_obs_as_matrix(latest)
```

## Arguments

- latest:

  `latest` `data.frame` output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

## Value

A matrix with each column being a group and each row a reference date

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md)
