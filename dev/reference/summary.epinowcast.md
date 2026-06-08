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
#> 19996:                 1     0             1      2        496   996    456
#> 19997:                 1     0             1      2        497   997    432
#> 19998:                 1     0             1      2        498   998    326
#> 19999:                 1     0             1      2        499   999    211
#> 20000:                 1     0             1      2        500  1000    308

# Nowcast model fit
summary(nowcast, type = "fit")
#>                    variable          mean        median         sd        mad
#>                      <char>         <num>         <num>      <num>      <num>
#>   1:                   lp__ -1312.6930717 -1312.2196500  7.3157458  7.3113678
#>   2: expr_lelatent_int[1,1]     4.2900304     4.2897159  0.1448255  0.1451874
#>   3:           expr_beta[1]    -0.3201914    -0.3134685  0.4719893  0.4663760
#>   4:           expr_beta[2]    -0.7403831    -0.7468828  0.4829204  0.4788528
#>   5:           expr_beta[3]     0.4740165     0.4764368  0.4999795  0.4899696
#>  ---                                                                         
#> 828:       pp_inf_obs[16,1]   299.2000000   298.0000000 14.6359903 14.8260000
#> 829:       pp_inf_obs[17,1]   300.2990000   298.0000000 19.3946320 19.2738000
#> 830:       pp_inf_obs[18,1]   299.9840000   298.0000000 24.9877596 23.7216000
#> 831:       pp_inf_obs[19,1]   307.1610000   303.0000000 41.4071205 41.5128000
#> 832:       pp_inf_obs[20,1]   319.7450000   308.0000000 79.5924427 71.1648000
#>                 q5           q20           q80           q95      rhat
#>              <num>         <num>         <num>         <num>     <num>
#>   1: -1324.8228700 -1.318916e+03 -1.306436e+03 -1.301735e+03 1.0169546
#>   2:     4.0523697  4.168425e+00  4.413531e+00  4.524110e+00 1.0028388
#>   3:    -1.0901889 -7.101084e-01  5.856751e-02  4.194518e-01 1.0007712
#>   4:    -1.5245174 -1.162537e+00 -3.265960e-01  4.203365e-02 1.0025927
#>   5:    -0.3409476  6.557318e-02  8.903362e-01  1.308813e+00 1.0055579
#>  ---                                                                  
#> 828:   278.0000000  2.870000e+02  3.110000e+02  3.250000e+02 0.9998453
#> 829:   271.0000000  2.840000e+02  3.162000e+02  3.350000e+02 1.0017384
#> 830:   262.0000000  2.790000e+02  3.202000e+02  3.420000e+02 0.9989077
#> 831:   244.9500000  2.720000e+02  3.390000e+02  3.781000e+02 0.9989433
#> 832:   211.9500000  2.550000e+02  3.802000e+02  4.680000e+02 1.0054390
#>       ess_bulk  ess_tail
#>          <num>     <num>
#>   1:  220.6282  513.3235
#>   2:  872.3770  684.6952
#>   3:  835.6741  561.3815
#>   4:  880.0079  845.4472
#>   5:  991.1887  674.8935
#>  ---                    
#> 828: 1127.4807 1016.4075
#> 829: 1141.5391  866.2177
#> 830: 1296.2822  972.9588
#> 831: 1152.7325  829.5739
#> 832: 1258.2447  765.8981

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
#>          mad    q5   q20   q35   q50   q65   q80    q95      rhat  ess_bulk
#>        <num> <num> <num> <num> <num> <num> <num>  <num>     <num>     <num>
#>   1:  8.8956 12.95  18.0    22    25    29    33  42.05 1.0043573  944.5563
#>   2:  5.9304  7.00  10.0    13    14    17    20  25.05 1.0014240 1000.5986
#>   3:  2.9652  3.00   5.0     6     7     9    10  14.00 0.9993039 1070.3435
#>   4:  2.9652  1.00   2.0     3     4     5     6   8.00 1.0012548  817.6990
#>   5:  1.4826  0.00   0.0     1     1     2     2   4.00 0.9990018  964.9174
#>  ---                                                                       
#> 606: 17.7912 29.00  39.8    47    54    61    70  85.00 1.0010789 1038.1755
#> 607:  5.9304  6.00   9.0    11    13    15    18  23.00 0.9999275  993.4925
#> 608: 29.6520 49.00  66.0    77    88   101   118 147.00 0.9999278 1097.1067
#> 609: 10.3782 15.00  22.0    27    31    35    41  53.00 1.0024538  928.9540
#> 610: 16.3086 23.00  31.0    38    44    51    60  81.00 1.0029994 1083.9580
#>       ess_tail
#>          <num>
#>   1:  985.9832
#>   2:  911.2469
#>   3:  922.9781
#>   4:  911.8348
#>   5:  860.7339
#>  ---          
#> 606: 1067.1632
#> 607:  998.6745
#> 608:  981.4012
#> 609:  888.5787
#> 610:  865.5026
```
