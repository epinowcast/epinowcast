
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
#> <environment: 0x5625f568b708>
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
#> <environment: 0x5625f568b708>
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
#> <environment: 0x5625f5b33998>
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
#> <environment: 0x5625f5b33998>
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
#> Chain 2 finished in 39.7 seconds.
#> Chain 1 finished in 44.3 seconds.
#> 
#> Both chains finished successfully.
#> Mean chain execution time: 42.0 seconds.
#> Total execution time: 44.4 seconds.
#> 
#> Warning: 2 of 2000 (0.0%) transitions ended with a divergence.
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
#> 1: <CmdStanMCMC[31]> <list[29]> <list[6]>    2000     1.01
#>    divergent_transitions per_divergent_transitions max_treedepth
#> 1:                     2                     0.001             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                1343               0.6715 44.4
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast, probs = c(0.05, 0.95))
#>     reference_date location age_group confirm group     mean median        sd
#>  1:     2021-08-22       DE       00+     239     1 239.0000  239.0  0.000000
#>  2:     2021-08-23       DE       00+     186     1 186.5780  186.0  0.810089
#>  3:     2021-08-24       DE       00+     437     1 439.0690  439.0  1.561556
#>  4:     2021-08-25       DE       00+     539     1 543.8370  544.0  2.496908
#>  5:     2021-08-26       DE       00+     509     1 515.9610  516.0  3.068907
#>  6:     2021-08-27       DE       00+     442     1 450.3780  450.0  3.347644
#>  7:     2021-08-28       DE       00+     412     1 423.0330  423.0  3.957492
#>  8:     2021-08-29       DE       00+     322     1 334.1050  334.0  4.069061
#>  9:     2021-08-30       DE       00+     204     1 212.2585  212.0  3.119703
#> 10:     2021-08-31       DE       00+     409     1 423.4865  423.0  4.421492
#> 11:     2021-09-01       DE       00+     535     1 563.3290  563.0  6.735387
#> 12:     2021-09-02       DE       00+     475     1 507.3920  507.0  7.394232
#> 13:     2021-09-03       DE       00+     444     1 479.0700  479.0  7.723466
#> 14:     2021-09-04       DE       00+     437     1 482.3730  482.0  9.349041
#> 15:     2021-09-05       DE       00+     310     1 348.9265  348.0  8.343974
#> 16:     2021-09-06       DE       00+     190     1 215.7060  215.0  6.243401
#> 17:     2021-09-07       DE       00+     395     1 440.4900  440.0  8.908062
#> 18:     2021-09-08       DE       00+     518     1 600.4730  600.0 13.958857
#> 19:     2021-09-09       DE       00+     433     1 519.2540  518.0 14.360069
#> 20:     2021-09-10       DE       00+     395     1 490.3795  489.0 15.318675
#> 21:     2021-09-11       DE       00+     365     1 483.5235  482.0 18.173376
#> 22:     2021-09-12       DE       00+     239     1 332.7235  332.0 15.753607
#> 23:     2021-09-13       DE       00+     147     1 212.1780  211.0 12.492091
#> 24:     2021-09-14       DE       00+     324     1 429.6740  428.0 17.539171
#> 25:     2021-09-15       DE       00+     313     1 458.8870  457.5 24.370108
#> 26:     2021-09-16       DE       00+     289     1 488.0560  485.0 32.030624
#> 27:     2021-09-17       DE       00+     203     1 421.7245  418.0 38.335811
#> 28:     2021-09-18       DE       00+     144     1 434.1210  430.0 51.522205
#> 29:     2021-09-19       DE       00+      73     1 399.5165  393.0 67.440840
#> 30:     2021-09-20       DE       00+      23     1 320.1785  309.0 85.813347
#>     reference_date location age_group confirm group     mean median        sd
#>         mad     q5    q95      rhat ess_bulk ess_tail
#>  1:  0.0000 239.00 239.00        NA       NA       NA
#>  2:  0.0000 186.00 188.00 1.0003284 1953.097 1668.094
#>  3:  1.4826 437.00 442.00 1.0007679 2093.702 1982.020
#>  4:  2.9652 540.00 548.00 1.0007157 1614.838 1841.222
#>  5:  2.9652 512.00 521.00 0.9998563 1892.997 1563.625
#>  6:  2.9652 446.00 456.00 1.0003667 1993.645 1700.705
#>  7:  4.4478 417.00 430.00 0.9991426 1908.143 1932.939
#>  8:  4.4478 328.00 341.00 1.0031046 1977.803 1561.987
#>  9:  2.9652 208.00 218.00 0.9995186 1946.645 1960.047
#> 10:  4.4478 417.00 431.00 0.9998603 2088.743 1964.958
#> 11:  7.4130 553.00 575.00 1.0004101 2086.063 2030.072
#> 12:  7.4130 496.00 520.00 1.0000913 1882.192 2014.923
#> 13:  7.4130 467.00 492.00 1.0003831 2137.728 1937.816
#> 14:  8.8956 468.00 498.05 0.9995531 2158.046 1723.401
#> 15:  8.8956 336.00 363.00 1.0002294 2056.931 2039.161
#> 16:  5.9304 206.00 226.00 1.0000084 2059.226 1920.054
#> 17:  8.8956 427.00 456.00 1.0000765 2381.518 2034.291
#> 18: 13.3434 578.95 625.00 0.9998414 2168.741 1928.875
#> 19: 13.3434 497.00 544.00 0.9999327 2261.149 1713.714
#> 20: 14.8260 467.00 517.00 1.0005783 2163.294 1933.962
#> 21: 17.7912 456.00 515.00 1.0005044 2234.027 2093.044
#> 22: 14.8260 308.00 360.00 1.0000980 2179.070 1937.098
#> 23: 11.8608 193.00 234.00 0.9993477 2144.112 1821.906
#> 24: 17.7912 403.00 460.00 1.0008161 2125.111 1974.652
#> 25: 24.4629 422.00 502.00 0.9993314 2448.007 2013.984
#> 26: 31.1346 440.00 545.00 0.9997037 2030.232 1701.561
#> 27: 35.5824 365.00 488.05 0.9991239 2376.844 1858.843
#> 28: 51.8910 358.00 525.00 1.0001402 2442.796 1885.862
#> 29: 65.2344 301.00 523.05 1.0009464 2155.562 1849.010
#> 30: 80.0604 204.00 477.15 0.9995327 2577.050 1662.108
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
