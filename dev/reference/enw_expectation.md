# Expectation model module

Expectation model module

## Usage

``` r
enw_expectation(
  r = ~0 + (1 | day:.group),
  generation_time = 1,
  observation = ~1,
  latent_reporting_delay = 1,
  data,
  ...
)
```

## Arguments

- r:

  A formula (as implemented in
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md))
  describing the generative process used for expected incidence. This
  can use features defined by reference date as defined in
  `metareference` as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).
  By default this is set to use a daily random effect by group. This
  parameterisation is highly flexible and may not be the most
  appropriate choice when data is sparsely reported or reporting delays
  are substantial. In these settings an alternative could be a
  group-specific weekly random walk (specified as
  `rw(week, by = .group)`). Setting to `~0` will produce an error as an
  expectation model is required. See
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  for details on formula syntax.

- generation_time:

  A numeric vector that sums to 1 and defaults to 1. Describes the
  weighting to apply to previous generations (i.e as part of a renewal
  equation). When set to 1 (the default) this corresponds to modelling
  the daily growth rate.

- observation:

  A formula (as implemented in
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md))
  describing the modifiers used to adjust expected observations. This
  can use features defined by reference date as defined in
  `metareference` as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).
  By default no modifiers are used but a common choice might be to
  adjust for the day of the week. Note that as the baseline is no
  modification, an intercept is always used and is set to 0. Set to `~0`
  to disable observation modifiers (internally converted to `~1` and
  flagged as inactive). See
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  for details on formula syntax.

- latent_reporting_delay:

  A numeric vector that defaults to 1. Describes the weighting to apply
  to past and current latent expected observations (from most recent to
  least). This can be used both to convolve based on some assumed
  reporting delay and to rescale observations (by multiplying a
  probability mass function by some fraction) to account ascertainment
  etc. A list of PMFs can be provided to allow for time-varying PMFs.
  This should be the same length as the modelled time period plus the
  length of the generation time if supplied.

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- ...:

  Additional parameters passed to
  [`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md).
  The same arguments as passed to
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  should be used here.

## Value

A list containing the supplied formulas, data passed into a list
describing the models, a `data.frame` describing the priors used, and a
function that takes the output data and priors and returns a function
that can be used to sample from a tightened version of the prior
distribution.

## See also

Model modules
[`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md),
[`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md),
[`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md),
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md),
[`enw_report()`](https://package.epinowcast.org/dev/reference/enw_report.md)

## Examples

``` r
enw_expectation(data = enw_example("preprocessed"))
#> A random effect using .group is not possible as this variable has fewer than 2
#> unique values.
#> ℹ The r design matrix is sparse (>90% zeros). Consider using `sparse_design = TRUE` in `enw_fit_opts()` to potentially reduce memory usage and computation time.
#> $formula
#> $formula$r
#> [1] "~0 + (1 | day:.group)"
#> 
#> $formula$observation
#> [1] "~1"
#> 
#> 
#> $data_raw
#> $data_raw$r
#> Key: <.group, date>
#>           date .group location age_group delay day_of_week   day  week month
#>         <IDat>  <num>   <fctr>    <fctr> <num>      <fctr> <num> <num> <num>
#>  1: 2021-07-15      1       DE       00+     0    Thursday     1     0     0
#>  2: 2021-07-16      1       DE       00+     0      Friday     2     0     0
#>  3: 2021-07-17      1       DE       00+     0    Saturday     3     0     0
#>  4: 2021-07-18      1       DE       00+     0      Sunday     4     0     0
#>  5: 2021-07-19      1       DE       00+     0      Monday     5     0     0
#>  6: 2021-07-20      1       DE       00+     0     Tuesday     6     0     0
#>  7: 2021-07-21      1       DE       00+     0   Wednesday     7     1     0
#>  8: 2021-07-22      1       DE       00+     0    Thursday     8     1     0
#>  9: 2021-07-23      1       DE       00+     0      Friday     9     1     0
#> 10: 2021-07-24      1       DE       00+     0    Saturday    10     1     0
#> 11: 2021-07-25      1       DE       00+     0      Sunday    11     1     0
#> 12: 2021-07-26      1       DE       00+     0      Monday    12     1     0
#> 13: 2021-07-27      1       DE       00+     0     Tuesday    13     1     0
#> 14: 2021-07-28      1       DE       00+     0   Wednesday    14     2     0
#> 15: 2021-07-29      1       DE       00+     0    Thursday    15     2     0
#> 16: 2021-07-30      1       DE       00+     0      Friday    16     2     0
#> 17: 2021-07-31      1       DE       00+     0    Saturday    17     2     0
#> 18: 2021-08-01      1       DE       00+     0      Sunday    18     2     1
#> 19: 2021-08-02      1       DE       00+     0      Monday    19     2     1
#> 20: 2021-08-03      1       DE       00+     0     Tuesday    20     2     1
#> 21: 2021-08-04      1       DE       00+     0   Wednesday    21     3     1
#> 22: 2021-08-05      1       DE       00+     0    Thursday    22     3     1
#> 23: 2021-08-06      1       DE       00+     0      Friday    23     3     1
#> 24: 2021-08-07      1       DE       00+     0    Saturday    24     3     1
#> 25: 2021-08-08      1       DE       00+     0      Sunday    25     3     1
#> 26: 2021-08-09      1       DE       00+     0      Monday    26     3     1
#> 27: 2021-08-10      1       DE       00+     0     Tuesday    27     3     1
#> 28: 2021-08-11      1       DE       00+     0   Wednesday    28     4     1
#> 29: 2021-08-12      1       DE       00+     0    Thursday    29     4     1
#> 30: 2021-08-13      1       DE       00+     0      Friday    30     4     1
#> 31: 2021-08-14      1       DE       00+     0    Saturday    31     4     1
#> 32: 2021-08-15      1       DE       00+     0      Sunday    32     4     1
#> 33: 2021-08-16      1       DE       00+     0      Monday    33     4     1
#> 34: 2021-08-17      1       DE       00+     0     Tuesday    34     4     1
#> 35: 2021-08-18      1       DE       00+     0   Wednesday    35     5     1
#> 36: 2021-08-19      1       DE       00+     0    Thursday    36     5     1
#> 37: 2021-08-20      1       DE       00+     0      Friday    37     5     1
#> 38: 2021-08-21      1       DE       00+     0    Saturday    38     5     1
#> 39: 2021-08-22      1       DE       00+     0      Sunday    39     5     1
#>           date .group location age_group delay day_of_week   day  week month
#>         <IDat>  <num>   <fctr>    <fctr> <num>      <fctr> <num> <num> <num>
#> 
#> $data_raw$observation
#> Key: <.group, date>
#>           date .group location age_group delay day_of_week   day  week month
#>         <IDat>  <num>   <fctr>    <fctr> <num>      <fctr> <num> <num> <num>
#>  1: 2021-07-14      1       DE       00+     0   Wednesday     0     0     0
#>  2: 2021-07-15      1       DE       00+     0    Thursday     1     0     0
#>  3: 2021-07-16      1       DE       00+     0      Friday     2     0     0
#>  4: 2021-07-17      1       DE       00+     0    Saturday     3     0     0
#>  5: 2021-07-18      1       DE       00+     0      Sunday     4     0     0
#>  6: 2021-07-19      1       DE       00+     0      Monday     5     0     0
#>  7: 2021-07-20      1       DE       00+     0     Tuesday     6     0     0
#>  8: 2021-07-21      1       DE       00+     0   Wednesday     7     1     0
#>  9: 2021-07-22      1       DE       00+     0    Thursday     8     1     0
#> 10: 2021-07-23      1       DE       00+     0      Friday     9     1     0
#> 11: 2021-07-24      1       DE       00+     0    Saturday    10     1     0
#> 12: 2021-07-25      1       DE       00+     0      Sunday    11     1     0
#> 13: 2021-07-26      1       DE       00+     0      Monday    12     1     0
#> 14: 2021-07-27      1       DE       00+     0     Tuesday    13     1     0
#> 15: 2021-07-28      1       DE       00+     0   Wednesday    14     2     0
#> 16: 2021-07-29      1       DE       00+     0    Thursday    15     2     0
#> 17: 2021-07-30      1       DE       00+     0      Friday    16     2     0
#> 18: 2021-07-31      1       DE       00+     0    Saturday    17     2     0
#> 19: 2021-08-01      1       DE       00+     0      Sunday    18     2     1
#> 20: 2021-08-02      1       DE       00+     0      Monday    19     2     1
#> 21: 2021-08-03      1       DE       00+     0     Tuesday    20     2     1
#> 22: 2021-08-04      1       DE       00+     0   Wednesday    21     3     1
#> 23: 2021-08-05      1       DE       00+     0    Thursday    22     3     1
#> 24: 2021-08-06      1       DE       00+     0      Friday    23     3     1
#> 25: 2021-08-07      1       DE       00+     0    Saturday    24     3     1
#> 26: 2021-08-08      1       DE       00+     0      Sunday    25     3     1
#> 27: 2021-08-09      1       DE       00+     0      Monday    26     3     1
#> 28: 2021-08-10      1       DE       00+     0     Tuesday    27     3     1
#> 29: 2021-08-11      1       DE       00+     0   Wednesday    28     4     1
#> 30: 2021-08-12      1       DE       00+     0    Thursday    29     4     1
#> 31: 2021-08-13      1       DE       00+     0      Friday    30     4     1
#> 32: 2021-08-14      1       DE       00+     0    Saturday    31     4     1
#> 33: 2021-08-15      1       DE       00+     0      Sunday    32     4     1
#> 34: 2021-08-16      1       DE       00+     0      Monday    33     4     1
#> 35: 2021-08-17      1       DE       00+     0     Tuesday    34     4     1
#> 36: 2021-08-18      1       DE       00+     0   Wednesday    35     5     1
#> 37: 2021-08-19      1       DE       00+     0    Thursday    36     5     1
#> 38: 2021-08-20      1       DE       00+     0      Friday    37     5     1
#> 39: 2021-08-21      1       DE       00+     0    Saturday    38     5     1
#> 40: 2021-08-22      1       DE       00+     0      Sunday    39     5     1
#>           date .group location age_group delay day_of_week   day  week month
#>         <IDat>  <num>   <fctr>    <fctr> <num>      <fctr> <num> <num> <num>
#> 
#> 
#> $data
#> $data$expr_r_seed
#> [1] 1
#> 
#> $data$expr_gt_n
#> [1] 1
#> 
#> $data$expr_lrgt
#> [1] 0
#> 
#> $data$expr_t
#> [1] 39
#> 
#> $data$expr_obs
#> [1] 0
#> 
#> $data$expr_g
#> [1] 0
#> 
#> $data$expr_ft
#> [1] 40
#> 
#> $data$expr_fintercept
#> [1] 0
#> 
#> $data$expr_fnrow
#> [1] 39
#> 
#> $data$expr_findex
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#> [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39
#> 
#> $data$expr_fnindex
#> [1] 39
#> 
#> $data$expr_fncol
#> [1] 39
#> 
#> $data$expr_rncol
#> [1] 1
#> 
#> $data$expr_fdesign
#>    day1 day2 day3 day4 day5 day6 day7 day8 day9 day10 day11 day12 day13 day14
#> 1     1    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 2     0    1    0    0    0    0    0    0    0     0     0     0     0     0
#> 3     0    0    1    0    0    0    0    0    0     0     0     0     0     0
#> 4     0    0    0    1    0    0    0    0    0     0     0     0     0     0
#> 5     0    0    0    0    1    0    0    0    0     0     0     0     0     0
#> 6     0    0    0    0    0    1    0    0    0     0     0     0     0     0
#> 7     0    0    0    0    0    0    1    0    0     0     0     0     0     0
#> 8     0    0    0    0    0    0    0    1    0     0     0     0     0     0
#> 9     0    0    0    0    0    0    0    0    1     0     0     0     0     0
#> 10    0    0    0    0    0    0    0    0    0     1     0     0     0     0
#> 11    0    0    0    0    0    0    0    0    0     0     1     0     0     0
#> 12    0    0    0    0    0    0    0    0    0     0     0     1     0     0
#> 13    0    0    0    0    0    0    0    0    0     0     0     0     1     0
#> 14    0    0    0    0    0    0    0    0    0     0     0     0     0     1
#> 15    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 16    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 17    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 18    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 19    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 20    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 21    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 22    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 23    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 24    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 25    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 26    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 27    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 28    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 29    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 30    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 31    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 32    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 33    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 34    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 35    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 36    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 37    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 38    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#> 39    0    0    0    0    0    0    0    0    0     0     0     0     0     0
#>    day15 day16 day17 day18 day19 day20 day21 day22 day23 day24 day25 day26
#> 1      0     0     0     0     0     0     0     0     0     0     0     0
#> 2      0     0     0     0     0     0     0     0     0     0     0     0
#> 3      0     0     0     0     0     0     0     0     0     0     0     0
#> 4      0     0     0     0     0     0     0     0     0     0     0     0
#> 5      0     0     0     0     0     0     0     0     0     0     0     0
#> 6      0     0     0     0     0     0     0     0     0     0     0     0
#> 7      0     0     0     0     0     0     0     0     0     0     0     0
#> 8      0     0     0     0     0     0     0     0     0     0     0     0
#> 9      0     0     0     0     0     0     0     0     0     0     0     0
#> 10     0     0     0     0     0     0     0     0     0     0     0     0
#> 11     0     0     0     0     0     0     0     0     0     0     0     0
#> 12     0     0     0     0     0     0     0     0     0     0     0     0
#> 13     0     0     0     0     0     0     0     0     0     0     0     0
#> 14     0     0     0     0     0     0     0     0     0     0     0     0
#> 15     1     0     0     0     0     0     0     0     0     0     0     0
#> 16     0     1     0     0     0     0     0     0     0     0     0     0
#> 17     0     0     1     0     0     0     0     0     0     0     0     0
#> 18     0     0     0     1     0     0     0     0     0     0     0     0
#> 19     0     0     0     0     1     0     0     0     0     0     0     0
#> 20     0     0     0     0     0     1     0     0     0     0     0     0
#> 21     0     0     0     0     0     0     1     0     0     0     0     0
#> 22     0     0     0     0     0     0     0     1     0     0     0     0
#> 23     0     0     0     0     0     0     0     0     1     0     0     0
#> 24     0     0     0     0     0     0     0     0     0     1     0     0
#> 25     0     0     0     0     0     0     0     0     0     0     1     0
#> 26     0     0     0     0     0     0     0     0     0     0     0     1
#> 27     0     0     0     0     0     0     0     0     0     0     0     0
#> 28     0     0     0     0     0     0     0     0     0     0     0     0
#> 29     0     0     0     0     0     0     0     0     0     0     0     0
#> 30     0     0     0     0     0     0     0     0     0     0     0     0
#> 31     0     0     0     0     0     0     0     0     0     0     0     0
#> 32     0     0     0     0     0     0     0     0     0     0     0     0
#> 33     0     0     0     0     0     0     0     0     0     0     0     0
#> 34     0     0     0     0     0     0     0     0     0     0     0     0
#> 35     0     0     0     0     0     0     0     0     0     0     0     0
#> 36     0     0     0     0     0     0     0     0     0     0     0     0
#> 37     0     0     0     0     0     0     0     0     0     0     0     0
#> 38     0     0     0     0     0     0     0     0     0     0     0     0
#> 39     0     0     0     0     0     0     0     0     0     0     0     0
#>    day27 day28 day29 day30 day31 day32 day33 day34 day35 day36 day37 day38
#> 1      0     0     0     0     0     0     0     0     0     0     0     0
#> 2      0     0     0     0     0     0     0     0     0     0     0     0
#> 3      0     0     0     0     0     0     0     0     0     0     0     0
#> 4      0     0     0     0     0     0     0     0     0     0     0     0
#> 5      0     0     0     0     0     0     0     0     0     0     0     0
#> 6      0     0     0     0     0     0     0     0     0     0     0     0
#> 7      0     0     0     0     0     0     0     0     0     0     0     0
#> 8      0     0     0     0     0     0     0     0     0     0     0     0
#> 9      0     0     0     0     0     0     0     0     0     0     0     0
#> 10     0     0     0     0     0     0     0     0     0     0     0     0
#> 11     0     0     0     0     0     0     0     0     0     0     0     0
#> 12     0     0     0     0     0     0     0     0     0     0     0     0
#> 13     0     0     0     0     0     0     0     0     0     0     0     0
#> 14     0     0     0     0     0     0     0     0     0     0     0     0
#> 15     0     0     0     0     0     0     0     0     0     0     0     0
#> 16     0     0     0     0     0     0     0     0     0     0     0     0
#> 17     0     0     0     0     0     0     0     0     0     0     0     0
#> 18     0     0     0     0     0     0     0     0     0     0     0     0
#> 19     0     0     0     0     0     0     0     0     0     0     0     0
#> 20     0     0     0     0     0     0     0     0     0     0     0     0
#> 21     0     0     0     0     0     0     0     0     0     0     0     0
#> 22     0     0     0     0     0     0     0     0     0     0     0     0
#> 23     0     0     0     0     0     0     0     0     0     0     0     0
#> 24     0     0     0     0     0     0     0     0     0     0     0     0
#> 25     0     0     0     0     0     0     0     0     0     0     0     0
#> 26     0     0     0     0     0     0     0     0     0     0     0     0
#> 27     1     0     0     0     0     0     0     0     0     0     0     0
#> 28     0     1     0     0     0     0     0     0     0     0     0     0
#> 29     0     0     1     0     0     0     0     0     0     0     0     0
#> 30     0     0     0     1     0     0     0     0     0     0     0     0
#> 31     0     0     0     0     1     0     0     0     0     0     0     0
#> 32     0     0     0     0     0     1     0     0     0     0     0     0
#> 33     0     0     0     0     0     0     1     0     0     0     0     0
#> 34     0     0     0     0     0     0     0     1     0     0     0     0
#> 35     0     0     0     0     0     0     0     0     1     0     0     0
#> 36     0     0     0     0     0     0     0     0     0     1     0     0
#> 37     0     0     0     0     0     0     0     0     0     0     1     0
#> 38     0     0     0     0     0     0     0     0     0     0     0     1
#> 39     0     0     0     0     0     0     0     0     0     0     0     0
#>    day39
#> 1      0
#> 2      0
#> 3      0
#> 4      0
#> 5      0
#> 6      0
#> 7      0
#> 8      0
#> 9      0
#> 10     0
#> 11     0
#> 12     0
#> 13     0
#> 14     0
#> 15     0
#> 16     0
#> 17     0
#> 18     0
#> 19     0
#> 20     0
#> 21     0
#> 22     0
#> 23     0
#> 24     0
#> 25     0
#> 26     0
#> 27     0
#> 28     0
#> 29     0
#> 30     0
#> 31     0
#> 32     0
#> 33     0
#> 34     0
#> 35     0
#> 36     0
#> 37     0
#> 38     0
#> 39     1
#> attr(,"assign")
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [39] 1
#> attr(,"contrasts")
#> attr(,"contrasts")$day
#>    1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
#> 1  1 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 2  0 1 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 3  0 0 1 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 4  0 0 0 1 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 5  0 0 0 0 1 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 6  0 0 0 0 0 1 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 7  0 0 0 0 0 0 1 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 8  0 0 0 0 0 0 0 1 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 9  0 0 0 0 0 0 0 0 1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 10 0 0 0 0 0 0 0 0 0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 11 0 0 0 0 0 0 0 0 0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 12 0 0 0 0 0 0 0 0 0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 13 0 0 0 0 0 0 0 0 0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 14 0 0 0 0 0 0 0 0 0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 15 0 0 0 0 0 0 0 0 0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 16 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0
#> 17 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0
#> 18 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0
#> 19 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0
#> 20 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0
#> 21 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0
#> 22 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0
#> 23 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0
#> 24 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0
#> 25 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0
#> 26 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0
#> 27 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0
#> 28 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1
#> 29 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 30 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 31 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 32 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 33 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 34 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 35 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 36 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 37 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 38 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#> 39 0 0 0 0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
#>    29 30 31 32 33 34 35 36 37 38 39
#> 1   0  0  0  0  0  0  0  0  0  0  0
#> 2   0  0  0  0  0  0  0  0  0  0  0
#> 3   0  0  0  0  0  0  0  0  0  0  0
#> 4   0  0  0  0  0  0  0  0  0  0  0
#> 5   0  0  0  0  0  0  0  0  0  0  0
#> 6   0  0  0  0  0  0  0  0  0  0  0
#> 7   0  0  0  0  0  0  0  0  0  0  0
#> 8   0  0  0  0  0  0  0  0  0  0  0
#> 9   0  0  0  0  0  0  0  0  0  0  0
#> 10  0  0  0  0  0  0  0  0  0  0  0
#> 11  0  0  0  0  0  0  0  0  0  0  0
#> 12  0  0  0  0  0  0  0  0  0  0  0
#> 13  0  0  0  0  0  0  0  0  0  0  0
#> 14  0  0  0  0  0  0  0  0  0  0  0
#> 15  0  0  0  0  0  0  0  0  0  0  0
#> 16  0  0  0  0  0  0  0  0  0  0  0
#> 17  0  0  0  0  0  0  0  0  0  0  0
#> 18  0  0  0  0  0  0  0  0  0  0  0
#> 19  0  0  0  0  0  0  0  0  0  0  0
#> 20  0  0  0  0  0  0  0  0  0  0  0
#> 21  0  0  0  0  0  0  0  0  0  0  0
#> 22  0  0  0  0  0  0  0  0  0  0  0
#> 23  0  0  0  0  0  0  0  0  0  0  0
#> 24  0  0  0  0  0  0  0  0  0  0  0
#> 25  0  0  0  0  0  0  0  0  0  0  0
#> 26  0  0  0  0  0  0  0  0  0  0  0
#> 27  0  0  0  0  0  0  0  0  0  0  0
#> 28  0  0  0  0  0  0  0  0  0  0  0
#> 29  1  0  0  0  0  0  0  0  0  0  0
#> 30  0  1  0  0  0  0  0  0  0  0  0
#> 31  0  0  1  0  0  0  0  0  0  0  0
#> 32  0  0  0  1  0  0  0  0  0  0  0
#> 33  0  0  0  0  1  0  0  0  0  0  0
#> 34  0  0  0  0  0  1  0  0  0  0  0
#> 35  0  0  0  0  0  0  1  0  0  0  0
#> 36  0  0  0  0  0  0  0  1  0  0  0
#> 37  0  0  0  0  0  0  0  0  1  0  0
#> 38  0  0  0  0  0  0  0  0  0  1  0
#> 39  0  0  0  0  0  0  0  0  0  0  1
#> 
#> 
#> $data$expr_rdesign
#>    fixed day
#> 1      0   1
#> 2      0   1
#> 3      0   1
#> 4      0   1
#> 5      0   1
#> 6      0   1
#> 7      0   1
#> 8      0   1
#> 9      0   1
#> 10     0   1
#> 11     0   1
#> 12     0   1
#> 13     0   1
#> 14     0   1
#> 15     0   1
#> 16     0   1
#> 17     0   1
#> 18     0   1
#> 19     0   1
#> 20     0   1
#> 21     0   1
#> 22     0   1
#> 23     0   1
#> 24     0   1
#> 25     0   1
#> 26     0   1
#> 27     0   1
#> 28     0   1
#> 29     0   1
#> 30     0   1
#> 31     0   1
#> 32     0   1
#> 33     0   1
#> 34     0   1
#> 35     0   1
#> 36     0   1
#> 37     0   1
#> 38     0   1
#> 39     0   1
#> attr(,"assign")
#> [1] 1 2
#> 
#> $data$expl_lrd_n
#> [1] 1
#> 
#> $data$expl_lrd
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13]
#>  [1,]    1    0    0    0    0    0    0    0    0     0     0     0     0
#>  [2,]    0    1    0    0    0    0    0    0    0     0     0     0     0
#>  [3,]    0    0    1    0    0    0    0    0    0     0     0     0     0
#>  [4,]    0    0    0    1    0    0    0    0    0     0     0     0     0
#>  [5,]    0    0    0    0    1    0    0    0    0     0     0     0     0
#>  [6,]    0    0    0    0    0    1    0    0    0     0     0     0     0
#>  [7,]    0    0    0    0    0    0    1    0    0     0     0     0     0
#>  [8,]    0    0    0    0    0    0    0    1    0     0     0     0     0
#>  [9,]    0    0    0    0    0    0    0    0    1     0     0     0     0
#> [10,]    0    0    0    0    0    0    0    0    0     1     0     0     0
#> [11,]    0    0    0    0    0    0    0    0    0     0     1     0     0
#> [12,]    0    0    0    0    0    0    0    0    0     0     0     1     0
#> [13,]    0    0    0    0    0    0    0    0    0     0     0     0     1
#> [14,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [15,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [16,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [17,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [18,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [19,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [20,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [21,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [22,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [23,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [24,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [25,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [26,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [27,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [28,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [29,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [30,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [31,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [32,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [33,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [34,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [35,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [36,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [37,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [38,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [39,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#> [40,]    0    0    0    0    0    0    0    0    0     0     0     0     0
#>       [,14] [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25]
#>  [1,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [2,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [3,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [4,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [5,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [6,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [7,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [8,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [9,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [10,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [11,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [12,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [13,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [14,]     1     0     0     0     0     0     0     0     0     0     0     0
#> [15,]     0     1     0     0     0     0     0     0     0     0     0     0
#> [16,]     0     0     1     0     0     0     0     0     0     0     0     0
#> [17,]     0     0     0     1     0     0     0     0     0     0     0     0
#> [18,]     0     0     0     0     1     0     0     0     0     0     0     0
#> [19,]     0     0     0     0     0     1     0     0     0     0     0     0
#> [20,]     0     0     0     0     0     0     1     0     0     0     0     0
#> [21,]     0     0     0     0     0     0     0     1     0     0     0     0
#> [22,]     0     0     0     0     0     0     0     0     1     0     0     0
#> [23,]     0     0     0     0     0     0     0     0     0     1     0     0
#> [24,]     0     0     0     0     0     0     0     0     0     0     1     0
#> [25,]     0     0     0     0     0     0     0     0     0     0     0     1
#> [26,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [27,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [28,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [29,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [30,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [31,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [32,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [33,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [34,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [35,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [36,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [37,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [38,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [39,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [40,]     0     0     0     0     0     0     0     0     0     0     0     0
#>       [,26] [,27] [,28] [,29] [,30] [,31] [,32] [,33] [,34] [,35] [,36] [,37]
#>  [1,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [2,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [3,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [4,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [5,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [6,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [7,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [8,]     0     0     0     0     0     0     0     0     0     0     0     0
#>  [9,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [10,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [11,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [12,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [13,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [14,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [15,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [16,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [17,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [18,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [19,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [20,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [21,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [22,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [23,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [24,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [25,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [26,]     1     0     0     0     0     0     0     0     0     0     0     0
#> [27,]     0     1     0     0     0     0     0     0     0     0     0     0
#> [28,]     0     0     1     0     0     0     0     0     0     0     0     0
#> [29,]     0     0     0     1     0     0     0     0     0     0     0     0
#> [30,]     0     0     0     0     1     0     0     0     0     0     0     0
#> [31,]     0     0     0     0     0     1     0     0     0     0     0     0
#> [32,]     0     0     0     0     0     0     1     0     0     0     0     0
#> [33,]     0     0     0     0     0     0     0     1     0     0     0     0
#> [34,]     0     0     0     0     0     0     0     0     1     0     0     0
#> [35,]     0     0     0     0     0     0     0     0     0     1     0     0
#> [36,]     0     0     0     0     0     0     0     0     0     0     1     0
#> [37,]     0     0     0     0     0     0     0     0     0     0     0     1
#> [38,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [39,]     0     0     0     0     0     0     0     0     0     0     0     0
#> [40,]     0     0     0     0     0     0     0     0     0     0     0     0
#>       [,38] [,39] [,40]
#>  [1,]     0     0     0
#>  [2,]     0     0     0
#>  [3,]     0     0     0
#>  [4,]     0     0     0
#>  [5,]     0     0     0
#>  [6,]     0     0     0
#>  [7,]     0     0     0
#>  [8,]     0     0     0
#>  [9,]     0     0     0
#> [10,]     0     0     0
#> [11,]     0     0     0
#> [12,]     0     0     0
#> [13,]     0     0     0
#> [14,]     0     0     0
#> [15,]     0     0     0
#> [16,]     0     0     0
#> [17,]     0     0     0
#> [18,]     0     0     0
#> [19,]     0     0     0
#> [20,]     0     0     0
#> [21,]     0     0     0
#> [22,]     0     0     0
#> [23,]     0     0     0
#> [24,]     0     0     0
#> [25,]     0     0     0
#> [26,]     0     0     0
#> [27,]     0     0     0
#> [28,]     0     0     0
#> [29,]     0     0     0
#> [30,]     0     0     0
#> [31,]     0     0     0
#> [32,]     0     0     0
#> [33,]     0     0     0
#> [34,]     0     0     0
#> [35,]     0     0     0
#> [36,]     0     0     0
#> [37,]     0     0     0
#> [38,]     1     0     0
#> [39,]     0     1     0
#> [40,]     0     0     1
#> 
#> $data$expl_obs
#> [1] 0
#> 
#> $data$expl_fintercept
#> [1] 1
#> 
#> $data$expl_fnrow
#> [1] 40
#> 
#> $data$expl_findex
#>  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
#> [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
#> 
#> $data$expl_fnindex
#> [1] 40
#> 
#> $data$expl_fncol
#> [1] 0
#> 
#> $data$expl_rncol
#> [1] 0
#> 
#> $data$expl_fdesign
#>   
#> 1 
#> 2 
#> 3 
#> 4 
#> 5 
#> 6 
#> 7 
#> 8 
#> 9 
#> 10
#> 11
#> 12
#> 13
#> 14
#> 15
#> 16
#> 17
#> 18
#> 19
#> 20
#> 21
#> 22
#> 23
#> 24
#> 25
#> 26
#> 27
#> 28
#> 29
#> 30
#> 31
#> 32
#> 33
#> 34
#> 35
#> 36
#> 37
#> 38
#> 39
#> 40
#> 
#> $data$expl_rdesign
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> 
#> $priors
#>             variable dimension
#>               <char>     <num>
#> 1:        expr_r_int         1
#> 2:      expr_beta_sd         1
#> 3: expr_lelatent_int         1
#> 4:      expl_beta_sd         1
#>                                                                description
#>                                                                     <char>
#> 1:                                        Intercept of the log growth rate
#> 2:             Standard deviation of scaled pooled log growth rate effects
#> 3: Intercept for initial log observations (ordered by group and then time)
#> 4:             Standard deviation of scaled pooled log growth rate effects
#>             distribution  mean    sd
#>                   <char> <num> <num>
#> 1:                Normal   0.0   0.2
#> 2: Zero truncated normal   0.0   1.0
#> 3:                Normal   4.3   1.0
#> 4: Zero truncated normal   0.0   1.0
#> 
#> $inits
#> function (data, priors) 
#> {
#>     priors <- enw_priors_as_data_list(priors)
#>     fn <- function() {
#>         init <- list(expr_beta = numeric(0), expr_beta_sd = numeric(0), 
#>             expr_lelatent_int = matrix(purrr::map2_dbl(as.vector(priors$expr_lelatent_int_p[1]), 
#>                 as.vector(priors$expr_lelatent_int_p[2]), function(x, 
#>                   y) {
#>                   rnorm(1, x, y * 0.1)
#>                 }), nrow = data$expr_gt_n, ncol = data$g), expr_r_int = numeric(0), 
#>             expl_beta = numeric(0), expl_beta_sd = numeric(0))
#>         if (data$expr_fncol > 0) {
#>             init$expr_beta <- array(rnorm(data$expr_fncol, 0, 
#>                 0.01))
#>         }
#>         if (data$expr_rncol > 0) {
#>             init$expr_beta_sd <- array(abs(rnorm(data$expr_rncol, 
#>                 priors$expr_beta_sd_p[1], priors$expr_beta_sd_p[2]/10)))
#>         }
#>         if (data$expr_fintercept > 0) {
#>             init$expr_r_int <- array(rnorm(1, priors$expr_r_int_p[1], 
#>                 priors$expr_r_int_p[2] * 0.1))
#>         }
#>         if (data$expl_fncol > 0) {
#>             init$expl_beta <- array(rnorm(data$expl_fncol, 0, 
#>                 0.01))
#>         }
#>         if (data$expl_rncol > 0) {
#>             init$expl_beta_sd <- array(abs(rnorm(data$expl_rncol, 
#>                 priors$expl_beta_sd_p[1], priors$expl_beta_sd_p[2]/10)))
#>         }
#>         init
#>     }
#>     fn
#> }
#> <bytecode: 0x562aee716eb0>
#> <environment: 0x562aecc872d8>
#> 
```
