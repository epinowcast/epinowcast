# Extract data from preprocessed nowcast objects

Extracts a named component from an
[`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
or
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
object. List columns are unwrapped automatically so you get the
underlying `data.table` or value directly.

## Usage

``` r
enw_get_data(x, name)
```

## Arguments

- x:

  An `enw_preprocess_data` or `epinowcast` object.

- name:

  Character string naming the component to extract.

## Value

The extracted component. For list columns this is the first element
(typically a `data.table`); for scalar columns the value is returned
as-is.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md),
[`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md),
[`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)

## Examples

``` r
pobs <- enw_example("preprocessed_observations")
enw_get_data(pobs, "obs")
#> Key: <.group, reference_date, report_date>
#>      reference_date report_date max_confirm location age_group confirm
#>              <IDat>      <IDat>       <int>   <fctr>    <fctr>   <int>
#>   1:           <NA>  2021-07-14           0       DE       00+       0
#>   2:           <NA>  2021-07-15           0       DE       00+       0
#>   3:           <NA>  2021-07-16           0       DE       00+       0
#>   4:           <NA>  2021-07-17           0       DE       00+       0
#>   5:           <NA>  2021-07-18           0       DE       00+       0
#>  ---                                                                  
#> 646:     2021-08-20  2021-08-21         171       DE       00+     159
#> 647:     2021-08-20  2021-08-22         171       DE       00+     171
#> 648:     2021-08-21  2021-08-21         112       DE       00+      69
#> 649:     2021-08-21  2021-08-22         112       DE       00+     112
#> 650:     2021-08-22  2021-08-22          45       DE       00+      45
#>      cum_prop_reported delay .group
#>                  <num> <num>  <num>
#>   1:               NaN    NA      1
#>   2:               NaN    NA      1
#>   3:               NaN    NA      1
#>   4:               NaN    NA      1
#>   5:               NaN    NA      1
#>  ---                               
#> 646:         0.9298246     1      1
#> 647:         1.0000000     2      1
#> 648:         0.6160714     0      1
#> 649:         1.0000000     1      1
#> 650:         1.0000000     0      1
enw_get_data(pobs, "max_delay")
#> [1] 20
```
