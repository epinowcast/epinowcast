# Plot posterior prediction quantiles

Plot posterior prediction quantiles

## Usage

``` r
enw_plot_pp_quantiles(pp, log = FALSE, ...)
```

## Arguments

- pp:

  A `data.frame` of summarised posterior predictions estimates
  containing at least a `confirm` count column and a `report_date` date
  variable.

- log:

  Logical, defaults to `FALSE`. Should counts be plot on the log scale.

- ...:

  Additional arguments passed to `enw_plot_pp_quantiles()`.

## Value

A `ggplot2` plot.

## See also

Plotting functions
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/dev/reference/enw_plot_obs.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/dev/reference/enw_plot_theme.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
nowcast <- summary(
 nowcast, type = "posterior_prediction", probs = c(0.05, 0.2, 0.8, 0.95)
)
enw_plot_pp_quantiles(nowcast) +
 ggplot2::facet_wrap(ggplot2::vars(reference_date), scales = "free")
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
```
