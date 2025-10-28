# Precompute aggregation index lookups for Stan

Takes a nested list structure of aggregation indicator matrices and
precomputes sparse index lookups for efficient Stan operations.

## Usage

``` r
.precompute_aggregation_lookups(structural, n_groups, n_times, max_delay)
```

## Arguments

- structural:

  A nested list structure: list(groups) of list(times) of matrices
  (max_delay x max_delay). Each matrix contains 0s and 1s indicating
  which delays aggregate to which reporting delays.

- n_groups:

  Integer number of groups.

- n_times:

  Integer number of time points.

- max_delay:

  Integer maximum delay.

## Value

A list with two components:

- `n_selected`: 3D array with dimensions (groups, times, max_delay)
  containing the number of selected indices per row

- `selected_idx`: 4D array with dimensions (groups, times, max_delay,
  max_delay) containing the column indices where each row has 1s

## Details

Row i of the precomputed indices only contains column indices j where j
\<= i, ensuring reports aggregate from current or earlier delays only.
