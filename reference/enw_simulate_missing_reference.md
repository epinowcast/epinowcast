# Simulate observations with a missing reference date.

A simple binomial simulator of missing data by reference date using
simulated or observed data as an input. This function may be used to
validate missing data models, as part of examples and case studies, or
to explore the implications of missing data for your use case.

## Usage

``` r
enw_simulate_missing_reference(obs, proportion = 0.2, by = NULL)
```

## Arguments

- obs:

  A `data.frame` containing at least the following variables:
  `reference date` (index date of interest), `report_date` (report date
  for observations), and `confirm` (cumulative observations by reference
  and report date).

- proportion:

  Numeric, the proportion of observations that are missing a reference
  date, indexed by reference date. Currently only a fixed proportion are
  supported and this defaults to 0.2.

- by:

  A character vector describing the stratification of observations. This
  defaults to no grouping. This should be used when modelling multiple
  time series in order to identify them for downstream modelling

## Value

A `data.table` of the same format as the input but with a simulated
proportion of observations now having a missing reference date.

## Examples

``` r
# Load and filter germany hospitalisations
nat_germany_hosp <- subset(
  germany_covid19_hosp, location == "DE" & age_group == "00+"
)
nat_germany_hosp <- enw_filter_report_dates(
  nat_germany_hosp,
  latest_date = "2021-08-01"
)

# Make sure observations are complete
nat_germany_hosp <- enw_complete_dates(
  nat_germany_hosp,
  by = c("location", "age_group"), missing_reference = FALSE
)

# Simulate
enw_simulate_missing_reference(
  nat_germany_hosp,
  proportion = 0.35, by = c("location", "age_group")
)
#> Key: <location, age_group, reference_date, report_date>
#>       location age_group report_date reference_date confirm
#>         <fctr>    <fctr>      <IDat>         <IDat>   <num>
#>    1:       DE       00+  2021-04-06           <NA>      51
#>    2:       DE       00+  2021-04-07           <NA>     151
#>    3:       DE       00+  2021-04-08           <NA>     231
#>    4:       DE       00+  2021-04-09           <NA>     230
#>    5:       DE       00+  2021-04-10           <NA>     226
#>   ---                                                      
#> 7135:       DE       00+  2021-07-31     2021-07-30      37
#> 7136:       DE       00+  2021-08-01     2021-07-30      37
#> 7137:       DE       00+  2021-07-31     2021-07-31      19
#> 7138:       DE       00+  2021-08-01     2021-07-31      26
#> 7139:       DE       00+  2021-08-01     2021-08-01       4
```
