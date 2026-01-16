# Identify cache location in .Renviron

This function retrieves environment variable settings and manages the
`.Renviron` file in the user's project or home directory. The project
directory will be examined first, if it exists.

## Usage

``` r
get_renviron_contents()
```

## Value

A list containing the contents of the `.Renviron` file and its path.
