#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param report_date PARAM_DESCRIPTION
#' @param cmf PARAM_DESCRIPTION
#' @param cases PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family generatedata
#' @export
#' @importFrom data.table copy
#' @importFrom purrr map_dbl
enw_apply_truncation_to_cases <- function(report_date, cmf, cases) {
  reported_cases <- data.table::copy(cases)
  reported_cases <- reported_cases[date <= report_date]
  reported_cases[
    (.N - length(cmf) + 1):.N,
    confirm := purrr::map_dbl(confirm * rev(cmf), ~ rpois(1, .))
  ]
  reported_cases[, report_date := report_date]
  return(reported_cases)
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param logmean PARAM_DESCRIPTION
#' @param logsd PARAM_DESCRIPTION
#' @param max PARAM_DESCRIPTION, Default: 20
#' @return OUTPUT_DESCRIPTION
#' @family generatedata
#' @importFrom stats plnorm
#' @export
enw_dist_cmf <- function(logmean, logsd, max = 20) {
  cmf <- plnorm(1:max, logmean, logsd)
  cmf <- cmf / max(cmf)
  return(cmf)
}
#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param scenarios PARAM_DESCRIPTION
#' @param cases PARAM_DESCRIPTION
#' @param truncation_max PARAM_DESCRIPTION, Default: 20
#' @return OUTPUT_DESCRIPTION
#' @family generatedata
#' @export
#' @importFrom data.table copy
#' @importFrom purrr map2
enw_simulate_lnorm_trunc_obs <- function(scenarios, cases,
                                         truncation_max = 20) {
  if (!is.data.frame(scenarios) |
    length(
      intersect(colnames(scenarios), c("report_date", "logmean", "logsd"))
    ) != 3) {
    stop("scenarios must contain: report_date, logmean, and logsd variables")
  }

  obs <- data.table::copy(scenarios)
  obs[
    ,
    cmf := purrr::map2(logmean, logsd, enw_dist_cmf, max = truncation_max)
  ]
  obs[
    ,
    reported_cases := purrr::map2(
      report_date, cmf, enw_apply_truncation_to_cases,
      cases = cases
    )
  ]
  return(obs[])
}
