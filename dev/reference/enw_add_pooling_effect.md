# Add a pooling effect to model design metadata

This function adds a pooling effect to the metadata returned by
[`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md).
It does this updating the `fixed` column to 0 for the effects that match
the `string` argument and adding a new column `var_name` that is 1 for
the effects that match the `string` argument and 0 otherwise.

## Usage

``` r
enw_add_pooling_effect(effects, var_name = "sd", finder_fn = startsWith, ...)
```

## Arguments

- effects:

  A `data.table` with the following columns:

  - effects: the name of the effect

  - fixed: a logical indicating whether the effect is fixed (1) or
    random (0).

  This is the output of
  [`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md).

- var_name:

  The name of the new column that will be added to the `effects`
  data.table. This column will be 1 for the effects that match the
  string and 0 otherwise. Defaults to 'sd'.

- finder_fn:

  A function that will be used to find the effects that match the
  string. Defaults to
  [`startsWith()`](https://rdrr.io/r/base/startsWith.html). This can be
  any function that takes a `character` as it's first argument (the
  `effects$effects` column) and then any other other arguments in `...`
  and returns a logical vector indicating whether the effects were
  matched.

- ...:

  Additional arguments to `finder_fn`. E.g. for the
  `finder_fn = startsWith` default, this should be
  `prefix = "somestring"`.

## Value

A `data.table` with the following columns:

- effects: the name of the effect

- fixed: a logical indicating whether the effect is fixed (1) or random
  (0).

- Argument supplied to `var_name`: a logical indicating whether the
  effect should be pooled (1) or not (0).

## See also

Functions used to formulate models
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative_membership.md),
[`enw_design()`](https://package.epinowcast.org/dev/reference/enw_design.md),
[`enw_effects_metadata()`](https://package.epinowcast.org/dev/reference/enw_effects_metadata.md),
[`enw_one_hot_encode_feature()`](https://package.epinowcast.org/dev/reference/enw_one_hot_encode_feature.md)

## Examples

``` r
data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
design <- enw_design(a ~ b + c, data)$design
effects <- enw_effects_metadata(design)
enw_add_pooling_effect(effects, prefix = "b")
#>    effects fixed    sd
#>     <char> <num> <num>
#> 1:      b2     0     1
#> 2:      b3     0     1
#> 3:       c     1     0
```
