#' Forecast from a fitted nowcast under overridden model components
#'
#' @description `r lifecycle::badge("experimental")`
#' Project a fitted [epinowcast()] object forward by re-running the model's
#' generated quantities with the posterior draws, optionally overriding one or
#' more latent model components and optionally extending the modelled window
#' into the future. The components that are not overridden are taken from the
#' posterior per draw, so their uncertainty is propagated. This reuses the same
#' Stan generated-quantities machinery as [epinowcast()] so forecast and fitted
#' outputs are directly comparable.
#'
#' This is distinct from the horizon-based forecasting performed as part of a
#' fit. Here a fit already exists and is re-driven, optionally under new
#' latent-process assumptions, composing with the joint nowcast.
#'
#' @details
#' ## Overrides
#'
#' The override interface is a named list. Each element replaces a latent model
#' component for every posterior draw with the supplied values, while every
#' other component keeps its per-draw posterior values. Currently the supported
#' component is:
#'
#' - `r`: the growth rate (the log of the effective reproduction number when a
#'   generation time is supplied, or the log growth rate otherwise; see
#'   [enw_expectation()]). Supplied on the same scale as the fitted `r`
#'   parameter, with one value per modelled time point and group, ordered by
#'   group then time. A single value is recycled. `NA` elements re-use the
#'   posterior-mean growth rate at that position.
#'
#' The mechanism is general: each override is injected via a model data hook
#' that bypasses the corresponding regression. New components can be exposed by
#' adding the matching Stan hook. The interface mirrors `EpiNow2::
#' forecast_infections()`, which overrides the reproduction number of a fit;
#' here the same idea is generalised to any hooked component.
#'
#' When no override is supplied for a component, the forecast uses the full
#' per-draw posterior for that component (no collapse to a summary), so
#' `enw_forecast(fit)` with no overrides reproduces the fitted nowcast up to the
#' observation-model redraw.
#'
#' ## Forward extension
#'
#' With `horizon > 0` the modelled reference dates are extended forward by
#' `horizon` time steps and the generated quantities produce predictions for the
#' future window. The latent process over the future window must be supplied via
#' `overrides$r` (length `(expr_t + horizon) * g`); the fitted portion may be
#' left as `NA` to re-use the posterior. Forward extension is applied per draw
#' so each draw keeps its own fitted history.
#'
#' @param fit A fitted [epinowcast()] object.
#'
#' @param overrides A named list of model-component overrides (see Details).
#' The empty list (the default) re-drives the fit using the per-draw posterior.
#'
#' @param horizon Integer number of future time steps to forecast beyond the
#' fitted window. Default `0` (re-drive only). When greater than `0`,
#' `overrides$r` must cover the extended window.
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
#' @seealso [enw_simulate()] which forward-generates from known parameters.
#' @export
#' @importFrom cli cli_abort
#' @examplesIf interactive()
#' fit <- enw_example("nowcast")
#' # Re-drive the fit using the per-draw posterior
#' redriven <- enw_forecast(fit)
#' # Re-drive under a flat, slightly declining growth rate
#' counterfactual <- enw_forecast(fit, overrides = list(r = -0.05))
#' summary(counterfactual)
enw_forecast <- function(fit, overrides = list(), horizon = 0L,
                         model = epinowcast::enw_model(), ...) {
  if (!inherits(fit, "epinowcast")) {
    cli::cli_abort(
      "{.arg fit} must be a fitted {.cls epinowcast} object."
    )
  }
  if (!is.list(overrides)) {
    cli::cli_abort("{.arg overrides} must be a named list.")
  }
  unknown <- setdiff(names(overrides), "r")
  if (length(unknown)) {
    cli::cli_abort(
      "Unsupported override{?s}: {.val {unknown}}. Currently only {.val r}
      is supported."
    )
  }
  if (horizon < 0) {
    cli::cli_abort("{.arg horizon} must be a non-negative integer.")
  }

  if (horizon > 0) {
    return(enw_forecast_horizon(
      fit, overrides, as.integer(horizon), model, ...
    ))
  }

  data <- enw_get_data(fit, "data")
  cmdstan_fit <- enw_get_data(fit, "fit")
  expr_len <- data$expr_t * data$g
  if (is.null(overrides$r)) {
    # No override: use the per-draw posterior growth rate directly.
    data$expr_r_override <- 0L
    data$expr_r_override_value <- numeric(0)
  } else {
    data$expr_r_override <- 1L
    data$expr_r_override_value <- enw_resolve_growth_rate(
      overrides$r, cmdstan_fit, expr_len
    )
  }

  gq <- model$generate_quantities(
    fitted_params = cmdstan_fit, data = data, threads_per_chain = 1, ...
  )

  out <- data.table::copy(fit)
  out$fit <- list(gq)
  out$data <- list(data)
  out[]
}

#' Forecast a fitted nowcast beyond the fitted window
#'
#' Internal worker for [enw_forecast()] when `horizon > 0`. Extends the
#' modelled reference dates forward, then re-runs the generated quantities per
#' posterior draw so each draw keeps its own fitted history while the future
#' window is driven by the supplied growth rate.
#'
#' @inheritParams enw_forecast
#' @param horizon Integer number of future time steps (already validated).
#'
#' @return An object of class `epinowcast`.
#' @keywords internal
#' @importFrom cli cli_abort
enw_forecast_horizon <- function(fit, overrides, horizon, model, ...) {
  if (is.null(overrides$r)) {
    cli::cli_abort(
      "{.arg overrides$r} must be supplied when {.arg horizon} is greater
      than 0 so the future latent process is defined."
    )
  }
  cli::cli_abort(
    "Forward extension beyond the fitted window is not yet implemented; see
    the package roadmap. Use {.fn enw_forecast} with {.code horizon = 0} to
    re-drive the fit, or extend the data before fitting."
  )
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
  if (length(posterior_r) != expr_len) {
    cli::cli_abort(
      "The fitted growth rate has length {length(posterior_r)} but
      {expr_len} was expected; the fitted object may be from an
      incompatible model."
    )
  }
  if (is.null(growth_rate)) {
    return(posterior_r)
  }
  growth_rate <- .resolve_growth_rate_length(growth_rate, expr_len)
  na_idx <- is.na(growth_rate)
  growth_rate[na_idx] <- posterior_r[na_idx]
  growth_rate
}

#' Recycle and length-check a supplied growth rate
#'
#' Shared validation used by [enw_simulate()] and [enw_forecast()]: a single
#' value is recycled to `expr_len`, and any other length that does not match
#' `expr_len` is an error.
#'
#' @param growth_rate A numeric vector of log growth rates.
#' @param expr_len Expected number of growth rate values (`expr_t * g`).
#'
#' @return A numeric vector of growth rates of length `expr_len`.
#' @keywords internal
#' @importFrom cli cli_abort
.resolve_growth_rate_length <- function(growth_rate, expr_len) {
  if (length(growth_rate) == 1) {
    growth_rate <- rep(growth_rate, expr_len)
  }
  if (length(growth_rate) != expr_len) {
    cli::cli_abort(
      "The growth rate must have length 1 or {expr_len}, not
      {length(growth_rate)}."
    )
  }
  growth_rate
}
