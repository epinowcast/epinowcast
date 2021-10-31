
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
library(ggplot2)

nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]

retro_nat_germany <- enw_retrospective_data(
  nat_germany_hosp, rep_days =  30, ref_days = 30
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

Process reported data into format required for `{epinowcast}` and return
in a `{data.table}`. At this stage specify grouping (i.e age, location)
if any.

``` r
pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 30)
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
#> Chain 2 finished in 82.0 seconds.
#> Chain 1 finished in 84.7 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 83.3 seconds.
#> Total execution time: 84.8 seconds.
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
#> 1:                1515               0.7575 84.8
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median         sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000    239  0.0000000
#>  2:     2021-08-23       DE       00+     186     1 186.6365    186  0.8460057
#>  3:     2021-08-24       DE       00+     437     1 439.0780    439  1.5865606
#>  4:     2021-08-25       DE       00+     539     1 543.8040    544  2.4834790
#>  5:     2021-08-26       DE       00+     509     1 515.8065    516  3.0515101
#>  6:     2021-08-27       DE       00+     442     1 450.4380    450  3.2809356
#>  7:     2021-08-28       DE       00+     412     1 422.7545    423  3.7980841
#>  8:     2021-08-29       DE       00+     322     1 333.8730    334  3.9467277
#>  9:     2021-08-30       DE       00+     204     1 212.0910    212  3.1148949
#> 10:     2021-08-31       DE       00+     409     1 423.3965    423  4.4284414
#> 11:     2021-09-01       DE       00+     535     1 563.3640    563  6.8705972
#> 12:     2021-09-02       DE       00+     475     1 507.1340    507  7.4110395
#> 13:     2021-09-03       DE       00+     444     1 479.3040    479  7.8302772
#> 14:     2021-09-04       DE       00+     437     1 482.3390    482  8.8997574
#> 15:     2021-09-05       DE       00+     310     1 348.8320    349  8.0853239
#> 16:     2021-09-06       DE       00+     190     1 215.4730    215  6.2680073
#> 17:     2021-09-07       DE       00+     395     1 440.4685    440  8.9875690
#> 18:     2021-09-08       DE       00+     518     1 600.7075    600 14.0942282
#> 19:     2021-09-09       DE       00+     433     1 519.4390    519 14.0587020
#> 20:     2021-09-10       DE       00+     395     1 489.3385    489 14.7757599
#> 21:     2021-09-11       DE       00+     365     1 482.7800    482 18.6924130
#> 22:     2021-09-12       DE       00+     239     1 332.6310    332 15.0899202
#> 23:     2021-09-13       DE       00+     147     1 211.0235    210 12.2191899
#> 24:     2021-09-14       DE       00+     324     1 429.4355    428 17.2896011
#> 25:     2021-09-15       DE       00+     313     1 458.7630    457 23.0672903
#> 26:     2021-09-16       DE       00+     289     1 488.3065    485 32.7666352
#> 27:     2021-09-17       DE       00+     203     1 421.8185    420 36.7234648
#> 28:     2021-09-18       DE       00+     144     1 435.0210    430 53.8122332
#> 29:     2021-09-19       DE       00+      73     1 401.9055    395 68.4447727
#> 30:     2021-09-20       DE       00+      23     1 319.3735    307 89.0795632
#>     reference_date location age_group confirm group     mean median         sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 0.9994739 1953.630 1992.552
#>  3:  1.4826 437.00 442.00 0.9995540 1943.014 1984.116
#>  4:  2.9652 540.00 548.05 1.0027322 2045.463 1976.516
#>  5:  2.9652 511.00 521.00 1.0002531 1930.689 1941.193
#>  6:  2.9652 446.00 456.00 1.0005232 1824.885 1915.907
#>  7:  4.4478 417.00 429.00 1.0015534 1914.670 1730.440
#>  8:  4.4478 328.00 341.00 1.0003851 1824.339 1902.753
#>  9:  2.9652 207.00 217.00 1.0014209 2105.205 1893.988
#> 10:  4.4478 417.00 431.00 1.0009077 2050.713 1847.547
#> 11:  7.4130 553.00 576.00 1.0013102 1742.085 1892.192
#> 12:  7.4130 496.00 520.00 1.0002486 1753.861 1875.811
#> 13:  7.4130 467.00 492.00 0.9996270 2072.838 1813.302
#> 14:  8.8956 469.00 497.00 1.0001562 2086.323 1968.485
#> 15:  8.8956 336.00 362.00 0.9998721 1969.801 2025.558
#> 16:  5.9304 206.00 227.00 1.0006008 2057.989 1966.465
#> 17:  8.8956 426.00 456.00 0.9990911 2242.328 2004.006
#> 18: 13.3434 579.00 625.00 0.9995067 2406.901 1842.878
#> 19: 14.8260 498.00 544.00 1.0005682 2048.625 1677.032
#> 20: 14.8260 466.00 515.00 1.0009362 2336.735 2025.170
#> 21: 19.2738 454.00 515.00 1.0006068 2396.571 2008.264
#> 22: 14.8260 309.00 357.00 1.0000166 2307.431 1998.644
#> 23: 11.8608 192.00 233.00 1.0011354 1987.303 1676.124
#> 24: 17.7912 403.00 459.00 1.0000771 2365.686 1970.855
#> 25: 22.2390 424.00 500.00 1.0014952 2261.604 2032.798
#> 26: 31.1346 439.00 546.00 1.0003172 2106.757 1912.489
#> 27: 35.5824 365.00 486.00 0.9999009 2496.935 1676.701
#> 28: 53.3736 356.00 531.05 0.9993539 2128.773 1666.396
#> 29: 66.7170 299.95 527.00 1.0003235 2748.170 1826.230
#> 30: 83.0256 199.00 480.05 1.0000735 2959.971 1895.663
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
plot(nowcast, type = "posterior") +
  facet_wrap(vars(reference_date), scale = "free")
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
