# Constructs random walk terms

This function takes random walks as defined by
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md), produces
the required additional variables (denoted using a "c" prefix and
constructed using
[`enw_add_cumulative_membership()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative_membership.md)),
and then returns the extended `data.frame` along with the new fixed
effects and the random effect structure.

## Usage

``` r
construct_rw(rw, data)
```

## Arguments

- rw:

  A random walk term as defined by
  [`rw()`](https://package.epinowcast.org/dev/reference/rw.md).

- data:

  A `data.frame` of observations used to define the random walk term.
  Must contain the time and grouping variables defined in the
  [`rw()`](https://package.epinowcast.org/dev/reference/rw.md) term
  specified.

## Value

A list containing the following:

- `data`: The input `data.frame` with the addition of the new variables
  required by the specified random walk. These are added using
  [`enw_add_cumulative_membership()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative_membership.md).
  -`terms`: A character vector of new fixed effects terms to add to a
  model formula.

- `effects`: A `data.frame` describing the random effect structure of
  the new effects.

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_re()`](https://package.epinowcast.org/dev/reference/construct_re.md),
[`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/dev/reference/enw_manual_formula.md),
[`parse_formula()`](https://package.epinowcast.org/dev/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/dev/reference/re.md),
[`remove_rw_terms()`](https://package.epinowcast.org/dev/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/dev/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/dev/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/dev/reference/split_formula_to_terms.md)

## Examples

``` r
data <- enw_example("preproc")$metareference[[1]]

epinowcast:::construct_rw(rw(week), data)
#> $data
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
#>     cweek1 cweek2 cweek3 cweek4 cweek5
#>      <num>  <num>  <num>  <num>  <num>
#>  1:      0      0      0      0      0
#>  2:      0      0      0      0      0
#>  3:      0      0      0      0      0
#>  4:      0      0      0      0      0
#>  5:      0      0      0      0      0
#>  6:      0      0      0      0      0
#>  7:      0      0      0      0      0
#>  8:      1      0      0      0      0
#>  9:      1      0      0      0      0
#> 10:      1      0      0      0      0
#> 11:      1      0      0      0      0
#> 12:      1      0      0      0      0
#> 13:      1      0      0      0      0
#> 14:      1      0      0      0      0
#> 15:      1      1      0      0      0
#> 16:      1      1      0      0      0
#> 17:      1      1      0      0      0
#> 18:      1      1      0      0      0
#> 19:      1      1      0      0      0
#> 20:      1      1      0      0      0
#> 21:      1      1      0      0      0
#> 22:      1      1      1      0      0
#> 23:      1      1      1      0      0
#> 24:      1      1      1      0      0
#> 25:      1      1      1      0      0
#> 26:      1      1      1      0      0
#> 27:      1      1      1      0      0
#> 28:      1      1      1      0      0
#> 29:      1      1      1      1      0
#> 30:      1      1      1      1      0
#> 31:      1      1      1      1      0
#> 32:      1      1      1      1      0
#> 33:      1      1      1      1      0
#> 34:      1      1      1      1      0
#> 35:      1      1      1      1      0
#> 36:      1      1      1      1      1
#> 37:      1      1      1      1      1
#> 38:      1      1      1      1      1
#> 39:      1      1      1      1      1
#> 40:      1      1      1      1      1
#>     cweek1 cweek2 cweek3 cweek4 cweek5
#>      <num>  <num>  <num>  <num>  <num>
#> 
#> $terms
#> [1] "cweek1" "cweek2" "cweek3" "cweek4" "cweek5"
#> 
#> $effects
#>    effects fixed rw__week
#>     <char> <num>    <num>
#> 1:  cweek1     0        1
#> 2:  cweek2     0        1
#> 3:  cweek3     0        1
#> 4:  cweek4     0        1
#> 5:  cweek5     0        1
#> 

epinowcast:::construct_rw(rw(week, day_of_week), data)
#> $data
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
#>     cweek1 cweek2 cweek3 cweek4 cweek5
#>      <num>  <num>  <num>  <num>  <num>
#>  1:      0      0      0      0      0
#>  2:      0      0      0      0      0
#>  3:      0      0      0      0      0
#>  4:      0      0      0      0      0
#>  5:      0      0      0      0      0
#>  6:      0      0      0      0      0
#>  7:      0      0      0      0      0
#>  8:      1      0      0      0      0
#>  9:      1      0      0      0      0
#> 10:      1      0      0      0      0
#> 11:      1      0      0      0      0
#> 12:      1      0      0      0      0
#> 13:      1      0      0      0      0
#> 14:      1      0      0      0      0
#> 15:      1      1      0      0      0
#> 16:      1      1      0      0      0
#> 17:      1      1      0      0      0
#> 18:      1      1      0      0      0
#> 19:      1      1      0      0      0
#> 20:      1      1      0      0      0
#> 21:      1      1      0      0      0
#> 22:      1      1      1      0      0
#> 23:      1      1      1      0      0
#> 24:      1      1      1      0      0
#> 25:      1      1      1      0      0
#> 26:      1      1      1      0      0
#> 27:      1      1      1      0      0
#> 28:      1      1      1      0      0
#> 29:      1      1      1      1      0
#> 30:      1      1      1      1      0
#> 31:      1      1      1      1      0
#> 32:      1      1      1      1      0
#> 33:      1      1      1      1      0
#> 34:      1      1      1      1      0
#> 35:      1      1      1      1      0
#> 36:      1      1      1      1      1
#> 37:      1      1      1      1      1
#> 38:      1      1      1      1      1
#> 39:      1      1      1      1      1
#> 40:      1      1      1      1      1
#>     cweek1 cweek2 cweek3 cweek4 cweek5
#>      <num>  <num>  <num>  <num>  <num>
#> 
#> $terms
#> [1] "day_of_week:cweek1" "day_of_week:cweek2" "day_of_week:cweek3"
#> [4] "day_of_week:cweek4" "day_of_week:cweek5"
#> 
#> $effects
#>                         effects fixed rw__day_of_weekWednesday__week
#>                          <char> <num>                          <num>
#>  1:    day_of_weekFriday:cweek1     0                              0
#>  2:    day_of_weekMonday:cweek1     0                              0
#>  3:  day_of_weekSaturday:cweek1     0                              0
#>  4:    day_of_weekSunday:cweek1     0                              0
#>  5:  day_of_weekThursday:cweek1     0                              0
#>  6:   day_of_weekTuesday:cweek1     0                              0
#>  7: day_of_weekWednesday:cweek1     0                              1
#>  8:    day_of_weekFriday:cweek2     0                              0
#>  9:    day_of_weekMonday:cweek2     0                              0
#> 10:  day_of_weekSaturday:cweek2     0                              0
#> 11:    day_of_weekSunday:cweek2     0                              0
#> 12:  day_of_weekThursday:cweek2     0                              0
#> 13:   day_of_weekTuesday:cweek2     0                              0
#> 14: day_of_weekWednesday:cweek2     0                              1
#> 15:    day_of_weekFriday:cweek3     0                              0
#> 16:    day_of_weekMonday:cweek3     0                              0
#> 17:  day_of_weekSaturday:cweek3     0                              0
#> 18:    day_of_weekSunday:cweek3     0                              0
#> 19:  day_of_weekThursday:cweek3     0                              0
#> 20:   day_of_weekTuesday:cweek3     0                              0
#> 21: day_of_weekWednesday:cweek3     0                              1
#> 22:    day_of_weekFriday:cweek4     0                              0
#> 23:    day_of_weekMonday:cweek4     0                              0
#> 24:  day_of_weekSaturday:cweek4     0                              0
#> 25:    day_of_weekSunday:cweek4     0                              0
#> 26:  day_of_weekThursday:cweek4     0                              0
#> 27:   day_of_weekTuesday:cweek4     0                              0
#> 28: day_of_weekWednesday:cweek4     0                              1
#> 29:    day_of_weekFriday:cweek5     0                              0
#> 30:    day_of_weekMonday:cweek5     0                              0
#> 31:  day_of_weekSaturday:cweek5     0                              0
#> 32:    day_of_weekSunday:cweek5     0                              0
#> 33:  day_of_weekThursday:cweek5     0                              0
#> 34:   day_of_weekTuesday:cweek5     0                              0
#> 35: day_of_weekWednesday:cweek5     0                              1
#>                         effects fixed rw__day_of_weekWednesday__week
#>                          <char> <num>                          <num>
#>     rw__day_of_weekThursday__week rw__day_of_weekFriday__week
#>                             <num>                       <num>
#>  1:                             0                           1
#>  2:                             0                           0
#>  3:                             0                           0
#>  4:                             0                           0
#>  5:                             1                           0
#>  6:                             0                           0
#>  7:                             0                           0
#>  8:                             0                           1
#>  9:                             0                           0
#> 10:                             0                           0
#> 11:                             0                           0
#> 12:                             1                           0
#> 13:                             0                           0
#> 14:                             0                           0
#> 15:                             0                           1
#> 16:                             0                           0
#> 17:                             0                           0
#> 18:                             0                           0
#> 19:                             1                           0
#> 20:                             0                           0
#> 21:                             0                           0
#> 22:                             0                           1
#> 23:                             0                           0
#> 24:                             0                           0
#> 25:                             0                           0
#> 26:                             1                           0
#> 27:                             0                           0
#> 28:                             0                           0
#> 29:                             0                           1
#> 30:                             0                           0
#> 31:                             0                           0
#> 32:                             0                           0
#> 33:                             1                           0
#> 34:                             0                           0
#> 35:                             0                           0
#>     rw__day_of_weekThursday__week rw__day_of_weekFriday__week
#>                             <num>                       <num>
#>     rw__day_of_weekSaturday__week rw__day_of_weekSunday__week
#>                             <num>                       <num>
#>  1:                             0                           0
#>  2:                             0                           0
#>  3:                             1                           0
#>  4:                             0                           1
#>  5:                             0                           0
#>  6:                             0                           0
#>  7:                             0                           0
#>  8:                             0                           0
#>  9:                             0                           0
#> 10:                             1                           0
#> 11:                             0                           1
#> 12:                             0                           0
#> 13:                             0                           0
#> 14:                             0                           0
#> 15:                             0                           0
#> 16:                             0                           0
#> 17:                             1                           0
#> 18:                             0                           1
#> 19:                             0                           0
#> 20:                             0                           0
#> 21:                             0                           0
#> 22:                             0                           0
#> 23:                             0                           0
#> 24:                             1                           0
#> 25:                             0                           1
#> 26:                             0                           0
#> 27:                             0                           0
#> 28:                             0                           0
#> 29:                             0                           0
#> 30:                             0                           0
#> 31:                             1                           0
#> 32:                             0                           1
#> 33:                             0                           0
#> 34:                             0                           0
#> 35:                             0                           0
#>     rw__day_of_weekSaturday__week rw__day_of_weekSunday__week
#>                             <num>                       <num>
#>     rw__day_of_weekMonday__week rw__day_of_weekTuesday__week
#>                           <num>                        <num>
#>  1:                           0                            0
#>  2:                           1                            0
#>  3:                           0                            0
#>  4:                           0                            0
#>  5:                           0                            0
#>  6:                           0                            1
#>  7:                           0                            0
#>  8:                           0                            0
#>  9:                           1                            0
#> 10:                           0                            0
#> 11:                           0                            0
#> 12:                           0                            0
#> 13:                           0                            1
#> 14:                           0                            0
#> 15:                           0                            0
#> 16:                           1                            0
#> 17:                           0                            0
#> 18:                           0                            0
#> 19:                           0                            0
#> 20:                           0                            1
#> 21:                           0                            0
#> 22:                           0                            0
#> 23:                           1                            0
#> 24:                           0                            0
#> 25:                           0                            0
#> 26:                           0                            0
#> 27:                           0                            1
#> 28:                           0                            0
#> 29:                           0                            0
#> 30:                           1                            0
#> 31:                           0                            0
#> 32:                           0                            0
#> 33:                           0                            0
#> 34:                           0                            1
#> 35:                           0                            0
#>     rw__day_of_weekMonday__week rw__day_of_weekTuesday__week
#>                           <num>                        <num>
#> 
```
