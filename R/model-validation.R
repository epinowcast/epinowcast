#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param nowcast DESCRIPTION.
#'
#' @param latest_obs DESCRIPTION.
#'
#' @param round_to DESCRIPTION
#'
#' @param ... Additional arguments passed to [scoringutils::eval_forecasts()].
#'
#' @return RETURN_DESCRIPTION
#' @family modelvalidation
#' @importFrom data.table copy setnames
enw_score_nowcast <- function(nowcast, latest_obs, round_to = 3, ...) {
  if (!requireNamespace("scoringutils")) {
    stop("scoringutils is required for this function to work")
  }
  long_nowcast <- enw_quantiles_to_long(nowcast)
  latest_obs <- data.table::copy(latest_obs)
  data.table::setnames(latest_obs, "confirm", "true_value", skip_absent = TRUE)
  cols <- intersect(colnames(nowcast), colnames(latest_obs))
  long_nowcast <- merge(long_nowcast, latest_obs, by = cols)
  scores <- scoringutils::eval_forecasts(long_nowcast, ...)
  numeric_cols <- colnames(scores)[sapply(scores, is.numeric)]
  scores <- scores[, (numeric_cols) := lapply(.SD, signif, digits = round_to),
    .SDcols = numeric_cols
  ]
  return(scores[])
}
