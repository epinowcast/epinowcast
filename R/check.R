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
#' @param obs An observation data frame containing \code{report_date} and
#' \code{reference_date} columns.
#'
#' @return Returns the input data.frame with dates converted to date format
#' if not already.
#'
#' @importFrom data.table as.data.table copy
#' @family check
check_dates <- function(obs) {
  obs <- data.table::as.data.table(obs)
  obs <- data.table::copy(obs)
  if (is.null(obs$reference_date) && is.null(obs$report_date)) {
    stop(
      "Both reference_date and report_date must be present in order to use this
      function"
    )
  } else if (is.null(obs$reference_date)) {
    stop("reference_date must be present")
  } else if (is.null(obs$report_date)) {
    stop("report_date must be present")
  }
  obs[, report_date := as.IDate(report_date)]
  obs[, reference_date := as.IDate(reference_date)]
  return(obs[])
}

#' Check Observations for reserved grouping variables
#'
#' @param obs An observation data frame that does not contain `.group`,
#' `.old_group`, or `.new_group` as these are reserved variables.
#'
#' @return NULL
#'
#' @family check
check_group <- function(obs) {
  if (!is.null(obs$.group)) {
    stop(
      ".group is a reserved variable and must not be present in the input
       data"
    )
  } else if (!is.null(obs$.new_group)) {
    stop(
      ".new_group is a reserved variable and must not be present in the input
       data"
    )
  } else if (!is.null(obs$.old_group)) {
    stop(
      ".old_group is a reserved variable and must not be present in the input
       data"
    )
  }
  return(invisible(NULL))
}

#' Check a model module contains the required components
#'
#' @param module A model module. For example [enw_expectation()].
#'
#' @return NULL
#'
#' @family check
check_module <- function(module) {
  if (!"data" %in% names(module)) {
    stop(
      "Must contain a list component specifying the data requirements for
       further modelling as a list"
    )
  }
  if (!is.list(module[["data"]])) {
    stop(
      "data must be a list of required data"
    )
  }
  return(invisible(NULL))
}

#' Check that model modules have compatible specifications
#'
#' @param modules A list of model modules.
#'
#' @return NULL
#'
#' @family check
check_modules_compatible <- function(modules) {
  if (
    modules[[4]]$data$model_miss &&
      !modules[[6]]$data$likelihood_aggregation
  ) {
    warning(paste0(
      "Incompatible model specification: A missingness model has ",
      "been specified but likelihood aggregation is specified as ",
      "by snapshot. Switching to likelihood aggregation by group.",
      " This has no effect on the nowcast but limits the ",
      "number of threads per chain to the number of groups. To ",
      "silence this warning, set the `likelihood_aggregation` ",
      "argument in `enw_fit_opts` to 'groups'."
    ), immediate. = TRUE)
  }
  return(invisible(NULL))
}
