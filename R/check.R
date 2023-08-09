#' Check required quantiles are present
#'
#' @param posterior A `data.table` that will be [coerce_dt()]d in place; must
#' contain quantiles identified using the `q5` naming scheme.
#'
#' @param req_probs A numeric vector of required probabilities. Default:
#' c(0.5, 0.95, 0.2, 0.8).
#'
#' @return NULL
#'
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  stopifnot(
    "Please provide probabilities as numbers between 0 and 1." =
    all(data.table::between(req_probs, 0, 1, incbounds = FALSE))
  )
  return(coerce_dt(
    posterior, required_cols = sprintf("q%g", req_probs * 100), copy = FALSE,
    msg_required = "The following quantiles must be present (set with `probs`):"
  ))
}

#' Check observations for reserved grouping variables
#'
#' @param obs An object that will be `coerce_dt`d in place, that does not
#' contain `.group`, `.old_group`, or `.new_group`. These are reserved names.
#'
#' @return The `obs` object, which will be modifiable in place.
#'
#' @family check
check_group <- function(obs) {
  return(coerce_dt(
    obs, forbidden_cols = c(".group", ".new_group", ".old_group"), copy = FALSE,
    msg_forbidden = "The following are reserved grouping columns:"
  ))
}

#' Check observations for uniqueness of grouping variables with respect
#' to `reference_date` and `report_date`
#'
#' @description This function checks that the input data is stratified by
#' `reference_date`, `report_date`, and `.group.` It does this by counting the
#' number of observations for each combination of these variables, and
#' throwing a warning if any combination has more than one observation.
#'
#' @param obs An object that will be `coerce_dt`d in place, that contains
#' `.group`, `reference_date`, and `report_date` columns.
#'
#' @return NULL
#'
#' @family check
check_group_date_unique <- function(obs) {
  group_cols <- c("reference_date", "report_date", ".group")
  obs <- coerce_dt(obs, required_cols = group_cols, copy = FALSE)
  cells <- obs[, .(count = .N), by = group_cols]
  if (any(cells[, count > 1])) {
    stop("The input data seems to be stratified by more variables ",
         "than specified via the `by` argument. Please provide additional ",
         "grouping variables to `by`, ",
         "or aggregate the observations beforehand.")
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
#' @param data Any of the types supported by [data.table::as.data.table()]
#'
#' @param copy A logical; if `TRUE` (default), a new `data.table` is returned
#'
#' @param select An optional character vector of columns to return; *unchecked*
#' n.b. it is an error to include ".group"; use `group` argument for that
#'
#' @param required_cols An optional character vector of required columns
#'
#' @param forbidden_cols An optional character vector of forbidden columns
#'
#' @param group A logical; ensure the presence of a `.group` column?
#'
#' @param dates A logical; ensure the presence of `report_date` and
#' `reference_date`? If `TRUE` (default), those columns will be coerced with
#' [data.table::as.IDate()].
#'
#' @param msg_required A character string; for `required_cols`-related error
#' message
#'
#' @param msg_forbidden A character string; for `forbidden_cols`-related error
#' message
#'
#' @return A `data.table`; the returned object will be a copy, unless
#' `copy = FALSE`, in which case modifications are made in-place
#'
#' @details This function provides a single-point function for getting a "local"
#' version of data provided by the user, in the internally used `data.table`
#' format. It also enables selectively copying versus not, as well as checking
#' for the presence and/or absence of various columns.
#'
#' While it is intended to address garbage in from the *user*, it does not
#' generally attempt to address garbage in from the *developer* - e.g. if asking
#' for overlapping required and forbidden columns (though that will lead to an
#' always-error condition).
#'
#' @importFrom data.table as.data.table setDT
#' @family utils
coerce_dt <- function(
  data, select = NULL, required_cols = select,
  forbidden_cols = NULL, group = FALSE,
  dates = FALSE, copy = TRUE,
  msg_required = "The following columns are required: ",
  msg_forbidden = "The following columns are forbidden: "
) {
  if (!copy) { # if we want to keep the original data.table ...
    dt <- data.table::setDT(data)
  } else {     # ... otherwise, make a copy
    dt <- data.table::as.data.table(data)
  }

  if (dates) {
    required_cols <- c(required_cols, c("report_date", "reference_date"))
    if (length(select) > 0) {
      select <- c(select, c("report_date", "reference_date"))
    }
  }

  if ((length(required_cols) > 0)) {     # if we have required columns ...
    if (!is.character(required_cols)) {  # ... check they are check-able
      stop("`required_cols` must be a character vector")
    }
    # check that all required columns are present
    if (!all(required_cols %in% colnames(dt))) {
      stop(
        msg_required,
        toString(required_cols[!(required_cols %in% colnames(dt))]),
        " but are not present among ",
        toString(colnames(dt)),
        "\n(all `required_cols`: ",
        toString(required_cols),
        ")"
      )
    }
  }

  if ((length(forbidden_cols) > 0)) {    # if we have forbidden columns ...
    if (!is.character(forbidden_cols)) { # ... check they are check-able
      stop("`forbidden_cols` must be a character vector")
    }
    # check that no forbidden columns are present
    if (any(forbidden_cols %in% colnames(dt))) {
      stop(
        msg_forbidden,
        toString(forbidden_cols[forbidden_cols %in% colnames(dt)]),
        " but are present among ",
        toString(colnames(dt)),
        "\n(all `forbidden_cols`: ",
        toString(forbidden_cols),
        ")"
      )
    }
  }

  if (group) {                      # if we want to ensure a .group column ...
    if (is.null(dt[[".group"]])) {  # ... check it's presence
      dt <- dt[, .group := 1]       # ... and add it if it's not there
    }
    if (length(select) > 0) {         # if we have a select list ...
      select <- c(select, ".group") # ... add ".group" to it
    }
  }

  if (dates) {
    dt[,               # cast-in-place to IDateTime (as.IDate)
      c("report_date", "reference_date") := .(
        as.IDate(report_date), as.IDate(reference_date)
      )
    ]
  }

  if (length(select) > 0) {         # if selecting particular list ...
    return(dt[, .SD, .SDcols = c(select)][])
  } else {
    return(dt[])
  }
}
