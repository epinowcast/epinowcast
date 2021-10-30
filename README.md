
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Nowcast right censored epidemological counts

[![R-CMD-check](https://github.com/seabbs/epinowcast/workflows/R-CMD-check/badge.svg)](https://github.com/seabbs/epinowcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/seabbs/epinowcast/branch/main/graph/badge.svg)](https://app.codecov.io/gh/seabbs/epinowcast)

[![GitHub
contributors](https://img.shields.io/github/contributors/seabbs/epinowcast)](https://github.com/seabbs/epinowcast/graphs/contributors)

This package contains tools to enable flexible and efficient nowcasting
of right censored epidemiological counts using a semi-mechanistic method
with adjustment available for both day of reference and day of report
effects.

## Installation

### Installing the package

Install the unstable development from GitHub using the following,

``` r
remotes::install_github("seabbs/epinowcast", dependencies = TRUE)
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

### Example data

``` r
library(epinowcast)

national_germany_hosp <- germany_covid19_hosp
national_germany_hosp <- national_germany_hosp[location == "DE"]
national_germany_hosp <- national_germany_hosp[age_group %in% "00+"]

nat_germany_30_days_ago <-
  national_germany_hosp[report_date <= max(report_date) - 30]
nat_germany_30_days_ago <-
  nat_germany_30_days_ago[reference_date >= (max(reference_date) - 30)]
nat_germany_30_days_ago[]
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
latest_germany_hosp <- national_germany_hosp[report_date == max(report_date)]

latest_germany_hosp <-
  latest_germany_hosp[reference_date >= (max(reference_date) - 60)]
latest_germany_hosp <-
  latest_germany_hosp[reference_date <= (max(reference_date) - 30)]
latest_germany_hosp[]
#>     reference_date location age_group confirm report_date
#>  1:     2021-09-20       DE       00+     146  2021-10-20
#>  2:     2021-09-19       DE       00+     275  2021-10-20
#>  3:     2021-09-18       DE       00+     385  2021-10-20
#>  4:     2021-09-17       DE       00+     412  2021-10-20
#>  5:     2021-09-16       DE       00+     481  2021-10-20
#>  6:     2021-09-15       DE       00+     515  2021-10-20
#>  7:     2021-09-14       DE       00+     431  2021-10-20
#>  8:     2021-09-13       DE       00+     204  2021-10-20
#>  9:     2021-09-12       DE       00+     330  2021-10-20
#> 10:     2021-09-11       DE       00+     482  2021-10-20
#> 11:     2021-09-10       DE       00+     515  2021-10-20
#> 12:     2021-09-09       DE       00+     540  2021-10-20
#> 13:     2021-09-08       DE       00+     615  2021-10-20
#> 14:     2021-09-07       DE       00+     455  2021-10-20
#> 15:     2021-09-06       DE       00+     214  2021-10-20
#> 16:     2021-09-05       DE       00+     360  2021-10-20
#> 17:     2021-09-04       DE       00+     484  2021-10-20
#> 18:     2021-09-03       DE       00+     501  2021-10-20
#> 19:     2021-09-02       DE       00+     541  2021-10-20
#> 20:     2021-09-01       DE       00+     628  2021-10-20
#> 21:     2021-08-31       DE       00+     445  2021-10-20
#> 22:     2021-08-30       DE       00+     227  2021-10-20
#> 23:     2021-08-29       DE       00+     374  2021-10-20
#> 24:     2021-08-28       DE       00+     464  2021-10-20
#> 25:     2021-08-27       DE       00+     479  2021-10-20
#> 26:     2021-08-26       DE       00+     543  2021-10-20
#> 27:     2021-08-25       DE       00+     592  2021-10-20
#> 28:     2021-08-24       DE       00+     468  2021-10-20
#> 29:     2021-08-23       DE       00+     206  2021-10-20
#> 30:     2021-08-22       DE       00+     267  2021-10-20
#> 31:     2021-08-21       DE       00+     345  2021-10-20
#>     reference_date location age_group confirm report_date
```

### Data preprocessing and model specification

Process reported data into format required for `{epinowcast}` and return
in a `{data.table}`. At this stage specify grouping (i.e age, location)
if any.

``` r
pobs <- enw_preprocess_data(nat_germany_30_days_ago, max_delay = 30)
pobs
#>                    obs         new_confirm             latest
#> 1: <data.table[495x6]> <data.table[495x8]> <data.table[31x5]>
#>                   diff  reporting_triangle      metareference
#> 1: <data.table[495x8]> <data.table[31x32]> <data.table[31x4]>
#>            metareport time snapshots groups max_delay   max_date
#> 1: <data.table[60x5]>   31        31      1        30 2021-09-20
```

Construct an intercept only model for the date of reference.

``` r
reference_effects <- enw_intercept_model(pobs$metareference[[1]])
reference_effects
#> $fixed
#> $fixed$design
#>   (Intercept)
#> 1           1
#> 
#> $fixed$index
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
#> 
#> 
#> $random
#> $random$design
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $random$index
#> integer(0)
```

Construct a model with a random effect for the day of report.

``` r
report_effects <- enw_day_of_week_model(pobs$metareport[[1]])
report_effects
#> $fixed
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
#> $random$design
#>   fixed sd
#> 1     0  1
#> 2     0  1
#> 3     0  1
#> 4     0  1
#> 5     0  1
#> 6     0  1
#> 7     0  1
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
#> Chain 1 finished in 54.3 seconds.
#> Chain 2 finished in 55.3 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 54.8 seconds.
#> Total execution time: 55.4 seconds.
```

### Results

Print the output from `{epinowcast}` which includes diagnostic
information, the data used for fitting, and the `{cmdstanr`} object.

``` r
nowcast
#>                    obs         new_confirm             latest
#> 1: <data.table[495x6]> <data.table[495x8]> <data.table[31x5]>
#>                   diff  reporting_triangle      metareference
#> 1: <data.table[495x8]> <data.table[31x32]> <data.table[31x4]>
#>            metareport time snapshots groups max_delay   max_date
#> 1: <data.table[60x5]>   31        31      1        30 2021-09-20
#>                  fit       data  fit_args samples max_rhat
#> 1: <CmdStanMCMC[31]> <list[29]> <list[6]>    2000     1.01
#>    divergent_transitions per_divergent_transitions max_treedepth
#> 1:                     0                         0             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                1594                0.797 55.4
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date group location age_group confirm     mean median         sd
#>  1:     2021-08-22     1       DE       00+     239 239.0000    239  0.0000000
#>  2:     2021-08-23     1       DE       00+     186 186.5945    186  0.8132653
#>  3:     2021-08-24     1       DE       00+     437 439.1110    439  1.6208000
#>  4:     2021-08-25     1       DE       00+     539 543.8165    544  2.4955844
#>  5:     2021-08-26     1       DE       00+     509 515.9255    516  3.0314262
#>  6:     2021-08-27     1       DE       00+     442 450.4530    450  3.3520754
#>  7:     2021-08-28     1       DE       00+     412 422.7570    422  3.8971201
#>  8:     2021-08-29     1       DE       00+     322 334.0335    334  4.0547007
#>  9:     2021-08-30     1       DE       00+     204 212.0575    212  3.1180210
#> 10:     2021-08-31     1       DE       00+     409 423.3435    423  4.4768883
#> 11:     2021-09-01     1       DE       00+     535 563.4710    563  6.8376557
#> 12:     2021-09-02     1       DE       00+     475 507.0325    507  7.1272605
#> 13:     2021-09-03     1       DE       00+     444 479.2375    479  7.8459463
#> 14:     2021-09-04     1       DE       00+     437 481.9785    481  9.2393572
#> 15:     2021-09-05     1       DE       00+     310 348.5690    348  8.0037034
#> 16:     2021-09-06     1       DE       00+     190 215.5190    215  6.1416202
#> 17:     2021-09-07     1       DE       00+     395 440.2630    440  9.0525027
#> 18:     2021-09-08     1       DE       00+     518 600.5440    600 13.5078235
#> 19:     2021-09-09     1       DE       00+     433 518.4255    517 14.2038841
#> 20:     2021-09-10     1       DE       00+     395 489.5780    489 15.5306638
#> 21:     2021-09-11     1       DE       00+     365 483.3180    482 18.2377406
#> 22:     2021-09-12     1       DE       00+     239 333.3285    333 15.3855759
#> 23:     2021-09-13     1       DE       00+     147 212.1635    211 12.4643671
#> 24:     2021-09-14     1       DE       00+     324 429.9395    429 17.7580831
#> 25:     2021-09-15     1       DE       00+     313 458.8445    458 23.3267312
#> 26:     2021-09-16     1       DE       00+     289 487.4470    485 31.4180798
#> 27:     2021-09-17     1       DE       00+     203 423.1965    420 37.7128628
#> 28:     2021-09-18     1       DE       00+     144 435.1970    430 52.6164559
#> 29:     2021-09-19     1       DE       00+      73 402.5545    396 67.6122603
#> 30:     2021-09-20     1       DE       00+      23 319.5885    307 86.6744160
#>     reference_date group location age_group confirm     mean median         sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 0.9993352 1907.339 1848.293
#>  3:  1.4826 437.00 442.00 1.0004761 1934.512 1780.309
#>  4:  2.9652 540.00 548.00 0.9999210 2054.888 2021.513
#>  5:  2.9652 512.00 521.00 0.9999460 1913.582 1781.123
#>  6:  2.9652 445.00 457.00 1.0006570 2008.863 1960.766
#>  7:  4.4478 417.00 430.00 0.9995221 2087.169 2048.988
#>  8:  4.4478 328.00 341.00 1.0005721 2043.544 1895.895
#>  9:  2.9652 207.00 218.00 1.0007575 1922.449 1741.675
#> 10:  4.4478 417.00 431.00 0.9997743 1952.123 1909.372
#> 11:  7.4130 553.00 575.00 0.9999110 1807.538 1832.177
#> 12:  7.4130 496.00 520.00 1.0006397 2001.027 1661.260
#> 13:  7.4130 467.00 492.00 1.0032509 2001.059 1476.787
#> 14:  8.8956 468.00 498.00 1.0002402 2097.893 1608.648
#> 15:  7.4130 336.00 362.00 0.9998575 2115.660 1759.218
#> 16:  5.9304 206.00 226.00 1.0002556 2048.575 2016.486
#> 17:  8.8956 426.00 456.00 1.0006617 2205.876 1985.698
#> 18: 13.3434 580.00 624.05 1.0002983 2100.999 1996.207
#> 19: 14.8260 496.95 543.00 0.9999375 2253.352 1954.974
#> 20: 15.5673 466.00 517.00 0.9996898 2239.101 2015.250
#> 21: 17.7912 455.00 515.00 1.0010747 2358.748 1884.208
#> 22: 14.8260 309.00 360.05 1.0007746 2252.954 1818.850
#> 23: 11.8608 194.00 235.00 0.9994657 2254.843 1938.465
#> 24: 17.7912 403.00 460.05 0.9996863 2229.229 1808.741
#> 25: 23.7216 422.00 499.00 1.0001601 2325.593 1958.476
#> 26: 31.1346 441.00 542.00 0.9998120 2348.327 1730.851
#> 27: 37.0650 367.00 491.00 1.0000192 2677.325 1890.643
#> 28: 48.9258 360.00 527.05 1.0007903 2186.342 1939.236
#> 29: 66.7170 305.95 520.05 1.0006316 2304.264 1871.054
#> 30: 81.5430 199.00 489.05 1.0004510 2709.136 1480.763
#>         mad     q5    q95      rhat ess_bulk ess_tail
```

Plot the summarised nowcast against currently observed data (or
optionally more recent data for comparison purposes).

``` r
plot(nowcast, obs = latest_germany_hosp)
```

<img src="man/figures/README-unnamed-chunk-13-1.png" width="100%" />

Plot posterior predictions for observed notifications by date of report
as a check of how well the model reproduces the observed data.

``` r
library(ggplot2)

plot(nowcast, type = "posterior") +
  facet_wrap(vars(reference_date), scales = "free")
```

<img src="man/figures/README-unnamed-chunk-14-1.png" width="100%" />

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
[issue](https://github.com/seabbs/epinowcast/issues). If you have a
question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/seabbs/epinowcast/discussions/categories/q-a).

## Contributing

We welcome contributions and new contributors\! We particularly
appreciate help on priority problems in the
[issues](https://github.com/seabbs/epinowcast/issues). Please check and
add to the issues, and/or add a [pull
request](https://github.com/seabbs/epinowcast/pulls).

## Code of Conduct

Please note that the `forecast.vocs` project is released with a
[Contributor Code of
Conduct](samabbott.co.uk/epinowcast/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
