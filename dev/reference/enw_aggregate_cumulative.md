# Aggregate observations over a given timestep for both report and reference dates.

This function aggregates observations over a specified timestep,
ensuring alignment on the same day of week for report and reference
dates. It is useful for aggregating data to a weekly timestep, for
example which may be desirable if testing using a weekly timestep or if
you are very concerned about runtime. Note that the start of the
timestep will be determined by `min_date` + a single timestep (i.e. the
first timestep will be "2022-10-23" if the minimum reference date is
"2022-10-16"). Observations where the report dates do not form a
complete timestep will be dropped from the aggregated output.

## Usage

``` r
enw_aggregate_cumulative(
  obs,
  timestep = "day",
  by = NULL,
  min_reference_date = min(obs$reference_date, na.rm = TRUE),
  copy = TRUE
)
```

## Arguments

- obs:

  An object coercible to a `data.table` (such as a `data.frame`) which
  must have a `new_confirm` numeric column, and `report_date` and
  `reference_date` date columns. The input must have a timestep of a day
  and be complete. See
  [`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md)
  for more information. If NA values are present in the `confirm` column
  then these will be set to zero before aggregation this may not be
  desirable if this missingness is meaningful. Before aggregation, dates
  will be completed up to the last reference date to ensure all
  reference dates have the required report dates for the specified
  timestep.

- timestep:

  The timestep to used. This can be a string ("day", "week") or a
  numeric whole number representing the number of days. Note that
  "month" is not currently supported in user-facing functions and will
  throw an error if used.

- by:

  A character vector of variables to also aggregate by (i.e. as well as
  using the `reference_date` and `report_date`). If not supplied then
  the function will aggregate by just the `reference_date` and
  `report_date`.

- min_reference_date:

  The minimum reference date to start the aggregation from. Note that
  the timestep will start from the minimum reference date + a single
  time step (i.e. the first timestep will be "2022-10-23" if the minimum
  reference date is "2022-10-16"). The default is the minimum reference
  date in the `obs` object. Other sensible values would be the minimum
  report date in the `obs` object + 1 day if reporting is already weekly
  and you wish to ensure that the timestep of the output matches the
  reporting timestep.

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

A data.table with aggregated observations.

## See also

Data converters
[`enw_add_cumulative()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative.md),
[`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md),
[`enw_incidence_to_linelist()`](https://package.epinowcast.org/dev/reference/enw_incidence_to_linelist.md),
[`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)

## Examples

``` r
nat_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
enw_aggregate_cumulative(nat_hosp, timestep = "week")
#> Key: <reference_date, report_date>
#>      report_date reference_date location age_group confirm new_confirm delay
#>           <IDat>         <IDat>   <fctr>    <fctr>   <int>       <int> <int>
#>   1:  2021-04-12           <NA>     <NA>      <NA>       0           0     0
#>   2:  2021-04-19           <NA>     <NA>      <NA>       0           0     1
#>   3:  2021-04-26           <NA>     <NA>      <NA>       0           0     2
#>   4:  2021-05-03           <NA>     <NA>      <NA>       0           0     3
#>   5:  2021-05-10           <NA>     <NA>      <NA>       0           0     4
#>  ---                                                                        
#> 430:  2021-10-11     2021-10-04       DE       00+    2091         799     1
#> 431:  2021-10-18     2021-10-04       DE       00+    2346         255     2
#> 432:  2021-10-11     2021-10-11       DE       00+    1312        1312     0
#> 433:  2021-10-18     2021-10-11       DE       00+    2163         851     1
#> 434:  2021-10-18     2021-10-18       DE       00+    1597        1597     0
```
