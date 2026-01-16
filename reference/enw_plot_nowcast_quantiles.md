# Plot nowcast quantiles

Plot nowcast quantiles

## Usage

``` r
enw_plot_nowcast_quantiles(nowcast, latest_obs = NULL, log = FALSE, ...)
```

## Arguments

- nowcast:

  A `data.frame` of summarised posterior nowcast estimates containing at
  least a `confirm` count column and a `reference_date` date variable.

- latest_obs:

  A `data.frame` of observed data containing at least a `confirm` count
  variable and the same date variable as in the main data.frame used for
  plotting.

- log:

  Logical, defaults to `FALSE`. Should counts be plot on the log scale.

- ...:

  Additional arguments passed to
  [`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md).

## Value

A `ggplot2` plot.

## See also

Plotting functions
[`enw_plot_obs()`](https://package.epinowcast.org/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/reference/enw_plot_theme.md),
[`plot.epinowcast()`](https://package.epinowcast.org/reference/plot.epinowcast.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
nowcast <- summary(nowcast, probs = c(0.05, 0.2, 0.8, 0.95))
enw_plot_nowcast_quantiles(nowcast)
```
