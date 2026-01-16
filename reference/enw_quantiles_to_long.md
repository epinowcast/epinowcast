# Convert summarised quantiles from wide to long format

Convert summarised quantiles from wide to long format

## Usage

``` r
enw_quantiles_to_long(posterior)
```

## Arguments

- posterior:

  A `data.frame` as output by
  [`enw_posterior()`](https://package.epinowcast.org/reference/enw_posterior.md).

## Value

A `data.frame` of quantiles in long format.

## See also

Functions used for postprocessing of model fits
[`build_ord_obs()`](https://package.epinowcast.org/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_samples()`](https://package.epinowcast.org/reference/enw_nowcast_samples.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/reference/enw_pp_summary.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
posterior <- enw_posterior(fit$fit[[1]], var = "expr_lelatent_int[1,1]")
enw_quantiles_to_long(posterior)
#>                  variable     mean   median        sd       mad      rhat
#>                    <char>    <num>    <num>     <num>     <num>     <num>
#> 1: expr_lelatent_int[1,1] 4.313129 4.312379 0.1671607 0.1600364 0.9991704
#> 2: expr_lelatent_int[1,1] 4.313129 4.312379 0.1671607 0.1600364 0.9991704
#> 3: expr_lelatent_int[1,1] 4.313129 4.312379 0.1671607 0.1600364 0.9991704
#> 4: expr_lelatent_int[1,1] 4.313129 4.312379 0.1671607 0.1600364 0.9991704
#>    ess_bulk ess_tail quantile prediction
#>       <num>    <num>    <num>      <num>
#> 1: 1006.782 735.6759     0.05   4.022114
#> 2: 1006.782 735.6759     0.20   4.180943
#> 3: 1006.782 735.6759     0.80   4.457060
#> 4: 1006.782 735.6759     0.95   4.588217
```
