# Check environment setting

This internal function checks whether a given environment variable is
set or not. It returns `TRUE` if the variable is either null or an empty
string, indicating that the environment variable is not set. Otherwise,
it returns `FALSE`.

## Usage

``` r
check_environment_unset(x)
```

## Arguments

- x:

  The environment variable to be checked.

## Value

Logical value indicating whether the environment variable is not set
(either null or an empty string).
