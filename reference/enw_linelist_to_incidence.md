# Convert a Line List to Aggregate Counts (Incidence)

This function takes a line list (i.e. tabular data where each row
represents a case) and aggregates to a count (`new_confirm`) of cases by
user-specified `reference_date`s and `report_date`s. This is enables the
use of
[`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md)
and other
[`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md)
preprocessing functions.

## Usage

``` r
enw_linelist_to_incidence(
  linelist,
  reference_date = "reference_date",
  report_date = "report_date",
  by = NULL,
  max_delay,
  completion_beyond_max_report = FALSE,
  copy = TRUE
)
```

## Arguments

- linelist:

  An object coercible to a `data.table` (such as a `data.frame`) where
  each row represents a case. Must contain at least two date variables
  or variables that can be coerced to dates.

- reference_date:

  A date or a variable that can be coerced to a date that represents the
  date of interest for the case. For example, if the `reference_date` is
  the date of symptom onset then the `new_confirm` will be the number of
  new cases reported (based on `report_date`) on each day that had onset
  on that day. The default is "reference_date".

- report_date:

  A date or a variable that can be coerced to a date that represents the
  date the case was reported. The default is "report_date".

- by:

  A character vector of variables to also aggregate by (i.e. as well as
  using the `reference_date` and `report_date`). If not supplied then
  the function will aggregate by just the `reference_date` and
  `report_date`.

- max_delay:

  The maximum delay (in days) between the `reference_date` and the
  `report_date`. If not supplied then the function will use the maximum
  observed delay. Note that this function operates before timestep
  conversion, so max_delay is always in days here. If the `max_delay` is
  less than the maximum number of days between the `reference_date` and
  the `report_date` in the `linelist` then the function will use this
  value instead and inform the user.

- completion_beyond_max_report:

  Logical, should entries be completed beyond the maximum date found in
  the data? Default: FALSE

- copy:

  Should `obs` be copied (default) or modified in place?

## Value

A `data.table` with the following variables: `reference_date`,
`report_date`, `new_confirm`, `confirm`, `delay`, and any variables
specified in `by`.

## See also

Data converters
[`enw_add_cumulative()`](https://package.epinowcast.org/reference/enw_add_cumulative.md),
[`enw_add_incidence()`](https://package.epinowcast.org/reference/enw_add_incidence.md),
[`enw_aggregate_cumulative()`](https://package.epinowcast.org/reference/enw_aggregate_cumulative.md),
[`enw_incidence_to_linelist()`](https://package.epinowcast.org/reference/enw_incidence_to_linelist.md)

## Examples

``` r
linelist <- data.frame(
  onset_date = as.Date(c("2021-01-02", "2021-01-03", "2021-01-02")),
  report_date = as.Date(c("2021-01-03", "2021-01-05", "2021-01-04"))
)
enw_linelist_to_incidence(linelist, reference_date = "onset_date")
#> Using the maximum observed delay of 4 days to complete the incidence data.
#> Key: <reference_date, report_date>
#>     report_date reference_date new_confirm confirm delay
#>          <IDat>         <IDat>       <int>   <int> <int>
#>  1:  2021-01-02           <NA>           0       0     0
#>  2:  2021-01-03           <NA>           0       0     1
#>  3:  2021-01-04           <NA>           0       0     2
#>  4:  2021-01-05           <NA>           0       0     3
#>  5:  2021-01-02     2021-01-02           0       0     0
#>  6:  2021-01-03     2021-01-02           1       1     1
#>  7:  2021-01-04     2021-01-02           1       2     2
#>  8:  2021-01-05     2021-01-02           0       2     3
#>  9:  2021-01-03     2021-01-03           0       0     0
#> 10:  2021-01-04     2021-01-03           0       0     1
#> 11:  2021-01-05     2021-01-03           1       1     2
#> 12:  2021-01-04     2021-01-04           0       0     0
#> 13:  2021-01-05     2021-01-04           0       0     1
#> 14:  2021-01-05     2021-01-05           0       0     0

# Specify a custom maximum delay and allow completion beyond the maximum
# observed delay
enw_linelist_to_incidence(
 linelist, reference_date = "onset_date", max_delay = 5,
 completion_beyond_max_report = TRUE
)
#> Key: <reference_date, report_date>
#>     report_date reference_date new_confirm confirm delay
#>          <IDat>         <IDat>       <int>   <int> <int>
#>  1:  2021-01-02           <NA>           0       0     0
#>  2:  2021-01-03           <NA>           0       0     1
#>  3:  2021-01-04           <NA>           0       0     2
#>  4:  2021-01-05           <NA>           0       0     3
#>  5:  2021-01-02     2021-01-02           0       0     0
#>  6:  2021-01-03     2021-01-02           1       1     1
#>  7:  2021-01-04     2021-01-02           1       2     2
#>  8:  2021-01-05     2021-01-02           0       2     3
#>  9:  2021-01-06     2021-01-02           0       2     4
#> 10:  2021-01-07     2021-01-02           0       2     5
#> 11:  2021-01-03     2021-01-03           0       0     0
#> 12:  2021-01-04     2021-01-03           0       0     1
#> 13:  2021-01-05     2021-01-03           1       1     2
#> 14:  2021-01-06     2021-01-03           0       1     3
#> 15:  2021-01-07     2021-01-03           0       1     4
#> 16:  2021-01-08     2021-01-03           0       1     5
#> 17:  2021-01-04     2021-01-04           0       0     0
#> 18:  2021-01-05     2021-01-04           0       0     1
#> 19:  2021-01-06     2021-01-04           0       0     2
#> 20:  2021-01-07     2021-01-04           0       0     3
#> 21:  2021-01-08     2021-01-04           0       0     4
#> 22:  2021-01-09     2021-01-04           0       0     5
#> 23:  2021-01-05     2021-01-05           0       0     0
#> 24:  2021-01-06     2021-01-05           0       0     1
#> 25:  2021-01-07     2021-01-05           0       0     2
#> 26:  2021-01-08     2021-01-05           0       0     3
#> 27:  2021-01-09     2021-01-05           0       0     4
#> 28:  2021-01-10     2021-01-05           0       0     5
#>     report_date reference_date new_confirm confirm delay
#>          <IDat>         <IDat>       <int>   <int> <int>
```
