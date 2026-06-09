# Summary method for epinowcast

`summary` method for class "epinowcast".

## Usage

``` r
# S3 method for class 'epinowcast'
summary(
  object,
  type = c("nowcast", "nowcast_samples", "fit", "posterior_prediction"),
  max_delay = object$max_delay,
  ...
)
```

## Arguments

- object:

  A `data.table` output from
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md).

- type:

  Character string indicating the summary to return; enforced by
  [`base::match.arg()`](https://rdrr.io/r/base/match.arg.html).
  Supported options are:

  - "nowcast" which summarises nowcast posterior with
    [`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),

  - "nowcast_samples" which samples latest with
    [`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),

  - "fit" which returns the summarised `cmdstanr` fit with
    [`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),

  - "posterior_prediction" which returns summarised posterior
    predictions for the observations after fitting using
    [`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md).

- max_delay:

  Maximum delay to which nowcasts should be summarised, in units of the
  timestep used during preprocessing. Must be equal (default) or larger
  than the modelled maximum delay. If it is larger, then nowcasts for
  unmodelled dates are added by assuming that case counts beyond the
  modelled maximum delay are fully observed.

- ...:

  Additional arguments passed to summary specified by `type`.

## Value

A summary data.frame

## See also

summary epinowcast

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md),
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/plot.enw_preprocess_data.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`print.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.enw_preprocess_data.md),
[`print.epinowcast()`](https://package.epinowcast.org/dev/reference/print.epinowcast.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md),
[`summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/summary.enw_preprocess_data.md)

## Examples

``` r
nowcast <- enw_example("nowcast")

# Summarise nowcast posterior
summary(nowcast, type = "nowcast")
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

# Nowcast posterior samples
summary(nowcast, type = "nowcast_samples")
#>        reference_date report_date .group max_confirm location age_group confirm
#>                <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>     1:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     2:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     3:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     4:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     5:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>    ---                                                                         
#> 19996:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19997:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19998:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19999:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 20000:     2021-08-22  2021-08-22      1          45       DE       00+      45
#>        cum_prop_reported delay prop_reported .chain .iteration .draw sample
#>                    <num> <num>         <num>  <int>      <int> <int>  <num>
#>     1:                 1    19             0      1          1     1    149
#>     2:                 1    19             0      1          2     2    149
#>     3:                 1    19             0      1          3     3    149
#>     4:                 1    19             0      1          4     4    149
#>     5:                 1    19             0      1          5     5    149
#>    ---                                                                     
#> 19996:                 1     0             1      2        496   996    254
#> 19997:                 1     0             1      2        497   997    373
#> 19998:                 1     0             1      2        498   998    412
#> 19999:                 1     0             1      2        499   999    332
#> 20000:                 1     0             1      2        500  1000    347

# Nowcast model fit
summary(nowcast, type = "fit")
#>                    variable          mean        median         sd        mad
#>                      <char>         <num>         <num>      <num>      <num>
#>   1:                   lp__ -1312.1722704 -1311.9705000  7.2740418  7.2530275
#>   2: expr_lelatent_int[1,1]     4.2953356     4.2982551  0.1407952  0.1400908
#>   3:           expr_beta[1]    -0.3209256    -0.3029958  0.4974060  0.5003899
#>   4:           expr_beta[2]    -0.7426578    -0.7537567  0.4890380  0.4876114
#>   5:           expr_beta[3]     0.4907579     0.4852679  0.4909068  0.4815642
#>  ---                                                                         
#> 829:       pp_inf_obs[16,1]   299.4950000   299.0000000 15.7786229 16.3086000
#> 830:       pp_inf_obs[17,1]   300.8720000   299.0000000 19.5342059 17.7912000
#> 831:       pp_inf_obs[18,1]   301.1490000   299.5000000 25.0619013 25.9455000
#> 832:       pp_inf_obs[19,1]   310.9480000   304.5000000 44.5855264 40.7715000
#> 833:       pp_inf_obs[20,1]   322.4290000   310.5000000 77.0622187 71.9061000
#>                 q5           q20           q80           q95      rhat
#>              <num>         <num>         <num>         <num>     <num>
#>   1: -1324.8030150 -1317.9927800 -1305.9577000 -1.300480e+03 1.0022016
#>   2:     4.0710473     4.1780239     4.4131850  4.522491e+00 1.0047425
#>   3:    -1.1751767    -0.7363925     0.0902879  4.850281e-01 1.0018321
#>   4:    -1.5490582    -1.1367682    -0.3446364  6.348241e-02 1.0043698
#>   5:    -0.3189382     0.1004458     0.9074385  1.247705e+00 0.9982835
#>  ---                                                                  
#> 829:   275.0000000   285.0000000   312.0000000  3.280000e+02 0.9999211
#> 830:   272.0000000   285.0000000   316.0000000  3.340500e+02 1.0007756
#> 831:   263.0000000   279.0000000   321.2000000  3.470000e+02 0.9985244
#> 832:   250.0000000   273.0000000   345.2000000  3.960000e+02 1.0000264
#> 833:   214.9500000   256.0000000   384.0000000  4.631000e+02 1.0017480
#>       ess_bulk ess_tail
#>          <num>    <num>
#>   1:  223.4158 373.1034
#>   2:  884.3912 704.5825
#>   3:  878.4473 706.1199
#>   4:  741.5364 691.1377
#>   5:  733.0923 665.0849
#>  ---                   
#> 829:  961.7466 971.0490
#> 830: 1114.9192 893.4042
#> 831: 1210.6829 900.7933
#> 832: 1166.8854 988.3457
#> 833: 1320.3486 883.1070

# Posterior predictions
summary(nowcast, type = "posterior_prediction")
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
#>          mad    q5   q20   q35   q50   q65   q80    q95      rhat  ess_bulk
#>        <num> <num> <num> <num> <num> <num> <num>  <num>     <num>     <num>
#>   1:  8.8956    13    18    22    25    29  33.0  44.05 1.0004729 1061.6093
#>   2:  5.9304     7    10    12    15    17  20.0  27.00 0.9988477 1023.0243
#>   3:  2.9652     2     5     6     7     9  10.0  14.00 1.0020368  880.4481
#>   4:  2.9652     1     2     3     4     4   6.0   8.00 0.9988907 1042.2961
#>   5:  1.4826     0     0     1     1     2   2.0   4.00 1.0058021  947.5482
#>  ---                                                                       
#> 606: 17.7912    29    41    47    54    61  69.2  88.05 1.0017605 1121.7985
#> 607:  5.9304     6     8    11    13    14  17.0  22.00 0.9995106  941.1128
#> 608: 28.1694    52    69    80    91   102 117.0 148.00 1.0000863  950.7711
#> 609: 10.3782    17    22    27    31    35  41.0  55.00 1.0022798  866.9334
#> 610: 16.3086    25    33    39    45    52  60.2  79.00 1.0013025 1030.5884
#>       ess_tail
#>          <num>
#>   1:  991.5120
#>   2:  970.0040
#>   3:  852.4398
#>   4:  972.7787
#>   5:  928.1070
#>  ---          
#> 606:  944.1552
#> 607: 1010.1847
#> 608:  896.0739
#> 609:  748.8873
#> 610:  807.8255
```
