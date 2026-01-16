# Parse a formula into components

This function uses a series internal functions to break an input formula
into its component parts each of which can then be handled separately.
Currently supported components are fixed effects,
[lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) style random
effects, and random walks using the
[`rw()`](https://package.epinowcast.org/reference/rw.md) helper
function.

## Usage

``` r
parse_formula(formula)
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

A list of formula components. These currently include:

- `fixed`: A character vector of fixed effect terms

- `random`: A list of of
  [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) style random
  effects

- `rw`: A character vector of
  [`rw()`](https://package.epinowcast.org/reference/rw.md) random walk
  terms.

## Reference

The random walk functions used internally by this function were adapted
from code written by J Scott (under an MIT license) as part of the
`epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/reference/enw_manual_formula.md),
[`re()`](https://package.epinowcast.org/reference/re.md),
[`remove_rw_terms()`](https://package.epinowcast.org/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/reference/split_formula_to_terms.md)

## Examples

``` r
epinowcast:::parse_formula(~ 1 + age_group + location)
#> $fixed
#> [1] "1"         "age_group" "location" 
#> 
#> $random
#> NULL
#> 
#> $rw
#> character(0)
#> 

epinowcast:::parse_formula(~ 1 + age_group + (1 | location))
#> $fixed
#> [1] "1"         "age_group"
#> 
#> $random
#> $random[[1]]
#> 1 | location
#> 
#> 
#> $rw
#> character(0)
#> 

epinowcast:::parse_formula(~ 1 + (age_group | location))
#> $fixed
#> [1] "1"
#> 
#> $random
#> $random[[1]]
#> age_group | location
#> 
#> 
#> $rw
#> character(0)
#> 

epinowcast:::parse_formula(~ 1 + (1 | location) + rw(week, location))
#> $fixed
#> [1] "1"
#> 
#> $random
#> $random[[1]]
#> 1 | location
#> 
#> 
#> $rw
#> [1] "rw(week, location)"
#> 
```
