# Add a cumulative membership effect to a `data.frame`

This function adds a cumulative membership effect to a data frame. This
is useful for specifying models such as random walks (using
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md)) where
these features can be used in the design matrix with the appropriate
formula. Supports grouping via the optional `.group` column. Note that
cumulative membership is indexed to start with zero (i.e. the first
observation is assigned a cumulative membership of zero).

## Usage

``` r
enw_add_cumulative_membership(metaobs, feature, copy = TRUE)
```

## Arguments

- metaobs:

  A `data.frame` with a column named `feature` that contains a numeric
  vector of values.

- feature:

  The name of the column in `metaobs` that contains the numeric vector
  of values.

- copy:

  Should `metaobs` be copied (default) or modified in place?

## Value

A `data.frame` with a new columns `cfeature$` that contain the
cumulative membership effect for each value of `feature`. For example if
the original `feature` was `week` (with numeric entries `1, 2, 3`) then
the new columns will be `cweek1`, `cweek2`, and `cweek3`.

## See also

Functions used to formulate models
[`enw_add_pooling_effect()`](https://package.epinowcast.org/dev/reference/enw_add_pooling_effect.md),
[`enw_design()`](https://package.epinowcast.org/dev/reference/enw_design.md),
[`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md),
[`enw_one_hot_encode_feature()`](https://package.epinowcast.org/dev/reference/enw_one_hot_encode_feature.md)

## Examples

``` r
metaobs <- data.frame(week = 1:2)
enw_add_cumulative_membership(metaobs, "week")
#>     week .group cweek2
#>    <int>  <num>  <num>
#> 1:     1      1      0
#> 2:     2      1      1

metaobs <- data.frame(week = 1:3, .group = c(1,1,2))
enw_add_cumulative_membership(metaobs, "week")
#>     week .group cweek2 cweek3
#>    <int>  <num>  <num>  <num>
#> 1:     1      1      0      0
#> 2:     2      1      1      0
#> 3:     3      2      0      1
```
