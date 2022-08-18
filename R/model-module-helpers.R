#' Identify report dates with complete (i.e up to the maximum delay) reference
#' dates
#'
#' @param new_confirm `new_confirm` data.frame output from
#' [enw_preprocess_data()].
#'
#' @return A data frame containing a `report_date` variable, and grouping
#' variables specified for report dates that have complete reporting.
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reps_with_complete_refs <- function(new_confirm, max_delay, by = c()) {
  rep_with_complete_ref <- data.table::as.data.table(new_confirm)
  rep_with_complete_ref <- rep_with_complete_ref[,
    .(n = .N),
    by = c(by, "report_date")
  ][n >= max_delay]
  rep_with_complete_ref[, n := NULL]
  return(rep_with_complete_ref[])
}

#' Construct a lookup of references dates by report
#'
#' @param missing_reference `missing_reference` data.frame output from
#' [enw_preprocess_data()].
#'
#' @param reps_with_complete_refs A `data.frame` of report dates with complete
#' (i.e fully reported) reference dates as produced using
#' [enw_reps_with_complete_refs()].
#'
#' @param metareference `metareference` data.frame output from
#' [enw_preprocess_data()].
#'
#' @return A wide data frame with each row being a complete report date and'
#' the columns being the observation index for each reporting delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reference_by_report <- function(missing_reference, reps_with_complete_refs,
                                    metareference, max_delay) {
  # Make a complete data frame of all possible reference and report dates
  miss_lk <- data.table::copy(metareference)[
    ,
    .(reference_date = date, .group)
  ]
  miss_lk[, delay := list(0:(max_delay - 1))]
  miss_lk <- miss_lk[,
    .(delay = unlist(delay)),
    by = c("reference_date", ".group")
  ]
  miss_lk[, report_date := reference_date + delay]
  data.table::setkeyv(miss_lk, c(".group", "reference_date", "report_date"))

  # Assign an index (this should link with the in model index)
  miss_lk[, .id := 1:.N]

  # Link with reports with complete reference dates
  complete_miss_lk <- miss_lk[
    reps_with_complete_refs,
    on = c("report_date", ".group")
  ]
  data.table::setkeyv(
    complete_miss_lk, c(".group", "report_date", "reference_date")
  )

  # Make wide format
  refs_by_report <- data.table::dcast(
    complete_miss_lk[, .(report_date, .id, delay)], report_date ~ delay,
    value.var = ".id"
  )
  return(refs_by_report[])
}

#' Convert latest observed data to a matrix
#'
#' @param latest `latest` data.frame output from [enw_preprocess_data()].
#'
#' @return A matrix with each column being a group and each row a reference date
latest_obs_as_matrix <- function(latest) {
  latest_matrix <- data.table::dcast(
    latest, reference_date ~ .group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])
  return(latest_matrix)
}