# Style Guide

This document outlines the style guide for the `epinowcast` package. This guide is a work in progress and will be updated as the package evolves. We welcome contributions to this guide and encourage you to raise issues or submit PRs if you have any suggestions.

In addition to this guide we also follow the [tidyverse style guide](https://style.tidyverse.org/). This guide is a subset of the tidyverse style guide and outlines the additional style requirements for the `epinowcast` package.

## Naming conventions

- We use a `enw_` prefix to delineate functions that are part of the `epinowcast` package. This is to avoid conflicts with other packages and to make it clear to users which functions are part of the package.
- The use of this prefix is not required for internal functions (i.e. functions that are not exported) or that are unclear to have naming conflicts with other packages.

## Input types and checking

- We support inputs that are coercible to `data.table` objects using `data.table::as.data.table()`. This includes `data.frame` and `tibble` objects.
- We use an internal function `coerce_dt()` to check inputs are coercible to `data.table` objects and have the correct columns. This function is used in all functions that take data as input. The following functions demonstrate this pattern:

```r
print_dt <- function(dt) {
    dt <- coerce_dt(dt, required_cols = c("date", "cases"))
    return(dt)
}

print_dt(mtcars)

print_dt(data.frame(cases = 1, date = Sys.Date()))
```

In general, we aim to check the inputs for all external facing functions. This is to ensure that the user is aware of any issues with the input data and to provide a consistent error message. See the documentation for `coerce_dt()` for more details. It may also be helpful to review usage in the package more widely, for this `data-converters.R` is a sensible place to start.
- For external facing functions `coerce_dt()` should generally not update by reference (i.e. `copy = TRUE` should be set, the default). In cases where users may benefit from updating by reference the external function should pass through the `copy` argument to `coerce_dt()`.
- For internal functions `coerce_dt()` should generally update by reference (i.e. `copy = FALSE` should be set) when used internally. This is to avoid unnecessary copying of data.

## Internal data manipulation

- `data.table` objects are used for internal data manipulation. If you are unfamiliar with `data.table` please see the [documentation](https://rdatatable.gitlab.io/data.table/index.html) and [cheatsheet](https://s3.amazonaws.com/assets.datacamp.com/img/blog/data+table+cheat+sheet.pdf). Prototype code may be written with other tools but will generally need be refactored to use `data.table` before submission (in PRs where help is needed with this please clearly state this).
- We also use `list` structures for more complex objects or where `data.table` is not appropriate. If the appropriate data structure is unclear for the problem at hand please flag this in the issue you are addressing or in the PR discussion.

## Output types

- For external functions we aim for the output to be a `data.table` object if possible unless a custom class is used (which we generally aim to inherit from the `data.table` class). This is to ensure consistency with the input types and to allow for easy chaining of functions. The following functions demonstrate this pattern:
- All returned `data.table` objects should be followed with `[]` as this ensures the object prints automatically. The following functions demonstrate this pattern:

```r
library(data.table)

no_dt_print <- function(dt) {
    dt <- data.table::as.data.table(dt)
    return(dt)
}

dt_print <- function(dt) {
    dt <- data.table::as.data.table(dt)
    return(dt[])
}

no_dt_print(iris)
dt_print(iris)
```