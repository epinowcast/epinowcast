# Finds Gaussian process terms in a formula object

This function extracts Gaussian process terms denoted using
[`gp()`](https://package.epinowcast.org/dev/reference/gp.md) from a
formula so that they can be processed on their own.

## Usage

``` r
gp_terms(formula)
```

## Arguments

- formula:

  A model formula that may use standard fixed effects, random effects
  using [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax
  (see [`re()`](https://package.epinowcast.org/dev/reference/re.md)),
  and random walks defined using the
  [`rw()`](https://package.epinowcast.org/dev/reference/rw.md) helper
  function. See the Details section below for a comprehensive
  explanation of the supported syntax.

## Value

A character vector containing the Gaussian process terms identified in
the supplied formula.

## See also

Functions used to help convert formulas into model designs
[`ar()`](https://package.epinowcast.org/dev/reference/ar.md),
[`arima()`](https://package.epinowcast.org/dev/reference/arima.md),
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
epinowcast:::gp_terms(~ 1 + age_group + gp(week))
#> [1] "gp(week)"
epinowcast:::gp_terms(~ 1 + gp(week, kernel = "se") + gp(day))
#> [1] "gp(week, kernel = \"se\")" "gp(day)"                  
```
