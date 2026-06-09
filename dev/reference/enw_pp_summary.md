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
#>   1:         0.3055556     0          22    0.30555556 26.163     25  9.344932
#>   2:         0.4722222     1          12    0.16666667 15.230     14  5.883852
#>   3:         0.5277778     2           4    0.05555556  7.573      7  3.420581
#>   4:         0.5972222     3           5    0.06944444  3.982      4  2.336479
#>   5:         0.5972222     4           0    0.00000000  1.432      1  1.253374
#>  ---                                                                          
#> 606:         0.9298246     1          61    0.35672515 55.377     54 18.115492
#> 607:         1.0000000     2          12    0.07017544 13.307     13  5.440437
#> 608:         0.6160714     0          69    0.61607143 92.551     88 31.907107
#> 609:         1.0000000     1          43    0.38392857 32.052     31 11.525630
#> 610:         1.0000000     0          45    1.00000000 46.813     44 18.391745
#>          mad   q50      rhat  ess_bulk  ess_tail
#>        <num> <num>     <num>     <num>     <num>
#>   1:  8.8956    25 1.0043573  944.5563  985.9832
#>   2:  5.9304    14 1.0014240 1000.5986  911.2469
#>   3:  2.9652     7 0.9993039 1070.3435  922.9781
#>   4:  2.9652     4 1.0012548  817.6990  911.8348
#>   5:  1.4826     1 0.9990018  964.9174  860.7339
#>  ---                                            
#> 606: 17.7912    54 1.0010789 1038.1755 1067.1632
#> 607:  5.9304    13 0.9999275  993.4925  998.6745
#> 608: 29.6520    88 0.9999278 1097.1067  981.4012
#> 609: 10.3782    31 1.0024538  928.9540  888.5787
#> 610: 16.3086    44 1.0029994 1083.9580  865.5026
```
