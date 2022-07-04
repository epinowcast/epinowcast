#' Check Quantiles Required are Present
#'
#' @param posterior A dataframe containing quantiles identified using
#' the `q5` naming scheme. Default: No default.
#'
#' @param req_probs A numeric vector of required probabilities. Default:
#' c(0.5, 0.95, 0.2, 0.8).
#'
#' @return NULL
#'
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  cols <- colnames(posterior)
  if (sum(cols %in% c("q5", "q95", "q20", "q80")) != 4) {
    stop(
      "Following quantiles must be present (set with probs): ",
      paste(req_probs, collapse = ", ")
    )
  }
  return(invisible(NULL))
}

#' Check Report and Reference Dates are present
#'
#' @param obs A data.frame to check for the required date variables
#'
#' @return Returns the input data.frame with dates converted to date format
#' if not already.
#'
#' @importFrom data.table as.data.table copy
#' @family check
check_dates <- function(obs) {
  obs <- data.table::as.data.table(obs)
  obs <- data.table::copy(obs)
  if (is.null(obs$reference_date) || is.null(obs$report_date)) {
    stop(
      "Both reference_date and report_date must be present in order to use this
      function"
    )
  }
  retro_data[, report_date := as.IDate(report_date)]
  retro_data[, reference_date := as.IDate(reference_date)]
  return(obs[])
}