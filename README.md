
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
national_germany_hosp <-
  national_germany_hosp[reference_date >= (max(reference_date) - 30)]
national_germany_hosp[]
#>      reference_date location age_group confirm report_date
#>   1:     2021-09-20       DE       00+      23  2021-09-20
#>   2:     2021-09-21       DE       00+      93  2021-09-21
#>   3:     2021-09-22       DE       00+     104  2021-09-22
#>   4:     2021-09-23       DE       00+     100  2021-09-23
#>   5:     2021-09-24       DE       00+     110  2021-09-24
#>  ---                                                      
#> 492:     2021-09-21       DE       00+     361  2021-10-19
#> 493:     2021-09-22       DE       00+     447  2021-10-20
#> 494:     2021-09-20       DE       00+     146  2021-10-19
#> 495:     2021-09-21       DE       00+     361  2021-10-20
#> 496:     2021-09-20       DE       00+     146  2021-10-20
```

### Data preprocessing and model specification

Process reported data into format required for `{epinowcast}` and return
in a `{data.table}`. At this stage specify grouping (i.e age, location)
if any.

``` r
pobs <- enw_preprocess_data(national_germany_hosp)
pobs
#>                    obs         new_confirm             latest
#> 1: <data.table[430x6]> <data.table[430x8]> <data.table[31x5]>
#>     reporting_triangle      metareference         metareport time snapshots
#> 1: <data.table[31x22]> <data.table[31x4]> <data.table[50x5]>   31        31
#>    groups max_delay   max_date
#> 1:      1        20 2021-10-20
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
#> 1           1                 0                 1                   0
#> 2           1                 0                 0                   0
#> 3           1                 0                 0                   0
#> 4           1                 0                 0                   0
#> 5           1                 1                 0                   0
#> 6           1                 0                 0                   1
#> 7           1                 0                 0                   0
#>   day_of_weekSunday day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
#> 1                 0                   0                  0                    0
#> 2                 0                   0                  1                    0
#> 3                 0                   0                  0                    1
#> 4                 0                   1                  0                    0
#> 5                 0                   0                  0                    0
#> 6                 0                   0                  0                    0
#> 7                 1                   0                  0                    0
#> 
#> $fixed$index
#>  [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
#> [39] 4 5 6 7 1 2 3 4 5 6 7 1
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

``` r
options(mc.cores = 4)
nowcast <- epinowcast(pobs,
  report_effects = report_effects,
  reference_effects = reference_effects,
  save_warmup = FALSE
)
#> Init values were only set for a subset of parameters. 
#> Missing init values for the following parameters:
#>  - chain 1: leobs_init, leobs_resids, logmean_eff, logsd_eff, logmean_sd, logsd_sd, rd_eff_sd
#>  - chain 2: leobs_init, leobs_resids, logmean_eff, logsd_eff, logmean_sd, logsd_sd, rd_eff_sd
#>  - chain 3: leobs_init, leobs_resids, logmean_eff, logsd_eff, logmean_sd, logsd_sd, rd_eff_sd
#>  - chain 4: leobs_init, leobs_resids, logmean_eff, logsd_eff, logmean_sd, logsd_sd, rd_eff_sd
#> Running MCMC with 4 parallel chains...
#> 
#> Chain 1 Iteration:    1 / 2000 [  0%]  (Warmup)
#> Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 1 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 1
#> Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 1 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 1
#> Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 1 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 1
#> Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 1 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 1
#> Chain 1 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 1 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 1 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 1 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 1
#> Chain 2 Iteration:    1 / 2000 [  0%]  (Warmup)
#> Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 2 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 2
#> Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 2 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 2
#> Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 2 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 2
#> Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 2 Exception: neg_binomial_2_lpmf: Location parameter[1] is nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 2
#> Chain 2 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 2 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 2 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 2 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 2
#> Chain 3 Iteration:    1 / 2000 [  0%]  (Warmup)
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 3 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 3 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 3 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 3 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 3
#> Chain 4 Iteration:    1 / 2000 [  0%]  (Warmup)
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is -nan, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Informational Message: The current Metropolis proposal is about to be rejected because of the following issue:
#> Chain 4 Exception: neg_binomial_2_lpmf: Location parameter[1] is inf, but must be positive finite! (in '/tmp/RtmpBZbrv3/model-1415e42b0239f.stan', line 156, column 6 to column 53)
#> Chain 4 If this warning occurs sporadically, such as for highly constrained variable types like covariance matrices, then the sampler is fine,
#> Chain 4 but if this warning occurs often then your model may be either severely ill-conditioned or misspecified.
#> Chain 4
#> Chain 4 Iteration:  100 / 2000 [  5%]  (Warmup) 
#> Chain 3 Iteration:  100 / 2000 [  5%]  (Warmup) 
#> Chain 2 Iteration:  100 / 2000 [  5%]  (Warmup) 
#> Chain 1 Iteration:  100 / 2000 [  5%]  (Warmup) 
#> Chain 3 Iteration:  200 / 2000 [ 10%]  (Warmup) 
#> Chain 4 Iteration:  200 / 2000 [ 10%]  (Warmup) 
#> Chain 2 Iteration:  200 / 2000 [ 10%]  (Warmup) 
#> Chain 1 Iteration:  200 / 2000 [ 10%]  (Warmup) 
#> Chain 3 Iteration:  300 / 2000 [ 15%]  (Warmup) 
#> Chain 2 Iteration:  300 / 2000 [ 15%]  (Warmup) 
#> Chain 4 Iteration:  300 / 2000 [ 15%]  (Warmup) 
#> Chain 1 Iteration:  300 / 2000 [ 15%]  (Warmup) 
#> Chain 3 Iteration:  400 / 2000 [ 20%]  (Warmup) 
#> Chain 2 Iteration:  400 / 2000 [ 20%]  (Warmup) 
#> Chain 1 Iteration:  400 / 2000 [ 20%]  (Warmup) 
#> Chain 4 Iteration:  400 / 2000 [ 20%]  (Warmup) 
#> Chain 3 Iteration:  500 / 2000 [ 25%]  (Warmup) 
#> Chain 1 Iteration:  500 / 2000 [ 25%]  (Warmup) 
#> Chain 2 Iteration:  500 / 2000 [ 25%]  (Warmup) 
#> Chain 4 Iteration:  500 / 2000 [ 25%]  (Warmup) 
#> Chain 3 Iteration:  600 / 2000 [ 30%]  (Warmup) 
#> Chain 2 Iteration:  600 / 2000 [ 30%]  (Warmup) 
#> Chain 1 Iteration:  600 / 2000 [ 30%]  (Warmup) 
#> Chain 4 Iteration:  600 / 2000 [ 30%]  (Warmup) 
#> Chain 3 Iteration:  700 / 2000 [ 35%]  (Warmup) 
#> Chain 2 Iteration:  700 / 2000 [ 35%]  (Warmup) 
#> Chain 1 Iteration:  700 / 2000 [ 35%]  (Warmup) 
#> Chain 4 Iteration:  700 / 2000 [ 35%]  (Warmup) 
#> Chain 2 Iteration:  800 / 2000 [ 40%]  (Warmup) 
#> Chain 3 Iteration:  800 / 2000 [ 40%]  (Warmup) 
#> Chain 1 Iteration:  800 / 2000 [ 40%]  (Warmup) 
#> Chain 4 Iteration:  800 / 2000 [ 40%]  (Warmup) 
#> Chain 3 Iteration:  900 / 2000 [ 45%]  (Warmup) 
#> Chain 2 Iteration:  900 / 2000 [ 45%]  (Warmup) 
#> Chain 1 Iteration:  900 / 2000 [ 45%]  (Warmup) 
#> Chain 4 Iteration:  900 / 2000 [ 45%]  (Warmup) 
#> Chain 2 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
#> Chain 2 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
#> Chain 3 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
#> Chain 3 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
#> Chain 1 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
#> Chain 1 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
#> Chain 4 Iteration: 1000 / 2000 [ 50%]  (Warmup) 
#> Chain 4 Iteration: 1001 / 2000 [ 50%]  (Sampling) 
#> Chain 3 Iteration: 1100 / 2000 [ 55%]  (Sampling) 
#> Chain 2 Iteration: 1100 / 2000 [ 55%]  (Sampling) 
#> Chain 1 Iteration: 1100 / 2000 [ 55%]  (Sampling) 
#> Chain 4 Iteration: 1100 / 2000 [ 55%]  (Sampling) 
#> Chain 3 Iteration: 1200 / 2000 [ 60%]  (Sampling) 
#> Chain 2 Iteration: 1200 / 2000 [ 60%]  (Sampling) 
#> Chain 1 Iteration: 1200 / 2000 [ 60%]  (Sampling) 
#> Chain 4 Iteration: 1200 / 2000 [ 60%]  (Sampling) 
#> Chain 3 Iteration: 1300 / 2000 [ 65%]  (Sampling) 
#> Chain 2 Iteration: 1300 / 2000 [ 65%]  (Sampling) 
#> Chain 4 Iteration: 1300 / 2000 [ 65%]  (Sampling) 
#> Chain 1 Iteration: 1300 / 2000 [ 65%]  (Sampling) 
#> Chain 3 Iteration: 1400 / 2000 [ 70%]  (Sampling) 
#> Chain 2 Iteration: 1400 / 2000 [ 70%]  (Sampling) 
#> Chain 4 Iteration: 1400 / 2000 [ 70%]  (Sampling) 
#> Chain 1 Iteration: 1400 / 2000 [ 70%]  (Sampling) 
#> Chain 3 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
#> Chain 2 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
#> Chain 4 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
#> Chain 1 Iteration: 1500 / 2000 [ 75%]  (Sampling) 
#> Chain 3 Iteration: 1600 / 2000 [ 80%]  (Sampling) 
#> Chain 2 Iteration: 1600 / 2000 [ 80%]  (Sampling) 
#> Chain 4 Iteration: 1600 / 2000 [ 80%]  (Sampling) 
#> Chain 1 Iteration: 1600 / 2000 [ 80%]  (Sampling) 
#> Chain 3 Iteration: 1700 / 2000 [ 85%]  (Sampling) 
#> Chain 2 Iteration: 1700 / 2000 [ 85%]  (Sampling) 
#> Chain 4 Iteration: 1700 / 2000 [ 85%]  (Sampling) 
#> Chain 1 Iteration: 1700 / 2000 [ 85%]  (Sampling) 
#> Chain 3 Iteration: 1800 / 2000 [ 90%]  (Sampling) 
#> Chain 2 Iteration: 1800 / 2000 [ 90%]  (Sampling) 
#> Chain 4 Iteration: 1800 / 2000 [ 90%]  (Sampling) 
#> Chain 1 Iteration: 1800 / 2000 [ 90%]  (Sampling) 
#> Chain 3 Iteration: 1900 / 2000 [ 95%]  (Sampling) 
#> Chain 2 Iteration: 1900 / 2000 [ 95%]  (Sampling) 
#> Chain 4 Iteration: 1900 / 2000 [ 95%]  (Sampling) 
#> Chain 1 Iteration: 1900 / 2000 [ 95%]  (Sampling) 
#> Chain 3 Iteration: 2000 / 2000 [100%]  (Sampling) 
#> Chain 3 finished in 63.6 seconds.
#> Chain 2 Iteration: 2000 / 2000 [100%]  (Sampling) 
#> Chain 2 finished in 65.7 seconds.
#> Chain 4 Iteration: 2000 / 2000 [100%]  (Sampling) 
#> Chain 4 finished in 65.9 seconds.
#> Chain 1 Iteration: 2000 / 2000 [100%]  (Sampling) 
#> Chain 1 finished in 66.5 seconds.
#> 
#> All 4 chains finished successfully.
#> Mean chain execution time: 65.4 seconds.
#> Total execution time: 66.5 seconds.
```

### Results

Print the output from `{epinowcast}` which includes disagnostic
information, the data used for fitting, and the `{cmdstanr`} object.

``` r
nowcast
#>                    obs         new_confirm             latest
#> 1: <data.table[430x6]> <data.table[430x8]> <data.table[31x5]>
#>     reporting_triangle      metareference         metareport time snapshots
#> 1: <data.table[31x22]> <data.table[31x4]> <data.table[50x5]>   31        31
#>    groups max_delay   max_date               fit       data  fit_args samples
#> 1:      1        20 2021-10-20 <CmdStanMCMC[31]> <list[29]> <list[2]>    4000
#>    max_rhat divergent_transitions per_divergent_transitions max_treedepth
#> 1:        1                     0                         0             7
#>    no_at_max_treedepth per_at_max_treedepth time
#> 1:                3480                 0.87 66.5
```

Summarise the nowcast for the latest snapshot of data.

``` r
summary(nowcast)
#>     reference_date group location age_group confirm     mean median         sd
#>  1:     2021-10-01     1       DE       00+     338 338.0000    338   0.000000
#>  2:     2021-10-02     1       DE       00+     338 340.5255    340   1.800461
#>  3:     2021-10-03     1       DE       00+     235 239.2403    239   2.307024
#>  4:     2021-10-04     1       DE       00+     136 139.6475    139   2.076613
#>  5:     2021-10-05     1       DE       00+     332 340.4115    340   3.395445
#>  6:     2021-10-06     1       DE       00+     403 420.9588    421   5.214244
#>  7:     2021-10-07     1       DE       00+     415 442.8110    442   7.059762
#>  8:     2021-10-08     1       DE       00+     366 397.7928    397   7.460678
#>  9:     2021-10-09     1       DE       00+     376 419.0925    419   9.273535
#> 10:     2021-10-10     1       DE       00+     247 284.1725    284   8.638165
#> 11:     2021-10-11     1       DE       00+     150 176.8850    176   6.694026
#> 12:     2021-10-12     1       DE       00+     381 434.1615    433  10.803059
#> 13:     2021-10-13     1       DE       00+     413 494.2077    493  15.047564
#> 14:     2021-10-14     1       DE       00+     366 463.3250    462  17.570446
#> 15:     2021-10-15     1       DE       00+     324 442.1730    441  21.382689
#> 16:     2021-10-16     1       DE       00+     296 465.8905    463  30.329820
#> 17:     2021-10-17     1       DE       00+     197 382.6760    380  35.440810
#> 18:     2021-10-18     1       DE       00+     142 308.6662    305  36.356544
#> 19:     2021-10-19     1       DE       00+     387 696.8998    690  66.457730
#> 20:     2021-10-20     1       DE       00+     235 675.9540    657 124.695907
#>          mad  q5 q35 q50 q65    q95      rhat ess_bulk ess_tail
#>  1:   0.0000 338 338 338 338 338.00        NA       NA       NA
#>  2:   1.4826 338 340 340 341 344.00 1.0007576 4112.575 3860.078
#>  3:   2.9652 236 238 239 240 243.00 1.0001183 4161.662 4031.131
#>  4:   1.4826 137 139 139 140 143.00 1.0001398 4160.835 4042.333
#>  5:   2.9652 336 339 340 341 347.00 0.9997107 4089.838 4010.814
#>  6:   5.9304 413 419 421 423 430.00 1.0005852 4321.489 3642.098
#>  7:   7.4130 432 440 442 445 455.00 1.0005254 4320.146 3697.494
#>  8:   7.4130 386 395 397 400 411.00 1.0003145 4293.681 4014.148
#>  9:   8.8956 405 415 419 422 435.05 1.0012174 4439.741 3667.735
#> 10:   8.8956 271 280 284 287 299.00 1.0005260 4090.744 3939.093
#> 11:   5.9304 167 174 176 179 189.00 1.0016696 3836.953 3846.048
#> 12:  10.3782 418 430 433 438 453.00 1.0004828 4612.192 3866.978
#> 13:  14.8260 471 487 493 499 521.00 0.9999083 4583.372 3950.712
#> 14:  17.7912 436 456 462 469 494.00 0.9999204 4585.671 3965.722
#> 15:  20.7564 408 433 441 449 479.00 1.0001710 4720.362 3705.322
#> 16:  29.6520 421 453 463 475 521.00 1.0001615 4379.107 3751.099
#> 17:  34.0998 330 367 380 394 445.00 0.9997306 4764.507 3995.185
#> 18:  34.0998 255 292 305 320 374.00 1.0001303 4772.138 3690.794
#> 19:  60.7866 600 666 690 715 817.00 0.9998840 4800.344 3933.971
#> 20: 117.1254 509 615 657 704 913.00 0.9997498 5506.507 3592.240
```

Plot the nowcast against currently observed data (or optionally more
recent data for comparison purposes).

``` r
plot(nowcast)
```

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
