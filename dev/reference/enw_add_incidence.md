# Calculate incidence of new reports from cumulative reports

Computes incident counts from cumulative reports. Users should typically
call
[`enw_filter_reference_dates_by_report_start()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates_by_report_start.md)
before this function to remove reference dates that precede the earliest
report date, which would otherwise produce spurious leading entries.

## Usage

``` r
enw_add_incidence(obs, set_negatives_to_zero = TRUE, by = NULL, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- set_negatives_to_zero:

  Logical, defaults to TRUE. Should negative counts (for calculated
  incidence of observations) be set to zero? Currently downstream
  modelling does not support negative counts and so setting must be TRUE
  if intending to use
  [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md).

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

The input `data.frame` with a new variable `new_confirm`. If
`max_confirm` is present in the `data.frame`, then the proportion
reported on each day (`prop_reported`) will also be added.

## See also

Data converters
[`enw_add_cumulative()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative.md),
[`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md),
[`enw_incidence_to_linelist()`](https://package.epinowcast.org/dev/reference/enw_incidence_to_linelist.md),
[`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)

## Examples

``` r
# Default reconstruct incidence
dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
dt <- enw_filter_reference_dates_by_report_start(dt)
enw_add_incidence(dt)
#> Key: <reference_date, report_date>
#>        reference_date location age_group confirm report_date new_confirm delay
#>                <IDat>   <fctr>    <fctr>   <int>      <IDat>       <int> <int>
#>     1:     2021-04-06       DE       00+     149  2021-04-06         149     0
#>     2:     2021-04-06       DE       00+     289  2021-04-07         140     1
#>     3:     2021-04-06       DE       00+     350  2021-04-08          61     2
#>     4:     2021-04-06       DE       00+     402  2021-04-09          52     3
#>     5:     2021-04-06       DE       00+     438  2021-04-10          36     4
#>    ---                                                                        
#> 12911:     2021-10-18       DE       00+     113  2021-10-19          70     1
#> 12912:     2021-10-18       DE       00+     142  2021-10-20          29     2
#> 12913:     2021-10-19       DE       00+     223  2021-10-19         223     0
#> 12914:     2021-10-19       DE       00+     387  2021-10-20         164     1
#> 12915:     2021-10-20       DE       00+     235  2021-10-20         235     0

# Make use of maximum reported to calculate empirical
# daily reporting
dt <- germany_covid19_hosp[location == "DE"][
  age_group == "00+"
]
dt <- enw_add_max_reported(dt)
dt <- enw_filter_reference_dates_by_report_start(dt)
enw_add_incidence(dt)
#> Key: <reference_date, report_date>
#>        reference_date report_date .group max_confirm location age_group confirm
#>                <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#>     1:     2021-04-06  2021-04-06      1         708       DE       00+     149
#>     2:     2021-04-06  2021-04-07      1         708       DE       00+     289
#>     3:     2021-04-06  2021-04-08      1         708       DE       00+     350
#>     4:     2021-04-06  2021-04-09      1         708       DE       00+     402
#>     5:     2021-04-06  2021-04-10      1         708       DE       00+     438
#>    ---                                                                         
#> 12911:     2021-10-18  2021-10-19      1         142       DE       00+     113
#> 12912:     2021-10-18  2021-10-20      1         142       DE       00+     142
#> 12913:     2021-10-19  2021-10-19      1         387       DE       00+     223
#> 12914:     2021-10-19  2021-10-20      1         387       DE       00+     387
#> 12915:     2021-10-20  2021-10-20      1         235       DE       00+     235
#>        cum_prop_reported new_confirm delay prop_reported
#>                    <num>       <int> <int>         <num>
#>     1:         0.2104520         149     0    0.21045198
#>     2:         0.4081921         140     1    0.19774011
#>     3:         0.4943503          61     2    0.08615819
#>     4:         0.5677966          52     3    0.07344633
#>     5:         0.6186441          36     4    0.05084746
#>    ---                                                  
#> 12911:         0.7957746          70     1    0.49295775
#> 12912:         1.0000000          29     2    0.20422535
#> 12913:         0.5762274         223     0    0.57622739
#> 12914:         1.0000000         164     1    0.42377261
#> 12915:         1.0000000         235     0    1.00000000
```
