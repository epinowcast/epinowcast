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
        data.table::data.table(init = list(init), data = list(data))
      }
    ),
    model = NULL
  ))
  nowcast
}

skip_on_local <- function() {
  if (on_ci() || Sys.getenv("LOCAL_OVERRIDE") == "true") {
    return(invisible(TRUE))
  }
  testthat::skip("Not on CI")
}

round_numerics <- function(dt) {
  cols <- colnames(dt)[purrr::map_lgl(dt, is.numeric)]
  dt <- dt[, (cols) := lapply(.SD, round, 0), .SDcols = cols]
  dt
}

dt_copies <- function(...) {
  lapply(list(...), data.table::copy)
}

dt_compare_all <- function(ref_copies, ...) {
  all(mapply(function(l, r) all(l == r), ref_copies, list(...)))
}

check_r_version <- function(min_major = 4, min_minor = 0) {

  current_version <- as.numeric(
    paste0(
      R.version[["major"]],
      ".",
      gsub("(\\d+)\\..*", "\\1", R.version[["minor"]])
    )
  )

  target_min_version <- as.numeric(
    paste0(min_major, ".", min_minor)
  )

  if (current_version >= target_min_version) {
    TRUE
  } else {
    FALSE
  }
}

# A function to filter data used in test suite
run_window_filter <- function(
  x, filter_report_remove = 10, filter_reference_include = 10
) {
  obs <- enw_filter_report_dates(x, remove_days = filter_report_remove)
  obs <- enw_filter_reference_dates(
    obs, include_days = filter_reference_include
  )
  obs
}

silent_enw_sample <- function(...) {
  utils::capture.output(
    fit <- suppressMessages(enw_sample(...)) # nolint: implicit_assignment_linter
  )
  fit
}

silent_enw_pathfinder <- function(...) {
  utils::capture.output(
    fit <- suppressMessages(enw_pathfinder(...)) # nolint: implicit_assignment_linter
  )
  fit
}

# Build a minimal simulated enw_preprocess_data-like object for
# testing delay-summary helpers. Constructs a `new_confirm` table
# with known incidence by delay so expected proportions and
# quantiles can be checked by hand.
make_test_pobs <- function(
  delays = 0:4, new_confirms = c(10, 5, 3, 1, 1),
  n_dates = 3, max_delay = 4
) {
  dates <- as.IDate(
    seq.Date(as.Date("2021-01-01"), by = 1, length.out = n_dates)
  )
  nc <- data.table::CJ(
    reference_date = dates, delay = delays
  )
  nc[, `:=`(
    .group = 1L,
    new_confirm = rep(new_confirms, n_dates),
    report_date = reference_date + delay
  )]
  nc[, confirm := cumsum(new_confirm), by = reference_date]
  nc[, max_confirm := max(confirm), by = reference_date]
  nc[, cum_prop_reported := confirm / max_confirm]
  nc[, prop_reported := new_confirm / max_confirm]
  data.table::setkey(nc, reference_date, report_date)

  pobs <- list(
    new_confirm = list(nc),
    by = list(character(0)),
    max_delay = max_delay
  )
  class(pobs) <- c("enw_preprocess_data", class(pobs))
  pobs
}
