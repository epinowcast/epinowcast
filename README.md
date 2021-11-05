
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

This package contains tools to enable flexible and efficient hierarchical
nowcasting of right censored epidemiological counts using a semi-mechanistic
Bayesian method with support for both day of reference and day of report 
effects. Nowcasting in this context is the estimation of the total 
notifications (for example hospitalisations or deaths) that will be reported 
for a given date based on those currently reported and the pattern of 
reporting for previous days. This can be useful when tracking the spread of
infectious disease in real-time as otherwise changes in trends can be 
obfuscated by partial reporting or their detection may be delayed due to the 
use of simpler methods like truncation

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

Nowcasting is effectively the estimation of reporting patterns for recently reported data. This requires data on these patterns for previous observations and typically this means the time series of data as reported on multiple consecutive days (in theory non-consecutive days could be used but this is not yet supported in `epinowcast`). For this quick start these data are sourced from the [Robert Koch Institute via the Germany Nowcasting hub](https://github.com/KITmetricslab/hospitalization-nowcast-hub/wiki/Truth-data#role-an-definition-of-the-seven-day-hospitalization-incidence) where they are deconvolved from weekly data and days with negative reported hospitalisations are adjusted. 

Below we first filter for a snapshot of retrospective data available 30 days
before the 1st of October that contains 30 days of data and then produce the
nowcast target based on the latest available hospitalisations by date of
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
#> <environment: 0x55b26c191540>
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
#> <environment: 0x55b26c191540>
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
#> <environment: 0x55b26c5ded10>
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
#> <environment: 0x55b26c5ded10>
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
#> Chain 2 finished in 40.3 seconds.
#> Chain 1 finished in 43.1 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 41.7 seconds.
#> Total execution time: 43.2 seconds.
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
#> 1:                     2                     0.001             8
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                   1                5e-04 43.2
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median         sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000    239  0.0000000
#>  2:     2021-08-23       DE       00+     186     1 186.5660    186  0.7732677
#>  3:     2021-08-24       DE       00+     437     1 439.0325    439  1.5230245
#>  4:     2021-08-25       DE       00+     539     1 543.5730    543  2.4740112
#>  5:     2021-08-26       DE       00+     509     1 515.6230    515  3.0501677
#>  6:     2021-08-27       DE       00+     442     1 450.0520    450  3.1510729
#>  7:     2021-08-28       DE       00+     412     1 422.4130    422  3.7503951
#>  8:     2021-08-29       DE       00+     322     1 333.4830    333  4.0102060
#>  9:     2021-08-30       DE       00+     204     1 211.8800    212  3.1106974
#> 10:     2021-08-31       DE       00+     409     1 422.8800    423  4.2562493
#> 11:     2021-09-01       DE       00+     535     1 563.0145    563  6.6617174
#> 12:     2021-09-02       DE       00+     475     1 506.4800    506  6.8737344
#> 13:     2021-09-03       DE       00+     444     1 478.3965    478  7.5881538
#> 14:     2021-09-04       DE       00+     437     1 481.2315    481  8.7814272
#> 15:     2021-09-05       DE       00+     310     1 348.5960    348  8.1660349
#> 16:     2021-09-06       DE       00+     190     1 215.5430    215  6.1040790
#> 17:     2021-09-07       DE       00+     395     1 440.0695    440  8.9184325
#> 18:     2021-09-08       DE       00+     518     1 600.1070    599 14.0100211
#> 19:     2021-09-09       DE       00+     433     1 519.1130    519 14.2732300
#> 20:     2021-09-10       DE       00+     395     1 489.3685    489 15.3230580
#> 21:     2021-09-11       DE       00+     365     1 483.2405    483 18.3177081
#> 22:     2021-09-12       DE       00+     239     1 333.2770    332 15.8973468
#> 23:     2021-09-13       DE       00+     147     1 211.1640    211 12.2330670
#> 24:     2021-09-14       DE       00+     324     1 429.1775    428 17.4264120
#> 25:     2021-09-15       DE       00+     313     1 458.8460    458 23.7055956
#> 26:     2021-09-16       DE       00+     289     1 489.7240    488 32.5744128
#> 27:     2021-09-17       DE       00+     203     1 423.2580    421 37.5531564
#> 28:     2021-09-18       DE       00+     144     1 435.5435    431 53.4834586
#> 29:     2021-09-19       DE       00+      73     1 402.7460    396 70.2192912
#> 30:     2021-09-20       DE       00+      23     1 319.0340    308 88.5575353
#>     reference_date location age_group confirm group     mean median         sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 0.9990625 1983.222 1932.987
#>  3:  1.4826 437.00 442.00 1.0019935 2061.197 1895.605
#>  4:  2.9652 540.00 548.00 1.0001972 1694.254 1891.985
#>  5:  2.9652 511.00 521.00 0.9993671 1925.486 1723.477
#>  6:  2.9652 445.00 456.00 1.0025830 2023.347 1900.884
#>  7:  4.4478 417.00 429.00 1.0014112 1876.616 1856.513
#>  8:  4.4478 327.95 340.00 0.9999912 2038.197 1863.663
#>  9:  2.9652 207.00 217.00 1.0010224 2119.589 1971.781
#> 10:  4.4478 416.00 431.00 0.9997785 1977.020 1916.568
#> 11:  7.4130 552.95 574.00 1.0009141 1978.569 1276.811
#> 12:  7.4130 496.00 518.00 1.0034383 2045.919 1821.781
#> 13:  7.4130 467.00 492.00 0.9996717 1958.348 2054.393
#> 14:  8.8956 468.00 496.00 1.0006214 2091.167 1842.239
#> 15:  8.8956 336.00 363.00 1.0003729 1980.275 1931.249
#> 16:  5.9304 206.00 226.00 0.9998994 2061.591 1961.376
#> 17:  8.8956 426.00 456.00 0.9995559 2272.028 1859.089
#> 18: 13.3434 578.00 625.00 1.0002189 2201.121 2040.215
#> 19: 14.8260 497.00 544.00 1.0003311 2308.041 2143.145
#> 20: 14.8260 466.00 517.00 1.0002667 1978.913 1931.530
#> 21: 17.7912 455.00 514.00 0.9998524 2174.531 2018.026
#> 22: 14.8260 309.00 360.00 1.0009593 2115.872 1892.487
#> 23: 11.8608 192.00 232.00 1.0035928 2382.788 2021.230
#> 24: 16.3086 403.00 460.00 0.9998388 2020.999 1917.735
#> 25: 23.7216 423.00 500.05 1.0001102 2193.395 1930.911
#> 26: 32.6172 439.00 547.00 1.0028249 2473.968 1632.143
#> 27: 37.0650 365.00 489.00 0.9995178 2364.990 1901.595
#> 28: 51.8910 355.00 529.00 1.0005309 2218.930 1960.916
#> 29: 66.7170 300.00 528.00 0.9996431 2808.996 1981.343
#> 30: 83.0256 196.00 479.05 1.0001109 2597.594 2011.590
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

If using `epinowcast` in your work please consider citing it using the
following,

    #> 
    #> To cite epinowcast in publications use:
    #> 
    #>   Sam Abbott (2021). epinowcast: Hierarchical nowcasting of right
    #>   censored epidemological counts, DOI: 10.5281/zenodo.5637165
    #> 
    #> A BibTeX entry for LaTeX users is
    #> 
    #>   @Article{,
    #>     title = {epinowcast: Hierarchical nowcasting of right censored epidemological counts},
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
