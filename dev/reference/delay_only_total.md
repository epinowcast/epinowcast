# Known integer totals per snapshot for the delay-only model

Builds the `dlo_total` data entry: the known integer total per snapshot
(the latest cumulative `confirm`, i.e. the cutoff running total),
ordered by group then reference date to match the snapshot order. These
totals size the residual category when an observation indicator leaves
some before-cutoff cells unobserved.

## Usage

``` r
delay_only_total(data, delay_only)
```

## Arguments

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- delay_only:

  Logical; if `FALSE` an empty (`g` by `0`) matrix is returned so the
  model carries no delay-only totals.

## Value

An integer vector of length `snapshots` (or length 0 when not in
delay-only mode).

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/dev/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/dev/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/dev/reference/convolution_matrix.md),
[`delay_only_ltotal()`](https://package.epinowcast.org/dev/reference/delay_only_ltotal.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/dev/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/dev/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/dev/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/dev/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/dev/reference/latest_obs_as_matrix.md)
