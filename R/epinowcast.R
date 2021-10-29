#' @title Nowcast right censored data
#'
#' @description Provides a user friendly interface around package functionality
#' to produce a nowcast from observed preprocessed data, a reference model, and
#' a report model.
#'
#' @param ... Additional arguments passed to [enw_sample()].
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @inheritParams enw_as_data_list
#' @inheritParams enw_sample
#' @inheritParams enw_nowcast_summary
#' @family nowcast
#' @export
epinowcast <- function(pobs,
                       reference_effects = enw_intercept_model(
                         pobs$metareference[[1]]
                       ),
                       report_effects = enw_intercept_model(
                         pobs$metareport[[1]]
                       ),
                       dist = "lognormal",
                       probs = c(0.05, 0.35, 0.5, 0.65, 0.95),
                       model = NULL, nowcast = TRUE, pp = FALSE,
                       likelihood = TRUE, debug = FALSE,
                       output_loglik = FALSE, ...) {
  stan_data <- enw_as_data_list(pobs,
    reference_effects = reference_effects,
    report_effects = report_effects,
    dist = dist, nowcast = nowcast,
    likelihood = likelihood, debug = debug, pp = pp,
    output_loglik = output_loglik
  )

  inits <- enw_inits(stan_data)

  fit <- enw_sample(data = stan_data, model = model, inits = inits, ...)

  nowcast <- enw_nowcast_summary(fit, pobs$latest[[1]], probs = probs)

  out <- cbind(pobs, fit)
  out[, nowcast := list(nowcast)]

  class(out) <- c("epinowcast", class(out))
  return(out[])
}
