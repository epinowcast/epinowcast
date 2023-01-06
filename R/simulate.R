#' Simulate observations with a missing reference date.
#'
#' A simple binomial simulator of missing data by reference date using simulated
#' or observed data as an input. This function may be used to validate missing
#' data models, as part of examples and case studies, or to explore the
#' implications of missing data for your use case.
#'
#' @param proportion Numeric, the proportion of observations that are missing a
#' reference date, indexed by reference date. Currently only a fixed proportion
#' are supported and this defaults to 0.2.
#'
#' @return A `data.table` of the same format as the input but with a simulated
#' proportion of observations now having a missing reference date.
#'
#' @inheritParams enw_cumulative_to_incidence
#' @family simulate
#' @export
#' @examples
#' # Load and filter germany hospitalisations
#' nat_germany_hosp <- subset(
#'   germany_covid19_hosp, location == "DE" & age_group %in% "00+"
#' )
#' nat_germany_hosp <- enw_filter_report_dates(
#'   nat_germany_hosp,
#'   latest_date = "2021-08-01"
#' )
#'
#' # Make sure observations are complete
#' nat_germany_hosp <- enw_complete_dates(
#'   nat_germany_hosp,
#'   by = c("location", "age_group"), missing_reference = FALSE
#' )
#'
#' # Simulate
#' enw_simulate_missing_reference(
#'   nat_germany_hosp,
#'   proportion = 0.35, by = c("location", "age_group")
#' )
enw_simulate_missing_reference <- function(obs, proportion = 0.2, by = c()) {
  obs <- enw_cumulative_to_incidence(obs, by = by)

  obs[, missing := purrr::map2_dbl(
    new_confirm, proportion, ~ rbinom(1, .x, .y)
  )]
  obs[, new_confirm := new_confirm - missing]

  complete_ref <- enw_incidence_to_cumulative(obs, by = by)
  complete_ref[, c("new_confirm", "delay", "missing") := NULL]

  missing_ref <- obs[, .(confirm = sum(missing)),
    by = c(by, "report_date")
  ]
  missing_ref[, reference_date := as.IDate(NA)]

  obs <- rbind(complete_ref, missing_ref, use.names = TRUE)
  data.table::setkeyv(obs, c(by, "reference_date", "report_date"))
  return(obs[])
}
