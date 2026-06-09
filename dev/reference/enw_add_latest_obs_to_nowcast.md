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
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/dev/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/dev/reference/enw_posterior_delay.md),
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
#>  1:       DE       00+                 1    19   0.000000000 149.000  149.0
#>  2:       DE       00+                 1    18   0.000000000 167.570  167.0
#>  3:       DE       00+                 1    17   0.000000000 135.841  136.0
#>  4:       DE       00+                 1    16   0.000000000 141.576  141.0
#>  5:       DE       00+                 1    15   0.007194245 146.294  146.0
#>  6:       DE       00+                 1    14   0.000000000 104.040  104.0
#>  7:       DE       00+                 1    13   0.000000000  62.986   63.0
#>  8:       DE       00+                 1    12   0.000000000 185.872  186.0
#>  9:       DE       00+                 1    11   0.000000000 257.301  257.0
#> 10:       DE       00+                 1    10   0.004219409 268.618  268.0
#> 11:       DE       00+                 1     9   0.000000000 237.750  237.0
#> 12:       DE       00+                 1     8   0.015873016 232.124  231.0
#> 13:       DE       00+                 1     7   0.040000000 164.968  164.0
#> 14:       DE       00+                 1     6   0.010204082 129.748  129.0
#> 15:       DE       00+                 1     5   0.012396694 298.836  298.0
#> 16:       DE       00+                 1     4   0.017937220 299.495  299.0
#> 17:       DE       00+                 1     3   0.019801980 300.872  299.0
#> 18:       DE       00+                 1     2   0.070175439 301.149  299.5
#> 19:       DE       00+                 1     1   0.383928571 310.948  304.5
#> 20:       DE       00+                 1     0   1.000000000 322.429  310.5
#>     location age_group cum_prop_reported delay prop_reported    mean median
#>       <fctr>    <fctr>             <num> <num>         <num>   <num>  <num>
#>            sd     mad     q5   q20   q35   q50   q65   q80    q95      rhat
#>         <num>   <num>  <num> <num> <num> <num> <num> <num>  <num>     <num>
#>  1:  0.000000  0.0000 149.00   149   149 149.0   149 149.0 149.00        NA
#>  2:  1.341976  1.4826 166.00   166   167 167.0   168 169.0 170.00 1.0018294
#>  3:  1.839865  1.4826 133.00   134   135 136.0   136 137.0 139.00 0.9999078
#>  4:  2.333167  2.9652 138.00   139   140 141.0   142 143.0 146.00 0.9995363
#>  5:  2.986383  2.9652 142.00   144   145 146.0   147 149.0 151.00 1.0049074
#>  6:  3.024822  2.9652  99.95   102   103 104.0   105 107.0 109.00 1.0009570
#>  7:  2.453125  2.9652  60.00    61    62  63.0    64  65.0  67.00 0.9997744
#>  8:  3.783640  4.4478 180.00   183   184 186.0   187 189.0 192.00 1.0024075
#>  9:  6.031150  5.9304 248.00   252   255 257.0   259 262.0 267.00 0.9990347
#> 10:  7.433797  7.4130 257.00   262   265 268.0   271 275.0 281.05 1.0002420
#> 11:  7.647090  7.4130 226.00   231   234 237.0   240 244.0 251.05 1.0009314
#> 12:  9.302750  8.8956 218.00   224   228 231.0   235 240.0 249.00 0.9990366
#> 13:  8.833516  8.8956 152.00   157   161 164.0   168 172.0 180.05 1.0017740
#> 14:  7.402790  7.4130 118.00   124   127 129.0   132 136.0 143.00 1.0016858
#> 15: 11.534477 10.3782 282.00   289   294 298.0   302 308.0 319.05 1.0011654
#> 16: 15.778623 16.3086 275.00   285   292 299.0   304 312.0 328.00 0.9999211
#> 17: 19.534206 17.7912 272.00   285   292 299.0   306 316.0 334.05 1.0007756
#> 18: 25.061901 25.9455 263.00   279   290 299.5   309 321.2 347.00 0.9985244
#> 19: 44.585526 40.7715 250.00   273   289 304.5   323 345.2 396.00 1.0000264
#> 20: 77.062219 71.9061 214.95   256   285 310.5   343 384.0 463.10 1.0017480
#>            sd     mad     q5   q20   q35   q50   q65   q80    q95      rhat
#>         <num>   <num>  <num> <num> <num> <num> <num> <num>  <num>     <num>
#>      ess_bulk  ess_tail
#>         <num>     <num>
#>  1:        NA        NA
#>  2:  931.5700  943.7805
#>  3: 1110.6783  824.4184
#>  4:  976.8520  941.6408
#>  5: 1016.3094 1075.3542
#>  6:  952.3883  907.9565
#>  7:  939.2724  900.4309
#>  8:  963.8494  867.5415
#>  9: 1110.7851 1000.2993
#> 10:  896.3291  823.6561
#> 11: 1054.2097  821.3613
#> 12: 1066.2114  898.9808
#> 13:  827.0492  776.8752
#> 14:  940.2680  896.0489
#> 15: 1137.5067  958.8055
#> 16:  961.7466  971.0490
#> 17: 1114.9192  893.4042
#> 18: 1210.6829  900.7933
#> 19: 1166.8854  988.3457
#> 20: 1320.3486  883.1070
#>      ess_bulk  ess_tail
#>         <num>     <num>
```
