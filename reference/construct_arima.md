# Constructs ARIMA term metadata

Takes an ARIMA term as defined by
[`arima()`](https://package.epinowcast.org/reference/arima.md) and
returns the metadata required to wire the term into a Stan model. Unlike
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md),
this does not modify the data or produce design matrix columns; ARIMA
latent residuals enter the linear predictor through a
parameter-dependent kernel applied to unit-normal shocks (see
`inst/stan/functions/arima_kernel.stan`).

## Usage

``` r
construct_arima(arima, data)
```

## Arguments

- arima:

  An ARIMA term as defined by
  [`arima()`](https://package.epinowcast.org/reference/arima.md).

- data:

  A `data.frame` of observations used to define the ARIMA term. Must
  contain the time and (if specified) grouping variable.

## Value

A list with the following elements:

- `time`, `by`, `p`, `d`, `q`: passed through from the
  [`arima()`](https://package.epinowcast.org/reference/arima.md) term.

- `T`: number of distinct time points in the series.

- `G`: number of groups (1 if `by` is unspecified).

- `time_idx`: integer vector mapping each row of `data` to a time index
  in `1:T`.

- `group_idx`: integer vector mapping each row of `data` to a group
  index in `1:G`.

- `time_vals`, `group_levels`: lookup vectors so the indices can be
  inverted.

- `name`: a label for the term, suitable as a parameter prefix.

## See also

Functions used to help convert formulas into model designs
[`ar()`](https://package.epinowcast.org/reference/ar.md),
[`arima()`](https://package.epinowcast.org/reference/arima.md),
[`arima_terms()`](https://package.epinowcast.org/reference/arima_terms.md),
[`arma()`](https://package.epinowcast.org/reference/arma.md),
[`as_string_formula()`](https://package.epinowcast.org/reference/as_string_formula.md),
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
data <- enw_example("preproc")$metareference[[1]]
epinowcast:::construct_arima(arima(week), data)
#> $time
#> [1] "week"
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
epinowcast:::construct_arima(
  arima(week, day_of_week, p = 2, d = 1), data
)
#> $time
#> [1] "week"
#> 
#> $by
#> [1] "day_of_week"
#> 
#> $p
#> [1] 2
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
