
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Hierarchical nowcasting of right censored epidemiological counts <a href='https://epiforecasts.io/epinowcast'><img src='man/figures/logo.png' align="right" height="139" /></a>

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/epiforecasts/epinowcast/workflows/R-CMD-check/badge.svg)](https://github.com/epiforecasts/epinowcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/epiforecasts/epinowcast/branch/main/graph/badge.svg)](https://app.codecov.io/gh/epiforecasts/epinowcast)

[![Universe](https://epiforecasts.r-universe.dev/badges/epinowcast)](https://epiforecasts.r-universe.dev/)
[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/epiforecasts/epinowcast/blob/master/LICENSE.md/)
[![GitHub
contributors](https://img.shields.io/github/contributors/epiforecasts/epinowcast)](https://github.com/epiforecasts/epinowcast/graphs/contributors)

[![DOI](https://zenodo.org/badge/422611952.svg)](https://zenodo.org/badge/latestdoi/422611952)

This package contains tools to enable flexible and efficient
hierarchical nowcasting of right censored epidemiological counts using a
semi-mechanistic Bayesian method with support for both day of reference
and day of report effects. Nowcasting in this context is the estimation
of the total notifications (for example hospitalisations or deaths) that
will be reported for a given date based on those currently reported and
the pattern of reporting for previous days. This can be useful when
tracking the spread of infectious disease in real-time as otherwise
changes in trends can be obfuscated by partial reporting or their
detection may be delayed due to the use of simpler methods like
truncation.

## Installation

### Installing the package

Install the stable development version of the package with:

``` r
install.packages("epinowcast", repos = "https://epiforecasts.r-universe.dev")
```

Alternatively, install the stable development from GitHub using the
following,

``` r
remotes::install_github("epiforecasts/epinowcast", dependencies = TRUE)
```

The unstable development version can also be installed from GitHub using
the following,

``` r
remotes::install_github("epiforecasts/epinowcast@develop", dependencies = TRUE)
```

### Installing CmdStan

If you don’t already have CmdStan installed then, in addition to
installing `epinowcast`, it is also necessary to install CmdStan using
CmdStanR’s `install_cmdstan()` function to enable model fitting in
`epinowcast`. A suitable C++ toolchain is also required. Instructions
are provided in the [*Getting started with
CmdStanR*](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
vignette. See the [CmdStanR
documentation](https://mc-stan.org/cmdstanr/) for further details and
support.

``` r
cmdstanr::install_cmdstan()
```

## Quick start

In this quick start we use COVID-19 hospitalisations by date of positive
test in Germany available up to the 1st of October 2021 to demonstrate
the specification and fitting of a simple nowcasting model using
`epinowcast`. Examples using more complex models are available in the
package vignettes and in the papers linked to in the literature
vignette.

### Package

As well as `epinowcast` this quick start makes use of `data.table` and
`ggplot2` which are both installed when `epinowcast` is installed.

``` r
library(epinowcast)
library(data.table)
library(ggplot2)
```

### Data

Nowcasting is effectively the estimation of reporting patterns for
recently reported data. This requires data on these patterns for
previous observations and typically this means the time series of data
as reported on multiple consecutive days (in theory non-consecutive days
could be used but this is not yet supported in `epinowcast`). For this
quick start these data are sourced from the [Robert Koch Institute via
the Germany Nowcasting
hub](https://github.com/KITmetricslab/hospitalization-nowcast-hub/wiki/Truth-data#role-an-definition-of-the-seven-day-hospitalization-incidence)
where they are deconvolved from weekly data and days with negative
reported hospitalisations are adjusted.

Below we first filter for a snapshot of retrospective data available 40
days before the 1st of October that contains 40 days of data and then
produce the nowcast target based on the latest available
hospitalisations by date of positive test.

``` r
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
nat_germany_hosp <- nat_germany_hosp[report_date <= as.Date("2021-10-01")]

retro_nat_germany <- enw_retrospective_data(
  nat_germany_hosp,
  rep_days = 40, ref_days = 40
)
retro_nat_germany
#>      reference_date location age_group confirm report_date
#>   1:     2021-07-13       DE       00+      21  2021-07-13
#>   2:     2021-07-14       DE       00+      22  2021-07-14
#>   3:     2021-07-15       DE       00+      28  2021-07-15
#>   4:     2021-07-16       DE       00+      19  2021-07-16
#>   5:     2021-07-17       DE       00+      20  2021-07-17
#>  ---                                                      
#> 857:     2021-07-14       DE       00+      72  2021-08-21
#> 858:     2021-07-15       DE       00+      69  2021-08-22
#> 859:     2021-07-13       DE       00+      59  2021-08-21
#> 860:     2021-07-14       DE       00+      72  2021-08-22
#> 861:     2021-07-13       DE       00+      59  2021-08-22
```

``` r
latest_germany_hosp <- enw_latest_data(nat_germany_hosp, ref_window = c(80, 40))
latest_germany_hosp
#>     reference_date location age_group confirm
#>  1:     2021-07-13       DE       00+      60
#>  2:     2021-07-14       DE       00+      74
#>  3:     2021-07-15       DE       00+      69
#>  4:     2021-07-16       DE       00+      49
#>  5:     2021-07-17       DE       00+      67
#>  6:     2021-07-18       DE       00+      51
#>  7:     2021-07-19       DE       00+      36
#>  8:     2021-07-20       DE       00+      96
#>  9:     2021-07-21       DE       00+      94
#> 10:     2021-07-22       DE       00+      99
#> 11:     2021-07-23       DE       00+      88
#> 12:     2021-07-24       DE       00+      95
#> 13:     2021-07-25       DE       00+      75
#> 14:     2021-07-26       DE       00+      29
#> 15:     2021-07-27       DE       00+      81
#> 16:     2021-07-28       DE       00+     159
#> 17:     2021-07-29       DE       00+     143
#> 18:     2021-07-30       DE       00+     117
#> 19:     2021-07-31       DE       00+     132
#> 20:     2021-08-01       DE       00+      80
#> 21:     2021-08-02       DE       00+      59
#> 22:     2021-08-03       DE       00+     156
#> 23:     2021-08-04       DE       00+     183
#> 24:     2021-08-05       DE       00+     147
#> 25:     2021-08-06       DE       00+     155
#> 26:     2021-08-07       DE       00+     159
#> 27:     2021-08-08       DE       00+     119
#> 28:     2021-08-09       DE       00+      65
#> 29:     2021-08-10       DE       00+     204
#> 30:     2021-08-11       DE       00+     275
#> 31:     2021-08-12       DE       00+     273
#> 32:     2021-08-13       DE       00+     270
#> 33:     2021-08-14       DE       00+     262
#> 34:     2021-08-15       DE       00+     192
#> 35:     2021-08-16       DE       00+     140
#> 36:     2021-08-17       DE       00+     323
#> 37:     2021-08-18       DE       00+     409
#> 38:     2021-08-19       DE       00+     370
#> 39:     2021-08-20       DE       00+     361
#> 40:     2021-08-21       DE       00+     339
#> 41:     2021-08-22       DE       00+     258
#>     reference_date location age_group confirm
```

### Data preprocessing and model specification

Process reported data into format required for `epinowcast` and return
in a `data.table`. At this stage specify grouping (i.e age, location) if
any. It can be useful to check this output before beginning to model to
make sure everything is as expected.

``` r
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 40)
pobs
#>                    obs          new_confirm             latest
#> 1: <data.table[860x9]> <data.table[860x11]> <data.table[41x8]>
#>     reporting_triangle       metareference          metareport time snapshots
#> 1: <data.table[41x42]> <data.table[41x10]> <data.table[80x11]>   41        41
#>    groups max_delay   max_date
#> 1:      1        40 2021-08-22
```

Construct an intercept only model for the date of reference using the
metadata produced by `enw_preprocess_data()`. Note that `epinowcast`
uses a sparse design matrix to reduce runtimes so the design matrix
shows only unique rows with `index` containing the mapping to the full
design matrix.

``` r
reference_effects <- enw_formula(pobs$metareference[[1]])
reference_effects
#> $fixed
#> $fixed$formula
#> ~1
#> <environment: 0x55b140f4ed60>
#> 
#> $fixed$design
#>   (Intercept)
#> 1           1
#> 
#> $fixed$index
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> [39] 1 1 1
#> 
#> 
#> $random
#> $random$formula
#> ~1
#> <environment: 0x55b140f4ed60>
#> 
#> $random$design
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $random$index
#> integer(0)
```

Construct a model with a random effect for the day of report using the
metadata produced by `enw_preprocess_data()`.

``` r
report_effects <- enw_formula(pobs$metareport[[1]], random = "day_of_week")
report_effects
#> $fixed
#> $fixed$formula
#> ~1 + day_of_week
#> <environment: 0x55b141442b58>
#> 
#> $fixed$design
#>   (Intercept) day_of_weekFriday day_of_weekMonday day_of_weekSaturday
#> 1           1                 0                 0                   0
#> 2           1                 0                 0                   0
#> 3           1                 0                 0                   0
#> 4           1                 1                 0                   0
#> 5           1                 0                 0                   1
#> 6           1                 0                 0                   0
#> 7           1                 0                 1                   0
#>   day_of_weekSunday day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
#> 1                 0                   0                  1                    0
#> 2                 0                   0                  0                    1
#> 3                 0                   1                  0                    0
#> 4                 0                   0                  0                    0
#> 5                 0                   0                  0                    0
#> 6                 1                   0                  0                    0
#> 7                 0                   0                  0                    0
#> 
#> $fixed$index
#>  [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
#> [39] 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6
#> [77] 7 1 2 3
#> 
#> 
#> $random
#> $random$formula
#> ~0 + fixed + day_of_week
#> <environment: 0x55b141442b58>
#> 
#> $random$design
#>   fixed day_of_week
#> 1     0           1
#> 2     0           1
#> 3     0           1
#> 4     0           1
#> 5     0           1
#> 6     0           1
#> 7     0           1
#> attr(,"assign")
#> [1] 1 2
#> 
#> $random$index
#> [1] 1 2 3 4 5 6 7
```

### Model fitting

First compile the model. This step can be left to `epinowcast` but here
we want to use multiple cores per chain to speed up model fitting and so
need to compile the model with this feature turned on.

``` r
model <- enw_model(threads = TRUE)
```

We now fit the model and produce a nowcast using this fit. Note that
here we use two chains each using two threads as a demonstration but in
general using 4 chains is recommended. Also note that here we have
silenced fitting progress and potential warning messages for the
purposes of keeping this quick start short but in general this should
not be done.

``` r
options(mc.cores = 2)
nowcast <- epinowcast(pobs,
  model = model,
  report_effects = report_effects,
  reference_effects = reference_effects,
  save_warmup = FALSE, pp = TRUE,
  chains = 2, threads_per_chain = 2,
  show_messages = FALSE, refresh = 0
)
#> Running MCMC with 2 parallel chains, with 2 thread(s) per chain...
#> 
#> Chain 1 finished in 97.1 seconds.
#> Chain 2 finished in 102.3 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 99.7 seconds.
#> Total execution time: 102.4 seconds.
```

### Results

Print the output from `epinowcast` which includes diagnostic
information, the data used for fitting, and the `cmdstanr` object.

``` r
nowcast
#>                    obs          new_confirm             latest
#> 1: <data.table[860x9]> <data.table[860x11]> <data.table[41x8]>
#>     reporting_triangle       metareference          metareport time snapshots
#> 1: <data.table[41x42]> <data.table[41x10]> <data.table[80x11]>   41        41
#>    groups max_delay   max_date               fit       data  fit_args samples
#> 1:      1        40 2021-08-22 <CmdStanMCMC[32]> <list[39]> <list[6]>    2000
#>    max_rhat divergent_transitions per_divergent_transitions max_treedepth
#> 1:     1.01                     0                         0             8
#>    no_at_max_treedepth per_at_max_treedepth run_time
#> 1:                  20                 0.01    102.4
```

Summarise the nowcast for the latest snapshot of data.

``` r
head(summary(nowcast, probs = c(0.05, 0.95)), n = 10)
#>     reference_date location age_group confirm max_confirm cum_prop_reported
#>  1:     2021-07-14       DE       00+      72          72                 1
#>  2:     2021-07-15       DE       00+      69          69                 1
#>  3:     2021-07-16       DE       00+      47          47                 1
#>  4:     2021-07-17       DE       00+      65          65                 1
#>  5:     2021-07-18       DE       00+      50          50                 1
#>  6:     2021-07-19       DE       00+      36          36                 1
#>  7:     2021-07-20       DE       00+      94          94                 1
#>  8:     2021-07-21       DE       00+      91          91                 1
#>  9:     2021-07-22       DE       00+      99          99                 1
#> 10:     2021-07-23       DE       00+      86          86                 1
#>     delay group     mean median        sd    mad q5 q95      rhat ess_bulk
#>  1:    39     1  72.0000     72 0.0000000 0.0000 72  72        NA       NA
#>  2:    38     1  69.0455     69 0.2108364 0.0000 69  69 1.0003614 1941.517
#>  3:    37     1  47.0800     47 0.2839724 0.0000 47  48 1.0021833 1791.432
#>  4:    36     1  65.1820     65 0.4312412 0.0000 65  66 0.9993637 1871.230
#>  5:    35     1  50.2620     50 0.5248750 0.0000 50  51 0.9998088 1737.610
#>  6:    34     1  36.2370     36 0.4959375 0.0000 36  37 0.9994943 2076.506
#>  7:    33     1  94.4490     94 0.7208737 0.0000 94  96 1.0005755 1951.560
#>  8:    32     1  91.7340     92 0.9009161 1.4826 91  93 1.0005936 1797.432
#>  9:    31     1 100.0515    100 1.0809403 1.4826 99 102 1.0006480 1904.151
#> 10:    30     1  87.1765     87 1.1623353 1.4826 86  89 1.0028604 1757.715
#>     ess_tail
#>  1:       NA
#>  2: 1930.799
#>  3: 1787.071
#>  4: 1879.172
#>  5: 1722.039
#>  6: 1919.275
#>  7: 1948.554
#>  8: 1952.647
#>  9: 2002.516
#> 10: 1863.939
```

Plot the summarised nowcast against currently observed data (or
optionally more recent data for comparison purposes).

``` r
plot(nowcast, latest_obs = latest_germany_hosp)
```

<img src="man/figures/README-nowcast-1.png" width="100%" />

Plot posterior predictions for observed notifications by date of report
as a check of how well the model reproduces the observed data.

``` r
plot(nowcast, type = "posterior") +
  facet_wrap(vars(reference_date), scale = "free")
```

<img src="man/figures/README-pp-1.png" width="100%" />

Rather than using the methods supplied for `epinowcast` directly,
package functions can also be used to extract nowcast posterior samples,
summarise them, and then plot them. This is demonstrated here by
plotting the 7 day incidence for hospitalisations.

``` r
# extract samples
samples <- summary(nowcast, type = "nowcast_samples")

# Take a 7 day rolling sum of both samples and observations
cols <- c("confirm", "sample")
samples[, (cols) := lapply(.SD, frollsum, n = 7),
  .SDcols = cols, by = ".draw"
][!is.na(sample)]
#>        reference_date location age_group confirm max_confirm cum_prop_reported
#>     1:     2021-07-20       DE       00+     433          94                 1
#>     2:     2021-07-20       DE       00+     433          94                 1
#>     3:     2021-07-20       DE       00+     433          94                 1
#>     4:     2021-07-20       DE       00+     433          94                 1
#>     5:     2021-07-20       DE       00+     433          94                 1
#>    ---                                                                        
#> 67996:     2021-08-22       DE       00+    1093          45                 1
#> 67997:     2021-08-22       DE       00+    1093          45                 1
#> 67998:     2021-08-22       DE       00+    1093          45                 1
#> 67999:     2021-08-22       DE       00+    1093          45                 1
#> 68000:     2021-08-22       DE       00+    1093          45                 1
#>        delay group .chain .iteration .draw sample
#>     1:    33     1      1          1     1    434
#>     2:    33     1      1          2     2    433
#>     3:    33     1      1          3     3    434
#>     4:    33     1      1          4     4    435
#>     5:    33     1      1          5     5    435
#>    ---                                           
#> 67996:     0     1      2        996  1996   2357
#> 67997:     0     1      2        997  1997   1846
#> 67998:     0     1      2        998  1998   2372
#> 67999:     0     1      2        999  1999   2101
#> 68000:     0     1      2       1000  2000   2077
latest_germany_hosp_7day <- copy(latest_germany_hosp)[
  ,
  confirm := frollsum(confirm, n = 7)
][!is.na(confirm)]

# Summarise samples
sum_across_last_7_days <- enw_summarise_samples(samples)

# Plot samples
enw_plot_nowcast_quantiles(sum_across_last_7_days, latest_germany_hosp_7day)
```

<img src="man/figures/README-week_nowcast-1.png" width="100%" />

## Citation

If using `epinowcast` in your work please consider citing it using the
following,

    #> 
    #> To cite epinowcast in publications use:
    #> 
    #>   Sam Abbott (2021). epinowcast: Hierarchical nowcasting of right
    #>   censored epidemiological counts, DOI: 10.5281/zenodo.5637165
    #> 
    #> A BibTeX entry for LaTeX users is
    #> 
    #>   @Article{,
    #>     title = {epinowcast: Hierarchical nowcasting of right censored epidemiological counts},
    #>     author = {Sam Abbott},
    #>     journal = {Zenodo},
    #>     year = {2021},
    #>     doi = {10.5281/zenodo.5637165},
    #>   }

## How to make a bug report or feature request

Please briefly describe your problem and what output you expect in an
[issue](https://github.com/epiforecasts/epinowcast/issues). If you have
a question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/epiforecasts/epinowcast/discussions/categories/q-a).

## Contributing

We welcome contributions and new contributors\! We particularly
appreciate help on priority problems in the
[issues](https://github.com/epiforecasts/epinowcast/issues). Please
check and add to the issues, and/or add a [pull
request](https://github.com/epiforecasts/epinowcast/pulls). See our
[contributing
guide](https://github.com/epiforecasts/epinowcast/blob/main/CONTRIBUTING.md)
for more information.

If interested in expanding the functionality of the underlying model
note that `epinowcast` allows users to pass in their own models meaning
that alternative parameterisations, for example altering the forecast
model used for inferring expected observations, may be easily tested
within the package infrastructure. Once this testing has been done
alterations that increase the flexibility of the package model and
improves its defaults are very welcome via pull request or other
communication with the package authors.

## Code of Conduct

Please note that the `epinowcast` project is released with a
[Contributor Code of
Conduct](https://epiforecasts.io/epinowcast/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
