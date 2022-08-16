
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
#' @return A wide data frame with each row being a complete report date and'
#' the columns being the observation index for each reporting delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reference_by_report <- function(missing_reference, max_delay,
                                    reps_with_complete_refs) {
  # Make a complete data frame of all possible reference and report dates
  miss_lk <- unique(missing_reference[, .(report_date, .group)])
  miss_lk[, delay := list((max_delay[[1]] - 1):0)]
  miss_lk <- miss_lk[,
    .(delay = unlist(delay)),
    by = c("report_date", ".group")
  ]
  miss_lk[, reference_date := report_date - delay]
  data.table::setorderv(miss_lk, c("reference_date", ".group", "delay"))

  # Assign an index (this should link with the in model index)
  miss_lk[, .id := 1:.N]

  # Link with reports with complete reference dates
  complete_miss_lk <- miss_lk[
    reps_with_complete_refs,
    on = c("report_date", ".group")
  ]
  data.table::setorderv(complete_miss_lk, c(".group", "report_date"))

  # Make wide format
  refs_by_report <- data.table::dcast(
    complete_miss_lk[, .(report_date, .id, delay)], report_date ~ delay,
    value.var = ".id"
  )
  return(refs_by_report[])
}
