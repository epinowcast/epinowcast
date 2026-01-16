# Construct a convolution matrix

This function allows the construction of convolution matrices which can
be be combined with a vector of primary events to produce a vector of
secondary events for example in the form of a renewal equation or to
simulate reporting delays. Time-varying delays are supported as well as
distribution padding (to allow for use in renewal equation like
approaches).

## Usage

``` r
convolution_matrix(dist, t, include_partial = FALSE)
```

## Arguments

- dist:

  A vector of list of vectors describing the distribution to be
  convolved as a probability mass function.

- t:

  Integer value indicating the number of time steps to convolve over.

- include_partial:

  Logical, defaults to FALSE. If TRUE, the convolution include partially
  complete secondary events.

## Value

A matrix with each column indicating a primary event and each row
indicating a secondary event.

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`add_pmfs()`](https://package.epinowcast.org/reference/add_pmfs.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)

## Examples

``` r
# Simple convolution matrix with a static distribution
convolution_matrix(c(1, 2, 3), 10)
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
#>  [1,]    0    0    0    0    0    0    0    0    0     0
#>  [2,]    0    0    0    0    0    0    0    0    0     0
#>  [3,]    3    2    1    0    0    0    0    0    0     0
#>  [4,]    0    3    2    1    0    0    0    0    0     0
#>  [5,]    0    0    3    2    1    0    0    0    0     0
#>  [6,]    0    0    0    3    2    1    0    0    0     0
#>  [7,]    0    0    0    0    3    2    1    0    0     0
#>  [8,]    0    0    0    0    0    3    2    1    0     0
#>  [9,]    0    0    0    0    0    0    3    2    1     0
#> [10,]    0    0    0    0    0    0    0    3    2     1
# Include partially reported convolutions
convolution_matrix(c(1, 2, 3), 10, include_partial = TRUE)
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
#>  [1,]    1    0    0    0    0    0    0    0    0     0
#>  [2,]    2    1    0    0    0    0    0    0    0     0
#>  [3,]    3    2    1    0    0    0    0    0    0     0
#>  [4,]    0    3    2    1    0    0    0    0    0     0
#>  [5,]    0    0    3    2    1    0    0    0    0     0
#>  [6,]    0    0    0    3    2    1    0    0    0     0
#>  [7,]    0    0    0    0    3    2    1    0    0     0
#>  [8,]    0    0    0    0    0    3    2    1    0     0
#>  [9,]    0    0    0    0    0    0    3    2    1     0
#> [10,]    0    0    0    0    0    0    0    3    2     1
# Use a list of distributions
convolution_matrix(rep(list(c(1, 2, 3)), 10), 10)
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
#>  [1,]    0    0    0    0    0    0    0    0    0     0
#>  [2,]    0    0    0    0    0    0    0    0    0     0
#>  [3,]    3    2    1    0    0    0    0    0    0     0
#>  [4,]    0    3    2    1    0    0    0    0    0     0
#>  [5,]    0    0    3    2    1    0    0    0    0     0
#>  [6,]    0    0    0    3    2    1    0    0    0     0
#>  [7,]    0    0    0    0    3    2    1    0    0     0
#>  [8,]    0    0    0    0    0    3    2    1    0     0
#>  [9,]    0    0    0    0    0    0    3    2    1     0
#> [10,]    0    0    0    0    0    0    0    3    2     1
# Use a time-varying list of distributions
convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4, 5, 6))), 11)
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11]
#>  [1,]    0    0    0    0    0    0    0    0    0     0     0
#>  [2,]    0    0    0    0    0    0    0    0    0     0     0
#>  [3,]    3    2    1    0    0    0    0    0    0     0     0
#>  [4,]    0    3    2    1    0    0    0    0    0     0     0
#>  [5,]    0    0    3    2    1    0    0    0    0     0     0
#>  [6,]    0    0    0    3    2    1    0    0    0     0     0
#>  [7,]    0    0    0    0    3    2    1    0    0     0     0
#>  [8,]    0    0    0    0    0    3    2    1    0     0     0
#>  [9,]    0    0    0    0    0    0    3    2    1     0     0
#> [10,]    0    0    0    0    0    0    0    3    2     1     0
#> [11,]    0    0    0    0    0    0    0    0    3     2     4
```
