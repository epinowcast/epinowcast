# Known per-reference-date totals for the delay-only model

Builds the `dlo_ltotal` data entry for the delay-only model. The known
totals are the latest available `confirm` per reference date and group,
supplied to Stan on the log scale as a `g` by `t` matrix (cmdstanr's
layout for `array[g] vector[t]`). The log total is only an offset on the
expected cells and cancels in the multinomial likelihood, so reference
dates with no observed cells (a non-positive or missing latest total,
e.g. the most recent dates under an observation indicator) are floored
to 1 (log 0); such dates contribute nothing to the likelihood.

## Usage

``` r
delay_only_ltotal(data, delay_only)
```

## Arguments

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

- delay_only:

  Logical; if `FALSE` an empty (`g` by `0`) matrix is returned so the
  model carries no delay-only totals.

## Value

A `g` by `t` matrix of log totals (or `g` by `0` when not in delay-only
mode).

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`delay_only_total()`](https://package.epinowcast.org/reference/delay_only_total.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)
