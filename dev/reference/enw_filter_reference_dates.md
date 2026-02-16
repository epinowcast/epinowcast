# Filter by reference dates

This is a helper function which allows users to filter datasets by
reference date. This is useful, for example, when evaluating nowcast
performance against fully observed data. Users may wish to combine this
function with
[`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md).
Note that by definition it is assumed that report dates must be equal or
greater than the corresponding reference date (i.e a report cannot
happen before the event being reported occurs). This means that this
function will also filter out any report dates that are earlier than
their corresponding reference date.

## Usage

``` r
enw_filter_reference_dates(
  obs,
  earliest_date,
  include_days,
  latest_date,
  remove_days
)
```

## Arguments

- obs:

  A `data.frame`; must have `report_date` and `reference_date` columns.

- earliest_date:

  earliest reference date to include in the data set

- include_days:

  if `earliest_date` is not given, the number of reference dates to
  include, ending with the latest reference date included (determined by
  `latest_date` or `remove_days`). For example, `include_days = 10`
  returns exactly 10 reference dates.

- latest_date:

  Date, the latest reference date to include in the returned dataset.

- remove_days:

  Integer, if `latest_date` is not given, the number of reference dates
  to remove, starting from the latest date included.

## Value

A `data.table` filtered by report date

## Details

The `include_days` parameter filters to include exactly the specified
number of most recent reference dates. For example, if the latest
reference date is 2021-10-20 and `include_days = 10`, the filtered data
will contain reference dates from 2021-10-11 to 2021-10-20 (10 days
inclusive).

## See also

Preprocessing functions
[`enw_add_delay()`](https://package.epinowcast.org/dev/reference/enw_add_delay.md),
[`enw_add_max_reported()`](https://package.epinowcast.org/dev/reference/enw_add_max_reported.md),
[`enw_add_metaobs_features()`](https://package.epinowcast.org/dev/reference/enw_add_metaobs_features.md),
[`enw_assign_group()`](https://package.epinowcast.org/dev/reference/enw_assign_group.md),
[`enw_complete_dates()`](https://package.epinowcast.org/dev/reference/enw_complete_dates.md),
[`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md),
[`enw_extend_date()`](https://package.epinowcast.org/dev/reference/enw_extend_date.md),
[`enw_filter_delay()`](https://package.epinowcast.org/dev/reference/enw_filter_delay.md),
[`enw_filter_reference_dates_by_report_start()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates_by_report_start.md),
[`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md),
[`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md),
[`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_obs_at_delay()`](https://package.epinowcast.org/dev/reference/enw_obs_at_delay.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
# Filter by date
enw_filter_reference_dates(
  germany_covid19_hosp,
  earliest_date = "2021-09-01",
  latest_date = "2021-10-01"
)
#>         reference_date location age_group confirm report_date
#>                 <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>      1:     2021-09-01       DE       00+     124  2021-09-01
#>      2:     2021-09-02       DE       00+      94  2021-09-02
#>      3:     2021-09-03       DE       00+     130  2021-09-03
#>      4:     2021-09-04       DE       00+      82  2021-09-04
#>      5:     2021-09-05       DE       00+      42  2021-09-05
#>     ---                                                      
#> 129111:     2021-09-01    DE-TH     05-14       0  2021-10-20
#> 129112:     2021-09-01    DE-TH     15-34       0  2021-10-20
#> 129113:     2021-09-01    DE-TH     35-59       1  2021-10-20
#> 129114:     2021-09-01    DE-TH     60-79       2  2021-10-20
#> 129115:     2021-09-01    DE-TH       80+       2  2021-10-20
#
# Filter by days
enw_filter_reference_dates(
  germany_covid19_hosp,
  include_days = 10, remove_days = 10
)
#>        reference_date location age_group confirm report_date
#>                <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>     1:     2021-10-01       DE       00+     105  2021-10-01
#>     2:     2021-10-02       DE       00+      97  2021-10-02
#>     3:     2021-10-03       DE       00+      41  2021-10-03
#>     4:     2021-10-04       DE       00+      23  2021-10-04
#>     5:     2021-10-05       DE       00+     120  2021-10-05
#>    ---                                                      
#> 18441:     2021-10-01    DE-TH     05-14       0  2021-10-20
#> 18442:     2021-10-01    DE-TH     15-34       1  2021-10-20
#> 18443:     2021-10-01    DE-TH     35-59       3  2021-10-20
#> 18444:     2021-10-01    DE-TH     60-79       3  2021-10-20
#> 18445:     2021-10-01    DE-TH       80+       2  2021-10-20
```
