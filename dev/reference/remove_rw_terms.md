# Remove random walk terms from a formula object

This function removes random walk terms denoted using
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md) from a
formula so that they can be processed on their own.

## Usage

``` r
remove_rw_terms(formula)
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

A formula object with the random walk terms removed.

## Reference

This function was adapted from code written by J Scott (under an MIT
license) as part of the `epidemia` package
(https://github.com/ImperialCollegeLondon/epidemia/).

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/dev/reference/re.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
epinowcast:::remove_rw_terms(~ 1 + age_group + location)
#> ~1 + age_group + location
#> <environment: 0x55d64157f608>

epinowcast:::remove_rw_terms(~ 1 + age_group + location + rw(week, location))
#> ~1 + age_group + location
#> <environment: 0x55d63a27b3c0>
```
