#' Summarise the posterior
#'
#' @description A generic wrapper around [posterior::summarise_draws()] with
#' opinionated defaults.
#'
#' @param fit A `cmdstanr` fit object.
#'
#' @param variables A character vector of variables to return
#' posterior summaries for. By default summaries for all parameters
#' are returned.
#'
#' @param probs A vector of numeric probabilities to produce
#' quantile summaries for. By default these are the 5%, 20%, 80%,
#' and 95% quantiles which are also the minimum set required for
#' plotting functions to work.
#'
#' @param ... Additional arguments that may be passed but will not be used.
#'
#' @return A dataframe summarising the model posterior.
#'
#' @family postprocess
#' @export
#' @importFrom purrr reduce
#' @importFrom posterior quantile2 default_convergence_measures
#' @importFrom data.table .SD .N :=
enw_posterior <- function(fit, variables = NULL,
                          probs = c(0.05, 0.2, 0.8, 0.95), ...) {
  # order probs
  probs <- probs[order(probs)]
  # NULL out variables
  variable <- type <- NULL

  # extract summary parameters of interest and join
  sfit <- list(
    fit$summary(
      variables = variables, mean, median, sd, mad,
      .args = list(na.rm = TRUE), ...
    ),
    fit$summary(
      variables = variables, quantile2,
      .args = list(probs = probs, na.rm = TRUE),
      ...
    ),
    fit$summary(
      variables = variables, posterior::default_convergence_measures(),
      .args = list(na.rm = TRUE), ...
    )
  )
  cbind_custom <- function(x, y) {
    x <- setDT(x)
    y <- setDT(y)[, variable := NULL]
    cbind(x, y)
  }
  sfit <- purrr::reduce(sfit, cbind_custom)
  return(sfit[])
}


#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param fit PARAM_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @param probs PARAM_DESCRIPTION, Default: c(0.05, 0.2, 0.35, 0.5, 0.65, 0.8,
#' 0.95)
#' @return OUTPUT_DESCRIPTION
#' @family postprocess
#' @export
#' @importFrom data.table as.data.table copy setorderv
enw_nowcast_summary <- function(fit, obs,
                                probs = c(
                                  0.05, 0.2, 0.35, 0.5, 0.65, 0.8,
                                  0.95
                                )) {
  nowcast <- enw_posterior(
    fit,
    variables = "pp_inf_obs",
    probs = probs
  )

  max_delay <- nrow(nowcast) / max(obs$group)

  ord_obs <- data.table::copy(obs)
  ord_obs <- ord_obs[reference_date > (max(reference_date) - max_delay)]
  data.table::setorderv(ord_obs, c("group", "reference_date"))
  nowcast <- cbind(
    ord_obs,
    nowcast
  )
  data.table::setorderv(nowcast, c("group", "reference_date"))
  nowcast[, variable := NULL]
  return(nowcast[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param nowcast PARAM_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family postprocess
#' @export
#' @importFrom data.table as.data.table setcolorder
enw_add_latest_obs_to_nowcast <- function(nowcast, obs) {
  obs <- data.table::as.data.table(obs)
  obs <- obs[, .(reference_date, group, latest_confirm = confirm)]
  out <- merge(
    nowcast, obs,
    by = c("reference_date", "group"), all.x = TRUE
  )
  data.table::setcolorder(
    out,
    neworder = c("reference_date", "group", "latest_confirm", "confirm")
  )
  return(out[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param fit PARAM_DESCRIPTION
#' @param diff_obs PARAM_DESCRIPTION
#' @param probs PARAM_DESCRIPTION, Default: c(0.05, 0.2, 0.35, 0.5, 0.65, 0.8,
#' 0.95)
#' @return OUTPUT_DESCRIPTION
#' @family postprocess
#' @export
#' @importFrom data.table as.data.table copy setorderv
enw_pp_summary <- function(fit, diff_obs,
                           probs = c(
                             0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95
                           )) {
  pp <- enw_posterior(
    fit,
    variables = "pp_obs",
    probs = probs
  )

  ord_obs <- data.table::copy(diff_obs)
  data.table::setorderv(ord_obs, c("reference_date", "group"))
  pp <- cbind(
    ord_obs,
    pp
  )
  data.table::setorderv(pp, c("group", "reference_date"))
  pp[, variable := NULL]
  return(pp[])
}
