# Constructs random walk terms

This function takes random walks as defined by
[`rw()`](https://package.epinowcast.org/reference/rw.md), produces the
required additional variables (denoted using a "c" prefix and
constructed using
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/reference/enw_add_cumulative_membership.md)),
and then returns the extended `data.frame` along with the new fixed
effects and the random effect structure.

## Usage

``` r
construct_rw(rw, data)
```

## Arguments

- rw:

  A random walk term as defined by
  [`rw()`](https://package.epinowcast.org/reference/rw.md).

- data:

  A `data.frame` of observations used to define the random walk term.
  Must contain the time and grouping variables defined in the
  [`rw()`](https://package.epinowcast.org/reference/rw.md) term
  specified.

## Value

A list containing the following:

- `data`: The input `data.frame` with the addition of the new variables
  required by the specified random walk. These are added using
  [`enw_add_cumulative_membership()`](https://package.epinowcast.org/reference/enw_add_cumulative_membership.md).
  -`terms`: A character vector of new fixed effects terms to add to a
  model formula.

- `effects`: A `data.frame` describing the random effect structure of
  the new effects.

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
data <- enw_example("preproc")$metareference[[1]]

epinowcast:::construct_rw(rw(week), data)
#> $time
#> [1] "week"
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
#> $T
#> [1] 6
#> 
#> $G
#> [1] 1
#> 
#> $time_idx
#>  [1] 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6 6
#> [39] 6 6
#> 
#> $group_idx
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [39] 1 1
#> 
#> $time_vals
#> [1] 0 1 2 3 4 5
#> 
#> $group_levels
#> [1] "1"
#> 
#> $name
#> [1] "arima__week"
#> 

epinowcast:::construct_rw(rw(week, day_of_week), data)
#> $time
#> [1] "week"
#> 
#> $by
#> [1] "day_of_week"
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
#> $T
#> [1] 6
#> 
#> $G
#> [1] 7
#> 
#> $time_idx
#>  [1] 1 1 1 1 1 1 1 2 2 2 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 4 4 4 5 5 5 5 5 5 5 6 6 6
#> [39] 6 6
#> 
#> $group_idx
#>  [1] 7 5 1 3 4 2 6 7 5 1 3 4 2 6 7 5 1 3 4 2 6 7 5 1 3 4 2 6 7 5 1 3 4 2 6 7 5 1
#> [39] 3 4
#> 
#> $time_vals
#> [1] 0 1 2 3 4 5
#> 
#> $group_levels
#> [1] "Friday"    "Monday"    "Saturday"  "Sunday"    "Thursday"  "Tuesday"  
#> [7] "Wednesday"
#> 
#> $name
#> [1] "arima__week__day_of_week"
#> 
```
