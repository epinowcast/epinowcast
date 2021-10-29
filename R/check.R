#' Check Quantiles Required are Present
#'
#' @param posterior A dataframe containing quantiles identified using
#' the `q5` naming scheme. Default: No default.
#'
#' @param req_probs A numeric vector of required probabilities. Default:
#' c(0.5, 0.95, 0.2, 0.8).
#'
#' @return NULL
#'
#' @family check
check_quantiles <- function(posterior, req_probs = c(0.5, 0.95, 0.2, 0.8)) {
  cols <- colnames(posterior)
  if (sum(cols %in% c("q5", "q95", "q20", "q80")) != 4) {
    stop(
      "Following quantiles must be present (set with probs): ",
      paste(req_probs, collapse = ", ")
    )
  }
  return(invisible(NULL))
}