#' @title Nowcast right censored data
#'
#' @description Provides a user friendly interface around package functionality
#' to produce a nowcast from observed preprocessed data, a reference model, and
#' a report model.
#'
#' @param as_data_list PARAM_DESCRIPTION
#'
#' @param inits PARAM DESCRIPTION
#'
#' @param fit PARAM DESCRIPTION
#'
#' @param ... Additional arguments passed to [enw_sample()].
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @inheritParams enw_as_data_list
#' @inheritParams enw_sample
#' @inheritParams enw_nowcast_summary
#' @family epinowcast
#' @export
epinowcast <- function(pobs,
                       reference_effects = epinowcast::enw_formula(
                         ~1, pobs$metareference[[1]]
                       ),
                       report_effects = epinowcast::enw_formula(
                         ~1, pobs$metareport[[1]]
                       ),
                       priors = epinowcast::enw_priors(),
                       distribution = "lognormal",
                       model = epinowcast::enw_model(),
                       as_data_list = epinowcast::enw_as_data_list,
                       inits = epinowcast::enw_inits,
                       fit = epinowcast::enw_sample,
                       nowcast = TRUE, pp = FALSE,
                       likelihood = TRUE, debug = FALSE,
                       output_loglik = FALSE, ...) {
  stan_data <- as_data_list(pobs,
    reference_effects = reference_effects,
    report_effects = report_effects,
    priors = priors,
    distribution = distribution, nowcast = nowcast,
    likelihood = likelihood, debug = debug, pp = pp,
    output_loglik = output_loglik
  )

  inits <- inits(stan_data)

  fit <- fit(data = stan_data, model = model, init = inits, ...)

  out <- cbind(pobs, fit)
  class(out) <- c("epinowcast", "enw_preprocess_data", class(out))
  return(out[])
}
