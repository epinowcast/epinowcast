# Summarise the posterior nowcast prediction

A generic wrapper around
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md)
with opinionated defaults to extract the posterior prediction for the
nowcast (`"pp_inf_obs"` from the `stan` code). The functionality of this
function can be used directly on the output of
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
using the supplied
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)
method.

## Usage

``` r
enw_nowcast_summary(
  fit,
  obs,
  max_delay = NULL,
  timestep = "day",
  probs = c(0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95)
)
```

## Arguments

- fit:

  A `cmdstanr` fit object.

- obs:

  An observation `data.frame` containing `reference_date` columns of the
  same length as the number of rows in the posterior and the most up to
  date observation for each date. This is used to align the posterior
  with the observations. The easiest source of this data is the output
  of latest output of
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  or
  [`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md).

- max_delay:

  Maximum delay to which nowcasts should be summarised, in units of the
  timestep used during preprocessing. Must be equal (default) or larger
  than the modelled maximum delay. If it is larger, then nowcasts for
  unmodelled dates are added by assuming that case counts beyond the
  modelled maximum delay are fully observed.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

- probs:

  A vector of numeric probabilities to produce quantile summaries for.
  By default these are the 5%, 20%, 80%, and 95% quantiles which are
  also the minimum set required for plotting functions to work.

## Value

A `data.frame` summarising the model posterior nowcast prediction. This
uses observed data where available and the posterior prediction where
not.

## See also

[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

Functions used for postprocessing of model fits
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/dev/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/dev/reference/enw_posterior_delay.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
enw_nowcast_summary(
  fit$fit[[1]],
  fit$latest[[1]],
  fit$max_delay
  )
#>     reference_date report_date .group max_confirm location age_group confirm
#>             <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>  1:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>  2:     2021-08-04  2021-08-22      1         166       DE       00+     166
#>  3:     2021-08-05  2021-08-22      1         133       DE       00+     133
#>  4:     2021-08-06  2021-08-22      1         137       DE       00+     137
#>  5:     2021-08-07  2021-08-22      1         139       DE       00+     139
#>  6:     2021-08-08  2021-08-22      1          97       DE       00+      97
#>  7:     2021-08-09  2021-08-22      1          58       DE       00+      58
#>  8:     2021-08-10  2021-08-22      1         175       DE       00+     175
#>  9:     2021-08-11  2021-08-22      1         233       DE       00+     233
#> 10:     2021-08-12  2021-08-22      1         237       DE       00+     237
#> 11:     2021-08-13  2021-08-22      1         204       DE       00+     204
#> 12:     2021-08-14  2021-08-22      1         189       DE       00+     189
#> 13:     2021-08-15  2021-08-22      1         125       DE       00+     125
#> 14:     2021-08-16  2021-08-22      1          98       DE       00+      98
#> 15:     2021-08-17  2021-08-22      1         242       DE       00+     242
#> 16:     2021-08-18  2021-08-22      1         223       DE       00+     223
#> 17:     2021-08-19  2021-08-22      1         202       DE       00+     202
#> 18:     2021-08-20  2021-08-22      1         171       DE       00+     171
#> 19:     2021-08-21  2021-08-22      1         112       DE       00+     112
#> 20:     2021-08-22  2021-08-22      1          45       DE       00+      45
#>     reference_date report_date .group max_confirm location age_group confirm
#>             <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>     cum_prop_reported delay prop_reported    mean median        sd     mad
#>                 <num> <num>         <num>   <num>  <num>     <num>   <num>
#>  1:                 1    19   0.000000000 149.000  149.0  0.000000  0.0000
#>  2:                 1    18   0.000000000 167.570  167.0  1.341976  1.4826
#>  3:                 1    17   0.000000000 135.841  136.0  1.839865  1.4826
#>  4:                 1    16   0.000000000 141.576  141.0  2.333167  2.9652
#>  5:                 1    15   0.007194245 146.294  146.0  2.986383  2.9652
#>  6:                 1    14   0.000000000 104.040  104.0  3.024822  2.9652
#>  7:                 1    13   0.000000000  62.986   63.0  2.453125  2.9652
#>  8:                 1    12   0.000000000 185.872  186.0  3.783640  4.4478
#>  9:                 1    11   0.000000000 257.301  257.0  6.031150  5.9304
#> 10:                 1    10   0.004219409 268.618  268.0  7.433797  7.4130
#> 11:                 1     9   0.000000000 237.750  237.0  7.647090  7.4130
#> 12:                 1     8   0.015873016 232.124  231.0  9.302750  8.8956
#> 13:                 1     7   0.040000000 164.968  164.0  8.833516  8.8956
#> 14:                 1     6   0.010204082 129.748  129.0  7.402790  7.4130
#> 15:                 1     5   0.012396694 298.836  298.0 11.534477 10.3782
#> 16:                 1     4   0.017937220 299.495  299.0 15.778623 16.3086
#> 17:                 1     3   0.019801980 300.872  299.0 19.534206 17.7912
#> 18:                 1     2   0.070175439 301.149  299.5 25.061901 25.9455
#> 19:                 1     1   0.383928571 310.948  304.5 44.585526 40.7715
#> 20:                 1     0   1.000000000 322.429  310.5 77.062219 71.9061
#>     cum_prop_reported delay prop_reported    mean median        sd     mad
#>                 <num> <num>         <num>   <num>  <num>     <num>   <num>
#>         q5   q20   q35   q50   q65   q80    q95      rhat  ess_bulk  ess_tail
#>      <num> <num> <num> <num> <num> <num>  <num>     <num>     <num>     <num>
#>  1: 149.00   149   149 149.0   149 149.0 149.00        NA        NA        NA
#>  2: 166.00   166   167 167.0   168 169.0 170.00 1.0018294  931.5700  943.7805
#>  3: 133.00   134   135 136.0   136 137.0 139.00 0.9999078 1110.6783  824.4184
#>  4: 138.00   139   140 141.0   142 143.0 146.00 0.9995363  976.8520  941.6408
#>  5: 142.00   144   145 146.0   147 149.0 151.00 1.0049074 1016.3094 1075.3542
#>  6:  99.95   102   103 104.0   105 107.0 109.00 1.0009570  952.3883  907.9565
#>  7:  60.00    61    62  63.0    64  65.0  67.00 0.9997744  939.2724  900.4309
#>  8: 180.00   183   184 186.0   187 189.0 192.00 1.0024075  963.8494  867.5415
#>  9: 248.00   252   255 257.0   259 262.0 267.00 0.9990347 1110.7851 1000.2993
#> 10: 257.00   262   265 268.0   271 275.0 281.05 1.0002420  896.3291  823.6561
#> 11: 226.00   231   234 237.0   240 244.0 251.05 1.0009314 1054.2097  821.3613
#> 12: 218.00   224   228 231.0   235 240.0 249.00 0.9990366 1066.2114  898.9808
#> 13: 152.00   157   161 164.0   168 172.0 180.05 1.0017740  827.0492  776.8752
#> 14: 118.00   124   127 129.0   132 136.0 143.00 1.0016858  940.2680  896.0489
#> 15: 282.00   289   294 298.0   302 308.0 319.05 1.0011654 1137.5067  958.8055
#> 16: 275.00   285   292 299.0   304 312.0 328.00 0.9999211  961.7466  971.0490
#> 17: 272.00   285   292 299.0   306 316.0 334.05 1.0007756 1114.9192  893.4042
#> 18: 263.00   279   290 299.5   309 321.2 347.00 0.9985244 1210.6829  900.7933
#> 19: 250.00   273   289 304.5   323 345.2 396.00 1.0000264 1166.8854  988.3457
#> 20: 214.95   256   285 310.5   343 384.0 463.10 1.0017480 1320.3486  883.1070
#>         q5   q20   q35   q50   q65   q80    q95      rhat  ess_bulk  ess_tail
#>      <num> <num> <num> <num> <num> <num>  <num>     <num>     <num>     <num>
```
