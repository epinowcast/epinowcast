# Print method for enw_preprocess_data

`print` method for class `"enw_preprocess_data"`.

## Usage

``` r
# S3 method for class 'enw_preprocess_data'
print(x, ...)
```

## Arguments

- x:

  A `data.table` output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  or
  [`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md).

- ...:

  Additional arguments (not used).

## Value

Invisibly returns `x`.

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`print.epinowcast()`](https://package.epinowcast.org/dev/reference/print.epinowcast.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md),
[`summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/summary.enw_preprocess_data.md),
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")
pobs
#> ── Preprocessed nowcast data ─────────────────────────────────────────────────── 
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
```
