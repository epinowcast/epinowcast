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
      toString(req_probs)
    )
  }
  return(invisible(NULL))
}

#' Check Report and Reference Dates are present
#'
#' @param obs An observation `data.frame` containing `report_date` and
#' `reference_date` columns.
#'
#' @return a copy `data.table` version of `obs` with `report_date` and
#' `reference_date` as [IDateTime] format.
#'
#' @family check
check_dates <- function(obs) {
  obs <- coerce_dt(
    obs, required_cols = c("report_date", "reference_date"),
    copy = FALSE
  )
  obs[, report_date := as.IDate(report_date)]
  obs[, reference_date := as.IDate(reference_date)]
  return(obs[])
}

#' Check Observations for reserved grouping variables
#'
#' @param obs An observation `data.frame` that does not contain `.group`,
#' `.old_group`, or `.new_group` as these are reserved variables.
#'
#' @return The `obs` object
#'
#' @family check
check_group <- function(obs) {
  return(coerce_dt(
    obs, forbidden_cols = c(".group", ".new_group", ".old_group"), copy = FALSE
  ))
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
      immediate. = TRUE
    )
  }
  return(invisible(NULL))
}

#' @title Coerce `data.table`s
#'
#' @description Provides consistent coercion of inputs to [data.table]
#' with error handling, column checking, and optional selection.
#'
#' @param data any of the types supported by [data.table::as.data.table()]
#'
#' @param new logical; if `TRUE` (default), a new `data.table` is returned
#'
#' @param select optional character vector of columns to return; *unchecked*
#' n.b. it is an error to include ".group"; use `group` argument for that
#'
#' @param required_cols optional character vector of required columns; checked
#'
#' @param forbidden_cols optional character vector of forbidden columns; checked
#'
#' @param group logical; ensure the presence of a `.group` column?
#'
#' @return a `data.table`; if `data` is a `data.table`, the returned object
#' will have a new address, unless `new = FALSE`.
#' i.e. be distinct from the original and not cause any side effects with
#' changes.
#'
#' @details This function provides one-stop shopping for getting a "local"
#' version of data provided by the user, in the internally used `data.table`
#' format. It also enables selectively copying vs not, as well as checking
#' for the presence and/or absence of various columns.
#'
#' While it is intended to address garbage in from the *user*, it does not
#' generally attempt to address garbage in from the *developer* - e.g. if asking
#' for overlapping required and forbidden columns (though that will lead to an
#' always-error condition).
#'
#' @importFrom data.table as.data.table
#' @family utils
coerce_dt <- function(
  data, select = NULL, required_cols = select,
  forbidden_cols = NULL, group = FALSE, copy = TRUE
) {
  if (!copy) { # if we want to keep the original data.table ...
    dt <- data.table::setDT(data)
  } else {    # ... otherwise, make a copy
    dt <- data.table::as.data.table(data)
  }
  # check for required columns
  if ((length(required_cols) > 0)) {
    if (!is.character(required_cols)) {
      stop("`required_cols` must be a character vector")
    }
    if (!all(required_cols %in% colnames(dt))) {
      stop(
        "The following columns are required: ",
        toString(required_cols[!(required_cols %in% colnames(dt))])
      )
    }
  }
  # check for forbidden columns
  if ((length(forbidden_cols) > 0)) {
    if (!is.character(forbidden_cols)) {
      stop("`required_cols` must be a character vector")
    }
    if (any(forbidden_cols %in% colnames(dt))) {
      stop(
        "The following columns are forbidden: ",
        toString(forbidden_cols[forbidden_cols %in% colnames(dt)])
      )
    }
  }

  if (group) {
    if (is.null(dt[[".group"]])) {
      dt <- dt[, .group := 1]
    }
    if (!is.null(select)) {
      select <- c(select, ".group")
    }
  }

  # extract the desired columns
  if (length(select) > 0) {
    return(dt[, .SD, .SDcols = c(select)])
  } else {
    return(dt[])
  }
}
