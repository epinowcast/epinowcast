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
#' @importFrom data.table between
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  if (!all(data.table::between(req_probs, 0, 1, incbounds = FALSE))) {
    cli::cli_abort("Please provide probabilities as numbers between 0 and 1.")
  }
  coerce_dt(
    posterior,
    required_cols = sprintf("q%g", req_probs * 100), copy = FALSE,
    msg_required = "The following quantiles must be present (set with `probs`):"
  )
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
  coerce_dt(
    obs,
    forbidden_cols = c(".group", ".new_group", ".old_group"), copy = FALSE,
    msg_forbidden = "The following are reserved grouping columns:"
  )
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
        "The input data seems to be stratified by more variables than ",
        "specified via the `by` argument. Please provide additional grouping ",
        "variables to `by`, or aggregate the observations beforehand."
      )
    )
  }
  invisible(NULL)
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
        "Must contain a list component specifying the data requirements for ",
        "further modelling as a list"
      )
    )
  }
  if (!is.list(module[["data"]])) {
    cli::cli_abort("`data` must be a list of required data")
  }
  invisible(NULL)
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
      c(
        paste0(
          "Incompatible model specification: A missingness model has been ",
          "specified but likelihood aggregation is specified as by snapshot. ",
          "Switching to likelihood aggregation by group. ",
          "This has no effect on the nowcast but limits the number of threads ",
          "per chain to the number of groups."
        ),
        paste0(
          "To silence this warning, set the `likelihood_aggregation` argument ",
          "in `enw_fit_opts` to 'groups'. "
        )
      ),
      immediate. = TRUE
    )
  }
  invisible(NULL)
}

#' @title Coerce `data.table`s
#'
#' @description Provides consistent coercion of inputs to
#' \link[data.table]{data.table} with error handling, column checking, and
#' optional selection.
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
#' \link[data.table]{as.IDate}.
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
#' When `dates = TRUE`, this function ensures that `report_date` and
#' `reference_date` columns are coerced to `IDate` class with integer storage
#' mode. This is necessary because some operations (such as `dplyr::filter()`)
#' can convert `IDate` columns to double storage mode whilst preserving the
#' class, which violates data.table's requirements and causes errors in
#' subsequent date arithmetic operations.
#'
#' @importFrom data.table as.data.table setDT
#' @importFrom cli cli_abort
#' @family utils
coerce_dt <- function(
    data, select = NULL, required_cols = select,
    forbidden_cols = NULL, group = FALSE,
    dates = FALSE, copy = TRUE,
    msg_required = "The following columns are required: ",
    msg_forbidden = "The following columns are forbidden: ") {
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

  if ((length(required_cols) > 0)) { # if we have required columns ...
    if (!is.character(required_cols)) { # ... check they are check-able
      cli::cli_abort("`required_cols` must be a character vector")
    }
    # check that all required columns are present
    if (!all(required_cols %in% colnames(dt))) {
      cli::cli_abort(
        paste0(
          "{msg_required}",
          "{toString(required_cols[!(required_cols %in% colnames(dt))])} ",
          "but are not present among ",
          "{toString(colnames(dt))} ",
          "(all {.arg required_cols}: {toString(required_cols)})"
        )
      )
    }
  }

  if ((length(forbidden_cols) > 0)) { # if we have forbidden columns ...
    if (!is.character(forbidden_cols)) { # ... check they are check-able
      cli::cli_abort("`forbidden_cols` must be a character vector")
    }
    # check that no forbidden columns are present
    if (any(forbidden_cols %in% colnames(dt))) {
      cli::cli_abort(
        paste0(
          "{msg_forbidden}",
          "{toString(forbidden_cols[forbidden_cols %in% colnames(dt)])}",
          "but are present among",
          "{toString(colnames(dt))}",
          "(all `forbidden_cols`: {toString(forbidden_cols)})"
        )
      )
    }
  }

  if (group) { # if we want to ensure a .group column ...
    if (is.null(dt[[".group"]])) { # ... check it's presence
      dt <- dt[, .group := 1] # ... and add it if it's not there
    }
    if (length(select) > 0) { # if we have a select list ...
      select <- c(select, ".group") # ... add ".group" to it
    }
  }

  if (dates) {
    dt[
      ,
      c("report_date", "reference_date") := .(
        as.IDate(report_date), as.IDate(reference_date)
      )
    ]
    # Restore integer storage mode if corrupted by dplyr operations
    # dplyr can convert IDate to double storage whilst preserving class
    if (storage.mode(dt$report_date) != "integer") {
      dt[, report_date := as.integer(report_date)]
      class(dt$report_date) <- c("IDate", "Date")
    }
    if (storage.mode(dt$reference_date) != "integer") {
      dt[, reference_date := as.integer(reference_date)]
      class(dt$reference_date) <- c("IDate", "Date")
    }
  }

  if (length(select) > 0) { # if selecting particular list ...
    dt[, .SD, .SDcols = c(select)][]
  } else {
    dt[]
  }
}

#' @title Check appropriateness of maximum delay
#'
#' @description Check if maximum delay specified by the user is long enough and
#' raise potential warnings. This is achieved by computing the share of
#' reference dates where the cumulative case count is below some aspired
#' coverage.
#'
#' @details When data is very sparse (e.g., predominantly zero counts), the
#' function may not be able to compute meaningful coverage statistics.
#' In such cases, a warning is issued and the function treats the data as
#' having no coverage issues.
#' This typically occurs when groups have very few non-zero observations or
#' when the specified \code{max_delay} is too large relative to available
#' data.
#'
#' The coverage is with respect to the maximum observed case count for
#' the corresponding reference date. As the maximum observed case count is
#' likely smaller than the true overall case count for not yet fully observed
#' reference dates (due to right truncation), only reference dates that are
#' more than the maximum observed delay ago are included. Still, because we
#' can only use the maximum observed delay, not the unknown true maximum
#' delay, the computed coverage values should be interpreted with care, as they
#' are only proxies for the true coverage.
#'
#' @inheritParams enw_filter_delay
#' @inheritParams enw_preprocess_data
#'
#' @param data Output from [enw_preprocess_data()].
#'
#' @param cum_coverage The aspired percentage of cases that the maximum delay
#' should cover. Defaults to 0.8 (80%).
#'
#' @param maxdelay_quantile_outlier Only reference dates sufficiently far in
#' the past, determined based on the maximum observed delay, are included (see
#' details). Instead of the overall maximum observed delay, a quantile of the
#' maximum observed delay over all reference dates is used. This is more robust
#' against outliers. Defaults to 0.97 (97%).
#'
#' @param warn Should a warning be issued if the cumulative case count is
#' below `cum_coverage` for the majority of reference dates?
#'
#' @param warn_internal Should only be `TRUE` if this function is called
#' internally by another `epinowcast` function. Then, warnings are adjusted to
#' avoid confusing the user.
#'
#' @return A `data.table` with the share of reference dates where the
#' cumulative case count is below `cum_coverage`, stratified by group.
#'
#' @family check
#' @export
#' @examples
#' pobs <- enw_example(type = "preprocessed_observations")
#' check_max_delay(pobs, max_delay = 20, cum_coverage = 0.8)
check_max_delay <- function(data,
                            max_delay = data$max_delay,
                            cum_coverage = 0.8,
                            maxdelay_quantile_outlier = 0.97,
                            warn = TRUE, warn_internal = FALSE) {
  max_delay <- .validate_check_max_delay_args(
    max_delay, cum_coverage, maxdelay_quantile_outlier
  )

  timestep <- data$timestep
  internal_timestep <- get_internal_timestep(timestep)
  daily_max_delay <- internal_timestep * max_delay

  obs <- data.table::copy(data$obs[[1]])
  obs[, delay := internal_timestep * delay]

  max_delay_obs <- obs[, max(delay, na.rm = TRUE)] + internal_timestep
  if (max_delay_obs < daily_max_delay) {
    .warn_max_delay_exceeds_observed(
      max_delay, timestep, daily_max_delay, max_delay_obs, internal_timestep
    )
  }

  max_delay_ref <- obs[
    !is.na(reference_date) & cum_prop_reported == 1,
    .(.group, reference_date, delay)
  ]
  data.table::setorderv(max_delay_ref, c(".group", "reference_date", "delay"))
  max_delay_ref <- max_delay_ref[
    ,
    .SD[, .(delay = first(delay)), by = reference_date]
  ] # we here assume the same maximum delay for all groups

  max_delay_obs_q <- ceiling(
    max_delay_ref[, quantile(delay, maxdelay_quantile_outlier, na.rm = TRUE)]
  ) + 1

  # Filter by the user-specified maximum delay with daily resolution
  obs <- enw_filter_delay(obs, max_delay = daily_max_delay, timestep = "day")

  # filter by earliest observed report date
  obs <- obs[,
    .SD[reference_date >= min(report_date) | is.na(reference_date)],
    by = .group
  ]

  latest_obs <- enw_latest_data(obs)
  fully_observed_date <- latest_obs[, max(report_date)] - max_delay_obs_q + 1
  # filter by the maximum observed delay to reduce right truncation bias
  latest_obs <- enw_filter_reference_dates(
    latest_obs,
    latest_date = fully_observed_date
  )

  if (warn && max_delay_obs >= daily_max_delay && (latest_obs[, .N] < 5)) {
    .warn_insufficient_coverage_data(
      latest_obs[, .N], max_delay_obs_q, timestep, internal_timestep,
      warn_internal
    )
  }

  low_coverage <- latest_obs[, .(
    below_coverage =
      sum(cum_prop_reported < cum_coverage, na.rm = TRUE) /
        sum(!is.na(cum_prop_reported))
  ), by = .group]

  # Check if all coverage values are NaN or NA (occurs with sparse data)
  if (all(is.na(low_coverage$below_coverage) |
    is.nan(low_coverage$below_coverage))) {
    low_coverage[, below_coverage := 0]
    mean_coverage <- 0
    if (warn && warn_internal) {
      warning_message <- c(
        "Could not compute delay coverage statistics.",
        "*" = paste0(
          "All groups have insufficient data after filtering to ",
          "compute meaningful coverage metrics."
        ),
        i = paste0(
          "This typically occurs with sparse data or when max_delay ",
          "is too large relative to available observations."
        )
      )
      cli::cli_warn(warning_message)
    }
  } else {
    mean_coverage <- low_coverage[, mean(below_coverage, na.rm = TRUE)]
  }

  if (warn && !is.na(mean_coverage) && mean_coverage > 0.5) {
    # Format max_delay with appropriate units
    formatted_max <- .format_delay_with_units(
      max_delay, timestep, daily_max_delay
    )

    cli::cli_warn(
      paste0(
        "The specified maximum reporting delay ",
        "(", formatted_max, ") ",
        "covers less than ", 100 * cum_coverage,
        "% of cases for the majority (>50%) of reference dates. ",
        "Consider using a larger maximum delay to avoid potential model ",
        "misspecification."
      ),
      immediate. = TRUE
    )
  }

  low_coverage <- rbind(low_coverage, list("all", mean_coverage))
  low_coverage[, coverage := cum_coverage]
  data.table::setcolorder(low_coverage, c(".group", "coverage"))
  low_coverage[]
}

#' Validate check_max_delay arguments
#'
#' @param max_delay Maximum delay
#' @param cum_coverage Cumulative coverage threshold
#' @param maxdelay_quantile_outlier Quantile for outlier detection
#' @return Integer max_delay value
#' @keywords internal
.validate_check_max_delay_args <- function(max_delay, cum_coverage,
                                           maxdelay_quantile_outlier) {
  if (!is.numeric(max_delay)) {
    cli::cli_abort("`max_delay` must be an integer and not NA")
  }
  max_delay <- as.integer(max_delay)
  if (max_delay < 1) {
    cli::cli_abort("`max_delay` must be greater than or equal to one")
  }
  if (!(cum_coverage > 0 && cum_coverage <= 1)) {
    cli::cli_abort("`cum_coverage` must be between 0 and 1, e.g. 0.8 for 80%.")
  }
  if (!(maxdelay_quantile_outlier > 0 && maxdelay_quantile_outlier <= 1)) {
    cli::cli_abort(
      "`maxdelay_quantile_outlier` must be between 0 and 1, e.g. 0.97 for 97%."
    )
  }
  max_delay
}

#' Warn about max delay exceeding observed delay
#'
#' @param max_delay Maximum delay in timestep units
#' @param timestep Timestep specification
#' @param max_delay_obs Maximum observed delay in daily units
#' @param daily_max_delay Specified maximum delay in daily units
#' @param internal_timestep Internal timestep multiplier
#' @keywords internal
.warn_max_delay_exceeds_observed <- function(max_delay, timestep,
                                             daily_max_delay, max_delay_obs,
                                             internal_timestep) {
  formatted_max <- .format_delay_with_units(
    max_delay, timestep, daily_max_delay
  )
  formatted_obs <- .format_delay_with_units(
    max_delay_obs / internal_timestep, timestep, max_delay_obs
  )

  warning_message <- c(
    paste0(
      "You specified a maximum delay of ", formatted_max, ", ",
      "but the maximum observed delay is only ", formatted_obs, ". "
    ),
    paste0(
      "This is justified if you don't have much data yet (e.g. early ",
      "phase of an outbreak) and expect a longer maximum delay than ",
      "currently observed. epinowcast will then extrapolate the delay ",
      "distribution beyond the observed maximum delay."
    ),
    paste0(
      "Otherwise, we recommend using a shorter maximum delay to speed ",
      "up the nowcasting."
    )
  )
  names(warning_message) <- c("", "*", "*")
  cli::cli_warn(warning_message)
}

#' Warn about insufficient data for coverage check
#'
#' @param latest_obs_count Number of observations in filtered data
#' @param max_delay_obs_q Quantile-based maximum delay
#' @param timestep Timestep specification
#' @param internal_timestep Internal timestep multiplier
#' @param warn_internal Whether function is called internally
#' @keywords internal
.warn_insufficient_coverage_data <- function(latest_obs_count,
                                             max_delay_obs_q, timestep,
                                             internal_timestep,
                                             warn_internal) {
  formatted_obs_q <- .format_delay_with_units(
    max_delay_obs_q / internal_timestep, timestep, max_delay_obs_q
  )

  warning_message <- c(
    paste0(
      "The coverage of the specified maximum delay could not be ",
      "reliably checked."
    ),
    "*" = paste0(
      "There are only very few (", latest_obs_count, ") reference ",
      "dates that are sufficiently far in the past (more than ",
      formatted_obs_q, ") to compute coverage statistics for the ",
      "maximum delay. "
    )
  )

  if (warn_internal) {
    warning_message <- c(
      warning_message,
      "*" = paste0(
        "You can test different maximum delays and obtain coverage ",
        "statistics using the function ",
        "{.help [check_max_delay()](epinowcast::check_max_delay)}."
      )
    )
  } else {
    warning_message <- c(
      warning_message,
      "*" = paste0(
        "If you think the truncation threshold of ", formatted_obs_q,
        " is based on an outlier, and the true maximum delay is ",
        "likely shorter, you can decrease ",
        "`maxdelay_quantile_outlier` to silence this warning."
      )
    )
  }
  cli::cli_warn(warning_message)
}

#' Check Numeric Timestep
#'
#' This function verifies if the difference in numeric dates in the provided
#' observations corresponds to the provided timestep.
#'
#' @param dates Vector of Date class representing dates.
#' @param date_var The variable in `obs` representing dates.
#' @param timestep Numeric timestep for date difference.
#' @param exact Logical, if `TRUE`, checks if all differences exactly match the
#' timestep. If `FALSE`, checks if the sum of the differences modulo the
#' timestep equals zero. Default is `TRUE`.
#'
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
      "{date_var} has a duplicate date. Please remove duplicate dates."
    )
  }

  if (any(diffs < timestep)) {
    cli::cli_abort(
      paste0(
        "{date_var} has a shorter timestep than the specified timestep of ",
        "{timestep} day(s)"
      )
    )
  }

  if (exact) {
    check <- all(diffs == timestep)
  } else {
    check <- sum(diffs %% timestep) == 0
  }

  if (!check) {
    cli::cli_abort(
      "{date_var} does not have the specified timestep of {timestep} day(s)"
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
#' @param date_var The variable in `obs` representing dates.
#' @param exact Logical, if `TRUE`, checks if all differences exactly match the
#' timestep. If `FALSE`, checks if the sum of the differences modulo the
#' timestep equals zero. Default is `TRUE`.
#'
#' @inheritParams get_internal_timestep
#'
#' @return This function is used for its side effect of stopping if the check
#' fails. If the check passes, the function returns invisibly.
#' @importFrom cli cli_abort
#' @family check
check_timestep <- function(obs, date_var, timestep = "day", exact = TRUE,
                           check_nrow = TRUE) {
  obs <- coerce_dt(obs, required_cols = date_var, copy = FALSE)
  if (!is.Date(obs[[date_var]])) {
    cli::cli_abort("{date_var} must be of class Date")
  }

  dates <- obs[[date_var]]
  dates <- sort(dates)
  dates <- dates[!is.na(dates)]

  if (length(dates) <= 1 && !check_nrow) {
    invisible(NULL)
  }
  if (length(dates) <= 1) {
    cli::cli_abort("There must be at least two observations")
  }

  internal_timestep <- get_internal_timestep(timestep)
  check_numeric_timestep(dates, date_var, internal_timestep, exact)
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
      .SD,
      date_var = date_var, timestep, exact, check_nrow = FALSE
    ),
    by = ".group"
  ]
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
        "There must be at least two observations by group and date",
        " combination to establish a timestep"
      )
    )
  }
  obs[,
    check_timestep(
      .SD,
      date_var = "report_date", timestep, exact, check_nrow = FALSE
    ),
    by = c("reference_date", ".group")
  ]
  obs[,
    check_timestep(
      .SD,
      date_var = "reference_date", timestep, exact, check_nrow = FALSE
    ),
    by = c("report_date", ".group")
  ]
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
    new_confirm, observation_indicator = NULL) {
  if (!is.null(observation_indicator) &&
    !is.logical(new_confirm[[observation_indicator]])) {
    cli::cli_abort("observation_indicator must be a logical")
  }
}

#' Check design matrix sparsity
#'
#' This function checks the sparsity of a design matrix and provides a
#' recommendation if the matrix is considered sparse.
#'
#' @param matrix A numeric matrix to be checked for sparsity.
#' @param sparsity_threshold A numeric value between 0 and 1 indicating the
#' threshold for considering a matrix sparse. Default is 0.9.
#' @param min_matrix_size An integer indicating the minimum size of the matrix
#' for which to perform the sparsity check. Default is 50.
#' @param name A character string specifying the name of the design
#' matrix. Default is "checked".
#'
#' @return This function is used for its side effect of providing an
#' informational message if the matrix is sparse. It returns NULL invisibly.
#'
#' @importFrom cli cli_alert_info
#' @family check
check_design_matrix_sparsity <- function(matrix, sparsity_threshold = 0.9,
                                         min_matrix_size = 50,
                                         name = "checked") {
  if (length(matrix) < min_matrix_size) {
    invisible(NULL)
  }

  zero_proportion <- sum(matrix == 0) / length(matrix)

  if (zero_proportion > sparsity_threshold) {
    cli::cli_alert_info(
      c(
        "The {name} design matrix is sparse (>{sparsity_threshold*100}% ",
        "zeros). Consider using `sparse_design = TRUE` in `enw_fit_opts()` ",
        "to potentially reduce memory usage and computation time."
      )
    )
  }
}
