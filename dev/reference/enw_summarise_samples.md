# Summarise posterior samples

This function summarises posterior samples for arbitrary strata. It
optionally holds out the observed data (variables that are not ".draw",
".iteration", ".sample", ".chain" ) joins this to the summarised
posterior.

## Usage

``` r
enw_summarise_samples(
  samples,
  probs = c(0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95),
  by = c("reference_date", ".group"),
  link_with_obs = TRUE
)
```

## Arguments

- samples:

  A `data.frame` of posterior samples with at least a numeric sample
  variable.

- probs:

  A vector of numeric probabilities to produce quantile summaries for.
  By default these are the 5%, 20%, 80%, and 95% quantiles which are
  also the minimum set required for plotting functions to work.

- by:

  A character vector of variables to summarise by. Defaults to
  `c("reference_date", ".group")`.

- link_with_obs:

  Logical, should the observed data be linked to the posterior summary?
  This is useful for plotting the posterior against the observed data.
  Defaults to `TRUE`.

## Value

A `data.frame` summarising the posterior samples.

## See also

Functions used for postprocessing of model fits
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
samples <- summary(fit, type = "nowcast_sample")
enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
#> Key: <reference_date, .group>
#>     reference_date .group report_date max_confirm location age_group confirm
#>             <IDat>  <num>      <IDat>       <int>   <fctr>    <fctr>   <int>
#>  1:     2021-08-03      1  2021-08-22         149       DE       00+     149
#>  2:     2021-08-04      1  2021-08-22         166       DE       00+     166
#>  3:     2021-08-05      1  2021-08-22         133       DE       00+     133
#>  4:     2021-08-06      1  2021-08-22         137       DE       00+     137
#>  5:     2021-08-07      1  2021-08-22         139       DE       00+     139
#>  6:     2021-08-08      1  2021-08-22          97       DE       00+      97
#>  7:     2021-08-09      1  2021-08-22          58       DE       00+      58
#>  8:     2021-08-10      1  2021-08-22         175       DE       00+     175
#>  9:     2021-08-11      1  2021-08-22         233       DE       00+     233
#> 10:     2021-08-12      1  2021-08-22         237       DE       00+     237
#> 11:     2021-08-13      1  2021-08-22         204       DE       00+     204
#> 12:     2021-08-14      1  2021-08-22         189       DE       00+     189
#> 13:     2021-08-15      1  2021-08-22         125       DE       00+     125
#> 14:     2021-08-16      1  2021-08-22          98       DE       00+      98
#> 15:     2021-08-17      1  2021-08-22         242       DE       00+     242
#> 16:     2021-08-18      1  2021-08-22         223       DE       00+     223
#> 17:     2021-08-19      1  2021-08-22         202       DE       00+     202
#> 18:     2021-08-20      1  2021-08-22         171       DE       00+     171
#> 19:     2021-08-21      1  2021-08-22         112       DE       00+     112
#> 20:     2021-08-22      1  2021-08-22          45       DE       00+      45
#>     reference_date .group report_date max_confirm location age_group confirm
#>             <IDat>  <num>      <IDat>       <int>   <fctr>    <fctr>   <int>
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
#>         q5   q50   q95
#>      <num> <num> <num>
#>  1: 149.00   149 149.0
#>  2: 166.00   167 170.0
#>  3: 133.00   136 139.0
#>  4: 138.00   141 146.0
#>  5: 142.00   146 151.0
#>  6: 100.00   104 109.0
#>  7:  60.00    63  67.0
#>  8: 180.00   185 193.0
#>  9: 247.00   257 268.0
#> 10: 258.00   268 282.0
#> 11: 226.00   237 252.0
#> 12: 218.00   232 248.0
#> 13: 151.00   165 181.0
#> 14: 118.00   129 143.0
#> 15: 281.00   298 318.0
#> 16: 278.00   298 325.0
#> 17: 271.00   298 335.0
#> 18: 262.00   298 342.0
#> 19: 244.95   303 378.1
#> 20: 211.95   308 468.0
#>         q5   q50   q95
#>      <num> <num> <num>
```
