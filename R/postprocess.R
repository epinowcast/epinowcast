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
#' @param obs An observation `data.frame` containing `reference_date`
#' columns of the same length as the number of rows in the posterior and the
#' most up to date observation for each date. This is used to align the
#' posterior with the observations. The easiest source of this data is the
#' output of latest output of [enw_preprocess_data()] or [enw_latest_data()].
#'
#' @param max_delay Maximum delay to which nowcasts should be summarised. Must
#' be equal (default) or larger than the modelled maximum delay. If it is
#' larger, then nowcasts for unmodelled dates are added by assuming that case
#' counts beyond the modelled maximum delay are fully observed.
#'
#' @inheritParams get_internal_timestep
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
#' enw_nowcast_summary(
#'   fit$fit[[1]],
#'   fit$latest[[1]],
#'   fit$max_delay
#'   )
enw_nowcast_summary <- function(fit, obs, max_delay = NULL, timestep = "day",
                                probs = c(
                                  0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95
                                )) {
  nowcast <- enw_posterior(
    fit,
    variables = "pp_inf_obs",
    probs = probs
  )

  max_delay_model <- nrow(nowcast) / max(obs$.group)
  if (is.null(max_delay)) {
    max_delay <- max_delay_model
  }
  if (max_delay < max_delay_model) {
    cli::cli_abort(paste0(
      "The specified maximum delay must be equal to or larger than ",
      "the modeled maximum delay."
    ))
  }

  internal_timestep <- get_internal_timestep(timestep)

  ord_obs <- build_ord_obs(obs, max_delay, internal_timestep,
                           timestep, "no_sample")

  # add observations for modelled dates
  obs_model <- subset_obs(ord_obs, max_delay_model, internal_timestep,
                          select = "after")
  nowcast <- cbind(obs_model, nowcast)

  # add not-modelled earlier dates with artificial summary statistics
  if (max_delay > max_delay_model) {
    obs_spec <- subset_obs(ord_obs, max_delay_model,
                           internal_timestep, select = "before")
    nowcast <- rbind(obs_spec, nowcast, fill = TRUE)
    nowcast[seq_len(nrow(obs_spec)), c("mean", "median") := confirm]
    cols_quantile <- grep("q\\d+", colnames(nowcast), value = TRUE) # nolint
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
#' @param max_delay Maximum delay to which nowcasts should be summarised. Must
#' be equal (default) or larger than the modelled maximum delay. If it is
#' larger, then nowcasts for unmodelled dates are added by assuming that case
#' counts beyond the modelled maximum delay are fully observed.
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
#' enw_nowcast_samples(
#'   fit$fit[[1]],
#'   fit$latest[[1]],
#'   fit$max_delay,
#'   "day"
#'   )
enw_nowcast_samples <- function(fit, obs, max_delay = NULL, timestep = "day") {
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

  max_delay_model <- nrow(nowcast) / max(obs$.group) / max(nowcast$.draw,
                                                           na.rm = TRUE)
  if (is.null(max_delay)) {
    max_delay <- max_delay_model
  }
  if (max_delay < max_delay_model) {
    cli::cli_abort(paste0(
      "The specified maximum delay must be equal to or larger than ",
      "the modeled maximum delay."
    ))
  }

  internal_timestep <- get_internal_timestep(timestep)

  ord_obs <- build_ord_obs(obs, max_delay, internal_timestep, timestep,
                           "get_sample", nowcast)

  # add observations for modelled dates
  obs_model <- subset_obs(ord_obs, max_delay_model, internal_timestep,
                          select = "after")

  nowcast <- cbind(obs_model, nowcast)

  # add artificial samples for not-modelled earlier dates
  if (max_delay > max_delay_model) {
    obs_spec <- subset_obs(ord_obs, max_delay_model,
                           internal_timestep, select = "before")
    obs_spec[, c(".chain", ".iteration") := NA]
    obs_spec[, .draw := rep(1:max(nowcast$.draw, na.rm = TRUE),
                            nrow(obs_spec) / max(nowcast$.draw, na.rm = TRUE))]
    obs_spec[, variable := NA]
    obs_spec[, sample := confirm]
    nowcast <- rbind(obs_spec, nowcast, fill = TRUE)
  }

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
  obs <- samples[.draw == min(.draw, na.rm = TRUE)]
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

  ord_obs <- coerce_dt(
    diff_obs,  required_cols = "new_confirm", dates = TRUE, group = TRUE
  )
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
  posterior <- coerce_dt(posterior)
  long <- melt(posterior,
    measure.vars = patterns("^q[0-9]"),
    value.name = "prediction", variable.name = "quantile"
  )
  long[, quantile := gsub("q", "", quantile, fixed = TRUE)]
  long[, quantile := as.numeric(quantile) / 100]
  return(long[])
}

#' Build the ord_obs `data.table`.
#'
#' @param obs Observations as pulled from nowcast$latest[[1]].
#' @param max_delay Whole number representing the maximum delay
#' in units of the timestep.
#' @param internal_timestep The internal timestep in days.
#' @param timestep The timestep to be used. This can be a string
#' ("day", "week", "month") or a numeric whole number representing
#' the number of days.
#' @param sample String, "get_sample" or "no_sample".
#' @param nowcast If getting posterior samples, the fit to pull
#' the draws from.
#'
#' @return ord_obs A `data.table`.
#'
#' @family postprocess

build_ord_obs <- function(obs, max_delay, internal_timestep, timestep, sample, nowcast = NULL) { # nolint
  ord_obs <- coerce_dt(
    obs, required_cols = c("reference_date", "confirm"), group = TRUE
  )
  check_timestep_by_group(
    ord_obs, "reference_date", timestep, exact = TRUE
  )

  ord_obs <- subset_obs(ord_obs, max_delay, internal_timestep,
                        select = "after")

sample <- rlang::arg_match(sample, c("get_sample", "no_sample"))

  data.table::setorderv(ord_obs, c(".group", "reference_date"))
  if (sample == "get_sample") {
    ord_obs <- data.table::data.table(
      .draws = 1:max(nowcast$.draw),
      obs = rep(list(ord_obs), max(nowcast$.draw))
    )
    ord_obs <- ord_obs[, rbindlist(obs), by = .draws]
    ord_obs <- ord_obs[order(.group, reference_date)]
  }
  return(ord_obs)
}

#' Subset observations data table for either modelled dates
#' or not-modelled earlier dates.
#'
#' @param ord_obs The observations `data.table` to be subset,
#' as pulled from the result of calling epinowcast() and
#' coerced to a data table.
#' @param max_delay Whole number representing the maximum delay
#' in units of the timestep.
#' @param internal_timestep A numeric value representing the number
#' of days in the timestep, e.g. 7 when the timesteps are weeks.
#' @param select String, select reference dates from "before" the
#' max_delay or "after"?
#'
#' @return A `data.frame` subset for the desired observations
#'
#' @family postprocess


subset_obs <- function(ord_obs, max_delay, internal_timestep,
                       select) {
  select <- rlang::arg_match(select, c("before", "after"))
  if (select == "after") {
    return(ord_obs[reference_date > (max(reference_date, na.rm = TRUE) -
                 max_delay * internal_timestep)])
  } else if (select == "before") {
    return(ord_obs[reference_date <= (max(reference_date, na.rm = TRUE) -
                 max_delay * internal_timestep)])
  } else {
    stop("Invalid `select` argument")
  }
}
