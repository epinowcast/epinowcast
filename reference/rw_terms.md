# Finds random walk terms in a formula object

This function extracts random walk terms denoted using
[`rw()`](https://package.epinowcast.org/reference/rw.md) from a formula
so that they can be processed on their own.

## Usage

``` r
rw_terms(formula)
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

A character vector containing the random walk terms that have been
identified in the supplied formula.

## Reference

This function was adapted from code written by J Scott (under an MIT
license) as part of the `epidemia` package
(https://github.com/ImperialCollegeLondon/epidemia/).

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
[`split_formula_to_terms()`](https://package.epinowcast.org/reference/split_formula_to_terms.md)

## Examples

``` r
epinowcast:::rw_terms(~ 1 + age_group + location)
#> character(0)

epinowcast:::rw_terms(~ 1 + age_group + location + rw(week, location))
#> [1] "rw(week, location)"
```
