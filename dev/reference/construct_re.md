# Constructs random effect terms

Constructs random effect terms

## Usage

``` r
construct_re(re, data)
```

## Arguments

- re:

  A random effect as defined using
  [`re()`](https://package.epinowcast.org/dev/reference/re.md) which
  itself takes random effects specified in a model formula using the
  [lme4](https://rdrr.io/pkg/lme4/man/lme4-package.html) syntax.

- data:

  A `data.frame` of observations used to define the random effects. Must
  contain the variables specified in the
  [`re()`](https://package.epinowcast.org/dev/reference/re.md) term.

## Value

A list containing the transformed data ("data"), fixed effects terms
("terms") and a `data.frame` specifying the random effect structure
between these terms (`effects`). Note that if the specified random
effect was not a factor it will have been converted into one.

## See also

Functions used to help convert formulas into model designs
[`as_string_formula()`](https://package.epinowcast.org/dev/reference/as_string_formula.md),
[`construct_rw()`](https://package.epinowcast.org/dev/reference/construct_rw.md),
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
# Simple examples
form <- epinowcast:::parse_formula(~ 1 + (1 | day_of_week))
#> Warning: the ‘nobars’ function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainter to do so.
#> This warning is displayed once per session.
#> Warning: the ‘findbars’ function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainter to do so.
#> This warning is displayed once per session.
data <- enw_example("prepr")$metareference[[1]]
random_effect <- re(form$random[[1]])
epinowcast:::construct_re(random_effect, data)
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
#> 
#> $terms
#> [1] "day_of_week"
#> 
#> $effects
#>                 effects fixed day_of_week
#>                  <char> <num>       <num>
#> 1:    day_of_weekFriday     0           1
#> 2:    day_of_weekMonday     0           1
#> 3:  day_of_weekSaturday     0           1
#> 4:    day_of_weekSunday     0           1
#> 5:  day_of_weekThursday     0           1
#> 6:   day_of_weekTuesday     0           1
#> 7: day_of_weekWednesday     0           1
#> 

# A more complex example
form <- epinowcast:::parse_formula(
  ~ 1 + disp + (1 + gear | cyl) + (0 + wt | am)
)
random_effect <- re(form$random[[1]])
epinowcast:::construct_re(random_effect, mtcars)
#> $data
#>       mpg    cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>     <num> <fctr> <num> <num> <num> <num> <num> <num> <num> <num> <num>
#>  1:  21.0      6 160.0   110  3.90 2.620 16.46     0     1     4     4
#>  2:  21.0      6 160.0   110  3.90 2.875 17.02     0     1     4     4
#>  3:  22.8      4 108.0    93  3.85 2.320 18.61     1     1     4     1
#>  4:  21.4      6 258.0   110  3.08 3.215 19.44     1     0     3     1
#>  5:  18.7      8 360.0   175  3.15 3.440 17.02     0     0     3     2
#>  6:  18.1      6 225.0   105  2.76 3.460 20.22     1     0     3     1
#>  7:  14.3      8 360.0   245  3.21 3.570 15.84     0     0     3     4
#>  8:  24.4      4 146.7    62  3.69 3.190 20.00     1     0     4     2
#>  9:  22.8      4 140.8    95  3.92 3.150 22.90     1     0     4     2
#> 10:  19.2      6 167.6   123  3.92 3.440 18.30     1     0     4     4
#> 11:  17.8      6 167.6   123  3.92 3.440 18.90     1     0     4     4
#> 12:  16.4      8 275.8   180  3.07 4.070 17.40     0     0     3     3
#> 13:  17.3      8 275.8   180  3.07 3.730 17.60     0     0     3     3
#> 14:  15.2      8 275.8   180  3.07 3.780 18.00     0     0     3     3
#> 15:  10.4      8 472.0   205  2.93 5.250 17.98     0     0     3     4
#> 16:  10.4      8 460.0   215  3.00 5.424 17.82     0     0     3     4
#> 17:  14.7      8 440.0   230  3.23 5.345 17.42     0     0     3     4
#> 18:  32.4      4  78.7    66  4.08 2.200 19.47     1     1     4     1
#> 19:  30.4      4  75.7    52  4.93 1.615 18.52     1     1     4     2
#> 20:  33.9      4  71.1    65  4.22 1.835 19.90     1     1     4     1
#> 21:  21.5      4 120.1    97  3.70 2.465 20.01     1     0     3     1
#> 22:  15.5      8 318.0   150  2.76 3.520 16.87     0     0     3     2
#> 23:  15.2      8 304.0   150  3.15 3.435 17.30     0     0     3     2
#> 24:  13.3      8 350.0   245  3.73 3.840 15.41     0     0     3     4
#> 25:  19.2      8 400.0   175  3.08 3.845 17.05     0     0     3     2
#> 26:  27.3      4  79.0    66  4.08 1.935 18.90     1     1     4     1
#> 27:  26.0      4 120.3    91  4.43 2.140 16.70     0     1     5     2
#> 28:  30.4      4  95.1   113  3.77 1.513 16.90     1     1     5     2
#> 29:  15.8      8 351.0   264  4.22 3.170 14.50     0     1     5     4
#> 30:  19.7      6 145.0   175  3.62 2.770 15.50     0     1     5     6
#> 31:  15.0      8 301.0   335  3.54 3.570 14.60     0     1     5     8
#> 32:  21.4      4 121.0   109  4.11 2.780 18.60     1     1     4     2
#>       mpg    cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>     <num> <fctr> <num> <num> <num> <num> <num> <num> <num> <num> <num>
#> 
#> $terms
#> [1] "cyl"      "gear:cyl"
#> 
#> $effects
#>      effects fixed   cyl gear__cyl
#>       <char> <num> <num>     <num>
#> 1:      cyl4     0     1         0
#> 2:      cyl6     0     1         0
#> 3:      cyl8     0     1         0
#> 4: cyl4:gear     0     0         1
#> 5: cyl6:gear     0     0         1
#> 6: cyl8:gear     0     0         1
#> 

random_effect2 <- re(form$random[[2]])
epinowcast:::construct_re(random_effect2, mtcars)
#> $data
#>       mpg   cyl  disp    hp  drat    wt  qsec    vs     am  gear  carb
#>     <num> <num> <num> <num> <num> <num> <num> <num> <fctr> <num> <num>
#>  1:  21.0     6 160.0   110  3.90 2.620 16.46     0      1     4     4
#>  2:  21.0     6 160.0   110  3.90 2.875 17.02     0      1     4     4
#>  3:  22.8     4 108.0    93  3.85 2.320 18.61     1      1     4     1
#>  4:  21.4     6 258.0   110  3.08 3.215 19.44     1      0     3     1
#>  5:  18.7     8 360.0   175  3.15 3.440 17.02     0      0     3     2
#>  6:  18.1     6 225.0   105  2.76 3.460 20.22     1      0     3     1
#>  7:  14.3     8 360.0   245  3.21 3.570 15.84     0      0     3     4
#>  8:  24.4     4 146.7    62  3.69 3.190 20.00     1      0     4     2
#>  9:  22.8     4 140.8    95  3.92 3.150 22.90     1      0     4     2
#> 10:  19.2     6 167.6   123  3.92 3.440 18.30     1      0     4     4
#> 11:  17.8     6 167.6   123  3.92 3.440 18.90     1      0     4     4
#> 12:  16.4     8 275.8   180  3.07 4.070 17.40     0      0     3     3
#> 13:  17.3     8 275.8   180  3.07 3.730 17.60     0      0     3     3
#> 14:  15.2     8 275.8   180  3.07 3.780 18.00     0      0     3     3
#> 15:  10.4     8 472.0   205  2.93 5.250 17.98     0      0     3     4
#> 16:  10.4     8 460.0   215  3.00 5.424 17.82     0      0     3     4
#> 17:  14.7     8 440.0   230  3.23 5.345 17.42     0      0     3     4
#> 18:  32.4     4  78.7    66  4.08 2.200 19.47     1      1     4     1
#> 19:  30.4     4  75.7    52  4.93 1.615 18.52     1      1     4     2
#> 20:  33.9     4  71.1    65  4.22 1.835 19.90     1      1     4     1
#> 21:  21.5     4 120.1    97  3.70 2.465 20.01     1      0     3     1
#> 22:  15.5     8 318.0   150  2.76 3.520 16.87     0      0     3     2
#> 23:  15.2     8 304.0   150  3.15 3.435 17.30     0      0     3     2
#> 24:  13.3     8 350.0   245  3.73 3.840 15.41     0      0     3     4
#> 25:  19.2     8 400.0   175  3.08 3.845 17.05     0      0     3     2
#> 26:  27.3     4  79.0    66  4.08 1.935 18.90     1      1     4     1
#> 27:  26.0     4 120.3    91  4.43 2.140 16.70     0      1     5     2
#> 28:  30.4     4  95.1   113  3.77 1.513 16.90     1      1     5     2
#> 29:  15.8     8 351.0   264  4.22 3.170 14.50     0      1     5     4
#> 30:  19.7     6 145.0   175  3.62 2.770 15.50     0      1     5     6
#> 31:  15.0     8 301.0   335  3.54 3.570 14.60     0      1     5     8
#> 32:  21.4     4 121.0   109  4.11 2.780 18.60     1      1     4     2
#>       mpg   cyl  disp    hp  drat    wt  qsec    vs     am  gear  carb
#>     <num> <num> <num> <num> <num> <num> <num> <num> <fctr> <num> <num>
#> 
#> $terms
#> [1] "wt:am"
#> 
#> $effects
#>    effects fixed wt__am
#>     <char> <num>  <num>
#> 1:  wt:am0     0      1
#> 2:  wt:am1     0      1
#> 
```
