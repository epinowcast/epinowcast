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
#>     cum_prop_reported delay prop_reported    mean median         sd     mad
#>                 <num> <num>         <num>   <num>  <num>      <num>   <num>
#>  1:                 1    19   0.000000000 149.000  149.0   0.000000  0.0000
#>  2:                 1    18   0.000000000 167.480  167.0   1.403414  1.4826
#>  3:                 1    17   0.000000000 135.797  136.0   1.858291  1.4826
#>  4:                 1    16   0.000000000 141.272  141.0   2.414507  2.9652
#>  5:                 1    15   0.007194245 145.764  145.0   3.070461  2.9652
#>  6:                 1    14   0.000000000 103.614  103.0   2.892987  2.9652
#>  7:                 1    13   0.000000000  62.838   63.0   2.595475  2.9652
#>  8:                 1    12   0.000000000 185.149  185.0   3.655155  2.9652
#>  9:                 1    11   0.000000000 256.191  256.0   7.084540  7.4130
#> 10:                 1    10   0.004219409 267.189  266.0   8.269563  7.4130
#> 11:                 1     9   0.000000000 236.218  235.0   8.635453  8.8956
#> 12:                 1     8   0.015873016 230.463  230.0  10.395995 10.3782
#> 13:                 1     7   0.040000000 165.184  165.0   9.660925  8.8956
#> 14:                 1     6   0.010204082 129.535  129.0   8.499354  8.8956
#> 15:                 1     5   0.012396694 293.236  292.0  11.922603 11.8608
#> 16:                 1     4   0.017937220 293.392  292.0  15.981231 14.8260
#> 17:                 1     3   0.019801980 291.537  290.0  20.271200 20.7564
#> 18:                 1     2   0.070175439 295.258  292.5  29.356997 27.4281
#> 19:                 1     1   0.383928571 310.440  304.0  50.020660 47.4432
#> 20:                 1     0   1.000000000 384.142  368.0 115.713601 97.8516
#>     cum_prop_reported delay prop_reported    mean median         sd     mad
#>                 <num> <num>         <num>   <num>  <num>      <num>   <num>
#>         q5   q20    q35   q50   q65   q80    q95      rhat  ess_bulk  ess_tail
#>      <num> <num>  <num> <num> <num> <num>  <num>     <num>     <num>     <num>
#>  1: 149.00   149 149.00 149.0   149 149.0 149.00        NA        NA        NA
#>  2: 166.00   166 167.00 167.0   168 168.0 170.00 1.0011717 1032.9494 1005.1434
#>  3: 133.00   134 135.00 136.0   136 137.0 139.00 1.0023790  927.8688  880.2070
#>  4: 138.00   139 140.00 141.0   142 143.0 146.00 0.9997357 1024.0598  943.1194
#>  5: 141.00   143 144.00 145.0   147 148.0 151.00 1.0009523 1192.6161  903.2221
#>  6:  99.00   101 102.00 103.0   105 106.0 109.00 1.0056338 1020.5322 1049.4998
#>  7:  59.00    61  62.00  63.0    64  65.0  68.00 0.9989559 1026.9068  976.3448
#>  8: 180.00   182 183.00 185.0   186 188.0 192.00 1.0008924  874.1838  752.9787
#>  9: 246.00   250 253.00 256.0   258 262.0 269.00 1.0019152  840.3245  950.3159
#> 10: 255.00   260 264.00 266.0   270 274.0 282.00 0.9991677 1046.7181  969.9759
#> 11: 224.00   229 232.00 235.0   239 243.0 252.00 1.0025829  884.3839  943.4474
#> 12: 215.00   222 226.00 230.0   234 239.0 249.00 1.0004028  857.4908  808.3249
#> 13: 150.00   157 161.00 165.0   168 173.0 182.00 1.0063929  942.5139  877.8069
#> 14: 117.00   122 125.00 129.0   132 136.0 144.00 1.0015131 1034.7024  934.5488
#> 15: 276.00   283 288.00 292.0   297 302.0 315.00 1.0036606  886.4727  919.5960
#> 16: 269.00   280 286.00 292.0   299 306.0 321.00 0.9996327 1073.2110 1004.6946
#> 17: 262.00   274 282.00 290.0   298 308.0 327.05 0.9994497 1455.4791 1067.2793
#> 18: 252.00   271 282.00 292.5   304 317.0 350.00 0.9986679 1075.3975  898.2947
#> 19: 238.95   269 287.00 304.0   324 349.0 396.10 0.9996761 1254.5799  923.0215
#> 20: 235.00   288 329.65 368.0   406 462.2 602.00 1.0026839 1616.8851  595.4893
#>         q5   q20    q35   q50   q65   q80    q95      rhat  ess_bulk  ess_tail
#>      <num> <num>  <num> <num> <num> <num>  <num>     <num>     <num>     <num>
```
