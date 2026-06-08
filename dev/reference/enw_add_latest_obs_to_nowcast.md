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
#>             <IDat>  <num>          <int>   <int>      <IDat>       <int>
#>     location age_group cum_prop_reported delay prop_reported    mean median
#>       <fctr>    <fctr>             <num> <num>         <num>   <num>  <num>
#>  1:       DE       00+                 1    19   0.000000000 149.000    149
#>  2:       DE       00+                 1    18   0.000000000 167.574    167
#>  3:       DE       00+                 1    17   0.000000000 135.877    136
#>  4:       DE       00+                 1    16   0.000000000 141.495    141
#>  5:       DE       00+                 1    15   0.007194245 146.052    146
#>  6:       DE       00+                 1    14   0.000000000 103.948    104
#>  7:       DE       00+                 1    13   0.000000000  63.054     63
#>  8:       DE       00+                 1    12   0.000000000 185.686    185
#>  9:       DE       00+                 1    11   0.000000000 256.904    257
#> 10:       DE       00+                 1    10   0.004219409 268.527    268
#> 11:       DE       00+                 1     9   0.000000000 237.790    237
#> 12:       DE       00+                 1     8   0.015873016 232.571    232
#> 13:       DE       00+                 1     7   0.040000000 165.001    165
#> 14:       DE       00+                 1     6   0.010204082 129.538    129
#> 15:       DE       00+                 1     5   0.012396694 298.709    298
#> 16:       DE       00+                 1     4   0.017937220 299.200    298
#> 17:       DE       00+                 1     3   0.019801980 300.299    298
#> 18:       DE       00+                 1     2   0.070175439 299.984    298
#> 19:       DE       00+                 1     1   0.383928571 307.161    303
#> 20:       DE       00+                 1     0   1.000000000 319.745    308
#>     location age_group cum_prop_reported delay prop_reported    mean median
#>       <fctr>    <fctr>             <num> <num>         <num>   <num>  <num>
#>            sd     mad     q5   q20    q35   q50    q65   q80   q95      rhat
#>         <num>   <num>  <num> <num>  <num> <num>  <num> <num> <num>     <num>
#>  1:  0.000000  0.0000 149.00   149 149.00   149 149.00 149.0 149.0        NA
#>  2:  1.338774  1.4826 166.00   166 167.00   167 168.00 168.0 170.0 1.0006578
#>  3:  1.848591  1.4826 133.00   134 135.00   136 136.00 137.0 139.0 1.0005655
#>  4:  2.425254  2.9652 138.00   139 140.00   141 142.00 143.0 146.0 0.9999635
#>  5:  2.953645  2.9652 142.00   144 145.00   146 147.00 148.0 151.0 0.9987875
#>  6:  3.035211  2.9652 100.00   101 103.00   104 105.00 106.0 109.0 1.0002551
#>  7:  2.460719  2.9652  60.00    61  62.00    63  64.00  65.0  67.0 1.0012838
#>  8:  3.911356  4.4478 180.00   182 184.00   185 187.00 189.0 193.0 0.9991483
#>  9:  6.209939  5.9304 247.00   252 254.00   257 259.00 262.0 268.0 0.9999346
#> 10:  7.155450  7.4130 258.00   262 265.00   268 271.00 274.0 282.0 1.0032576
#> 11:  7.910656  7.4130 226.00   231 234.00   237 240.00 244.0 252.0 1.0026795
#> 12:  9.143882  8.8956 218.00   225 229.00   232 236.00 240.0 248.0 1.0020812
#> 13:  8.814459  8.8956 151.00   158 161.00   165 168.00 172.0 181.0 1.0013960
#> 14:  7.826993  7.4130 118.00   123 126.00   129 132.00 136.0 143.0 1.0005851
#> 15: 11.585186 10.3782 281.00   289 294.00   298 302.35 308.0 318.0 0.9990900
#> 16: 14.635990 14.8260 278.00   287 293.00   298 304.00 311.0 325.0 0.9998453
#> 17: 19.394632 19.2738 271.00   284 292.00   298 307.00 316.2 335.0 1.0017384
#> 18: 24.987760 23.7216 262.00   279 290.00   298 307.00 320.2 342.0 0.9989077
#> 19: 41.407121 41.5128 244.95   272 290.00   303 318.00 339.0 378.1 0.9989433
#> 20: 79.592443 71.1648 211.95   255 281.65   308 339.35 380.2 468.0 1.0054390
#>            sd     mad     q5   q20    q35   q50    q65   q80   q95      rhat
#>         <num>   <num>  <num> <num>  <num> <num>  <num> <num> <num>     <num>
#>      ess_bulk  ess_tail
#>         <num>     <num>
#>  1:        NA        NA
#>  2:  997.0393  833.5025
#>  3:  894.4723  713.5909
#>  4:  806.4843  834.6731
#>  5:  958.5179 1030.9233
#>  6:  935.7023  928.2110
#>  7:  838.5999  952.5882
#>  8: 1114.0648  823.4480
#>  9:  998.3932  981.8837
#> 10: 1058.3332  764.5415
#> 11: 1112.8124  940.1685
#> 12:  869.6412  969.8644
#> 13: 1126.3482  686.8297
#> 14: 1020.8406  934.6108
#> 15:  865.2874  776.2480
#> 16: 1127.4807 1016.4075
#> 17: 1141.5391  866.2177
#> 18: 1296.2822  972.9588
#> 19: 1152.7325  829.5739
#> 20: 1258.2447  765.8981
#>      ess_bulk  ess_tail
#>         <num>     <num>
```
