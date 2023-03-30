#' Calculate cumulative reported cases from incidence of new reports
#'
#' @param obs A `data.frame` containing at least the following variables:
#' `reference date` (index date of interest), `report_date` (report date for
#' observations), and `new_confirm` (incident observations by reference and
#' report date).
#'
#' @return The input `data.frame` with a new variable `confirm`.
#' @inheritParams enw_preprocess_data
#' @family dataconverters
#' @export
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' dt <- enw_add_incidence(dt)
#' dt <- dt[, confirm := NULL]
#' enw_add_cumulative(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' enw_add_cumulative(dt)
enw_add_cumulative <- function(obs, by = c()) {
  obs <- check_dates(obs)
  check_by(obs)

  obs <- obs[!is.na(reference_date)]
  data.table::setkeyv(obs, c(by, "reference_date", "report_date"))

  obs[, confirm := cumsum(new_confirm), by = c(by, "reference_date")]
  return(obs[])
}

#' Calculate incidence of new reports from cumulative reports
#'
#' @param obs A `data.frame` containing at least the following variables:
#' `reference date` (index date of interest), `report_date` (report date for
#' observations), and `confirm` (cumulative observations by reference and report
#' date).
#'
#' @param set_negatives_to_zero Logical, defaults to TRUE. Should negative
#' counts (for calculated incidence of observations) be set to zero. Currently
#' downstream modelling does not support negative counts and so setting must be
#' TRUE if intending to use [epinowcast()].
#'
#' @return The input `data.frame` with a new variable `new_confirm`. If
#' `max_confirm` was present in the `data.frame` then the proportion
#' reported on each day (`prop_reported`) is also added.
#' @inheritParams enw_preprocess_data
#' @family dataconverters
#' @export
#' @importFrom data.table shift
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' enw_add_incidence(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' dt <- enw_add_max_reported(dt)
#' enw_add_incidence(dt)
enw_add_incidence <- function(obs, set_negatives_to_zero = TRUE, by = c()) {
  check_by(obs)
  reports <- check_dates(obs)
  data.table::setkeyv(reports, c(by, "reference_date", "report_date"))
  reports[, new_confirm := confirm - data.table::shift(confirm, fill = 0),
    by = c("reference_date", by)
  ]
  reports <- reports[,
    .SD[reference_date >= min(report_date) | is.na(reference_date)],
    by = by
  ]
  reports <- reports[, delay := 0:(.N - 1), by = c("reference_date", by)]

  if (!is.null(reports$max_confirm)) {
    reports[, prop_reported := new_confirm / max_confirm]
  }

  if (set_negatives_to_zero) {
    reports <- reports[new_confirm < 0, new_confirm := 0]
  }
  return(reports[])
}


#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param linelist DESCRIPTION.
#' @param by DESCRIPTION.
#' @param max_delay DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#'
#' @family dataconverters
#' @export
#' @examples
#' linelist <- data.frame(
#'   reference_date = as.Date(c("2021-01-02", "2021-01-03", "2021-01-02")),
#'   report_date = as.Date(c("2021-01-03", "2021-01-05", "2021-01-04"))
#' )
#' enw_linelist_to_incidence(linelist)
enw_linelist_to_incidence <- function(linelist, by = c(), max_delay) {
  check_by(linelist)
  obs <- check_dates(linelist)
  counts <- data.table::as.data.table(linelist)
  data.table::setkeyv(counts, c(by, "reference_date", "report_date"))
  counts <- counts[,
    .(new_confirm = .N), keyby = c("reference_date", "report_date", by)
  ]
  counts[order(reference_date, report_date)]

  obs_delay <- max(counts$report_date) - min(counts$reference_date) + 1
  if (missing(max_delay)) {
    max_delay <- obs_delay
    message("Using maximum observed delay of ", max_delay, " days")
  }
  if (max_delay < obs_delay) {
    message(
      "Using maximum observed delay of ", max_delay, " days as greater than
       the maximum specified")
       max_delay <- obs_delay
  }
  cum_counts <- enw_add_cumulative(counts)

  complete_counts <- enw_complete_dates(
    cum_counts, max_delay = max_delay, by = by
  )
  complete_counts <- enw_add_incidence(complete_counts, by = by)
  return(complete_counts)
}

#' @export
#' @param ... Arguments passed to [enw_add_incidence()].
enw_cumulative_to_incidence <- function(...) {
  lifecycle::deprecate_warn(
    "0.2.1", "enw_cumulative_to_incidence()", "enw_add_incidence()"
  )
  enw_add_incidence(...)
}

#' @export
#' @param ... Arguments passed to [enw_add_cumulative()].
enw_incidence_to_cumulative <- function(...) {
  lifecycle::deprecate_warn(
    "0.2.1", "enw_incidence_to_cumulative()", "enw_add_cumulative()"
  )
  enw_add_cumulative(...)
}