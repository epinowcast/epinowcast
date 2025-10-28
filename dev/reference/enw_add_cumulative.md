# Calculate cumulative reported cases from incidence of new reports

Calculate cumulative reported cases from incidence of new reports

## Usage

``` r
enw_add_cumulative(obs, by = NULL, copy = TRUE)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `new_confirm` (incident observations by
  reference and report date).

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

The input `data.frame` with a new variable `confirm`.

## See also

Data converters
[`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md),
[`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md),
[`enw_incidence_to_linelist()`](https://package.epinowcast.org/dev/reference/enw_incidence_to_linelist.md),
[`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)

## Examples

``` r
# Default reconstruct incidence
dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
dt <- enw_add_incidence(dt)
dt <- dt[, confirm := NULL]
enw_add_cumulative(dt)
#> Key: <reference_date, report_date>
#>        reference_date location age_group report_date new_confirm delay confirm
#>                <IDat>   <fctr>    <fctr>      <IDat>       <int> <int>   <int>
#>     1:     2021-04-06       DE       00+  2021-04-06         149     0     149
#>     2:     2021-04-06       DE       00+  2021-04-07         140     1     289
#>     3:     2021-04-06       DE       00+  2021-04-08          61     2     350
#>     4:     2021-04-06       DE       00+  2021-04-09          52     3     402
#>     5:     2021-04-06       DE       00+  2021-04-10          36     4     438
#>    ---                                                                        
#> 12911:     2021-10-18       DE       00+  2021-10-19          70     1     113
#> 12912:     2021-10-18       DE       00+  2021-10-20          29     2     142
#> 12913:     2021-10-19       DE       00+  2021-10-19         223     0     223
#> 12914:     2021-10-19       DE       00+  2021-10-20         164     1     387
#> 12915:     2021-10-20       DE       00+  2021-10-20         235     0     235

# Make use of maximum reported to calculate empirical daily reporting
enw_add_cumulative(dt)
#> Key: <reference_date, report_date>
#>        reference_date location age_group report_date new_confirm delay confirm
#>                <IDat>   <fctr>    <fctr>      <IDat>       <int> <int>   <int>
#>     1:     2021-04-06       DE       00+  2021-04-06         149     0     149
#>     2:     2021-04-06       DE       00+  2021-04-07         140     1     289
#>     3:     2021-04-06       DE       00+  2021-04-08          61     2     350
#>     4:     2021-04-06       DE       00+  2021-04-09          52     3     402
#>     5:     2021-04-06       DE       00+  2021-04-10          36     4     438
#>    ---                                                                        
#> 12911:     2021-10-18       DE       00+  2021-10-19          70     1     113
#> 12912:     2021-10-18       DE       00+  2021-10-20          29     2     142
#> 12913:     2021-10-19       DE       00+  2021-10-19         223     0     223
#> 12914:     2021-10-19       DE       00+  2021-10-20         164     1     387
#> 12915:     2021-10-20       DE       00+  2021-10-20         235     0     235
```
