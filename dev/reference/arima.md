# Adds an ARIMA(p, d, q) latent residual to the model.

A call to `arima()` can be used in the `formula` argument of model
construction functions in the `epinowcast` package such as
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md).
It declares an ARIMA(p, d, q) latent series indexed by `time` (and
optionally a grouping variable `by`) whose value at each observation is
added to the linear predictor. As with
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md), arguments
are not evaluated; they are passed by name for use in model
construction. Setting `p = d = q = 0` is not allowed; use
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md) (equivalent
to `arima(time, d = 1)`) for a random walk.

## Usage

``` r
arima(time, by, p = 1, d = 0, q = 0)
```

## Arguments

- time:

  Defines the time index of the ARIMA process.

- by:

  Optional grouping variable. If supplied, an independent ARIMA series
  is fitted for each level of `by`. Currently limited to a single
  variable.

- p:

  Non-negative integer. Order of the autoregressive part. Defaults to 1.

- d:

  Non-negative integer. Order of differencing (`d = 1` gives an
  integrated series, equivalent to
  [`rw()`](https://package.epinowcast.org/dev/reference/rw.md) when
  `p = q = 0`). Defaults to 0.

- q:

  Non-negative integer. Order of the moving-average part. Defaults to 0.

## Value

A list of class `enw_arima_term` describing the ARIMA term,
interpretable by
[`construct_arima()`](https://package.epinowcast.org/dev/reference/construct_arima.md).
Each group draws an independent shock series; `phi`, `theta`, and
`sigma` are shared across groups (per-group parameters are a planned
extension).

## See also

Functions used to help convert formulas into model designs
[`ar()`](https://package.epinowcast.org/dev/reference/ar.md),
[`arima_terms()`](https://package.epinowcast.org/dev/reference/arima_terms.md),
[`arma()`](https://package.epinowcast.org/dev/reference/arma.md),
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_arima()`](https://package.epinowcast.org/dev/reference/construct_arima.md),
[`construct_gp()`](https://package.epinowcast.org/dev/reference/construct_gp.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md),
[`gp()`](https://package.epinowcast.org/dev/reference/gp.md),
[`gp_terms()`](https://package.epinowcast.org/dev/reference/gp_terms.md),
[`ma()`](https://package.epinowcast.org/dev/reference/ma.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/dev/reference/re.md),
[`remove_arima_terms()`](https://package.epinowcast.org/dev/reference/remove_arima_terms.md),
[`remove_gp_terms()`](https://package.epinowcast.org/dev/reference/remove_gp_terms.md),
[`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
arima(time)
#> $time
#> [1] "time"
#> 
#> $by
#> NULL
#> 
#> $p
#> [1] 1
#> 
#> $d
#> [1] 0
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"
arima(time, location)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $p
#> [1] 1
#> 
#> $d
#> [1] 0
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"
arima(time, location, p = 2, d = 1, q = 1)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $p
#> [1] 2
#> 
#> $d
#> [1] 1
#> 
#> $q
#> [1] 1
#> 
#> attr(,"class")
#> [1] "enw_arima_term"
```
