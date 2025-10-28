# Precompute indices from aggregation indicator matrix

Extracts the column indices where each row of a binary indicator matrix
has 1s. This is used for numerically stable aggregation operations in
Stan.

## Usage

``` r
.precompute_matrix_indices(matrix)
```

## Arguments

- matrix:

  A binary indicator matrix (0s and 1s) where each row indicates which
  columns should be aggregated together.

## Value

A list with two components:

- `n_selected`: Integer vector of length `nrow(matrix)` containing the
  number of selected (non-zero) indices per row

- `selected_idx`: Integer matrix of dimensions
  `[nrow(matrix), ncol(matrix)]` containing the column indices where
  each row has 1s, with unused positions filled with 0

## Details

This helper function is primarily used in tests and by
[`.precompute_aggregation_lookups()`](https://package.epinowcast.org/dev/reference/dot-precompute_aggregation_lookups.md)
to precompute sparse index lookups for aggregation operations.
