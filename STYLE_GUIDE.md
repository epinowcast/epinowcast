# Style Guide

This document outlines the style guide for the `epinowcast` package. This guide is a work in progress and will be updated as the package evolves. We welcome contributions to this guide and encourage you to raise issues or submit PRs if you have any suggestions.

In addition to this guide we also follow the [tidyverse style guide](https://style.tidyverse.org/). This guide is a subset of the `tidyverse` style guide and outlines the additional style requirements for the `epinowcast` package.

## Naming conventions

- We use a `enw_` prefix to delineate functions that are exported by the `epinowcast` package. This is to avoid conflicts with other packages and to make it clear to users which functions are part of the package.
- The use of this prefix is not required for internal functions (i.e. functions that are not exported) or that are unlikely to have naming conflicts with other packages.

## Dependencies

In general we aim to minimise dependencies on other packages where possible. This makes it easier to maintain the package and reduces the risk of breaking changes in other packages impacting our users. However, additional dependencies are sometimes necessary to improve the functionality of the package.

The following guidelines should be followed when using adding dependencies:

- Added to the `Imports` or `Suggests` field `DESCRIPTION` file in alphabetical order. A dependency should be an `Imports` if it is required for the package to function and a `Suggests` if it is only required for certain non-core functions or vignettes.
- In the PR that adds the dependency this should be clearly stated in the PR description along with a justification for the dependency, the number and type of downstream dependencies, and an assessment of the risk of the dependency breaking. In general, the barrier for adding dependencies should be high but is lower for `Suggests` dependencies.

More generally when adding functions from external packages (i.e. even if they are already a dependency) the following should be followed:

- Documented in function documentation using the `@importFrom` tag.
- Used within functions using the `package::function` format (though we make exception for functions from `data.table` as these are all imported by `epinowcast`).

## Input types and checking

- We support inputs that are coercible to `data.table` objects using `data.table::as.data.table()`. This includes `data.frame` and `tibble` objects. This should be clearly documented in the function documentation.
- Any required inputs should be clearly documented in the function documentation.
- We use an internal function `coerce_dt()` to check inputs are coercible to `data.table` objects and have the correct columns. This function is used in all functions that take data as input. The following function demonstrates this pattern (note this requires the use of `devtools::load_all()` in the package directory):

```r
print_dt <- function(dt) {
    dt <- coerce_dt(dt, required_cols = c("date", "cases"))
    return(dt[])
}

print_dt(mtcars)
# Error in epinowcast:::coerce_dt(dt, required_cols = c("date", "cases")) : 
#   The following columns are required: date, cases but are not present among mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb
# (all `required_cols`: date, cases)
print_dt(data.frame(cases = 1, date = Sys.Date()))
#    cases       date
# 1:     1 2023-04-27
```

In general, we aim to check the inputs for all external facing functions. This is to ensure that the user is aware of any issues with the input data and to provide a consistent error message. See the documentation for `coerce_dt()` for more details. It may also be helpful to review usage in the package more widely, for this `data-converters.R` is a sensible place to start.

- For external facing functions `coerce_dt()` should generally not update by reference (i.e. `copy = TRUE` should be set, the default). In cases where users may benefit from updating by reference the external function should pass through the `copy` argument to `coerce_dt()`.
- However, those external functions may be invoked within other package functions, in which case `coerce_dt()` can often update by reference (i.e. `copy = FALSE` should be set). This is to avoid unnecessary copying of data. For purely internal functions, `coerce_dt()` can generally be used with `copy = FALSE`, again because copying is unnecessary. 

## Internal data manipulation

- `data.table` objects are used for internal data manipulation. If you are unfamiliar with `data.table` please see the [documentation](https://rdatatable.gitlab.io/data.table/index.html) and [cheatsheet](https://s3.amazonaws.com/assets.datacamp.com/img/blog/data+table+cheat+sheet.pdf). Prototype code may be written with other tools but will generally need be refactored to use `data.table` before submission (in PRs where help is needed with this please clearly state this).
- We aim to use more readable vs efficient `data.table` syntax where there is a trade-off (of course the exact trade-off requirers developer judgement). For example, rather than bracket chaining we prefer the use of one-line statements with re-assignment. The following functions demonstrate these patterns:

```r
library(data.table)
# we prefer this
dt <- as.data.table(mtcars)
dt[, mpg := mpg + 1]
dt[mpg > 20, cyl := 10]
dt[, cyl := cyl + 1]
#over this
dt_chain <- as.data.table(mtcars)[, mpg := mpg + 1][mpg > 20, cyl := 10][, cyl := cyl + 1]
```

- We also use `list` structures for more complex objects or where `data.table` is not appropriate. If the appropriate data structure is unclear for the problem at hand please flag this in the issue you are addressing or in the PR discussion.

## Output types

- For external functions we aim for the output to be a `data.table` object if possible unless a custom class is used (which we generally aim to inherit from the `data.table` class). This is to ensure consistency with the input types and to allow for easy chaining of functions.
- All returned `data.table` objects should be followed with `[]` as this ensures the object prints automatically. This holds for both internal and external functions in order to improve both the user and developer experience. The following functions demonstrate this pattern:

```r
library(data.table)

no_print_iris <- function(dt) {
    dt <- coerce_dt(dt)
    return(dt)
}

print_iris <- function(dt) {
    dt <- coerce_dt(dt)
    return(dt[])
}

no_print_iris(iris)
print_iris(iris)
#      Sepal.Length Sepal.Width Petal.Length Petal.Width   Species
#   1:          5.1         3.5          1.4         0.2    setosa
#   2:          4.9         3.0          1.4         0.2    setosa
#   3:          4.7         3.2          1.3         0.2    setosa
#   4:          4.6         3.1          1.5         0.2    setosa
#   5:          5.0         3.6          1.4         0.2    setosa
#  ---                                                            
# 146:          6.7         3.0          5.2         2.3 virginica
# 147:          6.3         2.5          5.0         1.9 virginica
# 148:          6.5         3.0          5.2         2.0 virginica
# 149:          6.2         3.4          5.4         2.3 virginica
# 150:          5.9         3.0          5.1         1.8 virginica
```
