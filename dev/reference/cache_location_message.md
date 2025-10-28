# Cache location message for epinowcast package

This function generates a message in the
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
package regarding the cache location. It checks the environment setting
for the cache location and provides guidance to the user on managing
this setting.

## Usage

``` r
cache_location_message()
```

## Value

A character vector containing messages. If `enw_cache_location` is not
set, it returns instructions for setting the cache location and where to
find more details. If it is set, the function returns a confirmation
message of the current cache location.

## Details

`cache_location_message()` examines the `enw_cache_location` environment
variable. If this variable is not set, it advises the user to set the
cache location using
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md)
to optimize stan compilation times. If `enw_cache_location` is set, it
confirms the current cache location to the user. Management and setting
of the cache location can be done using
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md).
