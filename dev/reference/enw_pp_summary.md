# Posterior predictive summary

This function summarises posterior predictives for observed data (by
report and reference date). The functionality of this function can be
used directly on the output of
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
using the supplied
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)
method.

## Usage

``` r
enw_pp_summary(fit, diff_obs, probs = c(0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95))
```

## Arguments

- fit:

  A `cmdstanr` fit object.

- diff_obs:

  A `data.frame` of observed data with at least a date variable
  `reference_date`, and a grouping variable `.group`.

- probs:

  A vector of numeric probabilities to produce quantile summaries for.
  By default these are the 5%, 20%, 80%, and 95% quantiles which are
  also the minimum set required for plotting functions to work.

## Value

A data.table summarising the posterior predictions.

## See also

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/dev/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/dev/reference/enw_posterior_delay.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
enw_pp_summary(fit$fit[[1]], fit$new_confirm[[1]], probs = c(0.5))
#>      reference_date report_date .group max_confirm location age_group confirm
#>              <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>   1:     2021-07-14  2021-07-14      1          72       DE       00+      22
#>   2:     2021-07-14  2021-07-15      1          72       DE       00+      34
#>   3:     2021-07-14  2021-07-16      1          72       DE       00+      38
#>   4:     2021-07-14  2021-07-17      1          72       DE       00+      43
#>   5:     2021-07-14  2021-07-18      1          72       DE       00+      43
#>  ---                                                                         
#> 606:     2021-08-20  2021-08-21      1         171       DE       00+     159
#> 607:     2021-08-20  2021-08-22      1         171       DE       00+     171
#> 608:     2021-08-21  2021-08-21      1         112       DE       00+      69
#> 609:     2021-08-21  2021-08-22      1         112       DE       00+     112
#> 610:     2021-08-22  2021-08-22      1          45       DE       00+      45
#>      cum_prop_reported delay new_confirm prop_reported   mean median        sd
#>                  <num> <num>       <int>         <num>  <num>  <num>     <num>
#>   1:         0.3055556     0          22    0.30555556 26.383     25  9.581969
#>   2:         0.4722222     1          12    0.16666667 15.233     15  6.050729
#>   3:         0.5277778     2           4    0.05555556  7.678      7  3.636969
#>   4:         0.5972222     3           5    0.06944444  3.944      4  2.286502
#>   5:         0.5972222     4           0    0.00000000  1.400      1  1.259995
#>  ---                                                                          
#> 606:         0.9298246     1          61    0.35672515 55.768     54 18.172904
#> 607:         1.0000000     2          12    0.07017544 12.969     13  5.157387
#> 608:         0.6160714     0          69    0.61607143 94.223     91 30.188319
#> 609:         1.0000000     1          43    0.38392857 32.499     31 11.903684
#> 610:         1.0000000     0          45    1.00000000 47.577     45 17.455107
#>          mad   q50      rhat  ess_bulk  ess_tail
#>        <num> <num>     <num>     <num>     <num>
#>   1:  8.8956    25 1.0004729 1061.6093  991.5120
#>   2:  5.9304    15 0.9988477 1023.0243  970.0040
#>   3:  2.9652     7 1.0020368  880.4481  852.4398
#>   4:  2.9652     4 0.9988907 1042.2961  972.7787
#>   5:  1.4826     1 1.0058021  947.5482  928.1070
#>  ---                                            
#> 606: 17.7912    54 1.0017605 1121.7985  944.1552
#> 607:  5.9304    13 0.9995106  941.1128 1010.1847
#> 608: 28.1694    91 1.0000863  950.7711  896.0739
#> 609: 10.3782    31 1.0022798  866.9334  748.8873
#> 610: 16.3086    45 1.0013025 1030.5884  807.8255
```
