#' Check Quantiles Required are Present
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
    posterior,
    required_cols = sprintf("q%g", req_probs * 100), copy = FALSE,
    msg_required = "The following quantiles must be present (set with `probs`):"
  ))
}

#' Check Observations for Reserved Grouping Variables
#'
#' @param obs An object that will be `coerce_dt`d in place, that does not
#' contain `.group`, `.old_group`, or `.new_group`. These are reserved names.
#'
#' @return The `obs` object, which will be modifiable in place.
#'
#' @family check
check_group <- function(obs) {
  return(coerce_dt(
    obs,
    forbidden_cols = c(".group", ".new_group", ".old_group"), copy = FALSE,
    msg_forbidden = "The following are reserved grouping columns:"
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
coerce_dt <- function(data, select = NULL, required_cols = select,
                      forbidden_cols = NULL, group = FALSE,
                      dates = FALSE, copy = TRUE,
                      msg_required = "The following columns are required: ",
                      msg_forbidden = "The following columns are forbidden: ") {
  if (!copy) { # if we want to keep the original data.table ...
    dt <- data.table::setDT(data)
  } else { # ... otherwise, make a copy
    dt <- data.table::as.data.table(data)
  }

  if (dates) {
    required_cols <- c(required_cols, c("report_date", "reference_date"))
    if (length(select) > 0) {
      select <- c(select, c("report_date", "reference_date"))
    }
  }

  if ((length(required_cols) > 0)) { # if we have required columns ...
    if (!is.character(required_cols)) { # ... check they are check-able
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

  if ((length(forbidden_cols) > 0)) { # if we have forbidden columns ...
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
      , # cast-in-place to IDateTime (as.IDate)
      c("report_date", "reference_date") := .(
        as.IDate(report_date), as.IDate(reference_date)
      )
    ]
  }

  if (length(select) > 0) { # if selecting particular list ...
    return(dt[, .SD, .SDcols = c(select)][])
  } else {
    return(dt[])
  }
}

#' @title Check appropriateness of maximum delay
#'
#' @description Check if maximum delay specified by the user is long enough and
#' raise potential warnings. This is achieved by computing the share of reference dates where the
#' cumulative case count is below some aspired coverage.
#'
#' @details The coverage is with respect to the maximum observed case count for
#' the corresponding reference date. As the maximum observed case count is
#' likely smaller than the true overall case count for not yet fully observed
#' reference dates (due to right truncation), only reference dates that are
#' more than the maximum observed delay ago are included. Still, because we
#' can only use the maximum observed delay, not the unknown true maximum
#' delay, the computed coverage values should be interpreted with care, as they
#' are only proxies for the true coverage.
#'
#' @inheritParams enw_preprocess_data
#' 
#' @inheritParams enw_add_incidence
#'
#' @param cum_coverage The aspired percentage of cases that the maximum delay
#' should cover. Defaults to 0.8 (80%).
#' 
#' @param quantile_outlier Only reference dates sufficiently far in the past,
#' determined based on the maximum observed delay, are included (see details).
#' Instead of the overall maximum observed delay, a quantile of the maximum
#' observed delay over all reference dates is used. This is more robust
#' against outliers. Defaults to 0.97 (97%).
#'
#' @param warn Should a warning be issued if the cumulative case count is
#' below `cum_coverage` for the majority of reference dates?
#'
#' @return A `data.table` with the share of reference dates where the
#' cumulative case count is below `cum_coverage`, stratified by group.
#'
#' @family check
#' @export
#' @examples
#' check_max_delay(germany_covid19_hosp, max_delay = 20, cum_coverage = 0.8)
check_max_delay <- function(obs,
                            max_delay = 20,
                            by = NULL,
                            cum_coverage = 0.8,
                            quantile_outlier = 0.97,
                            set_negatives_to_zero = TRUE,
                            warn = TRUE) {

  max_delay <- as.integer(max_delay)
  stopifnot(
    "`max_delay` must be an integer and not NA" = is.integer(max_delay),
    "`max_delay` must be greater than or equal to one" = max_delay >= 1,
    "`cum_coverage` must be between 0 and 1, e.g. 0.8 for 80%." =
      cum_coverage > 0 & cum_coverage <= 1,
    "`quantile_outlier` must be between 0 and 1, e.g. 0.97 for 97%." =
      quantile_outlier > 0 & quantile_outlier <= 1
  )

  obs <- coerce_dt(obs, dates = TRUE, copy = TRUE)
  data.table::setkeyv(obs, "reference_date")

  if (!is.null(by)) {
    if (by != ".group") {
      check_group(obs)
      obs <- enw_assign_group(obs, by = by, copy = FALSE)
    } else {
      stopifnot(
        "Column `.group` is not present in the data" =
          ".group" %in% colnames(obs)
      )
    }
  }
  obs <- enw_add_max_reported(obs, copy = FALSE)
  obs <- enw_add_delay(obs, copy = FALSE)

  diff_obs <- enw_add_incidence(
    obs, set_negatives_to_zero = set_negatives_to_zero, by = by
  )

  # filter obs based on diff constraints
  obs <- merge(
    obs, diff_obs[, .(reference_date, report_date, .group)],
    by = c("reference_date", "report_date", ".group")
  )

  # update grouping in case any are now missing
  if (!(is.null(by) || by == ".group")) {
    obs[, .group := NULL]
    obs <- enw_assign_group(obs, by = by, copy = FALSE)
  }

  max_delay_ref <- obs[
    !is.na(reference_date),
    .SD[, .(delay = max(delay, na.rm = TRUE)), by = reference_date]
  ]
  max_delay_obs <- ceiling(
    max_delay_ref[, quantile(delay, quantile_outlier, na.rm = TRUE)]
  ) + 1

  # Note that we if we here filter by the user-specified maximum delay, any
  # warnings obtained would also apply to a modelled, potentially shorter,
  # maximum delay.
  obs <- enw_filter_delay(obs, max_delay = max_delay)

  # filter by earliest observed report date
  obs <- obs[,
    .SD[reference_date >= min(report_date) | is.na(reference_date)],
    by = .group
  ]

  latest_obs <- enw_latest_data(obs)
  fully_observed_date <- latest_obs[, max(report_date)] - max_delay_obs + 1
  # filter by the maximum observed delay to reduce right truncation bias
  latest_obs <- enw_filter_reference_dates(
    latest_obs,
    latest_date = fully_observed_date
  )

  if (latest_obs[, .N] < 5) {
    warning(
      "There are only very few (", latest_obs[, .N], ") reference dates",
      " that are sufficiently far in the past (beyond maximum observed delay ",
      "of ", max_delay_obs, " days) to compute coverage statistics. ",
      "The maximum delay check may thus not be reliable. ",
      "If you think the maximum observed delay of ", max_delay_obs, " days is ",
      "an outlier, consider decreasing `quantile_outlier`."
    )
  }

  low_coverage <- latest_obs[, .(
    below_coverage =
      sum(cum_prop_reported < cum_coverage, na.rm = TRUE) /
        sum(!is.na(cum_prop_reported))
  ), by = .group]
  mean_coverage <- low_coverage[, mean(below_coverage)]

  if (warn && mean_coverage > 0.5) {
    warning(
      "The specified maximum reporting delay ",
      "(", max_delay, " days) ",
      "covers less than ", 100 * cum_coverage,
      "% of cases for the majority (>50%) of reference dates. ",
      "Consider using a larger maximum delay to avoid potential model ",
      "misspecification.",
      immediate. = TRUE
    )
  }

  low_coverage <- rbind(low_coverage, list("all", mean_coverage))
  low_coverage[, coverage := cum_coverage]
  setcolorder(low_coverage, c(".group", "coverage"))
  return(low_coverage[])
}
