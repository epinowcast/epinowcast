
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Nowcast right censored epidemological counts

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
`{epinowcast}`.Examples using more complex models are available in the
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
target based on the latest available hospitialisations by date of
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
in a `{data.table}`. At this stage specify grouping (i.e age, location)
if any. It can be useful to check this output before beginning to model
to make sure everything is as expected.

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
metadata produced by `enw_preprocess_data()`. Note that `{epinowcast}`
uses a sparse design matrix to reduce runtimes so the design matrix
shows only unique rows with `index` containing the mapping to the full
design matrix.

``` r
reference_effects <- enw_formula(pobs$metareference[[1]])
reference_effects
#> $fixed
#> $fixed$formula
#> ~1
#> <environment: 0x56443f6c1168>
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
#> <environment: 0x56443f6c1168>
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
#> <environment: 0x56443fb491a8>
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
#> <environment: 0x56443fb491a8>
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
  refresh = 0, show_messages = FALSE
)
#> Running MCMC with 2 parallel chains, with 2 thread(s) per chain...
#> 
#> Chain 1 finished in 44.2 seconds.
#> Chain 2 finished in 44.2 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 44.2 seconds.
#> Total execution time: 44.3 seconds.
```

### Results

Print the output from `{epinowcast}` which includes diagnostic
information, the data used for fitting, and the `{cmdstanr`} object.

``` r
nowcast
#>                    obs         new_confirm             latest
#> 1: <data.table[495x6]> <data.table[495x8]> <data.table[31x5]>
#>                   diff  reporting_triangle      metareference
#> 1: <data.table[495x8]> <data.table[31x32]> <data.table[31x7]>
#>            metareport time snapshots groups max_delay   max_date
#> 1: <data.table[60x8]>   31        31      1        30 2021-09-20
#>                  fit       data  fit_args samples max_rhat
#> 1: <CmdStanMCMC[31]> <list[29]> <list[6]>    2000     1.01
#>    divergent_transitions per_divergent_transitions max_treedepth
#> 1:                     0                         0             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                1879               0.9395 44.3
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median         sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000    239  0.0000000
#>  2:     2021-08-23       DE       00+     186     1 186.6275    186  0.8081276
#>  3:     2021-08-24       DE       00+     437     1 439.0925    439  1.5786671
#>  4:     2021-08-25       DE       00+     539     1 543.7920    544  2.4993718
#>  5:     2021-08-26       DE       00+     509     1 515.9025    516  2.9776546
#>  6:     2021-08-27       DE       00+     442     1 450.4590    450  3.3410927
#>  7:     2021-08-28       DE       00+     412     1 422.8270    423  3.8066148
#>  8:     2021-08-29       DE       00+     322     1 333.9690    334  4.1993876
#>  9:     2021-08-30       DE       00+     204     1 212.0110    212  3.1330156
#> 10:     2021-08-31       DE       00+     409     1 423.2020    423  4.4781942
#> 11:     2021-09-01       DE       00+     535     1 563.5335    563  6.9731765
#> 12:     2021-09-02       DE       00+     475     1 507.3505    507  7.3041992
#> 13:     2021-09-03       DE       00+     444     1 478.7115    478  7.5850533
#> 14:     2021-09-04       DE       00+     437     1 481.8540    481  9.3148842
#> 15:     2021-09-05       DE       00+     310     1 348.9480    348  8.2244220
#> 16:     2021-09-06       DE       00+     190     1 215.6990    215  6.1972253
#> 17:     2021-09-07       DE       00+     395     1 440.5830    440  9.0374193
#> 18:     2021-09-08       DE       00+     518     1 600.8125    600 13.9180171
#> 19:     2021-09-09       DE       00+     433     1 518.5695    518 14.3046664
#> 20:     2021-09-10       DE       00+     395     1 490.2430    490 15.3162085
#> 21:     2021-09-11       DE       00+     365     1 483.7110    483 18.4334038
#> 22:     2021-09-12       DE       00+     239     1 333.6055    333 16.1735173
#> 23:     2021-09-13       DE       00+     147     1 211.8540    211 12.2386509
#> 24:     2021-09-14       DE       00+     324     1 429.1345    428 17.6633068
#> 25:     2021-09-15       DE       00+     313     1 459.0355    458 24.1502766
#> 26:     2021-09-16       DE       00+     289     1 487.3125    486 32.2624593
#> 27:     2021-09-17       DE       00+     203     1 421.9865    418 37.1980936
#> 28:     2021-09-18       DE       00+     144     1 434.7650    430 55.2334241
#> 29:     2021-09-19       DE       00+      73     1 400.4825    393 68.4068231
#> 30:     2021-09-20       DE       00+      23     1 317.8180    310 85.1455328
#>     reference_date location age_group confirm group     mean median         sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 0.9992215 1795.159 1751.494
#>  3:  1.4826 437.00 442.00 1.0001363 1942.576 1828.531
#>  4:  2.9652 540.00 548.00 1.0009785 1787.301 1740.478
#>  5:  2.9652 512.00 521.00 0.9996505 1846.076 1943.944
#>  6:  2.9652 446.00 456.00 1.0007271 1972.206 1872.466
#>  7:  4.4478 417.00 430.00 1.0007874 1663.478 1814.270
#>  8:  4.4478 328.00 341.00 0.9997741 1791.221 1947.035
#>  9:  2.9652 207.00 217.00 1.0013510 1974.714 1732.971
#> 10:  4.4478 416.95 431.00 1.0000087 1541.149 1883.132
#> 11:  7.4130 553.00 576.00 1.0009724 1688.602 1811.652
#> 12:  7.4130 496.00 520.00 1.0002539 2163.127 2058.544
#> 13:  7.4130 467.00 492.00 0.9994651 2118.903 1915.943
#> 14:  8.8956 467.00 498.00 0.9996567 1928.605 1865.422
#> 15:  7.4130 336.00 363.00 1.0009321 2004.644 1678.558
#> 16:  5.9304 206.00 227.00 1.0005243 2121.367 1977.602
#> 17:  8.8956 426.00 456.00 0.9997277 2089.715 1835.294
#> 18: 13.3434 579.00 625.00 1.0004889 2035.469 1917.989
#> 19: 13.3434 496.00 543.00 1.0003562 2094.522 1987.369
#> 20: 16.3086 467.00 516.00 1.0002750 2066.929 1825.524
#> 21: 17.7912 455.00 516.00 1.0026167 2077.616 1893.522
#> 22: 16.3086 309.00 361.00 0.9996277 2249.448 2022.962
#> 23: 11.8608 193.00 233.00 0.9997477 2089.114 1958.539
#> 24: 17.7912 402.00 461.00 1.0009739 2395.142 1939.378
#> 25: 23.7216 422.00 501.00 1.0033148 2219.340 1830.752
#> 26: 31.1346 436.00 543.05 1.0029336 2528.973 1924.160
#> 27: 37.0650 367.00 488.00 1.0012985 1837.448 1906.721
#> 28: 50.4084 354.00 530.00 0.9998739 2567.897 1800.778
#> 29: 66.7170 301.95 526.00 1.0005864 2703.717 1948.242
#> 30: 81.5430 196.00 467.05 1.0000453 2744.299 1885.458
#>         mad     q5    q95      rhat ess_bulk ess_tail
```

Plot the summarised nowcast against currently observed data (or
optionally more recent data for comparison purposes).

``` r
plot(nowcast, obs = latest_germany_hosp)
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
note that `{epinowcast}` allows users to pass in their own models
meaning that alternative parameterisations, for example altering the
forecast model used for inferring expected observations, may be easily
tested using the package infrastructure. Once this testing has been done
alterations that increase the flexibility of the package model and
improves its defaults are very welcome.

## Code of Conduct

Please note that the `forecast.vocs` project is released with a
[Contributor Code of
Conduct](https://epiforecasts.io/epinowcast/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
