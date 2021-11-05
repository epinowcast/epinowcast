
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Hierarchical nowcasting of right censored epidemological counts

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
and day of report effects.

## Installation

### Installing the package

Install the stable development version of the package with:

``` r
install.packages("epinowcast", repos = "https://epiforecasts.r-universe.dev")
```

Install the unstable development from GitHub using the following,

``` r
remotes::install_github("epiforecasts/epinowcast", dependencies = TRUE)
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

These data are sourced from the [Robert Koch Institute via the Germany
Nowcasting
hub](https://github.com/KITmetricslab/hospitalization-nowcast-hub/wiki/Truth-data#role-an-definition-of-the-seven-day-hospitalization-incidence)
where they are deconvolved from weekly data and days with negative
reported hospitalisations are adjusted. Below we first filter for a
snapshot of retrospective data available 30 days before the 1st of
October that contains 30 days of data and then produce the nowcast
target based on the latest available hospitalisations by date of
positive test.

``` r
nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
nat_germany_hosp[report_date <= as.Date("2021-10-01")]
#>        reference_date location age_group confirm report_date
#>     1:     2021-04-06       DE       00+     149  2021-04-06
#>     2:     2021-04-07       DE       00+     312  2021-04-07
#>     3:     2021-04-08       DE       00+     424  2021-04-08
#>     4:     2021-04-09       DE       00+     288  2021-04-09
#>     5:     2021-04-10       DE       00+     273  2021-04-10
#>    ---                                                      
#> 11353:     2021-07-08       DE       00+      56  2021-09-27
#> 11354:     2021-07-09       DE       00+      47  2021-09-28
#> 11355:     2021-07-10       DE       00+      65  2021-09-29
#> 11356:     2021-07-11       DE       00+      50  2021-09-30
#> 11357:     2021-07-12       DE       00+      17  2021-10-01

retro_nat_germany <- enw_retrospective_data(
  nat_germany_hosp,
  rep_days = 30, ref_days = 30
)
retro_nat_germany
#>      reference_date location age_group confirm report_date
#>   1:     2021-08-21       DE       00+      69  2021-08-21
#>   2:     2021-08-22       DE       00+      45  2021-08-22
#>   3:     2021-08-23       DE       00+      28  2021-08-23
#>   4:     2021-08-24       DE       00+     136  2021-08-24
#>   5:     2021-08-25       DE       00+     128  2021-08-25
#>  ---                                                      
#> 492:     2021-08-22       DE       00+     239  2021-09-19
#> 493:     2021-08-23       DE       00+     186  2021-09-20
#> 494:     2021-08-21       DE       00+     323  2021-09-19
#> 495:     2021-08-22       DE       00+     239  2021-09-20
#> 496:     2021-08-21       DE       00+     323  2021-09-20
```

``` r
latest_germany_hosp <- enw_latest_data(nat_germany_hosp, ref_window = c(60, 30))
latest_germany_hosp
#>     reference_date location age_group confirm
#>  1:     2021-08-21       DE       00+     345
#>  2:     2021-08-22       DE       00+     267
#>  3:     2021-08-23       DE       00+     206
#>  4:     2021-08-24       DE       00+     468
#>  5:     2021-08-25       DE       00+     592
#>  6:     2021-08-26       DE       00+     543
#>  7:     2021-08-27       DE       00+     479
#>  8:     2021-08-28       DE       00+     464
#>  9:     2021-08-29       DE       00+     374
#> 10:     2021-08-30       DE       00+     227
#> 11:     2021-08-31       DE       00+     445
#> 12:     2021-09-01       DE       00+     628
#> 13:     2021-09-02       DE       00+     541
#> 14:     2021-09-03       DE       00+     501
#> 15:     2021-09-04       DE       00+     484
#> 16:     2021-09-05       DE       00+     360
#> 17:     2021-09-06       DE       00+     214
#> 18:     2021-09-07       DE       00+     455
#> 19:     2021-09-08       DE       00+     615
#> 20:     2021-09-09       DE       00+     540
#> 21:     2021-09-10       DE       00+     515
#> 22:     2021-09-11       DE       00+     482
#> 23:     2021-09-12       DE       00+     330
#> 24:     2021-09-13       DE       00+     204
#> 25:     2021-09-14       DE       00+     431
#> 26:     2021-09-15       DE       00+     515
#> 27:     2021-09-16       DE       00+     481
#> 28:     2021-09-17       DE       00+     412
#> 29:     2021-09-18       DE       00+     385
#> 30:     2021-09-19       DE       00+     275
#> 31:     2021-09-20       DE       00+     146
#>     reference_date location age_group confirm
```

### Data preprocessing and model specification

Process reported data into format required for `epinowcast` and return
in a `data.table`. At this stage specify grouping (i.e age, location) if
any. It can be useful to check this output before beginning to model to
make sure everything is as expected.

``` r
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 30)
pobs
#>                    obs         new_confirm             latest
#> 1: <data.table[495x6]> <data.table[495x8]> <data.table[31x5]>
#>                   diff  reporting_triangle      metareference
#> 1: <data.table[495x8]> <data.table[31x32]> <data.table[31x7]>
#>            metareport time snapshots groups max_delay   max_date
#> 1: <data.table[60x8]>   31        31      1        30 2021-09-20
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
#> <environment: 0x55f3056088c8>
#> 
#> $fixed$design
#>   (Intercept)
#> 1           1
#> 
#> $fixed$index
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> 
#> 
#> $random
#> $random$formula
#> ~1
#> <environment: 0x55f3056088c8>
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
#> <environment: 0x55f305a59ec8>
#> 
#> $fixed$design
#>   (Intercept) day_of_weekFriday day_of_weekMonday day_of_weekSaturday
#> 1           1                 0                 0                   1
#> 2           1                 0                 0                   0
#> 3           1                 0                 1                   0
#> 4           1                 0                 0                   0
#> 5           1                 0                 0                   0
#> 6           1                 0                 0                   0
#> 7           1                 1                 0                   0
#>   day_of_weekSunday day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
#> 1                 0                   0                  0                    0
#> 2                 1                   0                  0                    0
#> 3                 0                   0                  0                    0
#> 4                 0                   0                  1                    0
#> 5                 0                   0                  0                    1
#> 6                 0                   1                  0                    0
#> 7                 0                   0                  0                    0
#> 
#> $fixed$index
#>  [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
#> [39] 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4
#> 
#> 
#> $random
#> $random$formula
#> ~0 + fixed + day_of_week
#> <environment: 0x55f305a59ec8>
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
#> Chain 1 finished in 44.4 seconds.
#> Chain 2 finished in 45.7 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 45.0 seconds.
#> Total execution time: 45.8 seconds.
```

### Results

Print the output from `epinowcast` which includes diagnostic
information, the data used for fitting, and the `cmdstanr` object.

``` r
nowcast
#>                    obs         new_confirm             latest
#> 1: <data.table[495x6]> <data.table[495x8]> <data.table[31x5]>
#>                   diff  reporting_triangle      metareference
#> 1: <data.table[495x8]> <data.table[31x32]> <data.table[31x7]>
#>            metareport time snapshots groups max_delay   max_date
#> 1: <data.table[60x8]>   31        31      1        30 2021-09-20
#>                  fit       data  fit_args samples max_rhat
#> 1: <CmdStanMCMC[31]> <list[36]> <list[6]>    2000     1.01
#>    divergent_transitions per_divergent_transitions max_treedepth
#> 1:                     0                         0             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                1702                0.851 45.8
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median        sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000    239  0.000000
#>  2:     2021-08-23       DE       00+     186     1 186.5530    186  0.783261
#>  3:     2021-08-24       DE       00+     437     1 439.0415    439  1.518859
#>  4:     2021-08-25       DE       00+     539     1 543.5600    543  2.416675
#>  5:     2021-08-26       DE       00+     509     1 515.4930    515  2.929888
#>  6:     2021-08-27       DE       00+     442     1 450.0540    450  3.305230
#>  7:     2021-08-28       DE       00+     412     1 422.5300    422  3.894186
#>  8:     2021-08-29       DE       00+     322     1 333.5820    333  3.945004
#>  9:     2021-08-30       DE       00+     204     1 211.9955    212  3.168043
#> 10:     2021-08-31       DE       00+     409     1 423.0055    423  4.424167
#> 11:     2021-09-01       DE       00+     535     1 562.9745    563  6.795362
#> 12:     2021-09-02       DE       00+     475     1 506.8375    506  7.303134
#> 13:     2021-09-03       DE       00+     444     1 478.7440    478  7.679320
#> 14:     2021-09-04       DE       00+     437     1 481.6125    481  9.179895
#> 15:     2021-09-05       DE       00+     310     1 348.3345    348  8.270297
#> 16:     2021-09-06       DE       00+     190     1 215.4710    215  6.136937
#> 17:     2021-09-07       DE       00+     395     1 440.5250    440  8.831839
#> 18:     2021-09-08       DE       00+     518     1 600.5690    600 13.474718
#> 19:     2021-09-09       DE       00+     433     1 519.0615    518 14.105573
#> 20:     2021-09-10       DE       00+     395     1 489.5885    489 15.148726
#> 21:     2021-09-11       DE       00+     365     1 483.4045    482 18.518514
#> 22:     2021-09-12       DE       00+     239     1 332.9950    332 15.224285
#> 23:     2021-09-13       DE       00+     147     1 211.7365    211 12.087768
#> 24:     2021-09-14       DE       00+     324     1 429.2535    428 17.308091
#> 25:     2021-09-15       DE       00+     313     1 459.1785    458 23.483342
#> 26:     2021-09-16       DE       00+     289     1 488.0755    486 31.492454
#> 27:     2021-09-17       DE       00+     203     1 423.9575    422 37.787996
#> 28:     2021-09-18       DE       00+     144     1 436.7725    432 52.441909
#> 29:     2021-09-19       DE       00+      73     1 404.4645    396 68.991620
#> 30:     2021-09-20       DE       00+      23     1 317.6785    305 87.012331
#>     reference_date location age_group confirm group     mean median        sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 1.0011355 1748.013 1683.923
#>  3:  1.4826 437.00 442.00 1.0016667 2051.155 1855.236
#>  4:  2.9652 540.00 548.00 0.9995236 1976.784 1882.572
#>  5:  2.9652 511.00 521.00 1.0019635 2200.587 2082.110
#>  6:  2.9652 445.00 456.00 1.0008425 1810.801 2050.181
#>  7:  4.4478 417.00 430.00 1.0016124 2011.310 2067.515
#>  8:  4.4478 328.00 340.00 1.0000859 1813.239 2030.680
#>  9:  2.9652 207.00 218.00 1.0005271 2137.998 1833.634
#> 10:  4.4478 416.00 431.00 1.0004651 1852.400 1747.592
#> 11:  7.4130 553.00 575.00 1.0001108 1939.186 1931.899
#> 12:  7.4130 496.00 519.00 1.0007521 2109.944 1763.695
#> 13:  7.4130 467.00 492.00 1.0004613 1944.067 1910.117
#> 14:  8.8956 467.95 498.00 1.0006668 2038.571 1858.508
#> 15:  8.8956 336.00 363.00 1.0006592 1892.507 1756.191
#> 16:  5.9304 206.00 226.00 1.0002649 2058.708 1860.034
#> 17:  8.8956 427.00 456.00 1.0002989 2117.516 1769.627
#> 18: 13.3434 579.00 624.00 1.0003806 2286.819 2011.733
#> 19: 13.3434 497.00 543.00 1.0005675 2186.568 2039.634
#> 20: 14.8260 467.00 515.00 1.0008054 2064.401 1877.129
#> 21: 17.7912 453.00 516.00 1.0007999 2351.109 2011.789
#> 22: 14.8260 309.00 360.00 0.9996425 2187.500 1760.445
#> 23: 11.8608 193.00 232.00 1.0015021 2215.999 2002.483
#> 24: 16.3086 403.00 460.00 0.9996287 2274.178 1770.189
#> 25: 23.7216 424.95 501.00 0.9993421 2324.935 1923.692
#> 26: 31.1346 440.95 543.05 1.0002299 2090.750 1617.826
#> 27: 35.5824 366.00 490.05 1.0002439 2272.594 1681.046
#> 28: 53.3736 357.00 528.00 0.9995004 2609.756 1902.914
#> 29: 65.2344 305.00 528.05 1.0026114 2139.333 1878.615
#> 30: 80.0604 199.00 475.15 1.0018779 2436.114 1602.356
#>         mad     q5    q95      rhat ess_bulk ess_tail
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

## Citation

If using `epinowccast` in your work please consider citing it using the
following,

    #> 
    #> To cite epinowcast in publications use:
    #> 
    #>   Sam Abbott (2021). epinowcast: Nowcast right censored epidemiological
    #>   count data, DOI: 10.5281/zenodo.5637165
    #> 
    #> A BibTeX entry for LaTeX users is
    #> 
    #>   @Article{,
    #>     title = {epinowcast: Nowcast right censored epidemiological count data},
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
request](https://github.com/epiforecasts/epinowcast/pulls).

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
