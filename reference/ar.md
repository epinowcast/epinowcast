# Autoregressive alias for [`arima()`](https://package.epinowcast.org/reference/arima.md)

Thin wrapper around
[`arima()`](https://package.epinowcast.org/reference/arima.md) that
fixes `d = 0` and `q = 0`. Matches the in-formula `ar()` helper that
`brms` users will be familiar with. Equivalent to
`arima(time, by, p = p, d = 0, q = 0)`.

## Usage

``` r
ar(time, by, p = 1)
```

## Arguments

- time:

  Time variable for the latent series; numeric.

- by:

  Optional grouping variable. Each group draws an independent shock
  series; AR/MA parameters and the latent standard deviation are shared
  across groups.

- p:

  Autoregressive order. Defaults to `1`.

## Value

An `enw_arima_term` interpretable by
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md).

## See also

Functions used to help convert formulas into model designs
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
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/reference/split_formula_to_terms.md)

## Examples

``` r
ar(time)
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
ar(time, location, p = 2)
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
#> [1] 0
#> 
#> $q
#> [1] 0
#> 
#> attr(,"class")
#> [1] "enw_arima_term"
```
