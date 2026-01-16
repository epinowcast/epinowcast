# One-hot encode a variable and column-bind it to the original data.table

This function takes a data.frame and a categorical variable, performs
one-hot encoding, and column-binds the encoded variables back to the
data.frame.

## Usage

``` r
enw_one_hot_encode_feature(metaobs, feature, contrasts = FALSE)
```

## Arguments

- metaobs:

  A data.frame containing the data to be encoded.

- feature:

  The name of the categorical variable to one-hot encode as a character
  string.

- contrasts:

  Logical. If TRUE, create one-hot encoded variables with contrasts; if
  FALSE, create them without contrasts. Defaults to FALSE.

## See also

Functions used to formulate models
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/reference/enw_add_cumulative_membership.md),
[`enw_add_pooling_effect()`](https://package.epinowcast.org/reference/enw_add_pooling_effect.md),
[`enw_design()`](https://package.epinowcast.org/reference/enw_design.md),
[`enw_effects_metadata()`](https://package.epinowcast.org/reference/enw_effects_metadata.md)

## Examples

``` r
metaobs <- data.frame(week = 1:2)
enw_one_hot_encode_feature(metaobs, "week")
#>     week week1 week2
#>    <int> <num> <num>
#> 1:     1     1     0
#> 2:     2     0     1
enw_one_hot_encode_feature(metaobs, "week", contrasts = TRUE)
#>     week week2
#>    <int> <num>
#> 1:     1     0
#> 2:     2     1

metaobs <- data.frame(week = 1:6)
enw_one_hot_encode_feature(metaobs, "week")
#>     week week1 week2 week3 week4 week5 week6
#>    <int> <num> <num> <num> <num> <num> <num>
#> 1:     1     1     0     0     0     0     0
#> 2:     2     0     1     0     0     0     0
#> 3:     3     0     0     1     0     0     0
#> 4:     4     0     0     0     1     0     0
#> 5:     5     0     0     0     0     1     0
#> 6:     6     0     0     0     0     0     1
enw_one_hot_encode_feature(metaobs, "week", contrasts = TRUE)
#>     week week2 week3 week4 week5 week6
#>    <int> <num> <num> <num> <num> <num>
#> 1:     1     0     0     0     0     0
#> 2:     2     1     0     0     0     0
#> 3:     3     0     1     0     0     0
#> 4:     4     0     0     1     0     0
#> 5:     5     0     0     0     1     0
#> 6:     6     0     0     0     0     1
```
