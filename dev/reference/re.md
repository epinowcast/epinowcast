# Defines random effect terms using the lme4 syntax

Defines random effect terms using the lme4 syntax

## Usage

``` r
re(formula)
```

## Arguments

- formula:

  A random effect as returned by
  [findbars](https://rdrr.io/pkg/reformulas/man/formfuns.html) when a
  random effect is defined using the
  [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax in
  formula. Currently only simplified random effects (i.e LHS \| RHS) are
  supported.

## Value

A list defining the fixed and random effects of the specified random
effect

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
form <- epinowcast:::parse_formula(~ 1 + (1 | age_group))
re(form$random[[1]])
#> $fixed
#> [1] "1"
#> 
#> $random
#> [1] "age_group"
#> 
#> attr(,"class")
#> [1] "enw_re_term"

form <- epinowcast:::parse_formula(~ 1 + (location | age_group))
re(form$random[[1]])
#> $fixed
#> [1] "location"
#> 
#> $random
#> [1] "age_group"
#> 
#> attr(,"class")
#> [1] "enw_re_term"
```
