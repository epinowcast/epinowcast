on_ci <- function() {
  isTRUE(as.logical(Sys.getenv("CI")))
}

not_on_cran <- function() {
  identical(Sys.getenv("NOT_CRAN"), "true")
}

epinowcast_as_data <- function(...) {
  nowcast <- suppressMessages(epinowcast(
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        return(data.table::data.table(init = list(init), data = list(data)))
      }
    ),
    model = NULL
  ))
  return(nowcast)
}

skip_on_local <- function() {
  if (on_ci()) {
    return(invisible(TRUE))
  }
  testthat::skip("Not on CI")
}

round_numerics <- function(dt) {
  cols <- colnames(dt)[purrr::map_lgl(dt, is.numeric)]
  dt <- dt[, (cols) := lapply(.SD, round, 0), .SDcols = cols]
  return(dt)
}

dt_copies <- function(...) {
  lapply(list(...), data.table::copy)
}

dt_compare_all <- function(ref_copies, ...) {
  all(mapply(function(l, r) all(l == r), ref_copies, list(...)))
}
