# Define a model manually using fixed and random effects

For most typical use cases
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
should provide sufficient flexibility to allow models to be defined.
However, there may be some instances where more manual model
specification is required. This function supports this by allowing the
user to supply vectors of fixed, random, and customised random effects
(where they are not first treated as fixed effect terms). Prior to
`1.0.0` this was the main interface for specifying models and it is
still used internally to handle some parts of the model specification
process.

## Usage

``` r
enw_manual_formula(
  data,
  fixed = NULL,
  random = NULL,
  custom_random = NULL,
  no_contrasts = FALSE,
  add_intercept = TRUE
)
```

## Arguments

- data:

  A `data.frame` of observations. It must include all variables used in
  the supplied formula.

- fixed:

  A character vector of fixed effects.

- random:

  A character vector of random effects. Random effects specified here
  will be added to the fixed effects.

- custom_random:

  A vector of random effects. Random effects added here will not be
  added to the vector of fixed effects. This can be used to random
  effects for fixed effects that only have a partial name match.

- no_contrasts:

  Logical, defaults to `FALSE`. `TRUE` means that no variable uses
  contrast. Alternatively a character vector of variables can be
  supplied indicating which variables should not have contrasts.

- add_intercept:

  Logical, defaults to `FALSE`. Should an intercept be added to the
  fixed effects.

## Value

A list specifying the fixed effects (formula, design matrix, and design
matrix index), and random effects (formula and design matrix).

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/dev/reference/re.md),
[`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
data <- enw_example("prep")$metareference[[1]]
enw_manual_formula(data, fixed = "week", random = "day_of_week")
#> $fixed
#> $fixed$formula
#> [1] "~1 + week + day_of_week"
#> 
#> $fixed$design
#>    (Intercept) week day_of_weekFriday day_of_weekMonday day_of_weekSaturday
#> 1            1    0                 0                 0                   0
#> 2            1    0                 0                 0                   0
#> 3            1    0                 1                 0                   0
#> 4            1    0                 0                 0                   1
#> 5            1    0                 0                 0                   0
#> 6            1    0                 0                 1                   0
#> 7            1    0                 0                 0                   0
#> 8            1    1                 0                 0                   0
#> 9            1    1                 0                 0                   0
#> 10           1    1                 1                 0                   0
#> 11           1    1                 0                 0                   1
#> 12           1    1                 0                 0                   0
#> 13           1    1                 0                 1                   0
#> 14           1    1                 0                 0                   0
#> 15           1    2                 0                 0                   0
#> 16           1    2                 0                 0                   0
#> 17           1    2                 1                 0                   0
#> 18           1    2                 0                 0                   1
#> 19           1    2                 0                 0                   0
#> 20           1    2                 0                 1                   0
#> 21           1    2                 0                 0                   0
#> 22           1    3                 0                 0                   0
#> 23           1    3                 0                 0                   0
#> 24           1    3                 1                 0                   0
#> 25           1    3                 0                 0                   1
#> 26           1    3                 0                 0                   0
#> 27           1    3                 0                 1                   0
#> 28           1    3                 0                 0                   0
#> 29           1    4                 0                 0                   0
#> 30           1    4                 0                 0                   0
#> 31           1    4                 1                 0                   0
#> 32           1    4                 0                 0                   1
#> 33           1    4                 0                 0                   0
#> 34           1    4                 0                 1                   0
#> 35           1    4                 0                 0                   0
#> 36           1    5                 0                 0                   0
#> 37           1    5                 0                 0                   0
#> 38           1    5                 1                 0                   0
#> 39           1    5                 0                 0                   1
#> 40           1    5                 0                 0                   0
#>    day_of_weekSunday day_of_weekThursday day_of_weekTuesday
#> 1                  0                   0                  0
#> 2                  0                   1                  0
#> 3                  0                   0                  0
#> 4                  0                   0                  0
#> 5                  1                   0                  0
#> 6                  0                   0                  0
#> 7                  0                   0                  1
#> 8                  0                   0                  0
#> 9                  0                   1                  0
#> 10                 0                   0                  0
#> 11                 0                   0                  0
#> 12                 1                   0                  0
#> 13                 0                   0                  0
#> 14                 0                   0                  1
#> 15                 0                   0                  0
#> 16                 0                   1                  0
#> 17                 0                   0                  0
#> 18                 0                   0                  0
#> 19                 1                   0                  0
#> 20                 0                   0                  0
#> 21                 0                   0                  1
#> 22                 0                   0                  0
#> 23                 0                   1                  0
#> 24                 0                   0                  0
#> 25                 0                   0                  0
#> 26                 1                   0                  0
#> 27                 0                   0                  0
#> 28                 0                   0                  1
#> 29                 0                   0                  0
#> 30                 0                   1                  0
#> 31                 0                   0                  0
#> 32                 0                   0                  0
#> 33                 1                   0                  0
#> 34                 0                   0                  0
#> 35                 0                   0                  1
#> 36                 0                   0                  0
#> 37                 0                   1                  0
#> 38                 0                   0                  0
#> 39                 0                   0                  0
#> 40                 1                   0                  0
#>    day_of_weekWednesday
#> 1                     1
#> 2                     0
#> 3                     0
#> 4                     0
#> 5                     0
#> 6                     0
#> 7                     0
#> 8                     1
#> 9                     0
#> 10                    0
#> 11                    0
#> 12                    0
#> 13                    0
#> 14                    0
#> 15                    1
#> 16                    0
#> 17                    0
#> 18                    0
#> 19                    0
#> 20                    0
#> 21                    0
#> 22                    1
#> 23                    0
#> 24                    0
#> 25                    0
#> 26                    0
#> 27                    0
#> 28                    0
#> 29                    1
#> 30                    0
#> 31                    0
#> 32                    0
#> 33                    0
#> 34                    0
#> 35                    0
#> 36                    1
#> 37                    0
#> 38                    0
#> 39                    0
#> 40                    0
#> 
#> $fixed$index
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#> [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
#> 
#> 
#> $random
#> $random$formula
#> [1] "~0 + fixed + day_of_week"
#> 
#> $random$design
#>   fixed day_of_week
#> 1     1           0
#> 2     0           1
#> 3     0           1
#> 4     0           1
#> 5     0           1
#> 6     0           1
#> 7     0           1
#> 8     0           1
#> attr(,"assign")
#> [1] 1 2
#> 
#> $random$index
#> [1] 1 2 3 4 5 6 7 8
#> 
#> 
```
