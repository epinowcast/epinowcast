# Constructs Gaussian process term metadata

Takes a Gaussian process term as defined by
[`gp()`](https://package.epinowcast.org/reference/gp.md) and returns the
metadata required to wire the term into a Stan model. Like
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md),
this does not modify the data or produce design matrix columns; the
Gaussian process enters the linear predictor through a Hilbert-space
reduced-rank approximation (see
`inst/stan/functions/gaussian_process.stan`).

## Usage

``` r
construct_gp(gp, data)
```

## Arguments

- gp:

  A Gaussian process term as defined by
  [`gp()`](https://package.epinowcast.org/reference/gp.md).

- data:

  A `data.frame` of observations used to define the term. Must contain
  the time and (if specified) grouping variable.

## Value

A list with the following elements:

- `time`, `by`, `kernel`, `gp_type`, `nu`, `d`, `basis_prop`,
  `boundary_scale`: passed through from the
  [`gp()`](https://package.epinowcast.org/reference/gp.md) term.

- `T`: number of distinct time points in the integrated series.

- `G`: number of groups (1 if `by` is unspecified).

- `M`: number of basis functions, `ceiling(basis_prop * (T - d))`.

- `PHI`: the `(T - d) x M` basis matrix. For `d >= 1` the basis is built
  on the `T - d` free values that are integrated `d` times in Stan; the
  first `d` values of the realisation are anchored to zero.

- `time_idx`, `group_idx`: per-observation lookup indices.

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
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md),
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
epinowcast:::construct_gp(gp(week), data)
#> $time
#> [1] "week"
#> 
#> $by
#> NULL
#> 
#> $kernel
#> [1] "matern32"
#> 
#> $gp_type
#> [1] 2
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 0
#> 
#> $basis_prop
#> [1] 0.2
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> $T
#> [1] 6
#> 
#> $G
#> [1] 1
#> 
#> $M
#> [1] 2
#> 
#> $PHI
#>           [,1]       [,2]
#> [1,] 0.4082483  0.7071068
#> [2,] 0.6605596  0.7765344
#> [3,] 0.7986542  0.3320991
#> [4,] 0.7986542 -0.3320991
#> [5,] 0.6605596 -0.7765344
#> [6,] 0.4082483 -0.7071068
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
#> [1] "gp__week"
#> 
epinowcast:::construct_gp(gp(week, day_of_week, kernel = "se"), data)
#> $time
#> [1] "week"
#> 
#> $by
#> [1] "day_of_week"
#> 
#> $kernel
#> [1] "se"
#> 
#> $gp_type
#> [1] 0
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 0
#> 
#> $basis_prop
#> [1] 0.2
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> $T
#> [1] 6
#> 
#> $G
#> [1] 7
#> 
#> $M
#> [1] 2
#> 
#> $PHI
#>           [,1]       [,2]
#> [1,] 0.4082483  0.7071068
#> [2,] 0.6605596  0.7765344
#> [3,] 0.7986542  0.3320991
#> [4,] 0.7986542 -0.3320991
#> [5,] 0.6605596 -0.7765344
#> [6,] 0.4082483 -0.7071068
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
#> [1] "gp__week__day_of_week"
#> 
```
