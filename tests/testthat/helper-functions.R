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
  skip("Not on CI")
}
