# Style Guide

This document outlines the style guide for `epinowcast` family of packages.
This guide is a work in progress and will be updated as the community packages evolve.
We welcome contributions to this guide and encourage you to raise issues or submit PRs if you have any suggestions.

Generally, we follow the [`tidyverse` style guide](https://style.tidyverse.org/).
This guide provides extensions and exceptions to the `tidyverse` style guide.

## Naming conventions

- For most packages, we use a short prefix for exported functions (e.g. we use `enw_` prefix for the `epinowcast` package).
  This helps preclude conflicts with other packages and also makes it more convenient for users to tab-complete / browse functions from the package.
- There are some exceptions:
  * For functions that work with S3 objects (e.g. `plot.epinowcast()`), they must be named accordingly.
  * Internal functions (i.e. functions that are not exported) do not require this prefix.
    However, we do have standard internal prefixes as well: `check_` for functions that validate arguments, `coerce_` for functions that convert to a particular type.
  * For functions where the name is intended to leverage other R-wide naming conventions (e.g. `(d|r|p|q)DISTRO` style naming).

Also note that these are conventions, not hard rules.

## Function calls

When calling a function with multiple arguments, place the first argument on a new line after the opening bracket.
Each argument should be on its own line, indented by two spaces.
The closing bracket should be on its own line, aligned with the start of the function call.

```r
# Correct
result <- some_function(
  first_arg = value1,
  second_arg = value2,
  third_arg = value3
)

# Incorrect: first argument on the same line as the function name
result <- some_function(first_arg = value1,
                        second_arg = value2,
                        third_arg = value3)
```

This convention applies to both external function calls and function definitions.

```r
# Correct function definition
my_function <- function(
  arg1 = default1,
  arg2 = default2,
  arg3 = default3
) {
  # function body
}

# Correct nested function calls
outer_function(
  arg1 = inner_function(
    nested_arg1 = value1,
    nested_arg2 = value2
  ),
  arg2 = value3
)
```

Short function calls with a single argument may be kept on one line.

```r
# Acceptable for single-argument calls
result <- some_function(value)
result <- some_function(arg = value)
```

## Dependencies

In general we aim to minimise dependencies on packages outside the `epinowcast` community where possible.
This makes it easier to maintain our packages and reduces the risk of breaking changes in other packages impacting our users.
However, additional dependencies are sometimes necessary to improve the functionality of the package.

The following guidelines should be followed when adding dependencies:

- Added to the `Imports` or `Suggests` field of the `DESCRIPTION` file in alphabetical order.
  A dependency should be an `Imports` if it is required for the package to function and a `Suggests` if it is only required for certain non-core functions or vignettes.
- In the PR that adds the dependency this should be clearly stated in the PR description along with a justification for the dependency, the number and type of downstream dependencies, and an assessment of the risk of the dependency breaking.
  In general, the barrier for adding dependencies should be high but is lower for `Suggests` dependencies.

More generally when adding functions from external packages (i.e. even if they are already a dependency) the following should be followed:

- Documented in function documentation using the `@importFrom` tag.
- Used within functions using the `package::function` format (though we make exception for functions from `data.table` as these are all imported by `epinowcast`).

## Input types and checking

- Any required inputs should be clearly documented in the function documentation, particularly in terms of type, but also other constraints (e.g. presence/absence of columns).
- Any expressed constraint in exported functions should be verified using some sort of `check_` expression, and ideally unit tests written correspondingly to confirm that `check_` rejects bad input.
- Many of the methods across the `epinowcast` packages work with `data.frame` inputs (and subclasses of `data.frame` like `data.table` and `tibble`).
  Internally, for performance and syntax reasons, we prefer to use `data.table`s explicitly and that is generally the type returned by functions.
  However, we will continue to accept `data.frame`-like arguments as inputs.
- Translation from `data.frame` to `data.table` can be handled by `coerce_dt`, `check_dt` or `make_dt` (`coerce_dt` and `check_dt` combined) which will be provided in a to-be-released package `make_dt`.
- In general, functions should be side-effect-free on their arguments.
  This is generally the case in R, but notably `data.table` arguments may be modified inside functions.
  To maintain the benefits of using `data.table`, you may wish to allow side effects, either by method flag or with internal methods.

In general, we aim to check the inputs for all external facing functions.
This is to ensure that the user is aware of any issues with the input data and to provide a consistent error message.
For an example of this philosophy, review usage in `epinowcast` more widely, such as the functions in `R/data-converters.R`.

## Internal data manipulation

- `data.table` objects are used for internal data manipulation.
  If you are unfamiliar with `data.table` please see the [documentation](https://rdatatable.gitlab.io/data.table/index.html) and [cheatsheet](https://s3.amazonaws.com/assets.datacamp.com/img/blog/data+table+cheat+sheet.pdf).
  Prototype code may be written with other tools but will generally need be refactored to use `data.table` before submission (in PRs where help is needed with this please clearly state this).
- We aim to use more readable vs efficient `data.table` syntax where there is a trade-off (of course the exact trade-off requires developer judgement).
  For example, rather than bracket chaining we prefer the use of one-line statements with re-assignment.
  The following functions demonstrate these patterns (and the reason why we avoid them: the chained `dt` actually yields a different result for `dt_chain` vs `dt`):

```r
library(data.table)
# we prefer this
dt <- as.data.table(mtcars)
dt[, mpg := mpg + 1]
dt[mpg > 20, cyl := 10]
dt[, cyl := cyl + 1]
# over this
dt_chain <- as.data.table(mtcars)[
  , mpg := mpg + 1
][
  mpg > 20, cyl := 10
][
  , cyl := cyl + 1
]
```

- We also use `list` structures for more complex objects or where `data.table` is not appropriate.
  If the appropriate data structure is unclear for the problem at hand please flag this in the issue you are addressing or in the PR discussion.

## Output types

- For external functions we aim for the output to be a `data.table` object if possible unless a custom class is used (which we generally aim to inherit from the `data.table` class).
  This is to ensure consistency with the input types and to allow for easy chaining of functions.
- All returned `data.table` objects should be followed with `[]` as this ensures the object prints automatically.
  This holds for both internal and external functions in order to improve both the user and developer experience.
  The following functions demonstrate this pattern:

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
