# Convert an epinowcast object to a forecast_sample object

This function is used to convert an `epinowcast` as returned by
[`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md)
object to a `forecast_sample` object which can be used for scoring using
the `scoringutils` package.

## Usage

``` r
# S3 method for class 'epinowcast'
as_forecast_sample(data, latest_obs, ...)
```

## Arguments

- data:

  An `epinowcast` nowcast object as returned by
  [`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md).

- latest_obs:

  Latest observations to use for the true values must contain `confirm`
  and `observed` variables.

- ...:

  Additional arguments passed to
  [`scoringutils::as_forecast_sample()`](https://epiforecasts.io/scoringutils/reference/as_forecast_sample.html)

## Value

A `forecast_sample` object as returned by
[`scoringutils::as_forecast_sample()`](https://epiforecasts.io/scoringutils/reference/as_forecast_sample.html)

## Examples

``` r
if (FALSE) { # interactive()
library(scoringutils)

nowcast <- enw_example("nowcast")
latest_obs <- enw_example("observations")
as_forecast_sample(nowcast, latest_obs)
}
```
