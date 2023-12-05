#' Check required quantiles are present
#'
#' @param posterior A `data.table` that will be [coerce_dt()]d in place; must
#' contain quantiles identified using the `q5` naming scheme.
#'
#' @param req_probs A numeric vector of required probabilities. Default:
#' c(0.5, 0.95, 0.2, 0.8).
#'
#' @return NULL
#' @importFrom cli cli_abort
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  if (!all(between(req_probs, 0, 1, incbounds = FALSE))) {
    cli::cli_abort("Please provide probabilities as numbers between 0 and 1.")
  }
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
#' @importFrom cli cli_abort
#' @family check
check_group_date_unique <- function(obs) {
  group_cols <- c("reference_date", "report_date", ".group")
  obs <- coerce_dt(obs, required_cols = group_cols, copy = FALSE)
  cells <- obs[, .(count = .N), by = group_cols]
  if (any(cells[, count > 1])) {
    cli::cli_abort(
      paste0(
        "The input data seems to be stratified by more variables ",
        "than specified via the `by` argument. Please provide additional ",
        "grouping variables to `by`, ",
        "or aggregate the observations beforehand."
      )
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
#' @importFrom cli cli_abort
#' @family check
check_module <- function(module) {
  if (!"data" %in% names(module)) {
    cli::cli_abort(
      paste0(
        "Must contain a list component specifying the data requirements ",
        "for further modelling as a list"
      )
    )
  }
  if (!is.list(module[["data"]])) {
    cli::cli_abort(
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
#' @importFrom cli cli_warn
#' @family check
check_modules_compatible <- function(modules) {
  if (
    modules[[4]]$data$model_miss &&
      !modules[[6]]$data$likelihood_aggregation
  ) {
    cli::cli_warn(
      paste0(
        "Incompatible model specification: A missingness model has ",
        "been specified but likelihood aggregation is specified as ",
        "by snapshot. Switching to likelihood aggregation by group.",
        " This has no effect on the nowcast but limits the ",
        "number of threads per chain to the number of groups. To ",
        "silence this warning, set the `likelihood_aggregation` ",
        "argument in `enw_fit_opts` to 'groups'."
      ),
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
#' @importFrom cli cli_abort
#' @family utils
coerce_dt <- function(
  data, select = NULL, required_cols = select,
  forbidden_cols = NULL, group = FALSE,
  dates = FALSE, copy = TRUE,
  msg_required = "The following columns are required: ",
  msg_forbidden = "The following columns are forbidden: "
) {
  if (copy) {
    dt <- data.table::as.data.table(data)
  } else {
    dt <- data.table::setDT(data)
  }

  if (dates) {
    required_cols <- c(required_cols, c("report_date", "reference_date"))
    if (length(select) > 0) {
      select <- c(select, c("report_date", "reference_date"))
    }
  }

  if ((length(required_cols) > 0)) {     # if we have required columns ...
    if (!is.character(required_cols)) {  # ... check they are check-able
      cli::cli_abort("`required_cols` must be a character vector")
    }
    # check that all required columns are present
    if (!all(required_cols %in% colnames(dt))) {
      cli::cli_abort(
        paste0(
          msg_required,
          toString(required_cols[!(required_cols %in% colnames(dt))]),
          " but are not present among ",
          toString(colnames(dt)),
          "\n(all `required_cols`: ",
          toString(required_cols),
          ")"
        )
      )
    }
  }

  if ((length(forbidden_cols) > 0)) {    # if we have forbidden columns ...
    if (!is.character(forbidden_cols)) { # ... check they are check-able
      cli::cli_abort("`forbidden_cols` must be a character vector")
    }
    # check that no forbidden columns are present
    if (any(forbidden_cols %in% colnames(dt))) {
      cli::cli_abort(
        paste0(
          msg_forbidden,
          toString(forbidden_cols[forbidden_cols %in% colnames(dt)]),
          " but are present among ",
          toString(colnames(dt)),
          "\n(all `forbidden_cols`: ",
          toString(forbidden_cols),
          ")"
        )
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

#' Check calendar timestep
#'
#' This function verifies if the difference in calendar dates in the provided
#' observations corresponds to the provided timestep of "month".
#'
#' @param dates Vector of Date class representing dates.
#' @param date_var The variable in `obs` representing dates.
#' @param exact Logical, if `TRUE``, checks if all differences exactly match the
#' timestep. If `FALSE``, checks if the sum of the differences modulo the
#' timestep equals zero. Default is `TRUE`.
#'
#' @importFrom lubridate %m-%
#' @return This function is used for its side effect of stopping if the check
#' fails. If the check passes, the function returns invisibly.
#' @importFrom cli cli_abort
#' @family check
check_calendar_timestep <- function(dates, date_var, exact = TRUE) {
  diff_dates <- dates[-1] %m-% months(1L)
  sequential_dates <- dates[-length(dates)] == diff_dates
  all_sequential_dates <- all(sequential_dates)

  if (any(diff_dates < dates[-length(dates)])) {
    cli::cli_abort(
      paste0(
        date_var,
        " has a shorter timestep than the specified timestep of a month"
      )
    )
  }

  if (all_sequential_dates) {
    return(invisible(NULL))
  } else {
    if (exact) {
      cli::cli_abort(
        paste0(
          date_var,
          " does not have the specified timestep of month"
        )
      )
    } else {
      cli::cli_abort(
        "Non-sequential dates are not currently supported for monthly data"
      )
    }
  }
}

#' Check Numeric Timestep
#'
#' This function verifies if the difference in numeric dates in the provided
#' observations corresponds to the provided timestep.
#'
#' @param timestep Numeric timestep for date difference.
#'
#' @inheritParams check_calendar_timestep
#' @return This function is used for its side effect of stopping if the check
#' fails. If the check passes, the function returns invisibly.
#' @importFrom cli cli_abort
#' @family check
check_numeric_timestep <- function(dates, date_var, timestep, exact = TRUE) {
  diffs <- as.numeric(
    difftime(dates[-1], dates[-length(dates)], units = "days")
  )

  if (any(diffs == 0)) {
    cli::cli_abort(
      paste0(
        date_var,
        " has a duplicate date. Please remove duplicate dates."
      )
    )
  }

  if (any(diffs < timestep)) {
    cli::cli_abort(
      paste0(
        date_var, " has a shorter timestep than the specified timestep of ",
        timestep, " day(s)"
      )
    )
  }

  if (exact) {
    check <- all(diffs == timestep)
  } else {
    check <- sum(diffs %% timestep) == 0
  }

  if (check) {
    return(invisible(NULL))
  } else {
    cli::cli_abort(
      paste0(
        date_var, " does not have the specified timestep of ", timestep,
        " day(s)"
      )
    )
  }
}

#' Check timestep
#'
#' This function verifies if the difference in dates in the provided
#' observations corresponds to the provided timestep. If the `exact` argument
#' is set to TRUE, the function checks if all differences exactly match the
#' timestep; otherwise, it checks if the sum of the differences modulo the
#' timestep equals zero. If the check fails, the function stops and returns an
#' error message.
#'
#' @param obs Any of the types supported by [data.table::as.data.table()].
#'
#' @param check_nrow Logical, if `TRUE`, checks if there are at least two
#' observations. Default is `TRUE`. If `FALSE`, the function returns invisibly
#' if there is only one observation.
#'
#'
#' @inheritParams get_internal_timestep
#' @inheritParams check_calendar_timestep
#'
#' @return This function is used for its side effect of stopping if the check
#' fails. If the check passes, the function returns invisibly.
#' @importFrom cli cli_abort
#' @family check
check_timestep <- function(obs, date_var, timestep = "day", exact = TRUE,
                           check_nrow = TRUE) {
  obs <- coerce_dt(obs, required_cols = date_var, copy = FALSE)
  if (!is.Date(obs[[date_var]])) {
    cli::cli_abort(paste0(date_var, " must be of class Date"))
  }

  dates <- obs[[date_var]]
  dates <- sort(dates)
  dates <- dates[!is.na(dates)]

  if (length(dates) <= 1) {
    if (check_nrow) {
      cli::cli_abort("There must be at least two observations")
    } else {
      return(invisible(NULL))
    }
  }

  internal_timestep <- get_internal_timestep(timestep)

  if (internal_timestep == "month") {
    check_calendar_timestep(dates, date_var, exact)
  } else {
    check_numeric_timestep(dates, date_var, internal_timestep, exact)
  }

  return(invisible(NULL))
}

#' Check timestep by group
#'
#' This function verifies if the difference in dates within each group in the
#' provided observations corresponds to the provided timestep. This check is
#' performed for the specified `date_var` and for each group in `obs`.
#'
#' @param obs Any of the types supported by [data.table::as.data.table()].
#'
#' @inheritParams check_timestep
#' @return This function is used for its side effect of checking the timestep
#' by group in `obs`. If the check passes for all groups, the function
#' returns invisibly. Otherwise, it stops and returns an error message.
#' @family check
check_timestep_by_group <- function(obs, date_var, timestep = "day",
                                    exact = TRUE) {
  # Coerce to data.table and check for required columns
  obs <- coerce_dt(obs, required_cols = date_var, copy = FALSE, group = TRUE)

  # Check the timestep within each group
  obs[,
   check_timestep(
    .SD, date_var = date_var, timestep, exact, check_nrow = FALSE),
    by = ".group"
  ]

  return(invisible(NULL))
}

#' Check timestep by date
#'
#' This function verifies if the difference in dates within each date in the
#' provided observations corresponds to the provided timestep. This check is
#' performed for both `report_date` and `reference_date` and for each group in
#' `obs`.
#'
#' @inheritParams check_timestep
#'
#' @return This function is used for its side effect of checking the timestep
#' by date in `obs`. If the check passes for all dates, the function
#' returns invisibly. Otherwise, it stops and returns an error message.
#' @importFrom cli cli_abort
#' @family check
check_timestep_by_date <- function(obs, timestep = "day", exact = TRUE) {
  obs <- coerce_dt(obs, copy = TRUE, dates = TRUE, group = TRUE)
  cnt_obs_rep <- obs[, .(.N), by = c("report_date", ".group")]
  cnt_obs_ref <- obs[, .(.N), by = c("reference_date", ".group")]
  if (all(cnt_obs_rep$N <= 1) || all(cnt_obs_ref$N <= 1)) {
    cli::cli_abort(
      paste0(
        "There must be at least two observations by group and date ",
        "combination to establish a timestep"
      )
    )
  }
  obs[,
      check_timestep(
        .SD, date_var = "report_date", timestep, exact, check_nrow = FALSE
      ),
      by = c("reference_date", ".group")
  ]
  obs[,
      check_timestep(
        .SD, date_var = "reference_date", timestep, exact, check_nrow = FALSE
      ),
      by = c("report_date", ".group")
  ]
  return(invisible(NULL))
}

#' Check observation indicator
#'
#' This function verifies if the `observation_indicator` within the provided
#' `new_confirm` observations is logical. The check is performed to ensure
#' that the `observation_indicator` is of the correct type.
#'
#' @param new_confirm A data frame containing the observations to be checked.
#' @param observation_indicator A character string specifying the column name
#' in `new_confirm` that represents the observation indicator. This column
#' should be of logical type. If NULL, no check is performed.
#'
#' @return This function is used for its side effect of checking the observation
#' indicator in `new_confirm`. If the check passes, the function returns
#' invisibly. Otherwise, it stops and returns an error message.
#' @importFrom cli cli_abort
#' @family check
check_observation_indicator <- function(
  new_confirm, observation_indicator = NULL
) {
  if (!is.null(observation_indicator) &&
      !is.logical(new_confirm[[observation_indicator]])) {
    cli::cli_abort("observation_indicator must be a logical")
  }
  return(invisible(NULL))
}
