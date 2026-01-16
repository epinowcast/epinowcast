# Add common metadata variables

If not already present, annotates time series data with metadata
commonly used in models: day of week, and days, weeks, and months since
start of time series.

## Usage

``` r
enw_add_metaobs_features(
  metaobs,
  holidays = NULL,
  holidays_to = "Sunday",
  datecol = "date"
)
```

## Arguments

- metaobs:

  Raw data, coercible via
  [`data.table::as.data.table()`](https://rdatatable.gitlab.io/data.table/reference/as.data.table.html).
  Coerced object must have [Dates](https://rdrr.io/r/base/Dates.html)
  column corresponding to `datecol` name.

- holidays:

  a (potentially empty) vector of dates (or input coercible to such; see
  [`coerce_date()`](https://package.epinowcast.org/reference/coerce_date.md)).
  The `day_of_week` column will be set to `holidays_to` for these dates.

- holidays_to:

  A character string to assign to holidays, when `holidays` argument
  non-empty. Replaces the `day_of_week` column value

- datecol:

  The column in `metaobs` corresponding to pertinent dates.

## Value

A copy of the `metaobs` input, with additional columns:

- `day_of_week`, a factor of values as output from
  [`weekdays()`](https://rdrr.io/r/base/weekday.POSIXt.html) and
  possibly as `holiday_to` if distinct from weekdays values

- `day`, numeric, 0 based from start of time series

- `week`, numeric, 0 based from start of time series

- `month`, numeric, 0 based from start of time series

## Details

Effects models often need to include covariates for time-based features,
such as day of the week (e.g. to reflect different care-seeking and/or
reporting behaviour).

This function is called from within
[`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md)
to systematically annotate `metaobs` with these commonly used metadata,
if not already present.

However, it can also be used directly on other data.

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/reference/enw_add_max_reported.md),
[`enw_assign_group()`](https://package.epinowcast.org/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/reference/enw_complete_dates.md),
[`enw_construct_data()`](https://package.epinowcast.org/reference/enw_construct_data.md),
[`enw_extend_date()`](https://package.epinowcast.org/reference/enw_extend_date.md),
[`enw_filter_delay()`](https://package.epinowcast.org/reference/enw_filter_delay.md),
[`enw_filter_reference_dates()`](https://package.epinowcast.org/reference/enw_filter_reference_dates.md),
[`enw_filter_report_dates()`](https://package.epinowcast.org/reference/enw_filter_report_dates.md),
[`enw_flag_observed_observations()`](https://package.epinowcast.org/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
# make some example date
nat_germany_hosp <- subset(
  germany_covid19_hosp,
  location == "DE" & age_group == "80+"
)[1:40]

basemeta <- enw_add_metaobs_features(
  nat_germany_hosp,
  datecol = "report_date"
)
basemeta
#> Key: <report_date>
#>     reference_date location age_group confirm report_date day_of_week   day
#>             <IDat>   <fctr>    <fctr>   <int>      <Date>      <fctr> <num>
#>  1:     2021-04-06       DE       80+      35  2021-04-06     Tuesday     0
#>  2:     2021-04-07       DE       80+      81  2021-04-07   Wednesday     1
#>  3:     2021-04-08       DE       80+      85  2021-04-08    Thursday     2
#>  4:     2021-04-09       DE       80+      62  2021-04-09      Friday     3
#>  5:     2021-04-10       DE       80+      45  2021-04-10    Saturday     4
#>  6:     2021-04-11       DE       80+      23  2021-04-11      Sunday     5
#>  7:     2021-04-12       DE       80+      33  2021-04-12      Monday     6
#>  8:     2021-04-13       DE       80+      66  2021-04-13     Tuesday     7
#>  9:     2021-04-14       DE       80+      50  2021-04-14   Wednesday     8
#> 10:     2021-04-15       DE       80+      66  2021-04-15    Thursday     9
#> 11:     2021-04-16       DE       80+      67  2021-04-16      Friday    10
#> 12:     2021-04-17       DE       80+      50  2021-04-17    Saturday    11
#> 13:     2021-04-18       DE       80+      33  2021-04-18      Sunday    12
#> 14:     2021-04-19       DE       80+      25  2021-04-19      Monday    13
#> 15:     2021-04-20       DE       80+      53  2021-04-20     Tuesday    14
#> 16:     2021-04-21       DE       80+      68  2021-04-21   Wednesday    15
#> 17:     2021-04-22       DE       80+      56  2021-04-22    Thursday    16
#> 18:     2021-04-23       DE       80+      61  2021-04-23      Friday    17
#> 19:     2021-04-24       DE       80+      45  2021-04-24    Saturday    18
#> 20:     2021-04-25       DE       80+      35  2021-04-25      Sunday    19
#> 21:     2021-04-26       DE       80+      17  2021-04-26      Monday    20
#> 22:     2021-04-27       DE       80+      50  2021-04-27     Tuesday    21
#> 23:     2021-04-28       DE       80+      56  2021-04-28   Wednesday    22
#> 24:     2021-04-29       DE       80+      44  2021-04-29    Thursday    23
#> 25:     2021-04-30       DE       80+      54  2021-04-30      Friday    24
#> 26:     2021-05-01       DE       80+      48  2021-05-01    Saturday    25
#> 27:     2021-05-02       DE       80+      27  2021-05-02      Sunday    26
#> 28:     2021-05-03       DE       80+      26  2021-05-03      Monday    27
#> 29:     2021-05-04       DE       80+      55  2021-05-04     Tuesday    28
#> 30:     2021-05-05       DE       80+      59  2021-05-05   Wednesday    29
#> 31:     2021-05-06       DE       80+      58  2021-05-06    Thursday    30
#> 32:     2021-05-07       DE       80+      48  2021-05-07      Friday    31
#> 33:     2021-05-08       DE       80+      34  2021-05-08    Saturday    32
#> 34:     2021-05-09       DE       80+      10  2021-05-09      Sunday    33
#> 35:     2021-05-10       DE       80+      24  2021-05-10      Monday    34
#> 36:     2021-05-11       DE       80+      49  2021-05-11     Tuesday    35
#> 37:     2021-05-12       DE       80+      42  2021-05-12   Wednesday    36
#> 38:     2021-05-13       DE       80+      39  2021-05-13    Thursday    37
#> 39:     2021-05-14       DE       80+      15  2021-05-14      Friday    38
#> 40:     2021-05-15       DE       80+      23  2021-05-15    Saturday    39
#>     reference_date location age_group confirm report_date day_of_week   day
#>             <IDat>   <fctr>    <fctr>   <int>      <Date>      <fctr> <num>
#>      week month
#>     <num> <num>
#>  1:     0     0
#>  2:     0     0
#>  3:     0     0
#>  4:     0     0
#>  5:     0     0
#>  6:     0     0
#>  7:     0     0
#>  8:     1     0
#>  9:     1     0
#> 10:     1     0
#> 11:     1     0
#> 12:     1     0
#> 13:     1     0
#> 14:     1     0
#> 15:     2     0
#> 16:     2     0
#> 17:     2     0
#> 18:     2     0
#> 19:     2     0
#> 20:     2     0
#> 21:     2     0
#> 22:     3     0
#> 23:     3     0
#> 24:     3     0
#> 25:     3     0
#> 26:     3     1
#> 27:     3     1
#> 28:     3     1
#> 29:     4     1
#> 30:     4     1
#> 31:     4     1
#> 32:     4     1
#> 33:     4     1
#> 34:     4     1
#> 35:     4     1
#> 36:     5     1
#> 37:     5     1
#> 38:     5     1
#> 39:     5     1
#> 40:     5     1
#>      week month
#>     <num> <num>

# with holidays - n.b.: holidays not found are silently ignored
holidaymeta <- enw_add_metaobs_features(
  nat_germany_hosp,
  datecol = "report_date",
  holidays = c(
    "2021-04-04", "2021-04-05",
    "2021-05-01", "2021-05-13",
    "2021-05-24"
  ),
  holidays_to = "Holiday"
)
holidaymeta
#> Key: <report_date>
#>     reference_date location age_group confirm report_date day_of_week   day
#>             <IDat>   <fctr>    <fctr>   <int>      <Date>      <fctr> <num>
#>  1:     2021-04-06       DE       80+      35  2021-04-06     Tuesday     0
#>  2:     2021-04-07       DE       80+      81  2021-04-07   Wednesday     1
#>  3:     2021-04-08       DE       80+      85  2021-04-08    Thursday     2
#>  4:     2021-04-09       DE       80+      62  2021-04-09      Friday     3
#>  5:     2021-04-10       DE       80+      45  2021-04-10    Saturday     4
#>  6:     2021-04-11       DE       80+      23  2021-04-11      Sunday     5
#>  7:     2021-04-12       DE       80+      33  2021-04-12      Monday     6
#>  8:     2021-04-13       DE       80+      66  2021-04-13     Tuesday     7
#>  9:     2021-04-14       DE       80+      50  2021-04-14   Wednesday     8
#> 10:     2021-04-15       DE       80+      66  2021-04-15    Thursday     9
#> 11:     2021-04-16       DE       80+      67  2021-04-16      Friday    10
#> 12:     2021-04-17       DE       80+      50  2021-04-17    Saturday    11
#> 13:     2021-04-18       DE       80+      33  2021-04-18      Sunday    12
#> 14:     2021-04-19       DE       80+      25  2021-04-19      Monday    13
#> 15:     2021-04-20       DE       80+      53  2021-04-20     Tuesday    14
#> 16:     2021-04-21       DE       80+      68  2021-04-21   Wednesday    15
#> 17:     2021-04-22       DE       80+      56  2021-04-22    Thursday    16
#> 18:     2021-04-23       DE       80+      61  2021-04-23      Friday    17
#> 19:     2021-04-24       DE       80+      45  2021-04-24    Saturday    18
#> 20:     2021-04-25       DE       80+      35  2021-04-25      Sunday    19
#> 21:     2021-04-26       DE       80+      17  2021-04-26      Monday    20
#> 22:     2021-04-27       DE       80+      50  2021-04-27     Tuesday    21
#> 23:     2021-04-28       DE       80+      56  2021-04-28   Wednesday    22
#> 24:     2021-04-29       DE       80+      44  2021-04-29    Thursday    23
#> 25:     2021-04-30       DE       80+      54  2021-04-30      Friday    24
#> 26:     2021-05-01       DE       80+      48  2021-05-01     Holiday    25
#> 27:     2021-05-02       DE       80+      27  2021-05-02      Sunday    26
#> 28:     2021-05-03       DE       80+      26  2021-05-03      Monday    27
#> 29:     2021-05-04       DE       80+      55  2021-05-04     Tuesday    28
#> 30:     2021-05-05       DE       80+      59  2021-05-05   Wednesday    29
#> 31:     2021-05-06       DE       80+      58  2021-05-06    Thursday    30
#> 32:     2021-05-07       DE       80+      48  2021-05-07      Friday    31
#> 33:     2021-05-08       DE       80+      34  2021-05-08    Saturday    32
#> 34:     2021-05-09       DE       80+      10  2021-05-09      Sunday    33
#> 35:     2021-05-10       DE       80+      24  2021-05-10      Monday    34
#> 36:     2021-05-11       DE       80+      49  2021-05-11     Tuesday    35
#> 37:     2021-05-12       DE       80+      42  2021-05-12   Wednesday    36
#> 38:     2021-05-13       DE       80+      39  2021-05-13     Holiday    37
#> 39:     2021-05-14       DE       80+      15  2021-05-14      Friday    38
#> 40:     2021-05-15       DE       80+      23  2021-05-15    Saturday    39
#>     reference_date location age_group confirm report_date day_of_week   day
#>             <IDat>   <fctr>    <fctr>   <int>      <Date>      <fctr> <num>
#>      week month
#>     <num> <num>
#>  1:     0     0
#>  2:     0     0
#>  3:     0     0
#>  4:     0     0
#>  5:     0     0
#>  6:     0     0
#>  7:     0     0
#>  8:     1     0
#>  9:     1     0
#> 10:     1     0
#> 11:     1     0
#> 12:     1     0
#> 13:     1     0
#> 14:     1     0
#> 15:     2     0
#> 16:     2     0
#> 17:     2     0
#> 18:     2     0
#> 19:     2     0
#> 20:     2     0
#> 21:     2     0
#> 22:     3     0
#> 23:     3     0
#> 24:     3     0
#> 25:     3     0
#> 26:     3     1
#> 27:     3     1
#> 28:     3     1
#> 29:     4     1
#> 30:     4     1
#> 31:     4     1
#> 32:     4     1
#> 33:     4     1
#> 34:     4     1
#> 35:     4     1
#> 36:     5     1
#> 37:     5     1
#> 38:     5     1
#> 39:     5     1
#> 40:     5     1
#>      week month
#>     <num> <num>
subset(holidaymeta, day_of_week == "Holiday")
#> Key: <report_date>
#>    reference_date location age_group confirm report_date day_of_week   day
#>            <IDat>   <fctr>    <fctr>   <int>      <Date>      <fctr> <num>
#> 1:     2021-05-01       DE       80+      48  2021-05-01     Holiday    25
#> 2:     2021-05-13       DE       80+      39  2021-05-13     Holiday    37
#>     week month
#>    <num> <num>
#> 1:     3     1
#> 2:     5     1
```
