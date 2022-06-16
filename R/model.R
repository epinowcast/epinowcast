#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#'
#' @return RETURN_DESCRIPTION
#'
#' @importFrom data.table data.table
#' @family model
#' @export
#' @examples
#' enw_priors()
enw_priors <- function() {
  data.table::data.table(
    variable = c(
      "eobs_lsd",
      "logmean_int",
      "logsd_int",
      "logmean_sd",
      "logsd_sd",
      "rd_eff_sd",
      "sqrt_phi",
      "alpha_start",
      "alpha_sd"
    ),
    description = c(
      "Standard deviation for expected final observations",
      "Log mean intercept for reference date delay",
      "Log standard deviation for the reference date delay",
      "Standard deviation of scaled pooled logmean effects",
      "Standard deviation of scaled pooled logsd effects",
      "Standard deviation of scaled pooled report date effects",
      "One over the square of the reporting overdispersion",
      "Logit start value for share of cases with known reference date",
      "Standard deviation of random walk for share of cases with known reference date"
    ),
    distribution = c(
      "Zero truncated normal",
      "Normal",
      "Zero truncated normal",
      "Zero truncated normal",
      "Zero truncated normal",
      "Zero truncated normal",
      "Zero truncated normal",
      "Normal",
      "Zero truncated normal"
    ),
    mean = c(0, 1, 0.5, rep(0, 4), 0, 0),
    sd = c(rep(1, 7), 1, 0.1)
  )
}

#' Format observed data for use with stan
#'
#' @param pobs Output from [enw_preprocess_data()].
#'
#' @return A list as required by stan.
#' @family model
#' @export
enw_obs_as_data_list <- function(pobs) {
  # format latest matrix
  latest_matrix <- pobs$latest[[1]]
  latest_matrix <- data.table::dcast(
    latest_matrix, reference_date ~ group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])

  # get new confirm for processing
  new_confirm <- data.table::copy(pobs$new_confirm[[1]])
  data.table::setorderv(new_confirm, c("reference_date", "group", "delay"))
  new_confirm_missing <- data.table::copy(pobs$new_confirm_missing[[1]])
  data.table::setorderv(new_confirm_missing, c("group", "reference_date"))

  # get flat observations
  flat_obs <- new_confirm$new_confirm

  # format vector of snapshot lengths
  snap_length <- new_confirm
  snap_length <- snap_length[, .SD[delay == max(delay)],
    by = c("reference_date", "group")
  ]
  snap_length <- snap_length$delay + 1

  # snap lookup
  snap_lookup <- unique(new_confirm[, .(reference_date, group)])
  snap_lookup[, s := 1:.N]
  snap_lookup <- data.table::dcast(
    snap_lookup, reference_date ~ group,
    value.var = "s"
  )
  snap_lookup <- as.matrix(snap_lookup[, -1])

  # snap time
  snap_time <- unique(new_confirm[, .(reference_date, group)])
  snap_time[, t := 1:.N, by = "group"]
  snap_time <- snap_time$t
  
  # obs with missing reference date
  obs_miss <- as.matrix(data.table::dcast(
    new_confirm_missing,
    group ~ report_date,
    value.var = "new_confirm", fill = 0
  )[, -1])

  # Format indexing and observed data
  # See stan code for docs on what all of these are
  data <- list(
    n = length(flat_obs),
    t = pobs$time[[1]],
    s = pobs$snapshots[[1]],
    g = pobs$groups[[1]],
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    csl = cumsum(snap_length),
    sg = unique(new_confirm[, .(reference_date, group)])$group,
    dmax = pobs$max_delay[[1]],
    obs = as.matrix(pobs$reporting_triangle[[1]][, -c(1:2)]),
    flat_obs = flat_obs,
    latest_obs = latest_matrix,
    obs_miss = obs_miss
  )
  return(data)
}

#' Format data for use with stan
#'
#' @return A list as required by stan.
#' @inheritParams enw_obs_as_data_list
#' @inheritParams enw_opts_as_data_list
#' @inheritParams enw_formula_as_data_list
#' @inheritParams enw_priors_as_data_list
#' @family model
#' @export
enw_as_data_list <- function(pobs,
                             reference_effects = epinowcast::enw_formula(
                               pobs$metareference[[1]]
                             ),
                             report_effects = epinowcast::enw_formula(
                               pobs$metareport[[1]]
                             ),
                             priors = epinowcast::enw_priors(),
                             distribution = "lognormal",
                             nowcast = TRUE, pp = FALSE,
                             likelihood = TRUE, debug = FALSE,
                             output_loglik = FALSE) {
  data <- enw_obs_as_data_list(pobs)

  # Add model formula data
  data <- c(
    data,
    enw_formula_as_data_list(
      data,
      reference_effects = reference_effects,
      report_effects = report_effects
    )
  )

  # Add model options
  data <- c(
    data,
    enw_opts_as_data_list(
      distribution = distribution,
      debug = debug,
      likelihood = likelihood,
      pp = pp,
      nowcast = nowcast,
      output_loglik = output_loglik
    )
  )

  # Add  priors
  data <- c(
    data,
    enw_priors_as_data_list(priors)
  )
  return(data)
}

#' Set up initial conditions for model
#'
#' @param data A list of data as produced by [enw_as_data_list()].
#'
#' @return A function that when called returns a list of initial conditions
#' for the package stan models.
#'
#' @family model
#' @importFrom purrr map_dbl
#' @export
enw_inits <- function(data) {
  init_fn <- function() {
    init <- list(
      logmean_int = rnorm(1, data$logmean_int_p[1], data$logmean_int_p[2] / 10),
      logsd_int = abs(rnorm(1, data$logsd_int_p[1], data$logsd_int_p[2] / 10)),
      leobs_init = array(purrr::map_dbl(
        data$latest_obs[1, ] + 1,
        ~ rnorm(1, log(.), 1)
      )),
      eobs_lsd = array(abs(rnorm(
        data$g, data$eobs_lsd_p[1], data$eobs_lsd_p[2] / 10
      ))),
      leobs_resids = array(
        rnorm((data$t - 1) * data$g, 0, 0.01),
        dim = c(data$t - 1, data$g)
      ),
      sqrt_phi = abs(rnorm(1, data$sqrt_phi_p[1], data$sqrt_phi_p[2] / 10))
    )
    init$logmean <- rep(init$logmean_int, data$npmfs)
    init$logsd <- rep(init$logsd_int, data$npmfs)
    init$phi <- 1 / sqrt(init$sqrt_phi)
    # initialise reference date effects
    if (data$neffs > 0) {
      init$logmean_eff <- rnorm(data$neffs, 0, 0.01)
      init$logsd_eff <- rnorm(data$neffs, 0, 0.01)
    }
    if (data$neff_sds > 0) {
      init$logmean_sd <- abs(rnorm(
        data$neff_sds, data$logmean_sd_p[1], data$logmean_sd_p[2] / 10
      ))
      init$logsd_sd <- abs(rnorm(
        data$neff_sds, data$logsd_sd_p[1], data$logsd_sd_p[2] / 10
      ))
    }
    # initialise report date effects
    if (data$nrd_effs > 0) {
      init$rd_eff <- rnorm(data$nrd_effs, 0, 0.01)
    }
    if (data$nrd_eff_sds > 0) {
      init$rd_eff_sd <- abs(rnorm(
        data$nrd_eff_sds, data$rd_eff_sd_p[1], data$rd_eff_sd_p[2] / 10
      ))
    }
    return(init)
  }
  return(init_fn)
}

#' Load and compile the nowcasting model
#'
#' @param model A character string indicating the path to the model.
#' If not supplied the package default model is used.
#'
#' @param include A character string specifying the path to any stan
#' files to include in the model. If missing the package default is used.
#'
#' @param compile Logical, defaults to `TRUE`. Should the model
#' be loaded and compiled using [cmdstanr::cmdstan_model()].
#'
#' @param threads Logical, defaults to `FALSE`. Should the model compile with
#' support for multi-thread support in chain. Note that this requires the use of
#' the `threads_per_chain` argument when model fitting using [enw_sample()],
#' and [epinowcast()].
#'
#' @param verbose Logical, defaults to `TRUE`. Should verbose
#' messages be shown.
#'
#' @param profile Logical, defaults to `FALSE`. Should the model be profiled?
#' For more on profiling see the [cmdstanr documentation](https://mc-stan.org/cmdstanr/articles/profiling.html). # nolint
#'
#' @param stanc_options A list of options to pass to the `stanc_options` of
#' [cmdstanr::cmdstan_model()]. By default "01" is passed which specifies simple
#' optimisations should be done by the prior to compilation.
#'
#' @param ... Additional arguments passed to [cmdstanr::cmdstan_model()].
#'
#' @return A `cmdstanr` model.
#'
#' @family model
#' @export
#' @importFrom cmdstanr cmdstan_model
#' @examplesIf interactive()
#' mod <- enw_model()
enw_model <- function(model, include, compile = TRUE,
                      threads = FALSE, profile = FALSE,
                      stanc_options = list("O1"), verbose = TRUE, ...) {
  if (missing(model)) {
    model <- "stan/epinowcast.stan"
    model <- system.file(model, package = "epinowcast")
  }
  if (missing(include)) {
    include <- system.file("stan", package = "epinowcast")
  }

  if (!profile) {
    code <- paste(readLines(model), collapse = "\n")
    code_no_profile <- remove_profiling(code)
    model <- cmdstanr::write_stan_file(code_no_profile)
  }

  if (compile) {
    if (verbose) {
      model <- cmdstanr::cmdstan_model(model,
        include_paths = include,
        stanc_options = stanc_options,
        cpp_options = list(
          stan_threads = threads
        ),
        ...
      )
    } else {
      suppressMessages(
        model <- cmdstanr::cmdstan_model(model,
          include_paths = include,
          stanc_options = stanc_options,
          cpp_options = list(
            stan_threads = threads
          ), ...
        )
      )
    }
  }
  return(model)
}

#' Fit a CmdStan model using NUTS
#'
#' @param data A list of data as produced by [enw_as_data_list()].
#'
#' @param model A `cmdstanr` model object as loaded by [enw_model()].
#'
#' @param diagnostics Logical, defaults to `TRUE`. Should fitting diagnostics
#' be returned as a `data.frame`.
#'
#' @param ... Additional parameters passed to the `sample` method of `cmdstanr`.
#'
#' @return A `data.frame` containing the `cmdstanr` fit, the input data, the
#' fitting arguments, and optionally summary diagnostics.
#'
#' @family model
#' @export
#' @importFrom cmdstanr cmdstan_model
#' @importFrom posterior rhat
enw_sample <- function(data, model = epinowcast::enw_model(),
                       diagnostics = TRUE, ...) {
  fit <- model$sample(data = data, ...)

  out <- data.table(
    fit = list(fit),
    data = list(data),
    fit_args = list(list(...))
  )

  if (diagnostics) {
    diag <- fit$sampler_diagnostics(format = "df")
    diagnostics <- data.table(
      samples = nrow(diag),
      max_rhat = round(max(
        fit$summary(
          variables = NULL, posterior::rhat,
          .args = list(na.rm = TRUE)
        )$`posterior::rhat`,
        na.rm = TRUE
      ), 2),
      divergent_transitions = sum(diag$divergent__),
      per_divergent_transitions = sum(diag$divergent__) / nrow(diag),
      max_treedepth = max(diag$treedepth__)
    )
    diagnostics[, no_at_max_treedepth := sum(diag$treedepth__ == max_treedepth)]
    diagnostics[, per_at_max_treedepth := no_at_max_treedepth / nrow(diag)]
    out <- cbind(out, diagnostics)

    timing <- round(fit$time()$total, 1)
    out[, run_time := timing]
  }
  return(out[])
}
