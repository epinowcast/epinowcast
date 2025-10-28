# Coerce Dates

Provides consistent coercion of inputs to
[IDate](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html)
with error handling

## Usage

``` r
coerce_date(dates = NULL)
```

## Arguments

- dates:

  A vector-like input, which the function attempts to coerce via
  [`data.table::as.IDate()`](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html).
  Defaults to NULL.

## Value

An
[IDate](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html)
vector.

## Details

If any of the elements of `dates` cannot be coerced, this function will
result in an error, indicating all indices which cannot be coerced to
[IDate](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html).

Internal methods of
[epinowcast](https://package.epinowcast.org/dev/reference/epinowcast.md)
assume dates are represented as
[IDate](https://rdatatable.gitlab.io/data.table/reference/IDateTime.html).

## See also

Utility functions
[`coerce_dt()`](https://package.epinowcast.org/dev/reference/coerce_dt.md),
[`date_to_numeric_modulus()`](https://package.epinowcast.org/dev/reference/date_to_numeric_modulus.md),
[`enw_rolling_sum()`](https://package.epinowcast.org/dev/reference/enw_rolling_sum.md),
[`get_internal_timestep()`](https://package.epinowcast.org/dev/reference/get_internal_timestep.md),
[`is.Date()`](https://package.epinowcast.org/dev/reference/is.Date.md),
[`stan_fns_as_string()`](https://package.epinowcast.org/dev/reference/stan_fns_as_string.md)

## Examples

``` r
# works
coerce_date(c("2020-05-28", "2020-05-29"))
#> [1] "2020-05-28" "2020-05-29"
# does not, indicates index 2 is problem
tryCatch(
  coerce_date(c("2020-05-28", "2020-o5-29")),
  error = function(e) {
    print(e)
  }
)
#> <error/rlang_error>
#> Error in `coerce_date()`:
#> ! Failed to parse with `as.IDate`: 2020-o5-29 (indices 2).
#> ---
#> Backtrace:
#>      ▆
#>   1. └─pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
#>   2.   └─pkgdown::build_site(...)
#>   3.     └─pkgdown:::build_site_local(...)
#>   4.       └─pkgdown::build_reference(...)
#>   5.         ├─pkgdown:::unwrap_purrr_error(...)
#>   6.         │ └─base::withCallingHandlers(...)
#>   7.         └─purrr::map(...)
#>   8.           └─purrr:::map_("list", .x, .f, ..., .progress = .progress)
#>   9.             ├─purrr:::with_indexed_errors(...)
#>  10.             │ └─base::withCallingHandlers(...)
#>  11.             ├─purrr:::call_with_cleanup(...)
#>  12.             └─pkgdown (local) .f(.x[[i]], ...)
#>  13.               ├─base::withCallingHandlers(...)
#>  14.               └─pkgdown:::data_reference_topic(...)
#>  15.                 └─pkgdown:::run_examples(...)
#>  16.                   └─pkgdown:::highlight_examples(code, topic, env = env)
#>  17.                     └─downlit::evaluate_and_highlight(...)
#>  18.                       └─evaluate::evaluate(code, child_env(env), new_device = TRUE, output_handler = output_handler)
#>  19.                         ├─base::withRestarts(...)
#>  20.                         │ └─base (local) withRestartList(expr, restarts)
#>  21.                         │   ├─base (local) withOneRestart(withRestartList(expr, restarts[-nr]), restarts[[nr]])
#>  22.                         │   │ └─base (local) doWithOneRestart(return(expr), restart)
#>  23.                         │   └─base (local) withRestartList(expr, restarts[-nr])
#>  24.                         │     └─base (local) withOneRestart(expr, restarts[[1L]])
#>  25.                         │       └─base (local) doWithOneRestart(return(expr), restart)
#>  26.                         ├─evaluate:::with_handlers(...)
#>  27.                         │ ├─base::eval(call)
#>  28.                         │ │ └─base::eval(call)
#>  29.                         │ └─base::withCallingHandlers(...)
#>  30.                         ├─base::withVisible(eval(expr, envir))
#>  31.                         └─base::eval(expr, envir)
#>  32.                           └─base::eval(expr, envir)
#>  33.                             ├─base::tryCatch(...)
#>  34.                             │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
#>  35.                             │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
#>  36.                             │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
#>  37.                             └─epinowcast::coerce_date(c("2020-05-28", "2020-o5-29"))
```
