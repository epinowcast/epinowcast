# Construct a lookup of references dates by report

Construct a lookup of references dates by report

## Usage

``` r
enw_reference_by_report(
  missing_reference,
  reps_with_complete_refs,
  metareference,
  max_delay
)
```

## Arguments

- missing_reference:

  `missing_reference` `data.frame` output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

- reps_with_complete_refs:

  A `data.frame` of report dates with complete (i.e fully reported)
  reference dates as produced using
  [`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md).

- metareference:

  `metareference` `data.frame` output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

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
    [`check_max_delay()`](https://package.epinowcast.org/reference/check_max_delay.md)
    to check the coverage of a candidate `max_delay`.

  - If in doubt, check if increasing the maximum delay noticeably
    changes the delay distribution or nowcasts as estimated by
    `epinowcast`. If it does, your maximum delay may still be too short.

  Note that delays are zero indexed and so include the reference date
  and `max_delay - 1` other intervals (i.e. a `max_delay` of 1
  corresponds to no delay).

## Value

A wide `data.frame` with each row being a complete report date and' the
columns being the observation index for each reporting delay

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)
