# Plot cumulative empirical reporting delay

Stacked ribbon plot showing the cumulative fraction reported by delay
group over reference dates.

## Usage

``` r
enw_plot_delay_cumulative(pobs, delay_group_thresh, facet = TRUE)
```

## Arguments

- pobs:

  A preprocessed data object as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- delay_group_thresh:

  A numeric vector defining left-closed interval thresholds for delay
  groups.

- facet:

  Logical. When `TRUE` (the default), plots with more than one `.group`
  are automatically wrapped by group. Set to `FALSE` to disable and add
  a custom facet layer.

## Value

A `ggplot2` plot.

## See also

Plotting functions
[`enw_delay_categories()`](https://package.epinowcast.org/dev/reference/enw_delay_categories.md),
[`enw_delay_quantiles()`](https://package.epinowcast.org/dev/reference/enw_delay_quantiles.md),
[`enw_plot_delay_counts()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_counts.md),
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
enw_plot_delay_cumulative(pobs, c(0, 2, 5, 10, 21))
```
