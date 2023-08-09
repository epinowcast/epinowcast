#' Calculate cumulative reported cases from incidence of new reports
#'
#' @param obs A `data.frame` containing at least the following variables:
#' `reference date` (index date of interest), `report_date` (report date for
#' observations), and `new_confirm` (incident observations by reference and
#' report date).
#'
#' @inheritParams enw_add_incidence
#' @inheritParams enw_preprocess_data
#'
#' @return The input `data.frame` with a new variable `confirm`.
#'
#' @family dataconverters
#' @export
#' @importFrom data.table setkeyv
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' dt <- enw_add_incidence(dt)
#' dt <- dt[, confirm := NULL]
#' enw_add_cumulative(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' enw_add_cumulative(dt)
enw_add_cumulative <- function(obs, by = NULL, copy = TRUE) {
  reports <- coerce_dt(
    obs, dates = TRUE, required_cols = c(by, "new_confirm"), copy = copy
  )

  reports <- reports[!is.na(reference_date)]
  data.table::setkeyv(reports, c(by, "reference_date", "report_date"))

  reports[, confirm := cumsum(new_confirm), by = c(by, "reference_date")]
  return(reports[])
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
#' @param copy Should `obs` be copied (default) or modified in place?
#'
#' @inheritParams enw_preprocess_data
#'
#' @return The input `data.frame` with a new variable `new_confirm`. If
#' `max_confirm` was present in the `data.frame` then the proportion
#' reported on each day (`prop_reported`) is also added.
#'
#' @family dataconverters
#' @export
#' @importFrom data.table setkeyv
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' enw_add_incidence(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' dt <- enw_add_max_reported(dt)
#' enw_add_incidence(dt)
enw_add_incidence <- function(obs, set_negatives_to_zero = TRUE, by = NULL,
                              copy = TRUE) {
  reports <- coerce_dt(
    obs, dates = TRUE, required_cols = c(by, "confirm"), copy = copy
  )
  data.table::setkeyv(reports, c(by, "reference_date", "report_date"))
  reports[, new_confirm := c(confirm[1], diff(confirm)),
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


#' Convert a Line List to Aggregate Counts (Incidence)
#'
#' @description This function takes a line list (i.e. tabular data where each
#' row represents a case) and aggregates to a count (`new_confirm`) of cases by
#' user-specified `reference_date`s and `report_date`s. This is enables the use
#' of [enw_preprocess_data()] and other [epinowcast()] preprocessing functions.
#'
#' @param linelist An object coercible to a `data.table` (such as a
#' `data.frame`) where each row represents a case. Must contain at least
#' two date variables or variables that can be coerced to dates.
#'
#' @param reference_date A date or a variable that can be coerced to a date
#' that represents the date of interest for the case. For example, if the
#' `reference_date` is the date of symptom onset then the `new_confirm` will
#' be the number of new cases reported (based on `report_date`) on each day
#' that had onset on that day. The default is "reference_date".
#'
#' @param report_date A date or a variable that can be coerced to a date
#' that represents the date the case was reported. The default is "report_date".
#'
#' @param by A character vector of variables to also aggregate by (i.e. as well
#' as using the `reference_date` and `report_date`). If not supplied
#' then the function will aggregate by just the `reference_date` and
#' `report_date`.
#'
#' @param max_delay The maximum number of days between the `reference_date`
#' and the `report_date`. If not supplied then the function will use the
#' maximum number of days between the `reference_date` and the `report_date`
#' in the `linelist`. If the `max_delay` is less than the maximum number of
#' days between the `reference_date` and the `report_date` in the `linelist`
#' then the function will use this value instead and inform the user.
#'
#' @inheritParams enw_complete_dates
#' @inheritParams enw_add_incidence
#'
#' @return A `data.table` with the following variables: `reference_date`,
#' `report_date`, `new_confirm`, `confirm`, `delay`, and
#' any variables specified in `by`.
#'
#' @family dataconverters
#' @export
#' @importFrom data.table as.data.table setkeyv
#' @examples
#' linelist <- data.frame(
#'   onset_date = as.Date(c("2021-01-02", "2021-01-03", "2021-01-02")),
#'   report_date = as.Date(c("2021-01-03", "2021-01-05", "2021-01-04"))
#' )
#' enw_linelist_to_incidence(linelist, reference_date = "onset_date")
#'
#' # Specify a custom maximum delay and allow completion beyond the maximum
#' # observed delay
#' enw_linelist_to_incidence(
#'  linelist, reference_date = "onset_date", max_delay = 5,
#'  completion_beyond_max_report = TRUE
#' )
enw_linelist_to_incidence <- function(linelist,
                                      reference_date = "reference_date",
                                      report_date = "report_date",
                                      by = NULL, max_delay,
                                      completion_beyond_max_report = FALSE,
                                      copy = TRUE) {
  counts <- coerce_dt(
    linelist, required_cols = c(by, reference_date, report_date), copy = copy
  )
  data.table::setnames(
    counts,
    c(reference_date, report_date),
    c("reference_date", "report_date")
  )

  counts <- coerce_dt(counts, dates = TRUE, copy = FALSE)

  counts <- counts[,
    .(new_confirm = .N), keyby = c("reference_date", "report_date", by)
  ]

  obs_delay <- max(counts$report_date) - min(counts$reference_date) + 1
  if (missing(max_delay)) {
    max_delay <- obs_delay
    message(
      "Using the maximum observed delay of ", max_delay, " days ",
      "to complete the incidence data."
    )
  }
  if (max_delay < obs_delay) {
    message(
      "Using the maximum observed delay of ", obs_delay,
      " days as greater than the maximum specified to complete the incidence ",
      "data.")
       max_delay <- obs_delay
  }
  cum_counts <- enw_add_cumulative(counts, by = by, copy = FALSE)

  complete_counts <- enw_complete_dates(
    cum_counts, max_delay = max_delay, by = by,
    completion_beyond_max_report = completion_beyond_max_report,
    timestep = "day"
  )
  complete_counts <- enw_add_incidence(complete_counts, by = by, copy = FALSE)
  return(complete_counts[])
}


#' Convert Aggregate Counts (Incidence) to a Line List
#'
#' @description This function takes a `data.table` of aggregate counts or
#' something coercible to a `data.table` (such as a `data.frame`) and converts
#' it to a line list where each row represents a case.
#'
#' @param obs An object coercible to a `data.table` (such as a `data.frame`)
#' which must have a `new_confirm` column.
#'
#' @param reference_date A character string of the variable name to use
#' for the `reference_date` in the line list. The default is "reference_date".
#'
#' @param report_date A character string of the variable name to use
#' for the `report_date` in the line list. The default is "report_date".
#'
#' @return A `data.table` with the following variables: `id`, `reference_date`,
#' `report_date`, and any other variables in the `obs` object. Rows in `obs`
#' will be duplicated based on the `new_confirm` column. `reference_date` and
#' `report_date` may be renamed if `reference_date` and `report_date` are
#' supplied.
#'
#' @export
#' @family dataconverters
#' @importFrom data.table setcolorder setnames
#' @examples
#' incidence <- enw_add_incidence(germany_covid19_hosp)
#' incidence <- enw_filter_reference_dates(
#'   incidence[location %in% "DE"], include_days = 10
#' )
#' enw_incidence_to_linelist(incidence, reference_date = "onset_date")
enw_incidence_to_linelist <- function(obs, reference_date = "reference_date",
                                      report_date = "report_date") {
  obs <- coerce_dt(
    obs, dates = TRUE, required_cols = "new_confirm", forbidden_cols = "id"
  )
  suppressWarnings(obs <- obs[, "confirm" := NULL])
  cols <- setdiff(colnames(obs), "new_confirm")
  obs <- obs[new_confirm > 0]
  obs <- obs[, .(id = 1:new_confirm), by = cols]
  obs[, id := seq_len(.N)]
  data.table::setcolorder(obs, c("id", cols))
  data.table::setnames(
    obs,
    c("reference_date", "report_date"),
    c(reference_date, report_date)
  )

  return(obs[])
}

#' Calculate incidence of new reports from cumulative reports
#'
#' @description `r lifecycle::badge('deprecated')`
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
#' @importFrom lifecycle deprecate_warn
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' enw_add_incidence(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' dt <- enw_add_max_reported(dt)
#' enw_add_incidence(dt)
enw_cumulative_to_incidence <- function(obs, set_negatives_to_zero = TRUE,
                                        by = NULL) {
  lifecycle::deprecate_warn(
    "0.2.1", "enw_cumulative_to_incidence()", "enw_add_incidence()"
  )
  return(enw_add_incidence(obs, set_negatives_to_zero, by))
}

#' Calculate cumulative reported cases from incidence of new reports
#'
#' @description `r lifecycle::badge('deprecated')`
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
#' @importFrom lifecycle deprecate_warn
#' @examples
#' # Default reconstruct incidence
#' dt <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
#' dt <- enw_add_incidence(dt)
#' dt <- dt[, confirm := NULL]
#' enw_add_cumulative(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' enw_add_cumulative(dt)
enw_incidence_to_cumulative <- function(obs, by = NULL) {
  lifecycle::deprecate_warn(
    "0.2.1", "enw_incidence_to_cumulative()", "enw_add_cumulative()"
  )
  return(enw_add_cumulative(obs, by = by))
}

#' Aggregate observations over a given timestep for both report and reference
#' dates.
#'
#' This function aggregates observations over a specified timestep,
#' ensuring alignment on the same day of week for report and reference dates.
#' It is  useful for aggregating data to a weekly timestep, for example which
#' may be desirable if testing using a weekly timestep or if you are very
#' concerned about runtime.
#'
#' @param obs An object coercible to a `data.table` (such as a `data.frame`)
#' which must have a `new_confirm` numeric column, and `report_date` and
#' `reference_date` date columns. The input must have a timestep of a day
#' and be complete. See [enw_complete_dates()] for more information. If
#' NA values are present in the `confirm` column then these will be set to
#' zero before aggregation this may not be desirable if this missingness
#' is meaningful.
#'
#' @inheritParams get_internal_timestep
#' @inheritParams enw_linelist_to_incidence
#' @return A data.table with aggregated observations.
#'
#' @importFrom data.table setorder
#' @export
#' @family dataconverters
#' @examples
#' nat_hosp <- germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
#' enw_aggregate_cumulative(nat_hosp, timestep = "week")
enw_aggregate_cumulative <- function(obs, timestep = "day", by = c(),
                                     copy = TRUE) {
  stopifnot("The data already has a timestep of a day" = !timestep %in% "day")
  obs <- coerce_dt(
    obs,
    required_cols = c("confirm", by), forbidden_cols = ".group",
    dates = TRUE, copy = copy
  )

  obs <- enw_assign_group(obs, by = by)
  check_timestep_by_date(obs, timestep = "day", exact = TRUE)

  internal_timestep <- get_internal_timestep(timestep)

  # Initial filtering
  agg_obs <- obs[
    report_date >= min(reference_date, na.rm = TRUE) + internal_timestep
  ]

  stopifnot(
    "There are no complete report dates (i.e. report_date >= reference_date + timestep)" = nrow(agg_obs) > 0 # nolint
  )

  if (nrow(agg_obs) > 0)

  # Make numeric report and reference data
  agg_obs[,
    num_report_date :=
     as.numeric(report_date) - as.numeric(min(report_date, na.rm = TRUE))
  ]
  agg_obs[,
    num_reference_date :=
      as.numeric(reference_date) - as.numeric(min(reference_date, na.rm = TRUE))
  ]

  # Set the day of the timestep based on timestep
  agg_obs[, rep_mod := num_report_date %% internal_timestep]
  agg_obs[, ref_mod := num_reference_date %% internal_timestep]

  # Ordering by reference and report date 
  setorder(agg_obs, reference_date, report_date)

  # Split into missing and non-missing reference dates
  agg_obs_na_ref <- agg_obs[is.na(reference_date)]
  agg_obs <- agg_obs[!is.na(reference_date)]

  # For non-missing reference dates, aggregate over the reference date
  # using the desired reporting timestep
  agg_obs <- agg_obs[rep_mod == rep_mod[1]]

  # Aggregate over the timestep
  agg_obs <- aggregate_rolling_sum(
    agg_obs, internal_timestep, by = c("report_date", ".group")
  )

  # Set day of week for reference date and filter
  agg_obs <- agg_obs[ref_mod == rep_mod[1]]
  agg_obs <- agg_obs[reference_date >= min(report_date)]

  # If there are missing reference dates, aggregate over the report date
  # using the desired reporting timestep
  if (nrow(agg_obs_na_ref) > 0) {
    agg_obs_na_ref <- aggregate_rolling_sum(
      agg_obs_na_ref, internal_timestep, by = c(".group")
    )
    agg_obs_na_ref <- agg_obs_na_ref[rep_mod == rep_mod[1]]
    agg_obs <- rbind(agg_obs_na_ref, agg_obs)
  }

  # Drop internal processing columns
  agg_obs[,
   c("ref_mod", "num_report_date", "rep_mod", "num_reference_date", ".group") :=
    NULL
  ]
  return(agg_obs[])
}
