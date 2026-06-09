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
[`.check_primarycensored()`](https://package.epinowcast.org/dev/reference/dot-check_primarycensored.md),
[`.delay_draw_columns()`](https://package.epinowcast.org/dev/reference/dot-delay_draw_columns.md),
[`.discretise_parametric_pmf()`](https://package.epinowcast.org/dev/reference/dot-discretise_parametric_pmf.md),
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/dev/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_posterior_delay()`](https://package.epinowcast.org/dev/reference/enw_posterior_delay.md),
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
#>         q5   q50    q95
#>      <num> <num>  <num>
#>  1: 149.00 149.0 149.00
#>  2: 166.00 167.0 170.00
#>  3: 133.00 136.0 139.00
#>  4: 138.00 141.0 146.00
#>  5: 142.00 146.0 151.00
#>  6:  99.95 104.0 109.00
#>  7:  60.00  63.0  67.00
#>  8: 180.00 186.0 192.00
#>  9: 248.00 257.0 267.00
#> 10: 257.00 268.0 281.05
#> 11: 226.00 237.0 251.05
#> 12: 218.00 231.0 249.00
#> 13: 152.00 164.0 180.05
#> 14: 118.00 129.0 143.00
#> 15: 282.00 298.0 319.05
#> 16: 275.00 299.0 328.00
#> 17: 272.00 299.0 334.05
#> 18: 263.00 299.5 347.00
#> 19: 250.00 304.5 396.00
#> 20: 214.95 310.5 463.10
#>         q5   q50    q95
#>      <num> <num>  <num>
```
