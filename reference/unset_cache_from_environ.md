# Remove Cache Location Setting from `.Renviron`

This function searches for and removes the `enw_cache_location` setting
from the `.Renviron` file located in the user's project or home
directory. It utilizes the
[get_renviron_contents](https://package.epinowcast.org/reference/get_renviron_contents)
function to access and modify the contents of the `.Renviron` file. If
the `enw_cache_location` setting is found and successfully removed, a
success message is displayed. If the setting is not found, a warning
message is displayed.

## Usage

``` r
unset_cache_from_environ(alert_on_not_set = TRUE)
```

## Arguments

- alert_on_not_set:

  A logical value indicating whether to display a warning message if the
  `enw_cache_location` setting is not found in the `.Renviron` file.
  Defaults to `TRUE`.

## Value

Invisible NULL. The function is used for its side effect of modifying
the `.Renviron` file.

## See also

[`get_renviron_contents()`](https://package.epinowcast.org/reference/get_renviron_contents.md)
