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

enw_dist_cmf <- function(logmean, logsd, max = 20) {
  cmf <- plnorm(1:max, logmean, logsd)
  cmf <- cmf / max(cmf)
  return(cmf)
}

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
