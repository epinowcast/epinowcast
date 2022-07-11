#' @title Nowcast using partially observed data
#'
#' @description Provides a user friendly interface around package functionality
#' to produce a nowcast from observed preprocessed data, and a series of user
#' defined models.
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @inheritParams enw_as_data_list
#' @inheritParams enw_sample
#' @inheritParams enw_nowcast_summary
#' @family epinowcast
#' @export
epinowcast <- function(
    data,
    model = epinowcast::enw_model(),
    reference = epinowcast::enw_reference(
      parametric = ~ 1
      distribution = "log-normal",
      non_parametric = ~ 0,
      data = data
    ),
    report = epinowcast::enw_report(
      formula = ~ 0,
      structural = ~ 0,
      data
    ),
    expectation = epinowcast::enw_expectation(
      formula = ~ rw(day, .group),
      order = 1,
      data = data
    ),
    missing = epinowcast::enw_missing(
      formula = ~ 1,
      data = data
    )
    observation = epinowcast::enw_obs(family = "negbin"),
    fit = enw_fit(
      fit = epinowcast::enw_sample,
      nowcast = TRUE, pp = FALSE,
      likelihood = TRUE, debug = FALSE,
      output_loglik = FALSE
    )
) {
  data_as_list <- c(
    reference$data_as_list,
    report$data_as_list,
    expectation$data_as_list,
    missing$data_as_list,
    observation$data_as_list,
    fit$data_as_list
  )
  inits <- c(
    reference$inits,
    report$inits,
    expectation$inits,
    missing$inits,
    observation$inits
  )
  fit <- fit(data = data_as_list, model = model, init = inits, ...)

  out <- cbind(pobs, fit)
  class(out) <- c("epinowcast", "enw_preprocess_data", class(out))
  return(out[])
}
