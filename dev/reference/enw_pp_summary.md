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
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
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
#>   1:         0.3055556     0          22    0.30555556 22.049     20 10.447476
#>   2:         0.4722222     1          12    0.16666667 22.031     21 10.062370
#>   3:         0.5277778     2           4    0.05555556  7.992      8  4.118361
#>   4:         0.5972222     3           5    0.06944444  4.261      4  2.692978
#>   5:         0.5972222     4           0    0.00000000  1.326      1  1.258295
#>  ---                                                                          
#> 606:         0.9298246     1          61    0.35672515 81.048     77 33.870413
#> 607:         1.0000000     2          12    0.07017544 12.586     11  6.299229
#> 608:         0.6160714     0          69    0.61607143 73.471     69 32.792995
#> 609:         1.0000000     1          43    0.38392857 47.332     44 20.074730
#> 610:         1.0000000     0          45    1.00000000 40.534     37 20.435911
#>          mad   q50      rhat  ess_bulk  ess_tail
#>        <num> <num>     <num>     <num>     <num>
#>   1:  8.8956    20 1.0007087  981.0605  957.4820
#>   2: 10.3782    21 1.0006400 1010.0549  860.7285
#>   3:  4.4478     8 1.0018374 1046.7610  956.3804
#>   4:  2.9652     4 1.0008338  959.7921  978.0414
#>   5:  1.4826     1 1.0003294  999.1432  873.2038
#>  ---                                            
#> 606: 31.1346    77 0.9999674 1016.8230 1000.9385
#> 607:  5.9304    11 1.0006309  965.7202  850.5506
#> 608: 29.6520    69 0.9983329 1072.1422  973.6582
#> 609: 19.2738    44 0.9993679 1127.5257  906.6164
#> 610: 17.7912    37 1.0003136 1372.2704 1042.6714
```
