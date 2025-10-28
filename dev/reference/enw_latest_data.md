# Filter observations to the latest available reported

Filter observations for the latest available reported data for each
reference date. Note this is not the same as filtering for the maximum
report date in all cases as data may only be updated up to some maximum
number of days.

## Usage

``` r
enw_latest_data(obs)
```

## Arguments

- obs:

  A `data.frame`; must have `report_date` and `reference_date` columns.

## Value

A `data.table` of observations filtered for the latest available data
for each reference date.

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
[`enw_filter_report_dates()`](https://package.epinowcast.org/dev/reference/enw_filter_report_dates.md),
[`enw_flag_observed_observations()`](https://package.epinowcast.org/dev/reference/enw_flag_observed_observations.md),
[`enw_impute_na_observations()`](https://package.epinowcast.org/dev/reference/enw_impute_na_observations.md),
[`enw_metadata()`](https://package.epinowcast.org/dev/reference/enw_metadata.md),
[`enw_metadata_delay()`](https://package.epinowcast.org/dev/reference/enw_metadata_delay.md),
[`enw_missing_reference()`](https://package.epinowcast.org/dev/reference/enw_missing_reference.md),
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md),
[`enw_reporting_triangle()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle.md),
[`enw_reporting_triangle_to_long()`](https://package.epinowcast.org/dev/reference/enw_reporting_triangle_to_long.md)

## Examples

``` r
# Filter for latest reported data
enw_latest_data(germany_covid19_hosp)
#>        reference_date location age_group confirm report_date
#>                <IDat>   <fctr>    <fctr>   <int>      <IDat>
#>     1:     2021-04-06       DE       00+     708  2021-06-26
#>     2:     2021-04-06       DE     00-04      11  2021-06-26
#>     3:     2021-04-06       DE     05-14       5  2021-06-26
#>     4:     2021-04-06       DE     15-34      75  2021-06-26
#>     5:     2021-04-06       DE     35-59     192  2021-06-26
#>    ---                                                      
#> 23558:     2021-10-20    DE-TH     05-14       1  2021-10-20
#> 23559:     2021-10-20    DE-TH     15-34       2  2021-10-20
#> 23560:     2021-10-20    DE-TH     35-59       1  2021-10-20
#> 23561:     2021-10-20    DE-TH     60-79       5  2021-10-20
#> 23562:     2021-10-20    DE-TH       80+       5  2021-10-20
```
