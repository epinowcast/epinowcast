# Coerce `data.table`s

Provides consistent coercion of inputs to
[data.table](https://rdatatable.gitlab.io/data.table/reference/data.table.html)
with error handling, column checking, and optional selection.

## Usage

``` r
coerce_dt(
  data,
  select = NULL,
  required_cols = select,
  forbidden_cols = NULL,
  group = FALSE,
  dates = FALSE,
  copy = TRUE,
  msg_required = "The following columns are required: ",
  msg_forbidden = "The following columns are forbidden: "
)
```

## Arguments

- data:

  Any of the types supported by
  [`data.table::as.data.table()`](https://rdatatable.gitlab.io/data.table/reference/as.data.table.html)

- select:

  An optional character vector of columns to return; *unchecked* n.b. it
  is an error to include ".group"; use `group` argument for that

- required_cols:

  An optional character vector of required columns

- forbidden_cols:

  An optional character vector of forbidden columns

- group:

  A logical; ensure the presence of a `.group` column?

- dates:

  A logical; ensure the presence of `report_date` and `reference_date`?
  If `TRUE` (default), those columns will be coerced with
  [as.IDate](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html).

- copy:

  A logical; if `TRUE` (default), a new `data.table` is returned

- msg_required:

  A character string; for `required_cols`-related error message

- msg_forbidden:

  A character string; for `forbidden_cols`-related error message

## Value

A `data.table`; the returned object will be a copy, unless
`copy = FALSE`, in which case modifications are made in-place

## Details

This function provides a single-point function for getting a "local"
version of data provided by the user, in the internally used
`data.table` format. It also enables selectively copying versus not, as
well as checking for the presence and/or absence of various columns.

While it is intended to address garbage in from the *user*, it does not
generally attempt to address garbage in from the *developer* - e.g. if
asking for overlapping required and forbidden columns (though that will
lead to an always-error condition).

When `dates = TRUE`, this function ensures that `report_date` and
`reference_date` columns are coerced to `IDate` class with integer
storage mode. This is necessary because some operations (such as
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html))
can convert `IDate` columns to double storage mode whilst preserving the
class, which violates data.table's requirements and causes errors in
subsequent date arithmetic operations.

## See also

Utility functions
[`coerce_date()`](https://package.epinowcast.org/dev/reference/coerce_date.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md),
[`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)
