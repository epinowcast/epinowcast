# Extract observation metadata

This function extracts metadata from the provided dataset to be used in
the observation model.

## Usage

``` r
extract_obs_metadata(new_confirm, observation_indicator = NULL)
```

## Arguments

- new_confirm:

  A data.table containing the columns: "reference_date", "delay",
  ".group", "new_confirm", and "max_obs_delay". As produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  in the `new_confirm` output with the addition of the "max_obs_delay"
  column as produced by
  [`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md).

- observation_indicator:

  A character string specifying the column name in `new_confirm` that
  indicates whether an observation is observed or not. This column
  should be a logical vector. If NULL (default), all observations are
  considered observed.

## Value

A list containing:

- `st`: time index of each snapshot (snapshot time).

- `ts`: snapshot index by time and group.

- `sl`: number of reported observations per snapshot (snapshot length).

- `csl`: cumulative version of sl.

- `lsl`: number of consecutive reported observations per snapshot
  accounting for missing data.

- `clsl`: cumulative version of lsl.

- `nsl`: number of observed observations per snapshot (snapshot length).

- `cnsl`: cumulative version of nsl.

- `sg`: group index of each snapshot (snapshot group).

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/dev/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/dev/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/dev/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/dev/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/dev/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/dev/reference/latest_obs_as_matrix.md)
