# Add probability mass functions

This function allows the addition of probability mass functions (PMFs)
to produce a new PMF. This is useful for example in the context of
reporting delays where the PMF of the sum of two Poisson distributions
is the convolution of the PMFs.

## Usage

``` r
add_pmfs(pmfs)
```

## Arguments

- pmfs:

  A list of vectors describing the probability mass functions to

## Value

A vector describing the probability mass function of the sum of the

## See also

Helper functions for model modules
[`add_max_observed_delay()`](https://package.epinowcast.org/reference/add_max_observed_delay.md),
[`convolution_matrix()`](https://package.epinowcast.org/reference/convolution_matrix.md),
[`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/reference/enw_dayofweek_structural_reporting.md),
[`enw_reference_by_report()`](https://package.epinowcast.org/reference/enw_reference_by_report.md),
[`enw_reps_with_complete_refs()`](https://package.epinowcast.org/reference/enw_reps_with_complete_refs.md),
[`enw_structural_reporting_metadata()`](https://package.epinowcast.org/reference/enw_structural_reporting_metadata.md),
[`extract_obs_metadata()`](https://package.epinowcast.org/reference/extract_obs_metadata.md),
[`extract_sparse_matrix()`](https://package.epinowcast.org/reference/extract_sparse_matrix.md),
[`latest_obs_as_matrix()`](https://package.epinowcast.org/reference/latest_obs_as_matrix.md)

## Examples

``` r
# Sample and analytical PMFs for two Poisson distributions
x <- rpois(10000, 5)
xpmf <- dpois(0:20, 5)
y <- rpois(10000, 7)
ypmf <- dpois(0:20, 7)
# Add sampled Poisson distributions up to get combined distribution
z <- x + y
# Analytical convolution of PMFs
conv_pmf <- add_pmfs(list(xpmf, ypmf))
conv_cdf <- cumsum(conv_pmf)
# Empirical convolution of PMFs
cdf <- ecdf(z)(0:42)
# Compare sampled and analytical CDFs
plot(conv_cdf)
lines(cdf, col = "black")
```
