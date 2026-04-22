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
  [`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md).

- ...:

  Additional arguments (not used).

## Value

Invisibly returns `x`.

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md),
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/reference/plot.enw_preprocess_data.md),
[`plot.epinowcast()`](https://package.epinowcast.org/reference/plot.epinowcast.md),
[`print.enw_preprocess_data()`](https://package.epinowcast.org/reference/print.enw_preprocess_data.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/reference/print.summary.enw_preprocess_data.md),
[`summary.enw_preprocess_data()`](https://package.epinowcast.org/reference/summary.enw_preprocess_data.md),
[`summary.epinowcast()`](https://package.epinowcast.org/reference/summary.epinowcast.md)

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
#> Model objects (access with `enw_get_data(x, "<name>")`): 
#>   priors : 14 x 6 
#>   fit : CmdStanMCMC 
#>   data : list(112) 
#>   fit_args : list(5) 
#>   init_method_output : NULL 
#> Model fit: 
#>   Samples: 1,000 | Max Rhat: 1.01 
#>   Divergent transitions: 0 (0%) 
#>   Max treedepth: 8 (3 at max, 0.3%) 
#>   Run time: 26 secs 
```
