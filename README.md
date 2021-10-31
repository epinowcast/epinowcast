
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

Process reported data into format required for `{epinowcast}` and return
in a `{data.table}`. At this stage specify grouping (i.e age, location)
if any.

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

Construct an intercept only model for the date of reference.

``` r
reference_effects <- enw_formula(pobs$metareference[[1]])
reference_effects
#> $fixed
#> $fixed$formula
#> ~1
#> <environment: 0x561047ec4840>
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
#> <environment: 0x561047ec4840>
#> 
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
report_effects <- enw_formula(pobs$metareport[[1]], random = "day_of_week")
report_effects
#> $fixed
#> $fixed$formula
#> ~1 + day_of_week
#> <environment: 0x561048388e08>
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
#> <environment: 0x561048388e08>
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
#> Chain 2 finished in 38.8 seconds.
#> Chain 1 finished in 43.2 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 41.0 seconds.
#> Total execution time: 43.3 seconds.
#> 
#> Warning: 3 of 2000 (0.0%) transitions ended with a divergence.
#> This may indicate insufficient exploration of the posterior distribution.
#> Possible remedies include: 
#>   * Increasing adapt_delta closer to 1 (default is 0.8) 
#>   * Reparameterizing the model (e.g. using a non-centered parameterization)
#>   * Using informative or weakly informative prior distributions
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
#> 1: <CmdStanMCMC[31]> <list[29]> <list[6]>    2000        1
#>    divergent_transitions per_divergent_transitions max_treedepth
#> 1:                     3                    0.0015             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                1362                0.681 43.3
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median         sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000    239  0.0000000
#>  2:     2021-08-23       DE       00+     186     1 186.6260    186  0.8726424
#>  3:     2021-08-24       DE       00+     437     1 439.1065    439  1.6091776
#>  4:     2021-08-25       DE       00+     539     1 543.8780    544  2.5227561
#>  5:     2021-08-26       DE       00+     509     1 515.9360    516  3.0140415
#>  6:     2021-08-27       DE       00+     442     1 450.3980    450  3.3322887
#>  7:     2021-08-28       DE       00+     412     1 422.9075    423  3.8654126
#>  8:     2021-08-29       DE       00+     322     1 334.1275    334  4.0494991
#>  9:     2021-08-30       DE       00+     204     1 212.1230    212  3.1920159
#> 10:     2021-08-31       DE       00+     409     1 423.3685    423  4.3758750
#> 11:     2021-09-01       DE       00+     535     1 563.4605    563  6.7061111
#> 12:     2021-09-02       DE       00+     475     1 507.3540    507  7.0896273
#> 13:     2021-09-03       DE       00+     444     1 479.2550    479  7.7375649
#> 14:     2021-09-04       DE       00+     437     1 482.3705    482  9.0368724
#> 15:     2021-09-05       DE       00+     310     1 349.0140    349  8.0547032
#> 16:     2021-09-06       DE       00+     190     1 215.8265    215  6.1638782
#> 17:     2021-09-07       DE       00+     395     1 441.1640    441  9.0128086
#> 18:     2021-09-08       DE       00+     518     1 600.7120    600 13.3192626
#> 19:     2021-09-09       DE       00+     433     1 518.8645    518 13.8561227
#> 20:     2021-09-10       DE       00+     395     1 489.9740    489 14.9070599
#> 21:     2021-09-11       DE       00+     365     1 483.6065    482 18.3943696
#> 22:     2021-09-12       DE       00+     239     1 332.9545    332 15.9132663
#> 23:     2021-09-13       DE       00+     147     1 211.4055    211 12.0760086
#> 24:     2021-09-14       DE       00+     324     1 429.0310    428 17.0280362
#> 25:     2021-09-15       DE       00+     313     1 459.1100    457 23.3456293
#> 26:     2021-09-16       DE       00+     289     1 487.5015    487 31.6275853
#> 27:     2021-09-17       DE       00+     203     1 422.8385    420 37.4457008
#> 28:     2021-09-18       DE       00+     144     1 433.6530    429 51.3574375
#> 29:     2021-09-19       DE       00+      73     1 400.3710    392 68.5680986
#> 30:     2021-09-20       DE       00+      23     1 320.1685    307 91.9644488
#>     reference_date location age_group confirm group     mean median         sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 1.0009272 1872.144 1698.258
#>  3:  1.4826 437.00 442.00 1.0004321 1822.384 1881.145
#>  4:  2.9652 540.00 549.00 1.0011137 1513.479 1810.019
#>  5:  2.9652 511.00 521.00 1.0000054 1904.185 1746.571
#>  6:  2.9652 445.00 456.00 1.0018301 1841.210 1673.566
#>  7:  4.4478 417.00 430.00 0.9995478 1813.758 1740.185
#>  8:  4.4478 328.00 341.00 1.0005024 1985.402 2018.825
#>  9:  2.9652 207.00 218.00 1.0017948 1859.660 1838.306
#> 10:  4.4478 417.00 431.00 1.0006785 1834.301 1581.024
#> 11:  5.9304 553.00 575.00 1.0005054 1884.381 1879.135
#> 12:  7.4130 496.00 520.00 1.0035828 1920.924 1538.182
#> 13:  7.4130 467.00 493.00 0.9995285 2024.989 1939.877
#> 14:  8.8956 469.00 498.00 0.9997716 1962.896 1917.798
#> 15:  8.8956 336.00 363.00 1.0016939 2039.301 1880.041
#> 16:  5.9304 206.00 226.00 1.0008894 1998.962 1934.997
#> 17:  8.8956 427.00 457.00 0.9995223 2195.263 2078.331
#> 18: 13.3434 580.00 623.00 0.9991765 1860.700 1746.090
#> 19: 13.3434 498.00 542.00 0.9997655 2019.555 1999.918
#> 20: 14.8260 468.00 516.00 0.9995966 2178.169 1849.784
#> 21: 17.7912 456.00 515.00 1.0003125 1609.026 1958.458
#> 22: 16.3086 309.00 361.00 1.0008879 2257.794 2025.172
#> 23: 11.8608 192.00 232.00 1.0000377 2104.208 1761.094
#> 24: 16.3086 402.00 458.00 1.0002424 2367.646 2007.068
#> 25: 22.2390 424.00 499.00 1.0000921 2148.723 1757.746
#> 26: 31.1346 438.00 542.00 0.9998799 2721.001 1918.690
#> 27: 37.0650 367.00 488.00 0.9995128 2250.550 1999.755
#> 28: 50.4084 356.95 524.05 1.0009023 1886.011 1899.144
#> 29: 64.4931 302.00 523.00 1.0012538 2250.051 1697.980
#> 30: 84.5082 197.00 483.00 1.0013461 2265.951 1361.083
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
