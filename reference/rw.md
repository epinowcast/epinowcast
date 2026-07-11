# Adds random walks with Gaussian steps to the model.

A call to `rw()` can be used in the `formula` argument of model
construction functions in the `epinowcast` package such as
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md).
Mathematically a Gaussian random walk is exactly an ARIMA(0, 1, 0)
process; `rw(time, by, type)` is now a thin wrapper over
[`arima()`](https://package.epinowcast.org/reference/arima.md) with
`p = 0`, `d = 1`, `q = 0`. It is kept as a user-facing convenience
because random walks are the most common time-series structure in
`epinowcast` formulas.

## Usage

``` r
rw(time, by)
```

## Arguments

- time:

  Defines the random walk time period.

- by:

  Defines the grouping parameter used for the random walk. If not
  specified no grouping is used. Currently this is limited to a single
  variable. Each group draws an independent shock series; the latent
  standard deviation is shared across groups (per-group standard
  deviations are a planned extension).

## Value

A list of class `enw_arima_term` (with `p = 0`, `d = 1`, `q = 0`) that
can be interpreted by
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md).

## Details

Does not evaluate arguments but instead simply passes information for
use in model construction.

## See also

Functions used to help convert formulas into model designs
[`ar()`](https://package.epinowcast.org/reference/ar.md),
[`arima()`](https://package.epinowcast.org/reference/arima.md),
[`arima_terms()`](https://package.epinowcast.org/reference/arima_terms.md),
[`arma()`](https://package.epinowcast.org/reference/arma.md),
[`as_string_formula()`](https://package.epinowcast.org/reference/as_string_formula.md),
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md),
[`construct_gp()`](https://package.epinowcast.org/reference/construct_gp.md),
[`construct_re()`](https://package.epinowcast.org/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/reference/enw_manual_formula.md),
[`gp()`](https://package.epinowcast.org/reference/gp.md),
[`gp_terms()`](https://package.epinowcast.org/reference/gp_terms.md),
[`ma()`](https://package.epinowcast.org/reference/ma.md),
[`parse_formula()`](https://package.epinowcast.org/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/reference/re.md),
[`remove_arima_terms()`](https://package.epinowcast.org/reference/remove_arima_terms.md),
[`remove_gp_terms()`](https://package.epinowcast.org/reference/remove_gp_terms.md),
[`remove_rw_terms()`](https://package.epinowcast.org/reference/remove_rw_terms.md),
[`rw_terms()`](https://package.epinowcast.org/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/reference/split_formula_to_terms.md)

## Examples

``` r
rw(time)
#> $time
#> [1] "time"
#> 
#> $by
#> NULL
#> 
#> $p
#> [1] 0
#> 
#> $d
#> [1] 1
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"

rw(time, location)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $p
#> [1] 0
#> 
#> $d
#> [1] 1
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"

rw(time, location)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $p
#> [1] 0
#> 
#> $d
#> [1] 1
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"
```
