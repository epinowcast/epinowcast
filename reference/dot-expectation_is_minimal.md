# Is an expectation module minimal (intercept-only, no convolution)?

Used by
[`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md)
to decide whether a delay-only fit can leave the supplied expectation
untouched. A minimal expectation has no growth-rate covariates or random
effects (`expr_fncol` and `expr_rncol` both zero), so replacing it with
`enw_expectation(~1, ...)` would change nothing.

## Usage

``` r
.expectation_is_minimal(expectation)
```

## Arguments

- expectation:

  An expectation module as returned by
  [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md).

## Value

A logical scalar.

## See also

Model modules
[`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md),
[`enw_fit_opts()`](https://package.epinowcast.org/reference/enw_fit_opts.md),
[`enw_missing()`](https://package.epinowcast.org/reference/enw_missing.md),
[`enw_obs()`](https://package.epinowcast.org/reference/enw_obs.md),
[`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/reference/enw_report.md)
