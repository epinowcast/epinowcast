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
#' @return A `data.frame` summarising the model posterior.
#'
#' @family postprocess
#' @export
#' @importFrom purrr reduce
#' @importFrom posterior quantile2 default_convergence_measures
#' @importFrom data.table .SD .N :=
#' @examples
#' fit <- enw_example("nowcast")
#' enw_posterior(fit$fit[[1]], variables = "expr_beta")
enw_posterior <- function(fit, variables = NULL,
                          probs = c(0.05, 0.2, 0.8, 0.95), ...) {
  # order probs
  probs <- sort(probs, na.last = TRUE)

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
      variables = variables, posterior::default_convergence_measures(), ...
    )
  )
  cbind_custom <- function(x, y) {
    x <- data.table::setDT(x)
    y <- data.table::setDT(y)[, variable := NULL]
    cbind(x, y)
  }
  sfit <- purrr::reduce(sfit, cbind_custom)
  return(sfit[])
}


#' @title Summarise the posterior nowcast prediction
#'
#' @description A generic wrapper around [enw_posterior()] with
#' opinionated defaults to extract the posterior prediction for the
#' nowcast (`"pp_inf_obs"` from the `stan` code). The functionality of
#' this function can be used directly on the output of [epinowcast()] using
#' the supplied [summary.epinowcast()] method.
#'
#' @param obs An observation `data.frame` containing \code{reference_date}
#' columns of the same length as the number of rows in the posterior and the
#' most up to date observation for each date. This is used to align the
#' posterior with the observations. The easiest source of this data is the
#' output of latest output of [enw_preprocess_data()] or [enw_latest_data()].
#'
#' @param metamaxdelay Metadata for the maximum delay produced using
#' [enw_metadata_maxdelay()].
#'
#' @return A `data.frame` summarising the model posterior nowcast prediction.
#' This uses observed data where available and the posterior prediction
#' where not.
#'
#' @seealso [summary.epinowcast()]
#' @inheritParams enw_posterior
#' @family postprocess
#' @export
#' @importFrom data.table setorderv
#' @examples
#' fit <- enw_example("nowcast")
#' enw_nowcast_summary(fit$fit[[1]], fit$latest[[1]], fit$metamaxdelay[[1]])
enw_nowcast_summary <- function(fit, obs, metamaxdelay = NULL,
                                probs = c(
                                  0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95
                                )) {
  nowcast <- enw_posterior(
    fit,
    variables = "pp_inf_obs",
    probs = probs
  )

  if (is.null(metamaxdelay)) {
    max_delay_model <- nrow(nowcast) / max(obs$.group)
    max_delay_spec <- max_delay_model
  } else {
    if (nrow(nowcast) / max(obs$.group) !=
      metamaxdelay[type == "modelled", delay]) {
      stop(
        "Fitted maximum delay is not consistent with modeled maximum delay."
      )
    }
    max_delay_model <- metamaxdelay[type == "modelled", delay]
    max_delay_spec <- metamaxdelay[type == "specified", delay]
    if (max_delay_model > max_delay_spec) {
      stop(
        "Modelled maximum delay must not be larger than specified by the user.",
        " Please make sure that your epinowcast result object is not corrupt."
      )
    }
  }

  ord_obs <- coerce_dt(obs)
  ord_obs <- ord_obs[reference_date >
    (max(reference_date) - max_delay_spec)]
  data.table::setorderv(ord_obs, c(".group", "reference_date"))
  obs_model <- ord_obs[reference_date >
    (max(reference_date) - max_delay_model)]
  obs_spec <- ord_obs[reference_date <=
    (max(reference_date) - max_delay_model)]

  # add observations for modelled dates
  nowcast <- cbind(obs_model, nowcast)

  # add not-modelled earlier dates with artificial summary statistics
  if (max_delay_spec > max_delay_model) {
    nowcast <- rbind(obs_spec, nowcast, fill = TRUE)
    nowcast[seq_len(nrow(obs_spec)), c("mean", "median") := confirm]
    cols_quantile <- grep("q\\d+", colnames(nowcast), value = TRUE)
    nowcast[seq_len(nrow(obs_spec)), (cols_quantile) := confirm]
    nowcast[seq_len(nrow(obs_spec)), c("sd", "mad") := 0]
  }

  data.table::setorderv(nowcast, c(".group", "reference_date"))
  nowcast[, variable := NULL]
  return(nowcast[])
}

#' @title Extract posterior samples for the nowcast prediction
#'
#' @description A generic wrapper around [posterior::draws_df()] with
#' opinionated defaults to extract the posterior samples for the
#' nowcast (`"pp_inf_obs"` from the `stan` code). The functionality of
#' this function can be used directly on the output of [epinowcast()] using
#' the supplied [summary.epinowcast()] method.
#'
#' @param metamaxdelay Metadata for the maximum delay produced using
#' [enw_metadata_maxdelay()].
#'
#' @return A `data.frame` of posterior samples for the nowcast prediction.
#' This uses observed data where available and the posterior prediction
#' where not.
#'
#' @inheritParams enw_nowcast_summary
#' @family postprocess
#' @export
#' @importFrom data.table setorderv
#' @examples
#' fit <- enw_example("nowcast")
#' enw_nowcast_samples(fit$fit[[1]], fit$latest[[1]], fit$metamaxdelay[[1]])
enw_nowcast_samples <- function(fit, obs, metamaxdelay = NULL) {
  nowcast <- fit$draws(
    variables = "pp_inf_obs",
    format = "draws_df"
  )
  nowcast <- coerce_dt(
    nowcast,
    required_cols = c(".chain", ".iteration", ".draw")
  )
  nowcast <- melt(
    nowcast,
    value.name = "sample", variable.name = "variable",
    id.vars = c(".chain", ".iteration", ".draw")
  )

  if (is.null(metamaxdelay)) {
    max_delay_model <- nrow(nowcast) / max(obs$.group)
    max_delay_spec <- max_delay_model
  } else {
    if (nrow(nowcast) / max(obs$.group) / max(nowcast$.draw) !=
      metamaxdelay[type == "modelled", delay]) {
      stop(
        "Fitted maximum delay is not consistent with modeled maximum delay."
      )
    }
    max_delay_model <- metamaxdelay[type == "modelled", delay]
    max_delay_spec <- metamaxdelay[type == "specified", delay]
    if (max_delay_model > max_delay_spec) {
      stop(
        "Modelled maximum delay must not be larger than specified by the user.",
        " Please make sure that your epinowcast result object is not corrupt."
      )
    }
  }

  ord_obs <- coerce_dt(obs)
  ord_obs <- ord_obs[reference_date > (max(reference_date) - max_delay_spec)]
  data.table::setorderv(ord_obs, c(".group", "reference_date"))
  ord_obs <- data.table::data.table(
    .draws = 1:max(nowcast$.draw), obs = rep(list(ord_obs), max(nowcast$.draw))
  )
  ord_obs <- ord_obs[, rbindlist(obs), by = .draws]
  ord_obs <- ord_obs[order(.group, reference_date)]
  obs_spec <- ord_obs[reference_date <= (max(reference_date) - max_delay_model)]
  obs_model <- ord_obs[reference_date > (max(reference_date) - max_delay_model)]

  # add observations for modelled dates
  nowcast <- cbind(obs_model, nowcast)

  # add artificial samples for not-modelled earlier dates
  obs_spec[, sample := confirm]
  nowcast <- rbind(obs_spec, nowcast, fill = TRUE)

  data.table::setorderv(nowcast, c(".group", "reference_date"))
  nowcast[, variable := NULL][, .draws := NULL]
  return(nowcast[])
}

#' @title Summarise posterior samples
#'
#' @description This function summarises posterior samples for arbitrary
#' strata. It optionally holds out the observed data (variables that are not
#'  ".draw", ".iteration", ".sample", ".chain" ) joins this to the summarised
#' posterior.
#'
#' @param samples A `data.frame` of posterior samples with at least a numeric
#' sample variable.
#'
#' @param by A character vector of variables to summarise by. Defaults to
#' `c("reference_date", ".group")`.
#'
#' @param link_with_obs Logical, should the observed data be linked to the
#' posterior summary? This is useful for plotting the posterior against the
#' observed data. Defaults to `TRUE`.
#'
#' @return A `data.frame` summarising the posterior samples.
#' @inheritParams enw_nowcast_summary
#' @importFrom posterior mad
#' @importFrom purrr reduce
#' @export
#' @family postprocess
#' @examples
#' fit <- enw_example("nowcast")
#' samples <- summary(fit, type = "nowcast_sample")
#' enw_summarise_samples(samples, probs = c(0.05, 0.5, 0.95))
enw_summarise_samples <- function(samples, probs = c(
                                    0.05, 0.2, 0.35, 0.5,
                                    0.65, 0.8, 0.95
                                  ),
                                  by = c("reference_date", ".group"),
                                  link_with_obs = TRUE) {
  obs <- samples[.draw == min(.draw)]
  suppressWarnings(obs[, c(".draw", ".iteration", "sample", ".chain") := NULL])

  summary <- samples[,
    .(
      mean = mean(sample),
      median = median(sample),
      sd = sd(sample),
      mad = posterior::mad(sample)
    ),
    by = by
  ]

  quantiles <- unique(samples[, c(..by, "sample")][,
    paste0("q", probs * 100) := as.list(
      quantile(sample, probs, na.rm = TRUE)
    ),
    by = by
  ][, sample := NULL])

  dts <- list(summary, quantiles)
  if (link_with_obs) {
    dts <- c(list(obs), dts)
  }
  summary <- purrr::reduce(dts, merge, by = by)
  return(summary[])
}

#' @title Add latest observations to nowcast output
#'
#' @description Add the latest observations to the nowcast output.
#' This is useful for plotting the nowcast against the latest
#' observations.
#'
#' @param nowcast A `data.frame` of nowcast output from [enw_nowcast_summary()].
#'
#' @inheritParams enw_nowcast_summary
#'
#' @return A `data.frame` of nowcast output with the latest observations
#' added.
#' @family postprocess
#' @export
#' @importFrom data.table setcolorder
#' @examples
#' fit <- enw_example("nowcast")
#' obs <- enw_example("obs")
#' nowcast <- summary(fit, type = "nowcast")
#' enw_add_latest_obs_to_nowcast(nowcast, obs)
enw_add_latest_obs_to_nowcast <- function(nowcast, obs) {
  obs <- coerce_dt(obs, select = c("reference_date", "confirm"), group = TRUE)
  data.table::setnames(obs, "confirm", "latest_confirm")
  out <- merge(
    nowcast, obs,
    by = c("reference_date", ".group"), all.x = TRUE
  )
  data.table::setcolorder(
    out,
    neworder = c("reference_date", ".group", "latest_confirm", "confirm")
  )
  return(out[])
}

#' @title Posterior predictive summary
#'
#' @description This function summarises posterior predictives
#' for observed data (by report and reference date). The functionality of
#' this function can be used directly on the output of [epinowcast()] using
#' the supplied [summary.epinowcast()] method.
#'
#' @param diff_obs A `data.frame` of observed data with at least a date variable
#' `reference_date`, and a grouping variable `.group`.
#'
#' @return A data.table summarising the posterior predictions.
#'
#' @inheritParams enw_posterior
#' @family postprocess
#' @export
#' @importFrom data.table setorderv
#' @examples
#' fit <- enw_example("nowcast")
#' enw_pp_summary(fit$fit[[1]], fit$new_confirm[[1]], probs = c(0.5))
enw_pp_summary <- function(fit, diff_obs,
                           probs = c(
                             0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95
                           )) {
  pp <- enw_posterior(
    fit,
    variables = "pp_obs",
    probs = probs
  )

  ord_obs <- coerce_dt(diff_obs)
  data.table::setorderv(ord_obs, c(".group", "reference_date"))
  pp <- cbind(
    ord_obs,
    pp
  )
  data.table::setorderv(pp, c(".group", "reference_date"))
  pp[, variable := NULL]
  return(pp[])
}

#' Convert summarised quantiles from wide to long format
#'
#' @param posterior A `data.frame` as output by [enw_posterior()].
#'
#' @return A `data.frame` of quantiles in long format.
#'
#' @family postprocess
#' @export
#' @examples
#' fit <- enw_example("nowcast")
#' posterior <- enw_posterior(fit$fit[[1]], var = "expr_lelatent_int[1,1]")
#' enw_quantiles_to_long(posterior)
enw_quantiles_to_long <- function(posterior) {
  long <- melt(posterior,
    measure.vars = patterns("^q[0-9]"),
    value.name = "prediction", variable.name = "quantile"
  )
  long[, quantile := gsub("q", "", quantile, fixed = TRUE)]
  long[, quantile := as.numeric(quantile) / 100]
  return(long[])
}
