# Print method for epinowcast

`print` method for class `"epinowcast"`.

## Usage

``` r
# S3 method for class 'epinowcast'
print(x, ...)
```

## Arguments

- x:

  A `data.table` output from
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md).

- ...:

  Additional arguments (not used).

## Value

Invisibly returns `x`.

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`print.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.enw_preprocess_data.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md),
[`summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/summary.enw_preprocess_data.md),
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
nowcast
#> ── epinowcast model output ───────────────────────────────────────────────────── 
#> Groups: 1 | Timestep: day | Max delay: 20 
#> Observations: 40 timepoints x 40 snapshots 
#> Max date: 2021-08-22 
#> 
#> Datasets (access with `enw_get_data(x, "<name>")`): 
#>   obs                :     650 x 9 
#>   new_confirm        :     610 x 11 
#>   latest             :      40 x 10 
#>   missing_reference  :      40 x 6 
#>   reporting_triangle :      40 x 22 
#>   metareference      :      40 x 9 
#>   metareport         :      59 x 12 
#>   metadelay          :      20 x 5 
#> 
#> Priors: 14 parameters 
#>           variable          distribution  mean    sd
#>             <char>                <char> <num> <num>
#>         expr_r_int                Normal   0.0   0.2
#>       expr_beta_sd Zero truncated normal   0.0   1.0
#>  expr_lelatent_int                Normal   4.3   1.0
#>       expl_beta_sd Zero truncated normal   0.0   1.0
#>      refp_mean_int                Normal   1.0   1.0
#>        refp_sd_int Zero truncated normal   0.5   1.0
#>  refp_mean_beta_sd Zero truncated normal   0.0   1.0
#>    refp_sd_beta_sd Zero truncated normal   0.0   1.0
#>          refnp_int                Normal   0.0   1.0
#>      refnp_beta_sd Zero truncated normal   0.0   1.0
#>        rep_beta_sd Zero truncated normal   0.0   1.0
#>           miss_int                Normal   0.0   1.0
#>       miss_beta_sd Zero truncated normal   0.0   1.0
#>           sqrt_phi Zero truncated normal   0.0   0.5
#> Model fit: 
#> 
#>  Samples: 1,000 | Max Rhat: 1.01 
#> 
#>  Divergent transitions: 0 (0%) 
#>   Run time: 26 secs 
```
