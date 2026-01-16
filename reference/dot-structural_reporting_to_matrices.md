# Convert structural reporting data.table to nested list of matrices

Takes a structural reporting data.table and converts it to the nested
list structure required by `.convert_structural_to_arrays()`. This
involves creating delay columns and splitting by group and date.

## Usage

``` r
.structural_reporting_to_matrices(structural, pobs)
```

## Arguments

- structural:

  A `data.table` or `data.frame` with columns `.group`, `date`,
  `report_date`, and `report`.

- pobs:

  A preprocessed observation list from
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

## Value

A nested list: list(groups) of list(times) of matrices (max_delay x
max_delay). Each matrix contains 0s and 1s indicating which delays
aggregate to which reporting delays.
