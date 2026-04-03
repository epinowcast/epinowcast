# Summary method for enw_preprocess_data

`summary` method for class `"enw_preprocess_data"`. Returns a structured
overview of the preprocessed data including a preview of the latest
observations and a corner of the reporting triangle.

## Usage

``` r
# S3 method for class 'enw_preprocess_data'
summary(object, n = 6, ...)
```

## Arguments

- object:

  A `data.table` output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
  or
  [`enw_construct_data()`](https://package.epinowcast.org/dev/reference/enw_construct_data.md).

- n:

  Integer number of rows to show in previews. Defaults to 6.

- ...:

  Additional arguments (not used).

## Value

A list of class `"summary.enw_preprocess_data"` containing the
preprocessed data object and preview parameters, printed via
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md).

## See also

Other epinowcast:
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md),
[`plot.epinowcast()`](https://package.epinowcast.org/dev/reference/plot.epinowcast.md),
[`print.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.enw_preprocess_data.md),
[`print.epinowcast()`](https://package.epinowcast.org/dev/reference/print.epinowcast.md),
[`print.summary.enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/print.summary.enw_preprocess_data.md),
[`summary.epinowcast()`](https://package.epinowcast.org/dev/reference/summary.epinowcast.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")
summary(pobs)
#> ── Preprocessed nowcast data summary ─────────────────────────────────────────── 
#> Groups: 1 | Timestep: day | Max delay: 20 
#> Date range: 2021-07-14 to 2021-08-22 (39 days) 
#> Observations: 40 timepoints x 40 snapshots 
#> 
#> Latest observations (first 6 rows): 
#>    reference_date report_date .group max_confirm location age_group confirm
#>            <IDat>      <IDat>  <num>       <int>   <fctr>    <fctr>   <int>
#> 1:     2021-07-14  2021-08-02      1          72       DE       00+      70
#> 2:     2021-07-15  2021-08-03      1          69       DE       00+      69
#> 3:     2021-07-16  2021-08-04      1          47       DE       00+      47
#> 4:     2021-07-17  2021-08-05      1          65       DE       00+      63
#> 5:     2021-07-18  2021-08-06      1          50       DE       00+      46
#> 6:     2021-07-19  2021-08-07      1          36       DE       00+      36
#>    cum_prop_reported delay prop_reported
#>                <num> <num>         <num>
#> 1:         0.9722222    19          0.00
#> 2:         1.0000000    19          0.00
#> 3:         1.0000000    19          0.00
#> 4:         0.9692308    19          0.00
#> 5:         0.9200000    19          0.04
#> 6:         1.0000000    19          0.00
#> 
#> Reporting triangle corner (first 6 rows x 8 cols): 
#> Key: <.group, reference_date>
#>    .group reference_date     0     1     2     3     4     5
#>     <num>         <IDat> <int> <int> <int> <int> <int> <int>
#> 1:      1     2021-07-14    22    12     4     5     0     1
#> 2:      1     2021-07-15    28    15     3     3     0     1
#> 3:      1     2021-07-16    19    13     0     0     0     4
#> 4:      1     2021-07-17    20     7     1     3    10     3
#> 5:      1     2021-07-18     9     6     6     0     4     5
#> 6:      1     2021-07-19     3    16     4     4     1     1
#> ... (40 rows x 22 cols total) 
```
