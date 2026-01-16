# Extract sparse matrix elements

This helper function allows the extraction of a sparse matrix from a
matrix using a similar approach to that implemented in
`rstan::extract_sparse_parts()` and returns these elements in a named
list for use in stan. This function is used in the construction of the
expectation model (see
[`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)).

## Usage

``` r
extract_sparse_matrix(mat, prefix = "")
```

## Arguments

- mat:

  A matrix to extract the sparse matrix from.

- prefix:

  A character string to prefix the names of the returned list.

## Value

A list representing the sparse matrix, containing:

- `nw`: Count of non-zero elements in `mat`.

- `w`: Vector of non-zero elements in `mat`. Equivalent to the numeric
  values from `mat` excluding zeros.

- `nv`: Length of v.

- `v`: Vector of row indices corresponding to each non-zero element in
  `w`. Indicates the row location in `mat` for each non-zero value.

- `nu`: Length of u.

- `u`: Vector indicating the starting indices in `w` for non-zero
  elements of each row in `mat`. Helps identify the partition of `w`
  into different rows of `mat`.

## See also

[`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)

## Examples

``` r
mat <- matrix(1:12, nrow = 4)
mat[2, 2] <- 0
mat[3, 1] <- 0
extract_sparse_matrix(mat)
#> Warning: `extract_sparse_matrix()` was deprecated in epinowcast 0.5.0.
#> $nw
#> [1] 10
#> 
#> $w
#>  [1]  1  5  9  2 10  7 11  4  8 12
#> 
#> $nv
#> [1] 10
#> 
#> $v
#>  [1] 1 2 3 1 3 2 3 1 2 3
#> 
#> $nu
#> [1] 5
#> 
#> $u
#> [1]  1  4  6  8 11
#> 
```
