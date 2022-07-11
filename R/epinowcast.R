#' @title Nowcast using partially observed data
#'
#' @description Provides a user friendly interface around package functionality
#' to produce a nowcast from observed preprocessed data, and a series of user
#' defined models. By default a model that assumes a fixed parametric reporting
#' distributin with a flexible expectation model is used. Explored the
#' individual model components for additional documentation and see the package
#' case studies for example model specifications for different tasks..
#'
#' @param reference The reference time indexed reporting process model
#' specification as defined using [enw_reference()].
#'
#' @param report The report time indexed reporting process model
#' specification as defined using [enw_report()].
#'
#' @param expectation The expectation model specification as defined using
#' [enw_expectation()]. By default this is set to be highly flexible and thus
#' weakly informed.
#'
#' @param missing The missing data model for observations without a linked
#' reference time specified using [enw_missing()]. By default this is not used. 
#'
#' @param observation The observation model as defined by [enw_obs()].
#' Observations are also processed within this function for use in modelling.
#'
#' @param fit Model fit options as defined using [enw_fit_opts()]. This includes
#' the sampler function to use (with the package default being [enw_sample()]),
#' whether or now a nowcast should be used, etc. See [enw_fit_opts()] for
#' further details.
#'
#' @param model The model to usee witin `fit`. By default this uses
#' [enw_model()].
#'
#' @param priors A data.frame with the following variables:
#' `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions. Priors in this data.frame
#' replace the default priors specified by each model component.
#'
#' @return A object of the class "epinowcast" which inherits from
#' [enw_preprocess_data()] and `data.table`, and combines the output from
#' the sampler specified in `enw_fit_opts()`.
#' @inheritParams enw_obs
#' @family epinowcast
#' @export
epinowcast <- function(
    data,
    reference = epinowcast::enw_reference(
      parametric = ~ 1,
      distribution = "lognormal",
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
      formula = ~ 0,
      data = data
    ),
    observation = epinowcast::enw_obs(family = "negbin"),
    fit = enw_fit_opts(
      fit = epinowcast::enw_sample,
      nowcast = TRUE, pp = FALSE,
      likelihood = TRUE, debug = FALSE,
      output_loglik = FALSE
    ),
    model = epinowcast::enw_model(),
    priors
) {
  data_as_list <- c(
    reference$data,
    report$data,
    expectation$data,
    missing$datat,
    observation$data,
    fit$data
  )

  default_priors <- data.table::rbindlist(
    list(
      reference$priors,
      report$priors,
      expectation$priors,
      missing$priors,
      observation$priors,
      fit$priors
    ),
    fill = TRUE,
    use.names = TRUE
  )

  if (!missing(priors)) {
    priors <- enw_replace_priors(default_priors, priors)
  }else{
    priors <- default_priors
  }

  data_as_list <- c(
    data_as_list,
    enw_priors_as_data_list(priors)
  )

  inits <- c(
    reference$inits,
    report$inits,
    expectation$inits,
    missing$inits,
    observation$inits
  )

  inits <- inits(data_as_list)

  fit <- do.call(
    fit$sampler, c(
      list(
        data = data_as_list,
        model = model,
        init = inits
      ),
      fit$args
    )
  )

  out <- cbind(pobs, fit)
  class(out) <- c("epinowcast", "enw_preprocess_data", class(out))
  return(out[])
}
