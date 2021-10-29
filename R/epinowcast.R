#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param pobs PARAM_DESCRIPTION
#'
#' @param reference_effects PARAM_DESCRIPTION,
#' Default: enw_intercept_model(pobs$metareference[[1]])
#'
#' @param report_effects PARAM_DESCRIPTION, 
#' Default: enw_intercept_model(pobs$metareport[[1]])
#'
#' @param dist PARAM_DESCRIPTION, Default: 'lognormal'
#'
#' @param probs PARAM_DESCRIPTION, Default: c(0.05, 0.35, 0.5, 0.65, 0.95)
#'
#' @param model PARAM_DESCRIPTION, Default: NULL
#'
#' @param nowcast PARAM_DESCRIPTION, Default: TRUE
#'
#' @param likelihood PARAM_DESCRIPTION, Default: TRUE
#'
#' @param debug PARAM_DESCRIPTION, Default: FALSE
#'
#' @param pp PARAM_DESCRIPTION, Default: FALSE
#'
#' @param ... PARAM_DESCRIPTION
#'
#' @family nowcast
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @rdname epinowcast
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
                       output_loglik = FALSE,  ...) {
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
