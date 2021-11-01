
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

[![DOI](https://zenodo.org/badge/383161374.svg)](https://zenodo.org/badge/latestdoi/383161374)

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
#> <environment: 0x55bc3ecab730>
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
#> <environment: 0x55bc3ecab730>
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
#> <environment: 0x55bc3f130160>
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
#> <environment: 0x55bc3f130160>
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
#> Init values were only set for a subset of parameters. 
#> Missing init values for the following parameters:
#>  - chain 1: logmean_eff, logsd_eff, logmean_sd, logsd_sd
#>  - chain 2: logmean_eff, logsd_eff, logmean_sd, logsd_sd
#> Running MCMC with 2 parallel chains, with 2 thread(s) per chain...
#> 
#> Chain 1 finished in 43.1 seconds.
#> Chain 2 finished in 44.5 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 43.8 seconds.
#> Total execution time: 44.7 seconds.
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
#> 1:                1488                0.744 44.7
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median         sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000  239.0  0.0000000
#>  2:     2021-08-23       DE       00+     186     1 186.6080  186.0  0.8195559
#>  3:     2021-08-24       DE       00+     437     1 439.1020  439.0  1.6495322
#>  4:     2021-08-25       DE       00+     539     1 543.8330  544.0  2.5312674
#>  5:     2021-08-26       DE       00+     509     1 515.8580  516.0  2.9302097
#>  6:     2021-08-27       DE       00+     442     1 450.4660  450.0  3.4855299
#>  7:     2021-08-28       DE       00+     412     1 422.8265  423.0  3.8086284
#>  8:     2021-08-29       DE       00+     322     1 334.0265  334.0  3.9635404
#>  9:     2021-08-30       DE       00+     204     1 212.0120  212.0  3.1468726
#> 10:     2021-08-31       DE       00+     409     1 423.2845  423.0  4.4043455
#> 11:     2021-09-01       DE       00+     535     1 563.6500  563.0  6.8953080
#> 12:     2021-09-02       DE       00+     475     1 507.2705  507.0  7.4578911
#> 13:     2021-09-03       DE       00+     444     1 479.1530  479.0  7.9396543
#> 14:     2021-09-04       DE       00+     437     1 482.5560  482.0  9.0965509
#> 15:     2021-09-05       DE       00+     310     1 348.7585  348.0  8.0873284
#> 16:     2021-09-06       DE       00+     190     1 215.7615  215.0  6.3286368
#> 17:     2021-09-07       DE       00+     395     1 440.7510  440.0  8.9754263
#> 18:     2021-09-08       DE       00+     518     1 600.6365  600.0 13.6573288
#> 19:     2021-09-09       DE       00+     433     1 519.0625  518.0 14.1073067
#> 20:     2021-09-10       DE       00+     395     1 489.3310  489.0 14.8313325
#> 21:     2021-09-11       DE       00+     365     1 482.7250  482.0 17.7772999
#> 22:     2021-09-12       DE       00+     239     1 332.3020  332.0 15.6997464
#> 23:     2021-09-13       DE       00+     147     1 211.6355  211.0 12.2738325
#> 24:     2021-09-14       DE       00+     324     1 429.2635  428.0 17.8249806
#> 25:     2021-09-15       DE       00+     313     1 458.5830  457.0 24.1710205
#> 26:     2021-09-16       DE       00+     289     1 488.7820  487.0 31.9001612
#> 27:     2021-09-17       DE       00+     203     1 422.0715  419.0 37.2785090
#> 28:     2021-09-18       DE       00+     144     1 433.8435  429.0 51.2569570
#> 29:     2021-09-19       DE       00+      73     1 399.0130  391.5 65.9736090
#> 30:     2021-09-20       DE       00+      23     1 318.7735  306.0 87.7520792
#>     reference_date location age_group confirm group     mean median         sd
#>         mad     q5 q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239        NA       NA       NA
#>  2:  0.0000 186.00 188 0.9990975 1965.192 1975.537
#>  3:  1.4826 437.00 442 1.0000772 2069.327 1737.578
#>  4:  2.9652 540.00 549 1.0000793 2105.173 2098.975
#>  5:  2.9652 511.00 521 1.0000839 2113.507 1931.984
#>  6:  2.9652 445.00 457 1.0017854 2070.163 1756.567
#>  7:  4.4478 417.00 430 1.0017153 1694.227 1799.060
#>  8:  4.4478 328.00 341 0.9994905 2093.416 1971.078
#>  9:  2.9652 207.00 218 0.9994493 1983.189 2001.636
#> 10:  4.4478 417.00 431 1.0001907 2040.407 1948.096
#> 11:  7.4130 553.00 575 0.9999953 2189.043 1944.247
#> 12:  7.4130 496.00 520 1.0005186 2097.713 1948.748
#> 13:  7.4130 467.00 493 1.0003409 1746.778 1973.922
#> 14:  8.8956 469.00 498 1.0011602 2311.749 2135.581
#> 15:  7.4130 336.00 363 0.9996955 2204.485 1855.251
#> 16:  5.9304 206.00 227 0.9997457 2015.056 1819.456
#> 17:  8.8956 427.00 456 1.0001145 1800.797 1869.738
#> 18: 13.3434 579.00 624 1.0001635 1970.645 1968.117
#> 19: 13.3434 496.00 543 0.9997544 2348.841 1925.770
#> 20: 14.8260 466.00 515 1.0016535 1987.567 1757.157
#> 21: 16.3086 455.95 513 1.0008614 1986.171 1901.816
#> 22: 14.8260 308.00 359 0.9994887 2438.591 2103.513
#> 23: 12.6021 192.95 233 1.0005399 2168.438 1603.368
#> 24: 17.7912 401.00 460 0.9996405 2483.851 1624.099
#> 25: 23.7216 422.95 501 1.0014339 2302.898 1841.903
#> 26: 31.1346 439.95 545 1.0002719 2388.017 1957.364
#> 27: 35.5824 365.95 488 1.0015594 2199.261 1883.136
#> 28: 50.4084 357.00 526 1.0006532 2365.534 1910.065
#> 29: 63.0105 305.00 517 0.9997679 2589.797 1973.500
#> 30: 79.3191 199.95 483 1.0006786 2383.771 1742.966
#>         mad     q5 q95      rhat ess_bulk ess_tail
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
    #>   count data,
    #> 
    #> A BibTeX entry for LaTeX users is
    #> 
    #>   @Article{,
    #>     title = {epinowcast: Nowcast right censored epidemiological count data},
    #>     author = {Sam Abbott},
    #>     journal = {Zenodo},
    #>     year = {2021},
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
