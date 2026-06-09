# Convert summarised quantiles from wide to long format

Convert summarised quantiles from wide to long format

## Usage

``` r
enw_quantiles_to_long(posterior)
```

## Arguments

- posterior:

  A `data.frame` as output by
  [`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md).

## Value

A `data.frame` of quantiles in long format.

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
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
posterior <- enw_posterior(fit$fit[[1]], var = "expr_lelatent_int[1,1]")
enw_quantiles_to_long(posterior)
#>                  variable     mean   median        sd       mad     rhat
#>                    <char>    <num>    <num>     <num>     <num>    <num>
#> 1: expr_lelatent_int[1,1] 4.295336 4.298255 0.1407952 0.1400908 1.004743
#> 2: expr_lelatent_int[1,1] 4.295336 4.298255 0.1407952 0.1400908 1.004743
#> 3: expr_lelatent_int[1,1] 4.295336 4.298255 0.1407952 0.1400908 1.004743
#> 4: expr_lelatent_int[1,1] 4.295336 4.298255 0.1407952 0.1400908 1.004743
#>    ess_bulk ess_tail quantile prediction
#>       <num>    <num>    <num>      <num>
#> 1: 884.3912 704.5825     0.05   4.071047
#> 2: 884.3912 704.5825     0.20   4.178024
#> 3: 884.3912 704.5825     0.80   4.413185
#> 4: 884.3912 704.5825     0.95   4.522491
```
