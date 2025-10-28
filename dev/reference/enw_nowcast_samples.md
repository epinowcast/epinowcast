# Extract posterior samples for the nowcast prediction

A generic wrapper around
[`posterior::draws_df()`](https://mc-stan.org/posterior/reference/draws_df.html)
with opinionated defaults to extract the posterior samples for the
nowcast (`"pp_inf_obs"` from the `stan` code). The functionality of this
function can be used directly on the output of
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
using the supplied
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)
method.

## Usage

``` r
enw_nowcast_samples(fit, obs, max_delay = NULL, timestep = "day")
```

## Arguments

- fit:

  A `cmdstanr` fit object.

- obs:

  An observation `data.frame` containing `reference_date` columns of the
  same length as the number of rows in the posterior and the most up to
  date observation for each date. This is used to align the posterior
  with the observations. The easiest source of this data is the output
  of latest output of
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  or
  [`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md).

- max_delay:

  Maximum delay to which nowcasts should be extracted, in units of the
  timestep used during preprocessing. Must be equal (default) or larger
  than the modelled maximum delay. If it is larger, then nowcasts for
  unmodelled dates are added by assuming that case counts beyond the
  modelled maximum delay are fully observed.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

## Value

A `data.frame` of posterior samples for the nowcast prediction. This
uses observed data where available and the posterior prediction where
not.

## See also

Functions used for postprocessing of model fits
[`build_ord_obs()`](https://package.epinowcast.org/dev/reference/build_ord_obs.md),
[`enw_add_latest_obs_to_nowcast()`](https://package.epinowcast.org/dev/reference/enw_add_latest_obs_to_nowcast.md),
[`enw_nowcast_summary()`](https://package.epinowcast.org/dev/reference/enw_nowcast_summary.md),
[`enw_posterior()`](https://package.epinowcast.org/dev/reference/enw_posterior.md),
[`enw_pp_summary()`](https://package.epinowcast.org/dev/reference/enw_pp_summary.md),
[`enw_quantiles_to_long()`](https://package.epinowcast.org/dev/reference/enw_quantiles_to_long.md),
[`enw_summarise_samples()`](https://package.epinowcast.org/dev/reference/enw_summarise_samples.md),
[`subset_obs()`](https://package.epinowcast.org/dev/reference/subset_obs.md)

## Examples

``` r
fit <- enw_example("nowcast")
enw_nowcast_samples(
  fit$fit[[1]],
  fit$latest[[1]],
  fit$max_delay,
  "day"
  )
#>        reference_date report_date .group max_confirm location age_group confirm
#>                <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>     1:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     2:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     3:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     4:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>     5:     2021-08-03  2021-08-22      1         149       DE       00+     149
#>    ---                                                                         
#> 19996:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19997:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19998:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 19999:     2021-08-22  2021-08-22      1          45       DE       00+      45
#> 20000:     2021-08-22  2021-08-22      1          45       DE       00+      45
#>        cum_prop_reported delay prop_reported .chain .iteration .draw sample
#>                    <num> <num>         <num>  <int>      <int> <int>  <num>
#>     1:                 1    19             0      1          1     1    149
#>     2:                 1    19             0      1          2     2    149
#>     3:                 1    19             0      1          3     3    149
#>     4:                 1    19             0      1          4     4    149
#>     5:                 1    19             0      1          5     5    149
#>    ---                                                                     
#> 19996:                 1     0             1      2        496   996    453
#> 19997:                 1     0             1      2        497   997    274
#> 19998:                 1     0             1      2        498   998    250
#> 19999:                 1     0             1      2        499   999    432
#> 20000:                 1     0             1      2        500  1000    491
```
