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
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
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
#>  1:                 1    19   0.000000000 149.000    149  0.000000  0.0000
#>  2:                 1    18   0.000000000 167.574    167  1.338774  1.4826
#>  3:                 1    17   0.000000000 135.877    136  1.848591  1.4826
#>  4:                 1    16   0.000000000 141.495    141  2.425254  2.9652
#>  5:                 1    15   0.007194245 146.052    146  2.953645  2.9652
#>  6:                 1    14   0.000000000 103.948    104  3.035211  2.9652
#>  7:                 1    13   0.000000000  63.054     63  2.460719  2.9652
#>  8:                 1    12   0.000000000 185.686    185  3.911356  4.4478
#>  9:                 1    11   0.000000000 256.904    257  6.209939  5.9304
#> 10:                 1    10   0.004219409 268.527    268  7.155450  7.4130
#> 11:                 1     9   0.000000000 237.790    237  7.910656  7.4130
#> 12:                 1     8   0.015873016 232.571    232  9.143882  8.8956
#> 13:                 1     7   0.040000000 165.001    165  8.814459  8.8956
#> 14:                 1     6   0.010204082 129.538    129  7.826993  7.4130
#> 15:                 1     5   0.012396694 298.709    298 11.585186 10.3782
#> 16:                 1     4   0.017937220 299.200    298 14.635990 14.8260
#> 17:                 1     3   0.019801980 300.299    298 19.394632 19.2738
#> 18:                 1     2   0.070175439 299.984    298 24.987760 23.7216
#> 19:                 1     1   0.383928571 307.161    303 41.407121 41.5128
#> 20:                 1     0   1.000000000 319.745    308 79.592443 71.1648
#>     cum_prop_reported delay prop_reported    mean median        sd     mad
#>                 <num> <num>         <num>   <num>  <num>     <num>   <num>
#>         q5   q20    q35   q50    q65   q80   q95      rhat  ess_bulk  ess_tail
#>      <num> <num>  <num> <num>  <num> <num> <num>     <num>     <num>     <num>
#>  1: 149.00   149 149.00   149 149.00 149.0 149.0        NA        NA        NA
#>  2: 166.00   166 167.00   167 168.00 168.0 170.0 1.0006578  997.0393  833.5025
#>  3: 133.00   134 135.00   136 136.00 137.0 139.0 1.0005655  894.4723  713.5909
#>  4: 138.00   139 140.00   141 142.00 143.0 146.0 0.9999635  806.4843  834.6731
#>  5: 142.00   144 145.00   146 147.00 148.0 151.0 0.9987875  958.5179 1030.9233
#>  6: 100.00   101 103.00   104 105.00 106.0 109.0 1.0002551  935.7023  928.2110
#>  7:  60.00    61  62.00    63  64.00  65.0  67.0 1.0012838  838.5999  952.5882
#>  8: 180.00   182 184.00   185 187.00 189.0 193.0 0.9991483 1114.0648  823.4480
#>  9: 247.00   252 254.00   257 259.00 262.0 268.0 0.9999346  998.3932  981.8837
#> 10: 258.00   262 265.00   268 271.00 274.0 282.0 1.0032576 1058.3332  764.5415
#> 11: 226.00   231 234.00   237 240.00 244.0 252.0 1.0026795 1112.8124  940.1685
#> 12: 218.00   225 229.00   232 236.00 240.0 248.0 1.0020812  869.6412  969.8644
#> 13: 151.00   158 161.00   165 168.00 172.0 181.0 1.0013960 1126.3482  686.8297
#> 14: 118.00   123 126.00   129 132.00 136.0 143.0 1.0005851 1020.8406  934.6108
#> 15: 281.00   289 294.00   298 302.35 308.0 318.0 0.9990900  865.2874  776.2480
#> 16: 278.00   287 293.00   298 304.00 311.0 325.0 0.9998453 1127.4807 1016.4075
#> 17: 271.00   284 292.00   298 307.00 316.2 335.0 1.0017384 1141.5391  866.2177
#> 18: 262.00   279 290.00   298 307.00 320.2 342.0 0.9989077 1296.2822  972.9588
#> 19: 244.95   272 290.00   303 318.00 339.0 378.1 0.9989433 1152.7325  829.5739
#> 20: 211.95   255 281.65   308 339.35 380.2 468.0 1.0054390 1258.2447  765.8981
#>         q5   q20    q35   q50    q65   q80   q95      rhat  ess_bulk  ess_tail
#>      <num> <num>  <num> <num>  <num> <num> <num>     <num>     <num>     <num>
```
