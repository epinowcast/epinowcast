# Adds random walks with Gaussian steps to the model.

A call to `rw()` can be used in the 'formula' argument of model
construction functions in the `epinowcast` package such as
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md).
Does not evaluate arguments but instead simply passes information for
use in model construction.

## Usage

``` r
rw(time, by, type = c("independent", "dependent"))
```

## Arguments

- time:

  Defines the random walk time period.

- by:

  Defines the grouping parameter used for the random walk. If not
  specified no grouping is used. Currently this is limited to a single
  variable.

- type:

  Character string, how standard deviation of grouped random walks is
  estimated: "independent", or "dependent" across groups; enforced by
  [`base::match.arg()`](https://rdrr.io/r/base/match.arg.html).

## Value

A list defining the time frame, group, and type with class "enw_rw_term"
that can be interpreted by
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md).

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
#> $type
#> [1] "independent"
#> 
#> attr(,"class")
#> [1] "enw_rw_term"

rw(time, location)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $type
#> [1] "independent"
#> 
#> attr(,"class")
#> [1] "enw_rw_term"

rw(time, location, type = "dependent")
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $type
#> [1] "dependent"
#> 
#> attr(,"class")
#> [1] "enw_rw_term"
```
