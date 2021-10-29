#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @param snapshots PARAM_DESCRIPTION, Default: c(30:0)
#' @param logmean PARAM_DESCRIPTION, Default: 1.6
#' @param logmean_sd PARAM_DESCRIPTION, Default: 0.1
#' @param logsd PARAM_DESCRIPTION, Default: 1
#' @param logsd_sd PARAM_DESCRIPTION, Default: 0.1
#' @return OUTPUT_DESCRIPTION
#' @family scenarios
#' @export
#' @importFrom data.table data.table
enw_random_intercept_scenario <- function(obs,
                                          snapshots = c(30:0),
                                          logmean = 1.6, logmean_sd = 0.1,
                                          logsd = 1, logsd_sd = 0.1) {
  # get a range of dates to generate synthetic data for
  scenarios <- data.table::data.table(
    report_date = max(obs$date) - snapshots
  )

  # define a function to simulate summary parameters
  logmean_sim <- function(n) {
    rnorm(n, logmean, logmean_sd)
  }

  logsd_sim <- function(n) {
    rnorm(n, logsd, logsd_sd)
  }

  # Add truncations to scenarios
  scenarios[, `:=`(logmean = logmean_sim(.N), logsd = logsd_sim(.N))]
  return(scenarios[])
}
