# Generic quantile plot

Generic quantile plot

## Usage

``` r
enw_plot_obs(obs, latest_obs = NULL, log = TRUE, ...)
```

## Arguments

- obs:

  A `data.frame` of summarised posterior estimates containing at least a
  `confirm` count column and a date variable

- latest_obs:

  A `data.frame` of observed data containing at least a `confirm` count
  variable and the same date variable as in the main data.frame used for
  plotting.

- log:

  Logical, defaults to `FALSE`. Should counts be plot on the log scale.

- ...:

  Additional arguments passed to
  [`ggplot2::aes()`](https://ggplot2.tidyverse.org/reference/aes.html)
  must at least specify the x date variable.

## Value

A `ggplot2` plot.

## See also

Plotting functions
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/dev/reference/enw_plot_theme.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
obs <- enw_example("obs")

# Plot observed data by reference date
enw_plot_obs(obs, x = reference_date)


# Plot observed data by reference date with more recent data
enw_plot_obs(nowcast$latest[[1]], obs, x = reference_date)
```
