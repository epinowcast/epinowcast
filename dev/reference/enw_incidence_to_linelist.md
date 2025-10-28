# Convert Aggregate Counts (Incidence) to a Line List

This function takes a `data.table` of aggregate counts or something
coercible to a `data.table` (such as a `data.frame`) and converts it to
a line list where each row represents a case.

## Usage

``` r
enw_incidence_to_linelist(
  obs,
  reference_date = "reference_date",
  report_date = "report_date"
)
```

## Arguments

- obs:

  An object coercible to a `data.table` (such as a `data.frame`) which
  must have a `new_confirm` column.

- reference_date:

  A character string of the variable name to use for the
  `reference_date` in the line list. The default is "reference_date".

- report_date:

  A character string of the variable name to use for the `report_date`
  in the line list. The default is "report_date".

## Value

A `data.table` with the following variables: `id`, `reference_date`,
`report_date`, and any other variables in the `obs` object. Rows in
`obs` will be duplicated based on the `new_confirm` column.
`reference_date` and `report_date` may be renamed if `reference_date`
and `report_date` are supplied.

## See also

Data converters
[`enw_add_cumulative()`](https://package.epinowcast.org/dev/reference/enw_add_cumulative.md),
[`enw_add_incidence()`](https://package.epinowcast.org/dev/reference/enw_add_incidence.md),
[`enw_aggregate_cumulative()`](https://package.epinowcast.org/dev/reference/enw_aggregate_cumulative.md),
[`enw_linelist_to_incidence()`](https://package.epinowcast.org/dev/reference/enw_linelist_to_incidence.md)

## Examples

``` r
incidence <- enw_add_incidence(germany_covid19_hosp)
incidence <- enw_filter_reference_dates(
  incidence[location == "DE"], include_days = 10
)
enw_incidence_to_linelist(incidence, reference_date = "onset_date")
#>           id onset_date location age_group report_date delay
#>        <int>     <IDat>   <fctr>    <fctr>      <IDat> <int>
#>     1:     1 2021-10-11       DE       00+  2021-10-11     0
#>     2:     2 2021-10-11       DE       00+  2021-10-11     0
#>     3:     3 2021-10-11       DE       00+  2021-10-11     0
#>     4:     4 2021-10-11       DE       00+  2021-10-11     0
#>     5:     5 2021-10-11       DE       00+  2021-10-11     0
#>    ---                                                      
#> 16227: 16227 2021-10-20       DE       80+  2021-10-20     6
#> 16228: 16228 2021-10-20       DE       80+  2021-10-20     6
#> 16229: 16229 2021-10-20       DE       80+  2021-10-20     6
#> 16230: 16230 2021-10-20       DE       80+  2021-10-20     6
#> 16231: 16231 2021-10-20       DE       80+  2021-10-20     6
```
