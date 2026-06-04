#' Forecast from a fitted nowcast under a new growth rate
#'
#' @description `r lifecycle::badge("experimental")`
#' Project a fitted [epinowcast()] object forward under a new assumption about
#' the latent process by re-running the model's generated quantities with a
#' supplied growth rate trajectory. The delay, report, and observation
#' components are held at their posterior values so their uncertainty is
#' propagated, while the latent process is driven by the user-supplied growth
#' rate. This reuses the same Stan generated-quantities machinery as
#' [epinowcast()] so forecast and fitted outputs are directly comparable.
#'
#' This is distinct from the horizon-based forecasting performed as part of a
#' fit. Here a fit already exists and is re-driven with a new latent-process
#' input (a counterfactual or projected growth rate), composing with the joint
#' nowcast.
#'
#' @details
#' The growth rate `r` in `epinowcast` is the log of the effective reproduction
#' number when a generation time is supplied, or the log growth rate otherwise
#' (see [enw_expectation()]). It is supplied here on the same scale as the
#' fitted `r` parameter, with one value per modelled time point and group
#' (`expr_t * g` values, ordered by group then time). A single value is
#' recycled across all time points and groups. `NA` elements re-use the
#' posterior mean of the fitted growth rate at that position, so partial
#' overrides (for example only the most recent period) are supported.
#'
#' A single growth rate trajectory is applied across all posterior draws. The
#' uncertainty in the delay, report, and observation components is propagated
#' because those parameters are taken unchanged from the posterior. Per-draw
#' growth rate trajectories and extending the modelled window to add new future
#' time points are tracked as follow-up work.
#'
#' @param fit A fitted [epinowcast()] object.
#'
#' @param growth_rate Either `NULL` (the default, re-uses the posterior growth
#' rate unchanged, useful as a check), or a numeric vector of log growth rates
#' of length 1 (recycled) or `expr_t * g`. `NA` elements re-use the posterior
#' mean of the fitted growth rate at that position.
#'
#' @param model The compiled model to use, as returned by [enw_model()].
#'
#' @param ... Additional arguments passed to the `generate_quantities` method
#' of the `cmdstanr` model.
#'
#' @return An object of class `epinowcast` with the forecast generated
#' quantities, compatible with [summary.epinowcast()] and [plot.epinowcast()].
#'
#' @family modeltools
#' @export
#' @importFrom cli cli_abort
#' @examplesIf interactive()
#' fit <- enw_example("nowcast")
#' # Re-drive the fit with a flat, slightly declining growth rate
#' forecast <- enw_forecast(fit, growth_rate = -0.05)
#' summary(forecast)
enw_forecast <- function(fit, growth_rate = NULL,
                         model = epinowcast::enw_model(), ...) {
  if (!inherits(fit, "epinowcast")) {
    cli::cli_abort(
      "{.arg fit} must be a fitted {.cls epinowcast} object."
    )
  }
  data <- enw_get_data(fit, "data")
  cmdstan_fit <- enw_get_data(fit, "fit")
  expr_len <- data$expr_t * data$g

  data$expr_r_override <- 1L
  data$expr_r_override_value <- enw_resolve_growth_rate(
    growth_rate, cmdstan_fit, expr_len
  )

  gq <- model$generate_quantities(
    fitted_params = cmdstan_fit, data = data, threads_per_chain = 1, ...
  )

  out <- data.table::copy(fit)
  out$fit <- list(gq)
  out$data <- list(data)
  out[]
}

#' Resolve a user-supplied growth rate against the fitted posterior
#'
#' @param growth_rate User input as described in [enw_forecast()].
#' @param fit A `cmdstanr` fit object from which the posterior mean growth
#' rate is taken to fill `NULL` or `NA` entries.
#' @param expr_len Expected number of growth rate values (`expr_t * g`).
#'
#' @return A numeric vector of growth rates of length `expr_len`.
#' @keywords internal
#' @importFrom cli cli_abort
enw_resolve_growth_rate <- function(growth_rate, fit, expr_len) {
  posterior_r <- fit$summary("r", mean)$mean
  if (is.null(growth_rate)) {
    return(posterior_r)
  }
  if (length(growth_rate) == 1) {
    growth_rate <- rep(growth_rate, expr_len)
  }
  if (length(growth_rate) != expr_len) {
    cli::cli_abort(
      "{.arg growth_rate} must have length 1 or {expr_len}, not {length(growth_rate)}." # nolint
    )
  }
  na_idx <- is.na(growth_rate)
  growth_rate[na_idx] <- posterior_r[na_idx]
  growth_rate
}
