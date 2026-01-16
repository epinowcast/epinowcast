# Add maximum observed delay

This function calculates and adds the maximum observed delay for each
group and reference date in the provided dataset. It first checks the
validity of the observation indicator and then computes the maximum
delay. If an observation indicator is provided, it further adjusts the
maximum observed delay for unobserved data to be negative 1 (indicating
no maximum observed).

## Usage

``` r
add_max_observed_delay(new_confirm, observation_indicator = NULL)
```

## Arguments

- new_confirm:

  A data.table containing the columns: "reference_date", "delay",
  ".group", "new_confirm", and "max_obs_delay". As produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md)
  in the `new_confirm` output with the addition of the "max_obs_delay"
  column as produced by `add_max_observed_delay()`.

- observation_indicator:

  A character string specifying the column name in `new_confirm` that
  indicates whether an observation is observed or not. This column
  should be a logical vector. If NULL (default), all observations are
  considered observed.

## Value

A data.table with the original columns of `new_confirm` and an
additional "max_obs_delay" column representing the maximum observed
delay for each group and reference date. If an observation indicator is
provided, unobserved data will have a "max_obs_delay" value of -1.

## See also

Helper functions for model modules
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)
