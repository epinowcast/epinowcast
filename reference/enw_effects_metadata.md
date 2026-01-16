# Extracts metadata from a design matrix

This function extracts metadata from a design matrix and returns a
data.table with the following columns:

- effects: the name of the effect

- fixed: a logical indicating whether the effect is fixed (1) or random
  (0).

It automatically drops the intercept (defined as "(Intercept)").

This function is useful for constructing a model design object for
random effects when used in combination with `ewn_add_pooling_effect`.

## Usage

``` r
enw_effects_metadata(design)
```

## Arguments

- design:

  A design matrix as returned by
  [`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html).

## Value

A data.table with the following columns:

- effects: the name of the effect

- fixed: a logical indicating whether the effect is fixed (1) or random
  (0)

## See also

Functions used to formulate models
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/reference/enw_add_cumulative_membership.md),
[`enw_add_pooling_effect()`](https://package.epinowcast.org/reference/enw_add_pooling_effect.md),
[`enw_design()`](https://package.epinowcast.org/reference/enw_design.md),
[`enw_one_hot_encode_feature()`](https://package.epinowcast.org/reference/enw_one_hot_encode_feature.md)

## Examples

``` r
data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
design <- enw_design(a ~ b + c, data)$design
enw_effects_metadata(design)
#>    effects fixed
#>     <char> <num>
#> 1:      b2     1
#> 2:      b3     1
#> 3:       c     1
```
