#' Check Quantiles Required are Present
#'
#' @param posterior A `data.frame` containing quantiles identified using
#' the `q5` naming scheme. Default: No default.
#'
#' @param req_probs A numeric vector of required probabilities. Default:
#' c(0.5, 0.95, 0.2, 0.8).
#'
#' @return NULL
#'
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  if (any(req_probs <= 0) || any(req_probs >= 1)) {
    stop("Please provide probabilities as numbers between 0 and 1.")
  }
  cols <- colnames(posterior)
  if (sum(cols %in% paste0("q", req_probs * 100)) != length(req_probs)) {
    stop(
      "Following quantiles must be present (set with probs): ",
      paste(req_probs, collapse = ", ")
    )
  }
  return(invisible(NULL))
}

#' Check report and reference dates are present in the observations.
#'
#' @param obs An observation `data.frame` containing \code{report_date} and
#' \code{reference_date} columns.
#'
#' @return Returns the input `data.frame` with dates converted to date format
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
  } else {
    if (is.null(obs$reference_date)) {
      stop("reference_date must be present in order to use this function")
    }
    if (is.null(obs$report_date)) {
      stop("report_date must be present in order to use this function")
    }
  }
  obs[, report_date := as.IDate(report_date)]
  obs[, reference_date := as.IDate(reference_date)]
  return(obs[])
}

#' Check Observations for reserved grouping variables
#'
#' @param obs An observation `data.frame` that does not contain `.group`,
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
  }
  if (!is.null(obs$.new_group)) {
    stop(
      ".new_group is a reserved variable and must not be present in the input
       data"
    )
  }
  if (!is.null(obs$.old_group)) {
    stop(
      ".old_group is a reserved variable and must not be present in the input
       data"
    )
  }
  return(invisible(NULL))
}

#' Check by variables are present in the data
#'
#' @param obs An observation `data.frame`.
#'
#' @param by A character vector of variables to group by.
#'
#' @return NULL
#'
#' @family check
check_by <- function(obs, by = c()) {
  if (length(by) > 0) {
    if (!is.character(by)) {
      stop("`by` must be a character vector")
    }
    if (!all(by %in% colnames(obs))) {
      stop(
        "`by` must be a subset of the columns in `obs`. \n",
        paste0(paste(by[!(by %in% colnames(obs))], collapse = ", "),
        " are not present in `obs`")
      )
    }
  }
  return(invisible(NULL))
}

#' Add a reserved grouping variable if missing
#'
#' @param x A data.table
#'
#' @return A data table with a `.group` variable
#' @family check
add_group <- function(x) {
  if (is.null(x[[".group"]])) {
    x <- x[, .group := 1]
  }
  return(x[])
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
    warning(
      "Incompatible model specification: A missingness model has ",
      "been specified but likelihood aggregation is specified as ",
      "by snapshot. Switching to likelihood aggregation by group.",
      " This has no effect on the nowcast but limits the ",
      "number of threads per chain to the number of groups. To ",
      "silence this warning, set the `likelihood_aggregation` ",
      "argument in `enw_fit_opts` to 'groups'.",
      immediate. = TRUE)
  }
  return(invisible(NULL))
}

#' Compare maximum delays specified by the user vs. observed in the data, and
#' raise potential warnings.
#'
#' @param latest_obs The latest available observations.
#'
#' @param max_delay Metadata for the maximum delay produced using
#' [enw_metadata_maxdelay()].
#'
#' @param cum_coverage The cumulative coverage to use for the warning.
#' Defaults to 0.8 (80%)
#' @return NULL
#'
#' @family check
check_max_delay <- function(latest_obs, max_delay, cum_coverage = 0.8) {
  if (max_delay$obs < max_delay$spec) {
    warning(
      "You specified a maximum delay of ",
      max_delay$spec, " days, ",
      "but epinowcast will currently only model delays until the observed ",
      "maximum delay  (", max_delay$obs, " days). ",
      "Consider adding unobserved delays with zero reports to your data using ",
      "`enw_complete_dates` to avoid truncated delay distributions if you
      believe that these are truely zero. Otherwise consider opening an issue.",
      immediate. = TRUE
    )
  }

  low_cum <- latest_obs[,
    sum(cum_prop_reported < cum_coverage, na.rm = TRUE) /
     sum(!is.na(cum_prop_reported))
  ]
  if (low_cum > 0.5) {
    warning(
      "The currently specified maximum reporting delay ",
      "(", max_delay$spec, " days) ",
      "covers less than ", 100 * cum_coverage,
      "% of cases for the majority of reference dates. ",
      "Consider using a larger maximum delay to avoid potential model",
      "misspecification.",
      immediate. = TRUE
    )
  }
  return(invisible(NULL))
}