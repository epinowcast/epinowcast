# Empirical delay quantiles by reference date

Computes empirical quantiles of the reporting delay distribution for
each reference date. Intended for use with the `"delay_quantiles"` plot
type in
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/plot.enw_preprocess_data.md).

## Usage

``` r
enw_delay_quantiles(pobs, quantiles = c(0.1, 0.5, 0.9))
```

## Arguments

- pobs:

  A preprocessed data object as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- quantiles:

  A numeric vector of probabilities for which quantiles are computed.
  Defaults to `c(0.1, 0.5, 0.9)`.

## Value

A `data.table` with columns for each quantile by reference date.

## See also

Plotting functions
[`enw_delay_categories()`](https://package.epinowcast.org/dev/reference/enw_delay_categories.md),
[`enw_plot_delay_counts()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_counts.md),
[`enw_plot_delay_cumulative()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_cumulative.md),
[`enw_plot_delay_fraction()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_fraction.md),
[`enw_plot_delay_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_quantiles.md),
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/dev/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/dev/reference/enw_plot_theme.md),
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/plot.enw_preprocess_data.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")
enw_delay_quantiles(pobs)
#> Key: <.group>
#>     .group reference_date   0.1   0.5   0.9
#>      <num>         <IDat> <num> <num> <num>
#>  1:      1     2021-07-14     0     2     9
#>  2:      1     2021-07-15     0     1    12
#>  3:      1     2021-07-16     0     1     9
#>  4:      1     2021-07-17     0     4    12
#>  5:      1     2021-07-18     0     4    14
#>  6:      1     2021-07-19     1     1    12
#>  7:      1     2021-07-20     0     1     9
#>  8:      1     2021-07-21     0     1    10
#>  9:      1     2021-07-22     0     1    13
#> 10:      1     2021-07-23     0     1    14
#> 11:      1     2021-07-24     0     3    13
#> 12:      1     2021-07-25     0     4    15
#> 13:      1     2021-07-26     0     1    10
#> 14:      1     2021-07-27     0     1    10
#> 15:      1     2021-07-28     0     1    13
#> 16:      1     2021-07-29     0     1    13
#> 17:      1     2021-07-30     0     2    12
#> 18:      1     2021-07-31     0     3    12
#> 19:      1     2021-08-01     1     5    15
#> 20:      1     2021-08-02     0     2    13
#> 21:      1     2021-08-03     0     1    11
#> 22:      1     2021-08-04     0     1    10
#> 23:      1     2021-08-05     0     2     9
#> 24:      1     2021-08-06     0     1     8
#> 25:      1     2021-08-07     0     3     7
#> 26:      1     2021-08-08     0     2     9
#> 27:      1     2021-08-09     0     1     5
#> 28:      1     2021-08-10     0     1     4
#> 29:      1     2021-08-11     0     1     8
#> 30:      1     2021-08-12     0     1     7
#> 31:      1     2021-08-13     0     1     6
#> 32:      1     2021-08-14     0     1     6
#> 33:      1     2021-08-15     0     2     5
#> 34:      1     2021-08-16     0     1     4
#> 35:      1     2021-08-17     0     1     3
#> 36:      1     2021-08-18     0     1     2
#> 37:      1     2021-08-19     0     1     2
#> 38:      1     2021-08-20     0     0     1
#> 39:      1     2021-08-21     0     0     1
#> 40:      1     2021-08-22     0     0     0
#>     .group reference_date   0.1   0.5   0.9
#>      <num>         <IDat> <num> <num> <num>
```
