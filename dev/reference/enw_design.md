# A helper function to construct a design matrix from a formula

This function is a wrapper around
[`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html)
that can optionally return a sparse design matrix defined as the unique
number of rows in the design matrix and an index vector that allows the
full design matrix to be reconstructed. This is useful for models that
have many repeated rows in the design matrix and that are
computationally expensive to fit. This function also allows for the
specification of contrasts for categorical variables.

## Usage

``` r
enw_design(formula, data, no_contrasts = FALSE, sparse = TRUE, ...)
```

## Arguments

- formula:

  An R formula.

- data:

  A `data.frame` containing the variables in the formula.

- no_contrasts:

  A vector of variable names that should not be converted to contrasts.
  If `no_contrasts = FALSE` then all categorical variables will use
  contrasts. If `no_contrasts = TRUE` then no categorical variables will
  use contrasts.

- sparse:

  Logical, if TRUE return a sparse design matrix. Defaults to TRUE.

- ...:

  Arguments passed on to
  [`stats::model.matrix`](https://rdrr.io/r/stats/model.matrix.html)

  `object`

  :   an object of an appropriate class. For the default method, a model
      [formula](https://rdrr.io/r/stats/formula.html) or a
      [`terms`](https://rdrr.io/r/stats/terms.html) object.

## Value

A list containing the formula, the design matrix, and the index.

## See also

Functions used to formulate models
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative_membership.md),
[`enw_add_pooling_effect()`](https://package.epinowcast.org/dev/reference/enw_add_pooling_effect.md),
[`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md),
[`enw_one_hot_encode_feature()`](https://package.epinowcast.org/dev/reference/enw_one_hot_encode_feature.md)

## Examples

``` r
data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
enw_design(a ~ b + c, data)
#> $formula
#> [1] "a ~ b + c"
#> 
#> $design
#>   (Intercept) b2 b3 c
#> 1           1  0  0 1
#> 2           1  1  0 1
#> 3           1  0  1 2
#> 
#> $index
#> [1] 1 2 3
#> 
enw_design(a ~ b + c, data, no_contrasts = TRUE)
#> $formula
#> [1] "a ~ b + c"
#> 
#> $design
#>   (Intercept) b1 b2 b3 c
#> 1           1  1  0  0 1
#> 2           1  0  1  0 1
#> 3           1  0  0  1 2
#> 
#> $index
#> [1] 1 2 3
#> 
enw_design(a ~ b + c, data, no_contrasts = c("b"))
#> $formula
#> [1] "a ~ b + c"
#> 
#> $design
#>   (Intercept) b1 b2 b3 c
#> 1           1  1  0  0 1
#> 2           1  0  1  0 1
#> 3           1  0  0  1 2
#> 
#> $index
#> [1] 1 2 3
#> 
enw_design(a ~ c, data, sparse = TRUE)
#> $formula
#> [1] "a ~ c"
#> 
#> $design
#>   (Intercept) c
#> 1           1 1
#> 3           1 2
#> 
#> $index
#> [1] 1 1 2
#> 
enw_design(a ~ c, data, sparse = FALSE)
#> $formula
#> [1] "a ~ c"
#> 
#> $design
#>   (Intercept) c
#> 1           1 1
#> 2           1 1
#> 3           1 2
#> attr(,"assign")
#> [1] 0 1
#> 
#> $index
#> [1] 1 2 3
#> 
```
