#' Check required quantiles are present
#'
#' @param posterior A `data.table` that will be [coerceDT::makeDT()]d in place; must
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
  return(makeDT(
    posterior, require = sprintf("q%g", req_probs * 100), copy = FALSE
# TODO
#    , msg_required = "The following quantiles must be present (set with `probs`):"
  ))
}

#' Check observations for reserved grouping variables
#'
#' @param obs An object that will be [coerceDT::makeDT()]`d in place, that does not
#' contain `.group`, `.old_group`, or `.new_group`. These are reserved names.
#'
#' @return The `obs` object, which will be modifiable in place.
#'
#' @family check
check_group <- function(obs) {
  return(makeDT(
    obs, forbid = c(".group", ".new_group", ".old_group"), copy = FALSE
# TODO
#    , msg_forbidden = "The following are reserved grouping columns:"
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
#' @param obs An object that will be [coerceDT::makeDT()]d in place, that contains
#' `.group`, `reference_date`, and `report_date` columns.
#'
#' @return NULL
#'
#' @family check
check_group_date_unique <- function(obs) {
  group_cols <- c("reference_date", "report_date", ".group")
  obs <- makeDT(obs, require = group_cols, copy = FALSE)
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
#' @family check
check_calendar_timestep <- function(dates, date_var, exact = TRUE) {
  diff_dates <- dates[-1] %m-% months(1L)
  sequential_dates <- dates[-length(dates)] == diff_dates
  all_sequential_dates <- all(sequential_dates)

  if (any(diff_dates < dates[-length(dates)])) {
    stop(
      date_var, " has a shorter timestep than the specified timestep of a month"
    )
  }

  if (all_sequential_dates) {
    return(invisible(NULL))
  } else {
    if (exact) {
      stop(
        date_var, " does not have the specified timestep of month"
      )
    } else {
      stop(
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
#' @family check
check_numeric_timestep <- function(dates, date_var, timestep, exact = TRUE) {
  diffs <- as.numeric(
    difftime(dates[-1], dates[-length(dates)], units = "days")
  )

  if (any(diffs == 0)) {
    stop(
      date_var, " has a duplicate date. Please remove duplicate dates."
    )
  }

  if (any(diffs < timestep)) {
    stop(
      date_var, " has a shorter timestep than the specified timestep of ",
      timestep, " day(s)"
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
    stop(
      date_var, " does not have the specified timestep of ", timestep,
      " day(s)"
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
#' @importFrom coerceDT makeDT
#' 
#' @return This function is used for its side effect of stopping if the check
#' fails. If the check passes, the function returns invisibly.
#' @family check
check_timestep <- function(obs, date_var, timestep = "day", exact = TRUE,
                           check_nrow = TRUE) {
  reqstmt <- list()
  reqstmt[[date_var]] <- "Date"
  obs <- makeDT(obs, require = date_var, copy = FALSE)

  dates <- obs[[date_var]]
  dates <- sort(dates)
  dates <- dates[!is.na(dates)]

  if (length(dates) <= 1) {
    if (check_nrow) {
      stop("There must be at least two observations")
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
  obs <- makeDT(obs, require = date_var, copy = FALSE)
  # TODO
  #, group = TRUE)

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
#' @family check
check_timestep_by_date <- function(obs, timestep = "day", exact = TRUE) {
  obs <- makeDT(obs)
  # TODO
  # , dates = TRUE, group = TRUE)
  cnt_obs_rep <- obs[, .(.N), by = c("report_date", ".group")]
  cnt_obs_ref <- obs[, .(.N), by = c("reference_date", ".group")]
  if (all(cnt_obs_rep$N <= 1) || all(cnt_obs_ref$N <= 1)) {
    stop(
      "There must be at least two observations by group and date",
      " combination to establish a timestep"
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
#' @family check
check_observation_indicator <- function(
  new_confirm, observation_indicator = NULL
) {
  if (!is.null(observation_indicator)) {
    stopifnot(
      "observation_indicator must be a logical" = is.logical(new_confirm[[observation_indicator]] # nolint
      )
    )
  }
  return(invisible(NULL))
}
