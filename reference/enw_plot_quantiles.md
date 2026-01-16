# Generic quantile plot

Generic quantile plot

## Usage

``` r
enw_plot_quantiles(posterior, latest_obs = NULL, log = FALSE, ...)
```

## Arguments

- posterior:

  A `data.frame` of summarised posterior estimates containing at least a
  `confirm` count column a date variable, quantile estimates for the 5%,
  20%, 80%, and 95% quantiles and the mean and median. This function is
  wrapped in
  [`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md)
  and
  [`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md)
  with sensible default labels.

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

[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md)

Plotting functions
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/reference/enw_plot_theme.md),
[`plot.epinowcast()`](https://package.epinowcast.org/reference/plot.epinowcast.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
nowcast <- summary(nowcast, probs = c(0.05, 0.2, 0.8, 0.95))
enw_plot_quantiles(nowcast, x = reference_date)
```
