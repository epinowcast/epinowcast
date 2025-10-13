
#' @importFrom scoringutils as_forecast_sample
#' @export
scoringutils::as_forecast_sample

#' Convert an epinowcast object to a forecast_sample object
#'
#' This function is used to convert an `epinowcast` as returned by
#' [epinowcast()] object to a `forecast_sample` object which can be used for
#' scoring using the `scoringutils` package.
#'
#' @param data An `epinowcast` nowcast object as returned by
#' [epinowcast()].
#'
#' @param latest_obs Latest observations to use for the true values must
#' contain `confirm` and `observed` variables.
#'
#' @param ... Additional arguments passed to
#' [scoringutils::as_forecast_sample()]
#'
#' @return A `forecast_sample` object as returned by
#' [scoringutils::as_forecast_sample()]
#' @export
#' @method as_forecast_sample epinowcast
#' @family modelvalidation
#' @examplesIf interactive()
#' library(scoringutils)
#'
#' nowcast <- enw_example("nowcast")
#' latest_obs <- enw_example("observations")
#' as_forecast_sample(nowcast, latest_obs)
as_forecast_sample.epinowcast <- function(data, latest_obs, ...) {
  # Get samples from the nowcast
  samples <- summary(data, type = "nowcast_samples")
  samples[,
   c("confirm", ".chain", ".iteration", "max_confirm",
     "cum_prop_reported", "prop_reported"
    ) := NULL
  ]

  # Process latest observations
  latest_obs <- coerce_dt(
    latest_obs, required_cols = "confirm", dates = TRUE
  )
  latest_obs[, "report_date" := NULL]

  # Merge samples with observations
  cols <- intersect(colnames(samples), colnames(latest_obs))
  cols <- setdiff(cols, c("confirm", "sample", ".draw"))
  samples <- merge(samples, latest_obs, by = cols)


  # Convert to forecast_sample object using scoringutils column names
  scoringutils::as_forecast_sample(
    data = samples,
    observed = "confirm",
    predicted = "sample",
    sample_id = ".draw",
    ...)
}
