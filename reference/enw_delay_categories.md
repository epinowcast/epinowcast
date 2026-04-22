# Categorise new confirmations by delay group

Categorises incidence by delay group with empirical reporting
proportions. Intended for use with the
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/reference/plot.enw_preprocess_data.md)
visualisation types that show reporting patterns by delay.

## Usage

``` r
enw_delay_categories(pobs, delay_group_thresh)
```

## Arguments

- pobs:

  A preprocessed data object as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md).

- delay_group_thresh:

  A numeric vector defining left-closed interval thresholds for grouping
  reporting delays. The smallest value should be zero and the largest
  should exceed `max_delay` (intervals are left-closed, right-open).
  Delays outside the range are dropped.

## Value

A `data.table` of notification incidence by reference date and delay
group, including columns `prop_reported` and `cum_prop_reported`.

## See also

Plotting functions
[`enw_delay_quantiles()`](https://package.epinowcast.org/reference/enw_delay_quantiles.md),
[`enw_plot_delay_counts()`](https://package.epinowcast.org/reference/enw_plot_delay_counts.md),
[`enw_plot_delay_cumulative()`](https://package.epinowcast.org/reference/enw_plot_delay_cumulative.md),
[`enw_plot_delay_fraction()`](https://package.epinowcast.org/reference/enw_plot_delay_fraction.md),
[`enw_plot_delay_quantiles()`](https://package.epinowcast.org/reference/enw_plot_delay_quantiles.md),
[`enw_plot_nowcast_quantiles()`](https://package.epinowcast.org/reference/enw_plot_nowcast_quantiles.md),
[`enw_plot_obs()`](https://package.epinowcast.org/reference/enw_plot_obs.md),
[`enw_plot_pp_quantiles()`](https://package.epinowcast.org/reference/enw_plot_pp_quantiles.md),
[`enw_plot_quantiles()`](https://package.epinowcast.org/reference/enw_plot_quantiles.md),
[`enw_plot_theme()`](https://package.epinowcast.org/reference/enw_plot_theme.md),
[`plot.enw_preprocess_data()`](https://package.epinowcast.org/reference/plot.enw_preprocess_data.md),
[`plot.epinowcast()`](https://package.epinowcast.org/reference/plot.epinowcast.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")
enw_delay_categories(pobs, delay_group_thresh = c(0, 2, 5, 10, 21))
#> Key: <.group>
#>      .group reference_date delay_group confirm new_confirm max_confirm
#>       <num>         <IDat>      <fctr>   <int>       <int>       <int>
#>   1:      1     2021-07-14       [0,2)      34          34          70
#>   2:      1     2021-07-14       [2,5)      43           9          70
#>   3:      1     2021-07-14      [5,10)      64          21          70
#>   4:      1     2021-07-14     [10,21)      70           6          70
#>   5:      1     2021-07-15       [0,2)      43          43          69
#>  ---                                                                  
#> 139:      1     2021-08-19       [2,5)     202          31         202
#> 140:      1     2021-08-20       [0,2)     159         159         171
#> 141:      1     2021-08-20       [2,5)     171          12         171
#> 142:      1     2021-08-21       [0,2)     112         112         112
#> 143:      1     2021-08-22       [0,2)      45          45          45
#>      prop_reported cum_prop_reported
#>              <num>             <num>
#>   1:    0.48571429         0.4857143
#>   2:    0.12857143         0.6142857
#>   3:    0.30000000         0.9142857
#>   4:    0.08571429         1.0000000
#>   5:    0.62318841         0.6231884
#>  ---                                
#> 139:    0.15346535         1.0000000
#> 140:    0.92982456         0.9298246
#> 141:    0.07017544         1.0000000
#> 142:    1.00000000         1.0000000
#> 143:    1.00000000         1.0000000
```
