# Split formula into individual terms

Split formula into individual terms

## Usage

``` r
split_formula_to_terms(formula)
```

## Arguments

- formula:

  A model formula that may use standard fixed effects, random effects
  using [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax
  (see [`re()`](https://package.epinowcast.org/reference/re.md)), and
  random walks defined using the
  [`rw()`](https://package.epinowcast.org/reference/rw.md) helper
  function. See the Details section below for a comprehensive
  explanation of the supported syntax.

## Value

A character vector of formula terms

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/reference/enw_manual_formula.md),
[`parse_formula()`](https://package.epinowcast.org/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/reference/re.md),
[`remove_rw_terms()`](https://package.epinowcast.org/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/reference/rw_terms.md)

## Examples

``` r
epinowcast:::split_formula_to_terms(~ 1 + age_group + location)
#> [1] "1"         "age_group" "location" 
```
