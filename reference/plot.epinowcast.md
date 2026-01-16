# Plot method for epinowcast

`plot` method for class "epinowcast".

## Usage

``` r
# S3 method for class 'epinowcast'
plot(
  x,
  latest_obs = NULL,
  type = c("nowcast", "posterior_prediction"),
  log = FALSE,
  ...
)
```

## Arguments

- x:

  A `data.table` of output as produced by
  [`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md).

- latest_obs:

  A `data.frame` of observed data which may be passed to lower level
  methods.

- type:

  Character string indicating the plot required; enforced by
  [`base::match.arg()`](https://rdrr.io/r/base/match.arg.html).
  Currently supported options:

  - "nowcast" which plots the nowcast for each dataset along with latest
    available observed data using
    [`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md),

  - "posterior_prediction" which plots observations reported at the time
    against simulated observations from the model using
    [`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md).

- log:

  Logical, defaults to `FALSE`. Should counts be plot on the log scale.

- ...:

  Additional arguments to the plot function specified by `type`.

## Value

`ggplot2` object

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md),
[`summary.epinowcast()`](https://package.epinowcast.org/reference/summary.epinowcast.md)

Plotting functions
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/reference/enw_plot_theme.md)

## Examples

``` r
nowcast <- enw_example("nowcast")
latest_obs <- enw_example("obs")

# Plot nowcast
plot(nowcast, latest_obs = latest_obs, type = "nowcast")


# Plot posterior predictions by reference date
plot(nowcast, type = "posterior_prediction") +
 ggplot2::facet_wrap(ggplot2::vars(reference_date), scales = "free")
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
```
