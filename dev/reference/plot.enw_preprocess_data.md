# Plot method for enw_preprocess_data

`plot` method for preprocessed data of class `"enw_preprocess_data"`.
Creates descriptive plots of the empirical reporting delay distribution
and notification time series.

## Usage

``` r
# S3 method for class 'enw_preprocess_data'
plot(
  x,
  type = c("obs", "delay_cumulative", "delay_fraction", "delay_quantiles",
    "delay_counts"),
  delay_group_thresh = NULL,
  quantiles = c(0.1, 0.5, 0.9),
  log = FALSE,
  facet = TRUE,
  ...
)
```

## Arguments

- x:

  A preprocessed data object as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

- type:

  Character string indicating the plot type; enforced by
  [`base::match.arg()`](https://rdrr.io/r/base/match.arg.html). Options:

  - `"obs"` – latest observations (via
    [`enw_plot_obs()`](https://package.epinowcast.org/dev/reference/enw_plot_obs.md))

  - `"delay_cumulative"` – cumulative empirical delay (via
    [`enw_plot_delay_cumulative()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_cumulative.md))

  - `"delay_fraction"` – delay heatmap (via
    [`enw_plot_delay_fraction()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_fraction.md))

  - `"delay_quantiles"` – delay quantiles (via
    [`enw_plot_delay_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_quantiles.md))

  - `"delay_counts"` – notifications by delay group (via
    [`enw_plot_delay_counts()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_counts.md))

- delay_group_thresh:

  A numeric vector of left-closed interval thresholds for delay grouping
  (use `right = FALSE` semantics, so the upper bound should exceed
  `max_delay`). Used by `"delay_cumulative"`, `"delay_fraction"`, and
  `"delay_counts"`. Defaults to `NULL`, which auto-generates thresholds
  from `max_delay`.

- quantiles:

  A numeric vector of probabilities for the `"delay_quantiles"` type.
  Defaults to `c(0.1, 0.5, 0.9)`.

- log:

  Logical, defaults to `FALSE`. Should counts be plotted on the log
  scale (only for `"obs"` type).

- facet:

  Logical. When `TRUE` (the default), delay-based plots with more than
  one `.group` are automatically wrapped by group. Set to `FALSE` to
  disable and add a custom facet layer.

- ...:

  Additional arguments passed to the underlying plot function.

## Value

A `ggplot2` object.

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`print.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.enw_preprocess_data.md),
[`print.epinowcast()`](https://package.epinowcast.org/dev/reference/print.epinowcast.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md),
[`summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/summary.enw_preprocess_data.md),
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

Plotting functions
[`enw_delay_categories()`](https://package.epinowcast.org/dev/reference/enw_delay_categories.md),
[`enw_delay_quantiles()`](https://package.epinowcast.org/dev/reference/enw_delay_quantiles.md),
[`enw_plot_delay_counts()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_counts.md),
[`enw_plot_delay_cumulative()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_cumulative.md),
[`enw_plot_delay_fraction()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_fraction.md),
[`enw_plot_delay_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_delay_quantiles.md),
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/dev/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/dev/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/dev/reference/enw_plot_theme.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")

# Latest observations
plot(pobs, type = "obs")


# Cumulative reporting delay
plot(pobs, type = "delay_cumulative")


# Reporting delay heatmap
plot(pobs, type = "delay_fraction")


# Reporting delay quantiles
plot(pobs, type = "delay_quantiles")


# Notifications by delay group
plot(pobs, type = "delay_counts")
```
