# Add latest observations to nowcast output

Add the latest observations to the nowcast output. This is useful for
plotting the nowcast against the latest observations.

## Usage

``` r
enw_add_latest_obs_to_nowcast(nowcast, obs)
```

## Arguments

- nowcast:

  A `data.frame` of nowcast output from
  [`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md).

- obs:

  An observation `data.frame` containing `reference_date` columns of the
  same length as the number of rows in the posterior and the most up to
  date observation for each date. This is used to align the posterior
  with the observations. The easiest source of this data is the output
  of latest output of
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  or
  [`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md).

## Value

A `data.frame` of nowcast output with the latest observations added.

## See also

Functions used for postprocessing of model fits
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
obs <- enw_example("obs")
nowcast <- summary(fit, type = "nowcast")
enw_add_latest_obs_to_nowcast(nowcast, obs)
#> Key: <reference_date, .group>
#>     reference_date .group latest_confirm confirm report_date max_confirm
#>             <IDat>  <num>          <int>   <int>      <IDat>       <int>
#>  1:     2021-08-03      1            156     149  2021-08-22         149
#>  2:     2021-08-04      1            183     166  2021-08-22         166
#>  3:     2021-08-05      1            147     133  2021-08-22         133
#>  4:     2021-08-06      1            155     137  2021-08-22         137
#>  5:     2021-08-07      1            159     139  2021-08-22         139
#>  6:     2021-08-08      1            119      97  2021-08-22          97
#>  7:     2021-08-09      1             65      58  2021-08-22          58
#>  8:     2021-08-10      1            204     175  2021-08-22         175
#>  9:     2021-08-11      1            275     233  2021-08-22         233
#> 10:     2021-08-12      1            273     237  2021-08-22         237
#> 11:     2021-08-13      1            270     204  2021-08-22         204
#> 12:     2021-08-14      1            262     189  2021-08-22         189
#> 13:     2021-08-15      1            192     125  2021-08-22         125
#> 14:     2021-08-16      1            140      98  2021-08-22          98
#> 15:     2021-08-17      1            323     242  2021-08-22         242
#> 16:     2021-08-18      1            409     223  2021-08-22         223
#> 17:     2021-08-19      1            370     202  2021-08-22         202
#> 18:     2021-08-20      1            361     171  2021-08-22         171
#> 19:     2021-08-21      1            339     112  2021-08-22         112
#> 20:     2021-08-22      1            258      45  2021-08-22          45
#>     reference_date .group latest_confirm confirm report_date max_confirm
#>     location age_group cum_prop_reported delay prop_reported    mean median
#>       <fctr>    <fctr>             <num> <num>         <num>   <num>  <num>
#>  1:       DE       00+                 1    19   0.000000000 149.000  149.0
#>  2:       DE       00+                 1    18   0.000000000 167.480  167.0
#>  3:       DE       00+                 1    17   0.000000000 135.797  136.0
#>  4:       DE       00+                 1    16   0.000000000 141.272  141.0
#>  5:       DE       00+                 1    15   0.007194245 145.764  145.0
#>  6:       DE       00+                 1    14   0.000000000 103.614  103.0
#>  7:       DE       00+                 1    13   0.000000000  62.838   63.0
#>  8:       DE       00+                 1    12   0.000000000 185.149  185.0
#>  9:       DE       00+                 1    11   0.000000000 256.191  256.0
#> 10:       DE       00+                 1    10   0.004219409 267.189  266.0
#> 11:       DE       00+                 1     9   0.000000000 236.218  235.0
#> 12:       DE       00+                 1     8   0.015873016 230.463  230.0
#> 13:       DE       00+                 1     7   0.040000000 165.184  165.0
#> 14:       DE       00+                 1     6   0.010204082 129.535  129.0
#> 15:       DE       00+                 1     5   0.012396694 293.236  292.0
#> 16:       DE       00+                 1     4   0.017937220 293.392  292.0
#> 17:       DE       00+                 1     3   0.019801980 291.537  290.0
#> 18:       DE       00+                 1     2   0.070175439 295.258  292.5
#> 19:       DE       00+                 1     1   0.383928571 310.440  304.0
#> 20:       DE       00+                 1     0   1.000000000 384.142  368.0
#>     location age_group cum_prop_reported delay prop_reported    mean median
#>             sd     mad     q5   q20    q35   q50   q65   q80    q95      rhat
#>          <num>   <num>  <num> <num>  <num> <num> <num> <num>  <num>     <num>
#>  1:   0.000000  0.0000 149.00   149 149.00 149.0   149 149.0 149.00        NA
#>  2:   1.403414  1.4826 166.00   166 167.00 167.0   168 168.0 170.00 1.0011717
#>  3:   1.858291  1.4826 133.00   134 135.00 136.0   136 137.0 139.00 1.0023790
#>  4:   2.414507  2.9652 138.00   139 140.00 141.0   142 143.0 146.00 0.9997357
#>  5:   3.070461  2.9652 141.00   143 144.00 145.0   147 148.0 151.00 1.0009523
#>  6:   2.892987  2.9652  99.00   101 102.00 103.0   105 106.0 109.00 1.0056338
#>  7:   2.595475  2.9652  59.00    61  62.00  63.0    64  65.0  68.00 0.9989559
#>  8:   3.655155  2.9652 180.00   182 183.00 185.0   186 188.0 192.00 1.0008924
#>  9:   7.084540  7.4130 246.00   250 253.00 256.0   258 262.0 269.00 1.0019152
#> 10:   8.269563  7.4130 255.00   260 264.00 266.0   270 274.0 282.00 0.9991677
#> 11:   8.635453  8.8956 224.00   229 232.00 235.0   239 243.0 252.00 1.0025829
#> 12:  10.395995 10.3782 215.00   222 226.00 230.0   234 239.0 249.00 1.0004028
#> 13:   9.660925  8.8956 150.00   157 161.00 165.0   168 173.0 182.00 1.0063929
#> 14:   8.499354  8.8956 117.00   122 125.00 129.0   132 136.0 144.00 1.0015131
#> 15:  11.922603 11.8608 276.00   283 288.00 292.0   297 302.0 315.00 1.0036606
#> 16:  15.981231 14.8260 269.00   280 286.00 292.0   299 306.0 321.00 0.9996327
#> 17:  20.271200 20.7564 262.00   274 282.00 290.0   298 308.0 327.05 0.9994497
#> 18:  29.356997 27.4281 252.00   271 282.00 292.5   304 317.0 350.00 0.9986679
#> 19:  50.020660 47.4432 238.95   269 287.00 304.0   324 349.0 396.10 0.9996761
#> 20: 115.713601 97.8516 235.00   288 329.65 368.0   406 462.2 602.00 1.0026839
#>             sd     mad     q5   q20    q35   q50   q65   q80    q95      rhat
#>      ess_bulk  ess_tail
#>         <num>     <num>
#>  1:        NA        NA
#>  2: 1032.9494 1005.1434
#>  3:  927.8688  880.2070
#>  4: 1024.0598  943.1194
#>  5: 1192.6161  903.2221
#>  6: 1020.5322 1049.4998
#>  7: 1026.9068  976.3448
#>  8:  874.1838  752.9787
#>  9:  840.3245  950.3159
#> 10: 1046.7181  969.9759
#> 11:  884.3839  943.4474
#> 12:  857.4908  808.3249
#> 13:  942.5139  877.8069
#> 14: 1034.7024  934.5488
#> 15:  886.4727  919.5960
#> 16: 1073.2110 1004.6946
#> 17: 1455.4791 1067.2793
#> 18: 1075.3975  898.2947
#> 19: 1254.5799  923.0215
#> 20: 1616.8851  595.4893
#>      ess_bulk  ess_tail
```
