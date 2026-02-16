# Filter by report dates

This is a helper function which allows users to create truncated data
sets at past time points from a given larger data set. This is useful
when evaluating nowcast performance against fully observed data. Users
may wish to combine this function with
[`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md).

## Usage

``` r
enw_filter_report_dates(obs, latest_date, remove_days)
```

## Arguments

- obs:

  A `data.frame`; must have `report_date` and `reference_date` columns.

- latest_date:

  Date, the latest report date to include in the returned dataset.

- remove_days:

  Integer, if `latest_date` is not given, the number of report dates to
  remove, starting from the latest date included.

## Value

A data.table filtered by report date

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
[`enw_filter_reference_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates.md),
[`enw_filter_reference_dates_by_report_start()`](https://package.epinowcast.org/dev/reference/enw_filter_reference_dates_by_report_start.md),
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
enw_filter_report_dates(germany_covid19_hosp, latest_date = "2021-09-01")
#>          reference_date location age_group confirm report_date
#>                  <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>       1:     2021-04-06       DE       00+     149  2021-04-06
#>       2:     2021-04-07       DE       00+     312  2021-04-07
#>       3:     2021-04-08       DE       00+     424  2021-04-08
#>       4:     2021-04-09       DE       00+     288  2021-04-09
#>       5:     2021-04-10       DE       00+     273  2021-04-10
#>      ---                                                      
#> 1058739:     2021-06-08    DE-TH       80+       4  2021-08-28
#> 1058740:     2021-06-09    DE-TH       80+       4  2021-08-29
#> 1058741:     2021-06-10    DE-TH       80+       1  2021-08-30
#> 1058742:     2021-06-11    DE-TH       80+       0  2021-08-31
#> 1058743:     2021-06-12    DE-TH       80+       2  2021-09-01

# Filter by days
enw_filter_report_dates(germany_covid19_hosp, remove_days = 10)
#>          reference_date location age_group confirm report_date
#>                  <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>       1:     2021-04-06       DE       00+     149  2021-04-06
#>       2:     2021-04-07       DE       00+     312  2021-04-07
#>       3:     2021-04-08       DE       00+     424  2021-04-08
#>       4:     2021-04-09       DE       00+     288  2021-04-09
#>       5:     2021-04-10       DE       00+     273  2021-04-10
#>      ---                                                      
#> 1439301:     2021-07-17    DE-TH       80+       1  2021-10-06
#> 1439302:     2021-07-18    DE-TH       80+       0  2021-10-07
#> 1439303:     2021-07-19    DE-TH       80+       0  2021-10-08
#> 1439304:     2021-07-20    DE-TH       80+       0  2021-10-09
#> 1439305:     2021-07-21    DE-TH       80+       0  2021-10-10
```
