#' Format data for use with stan
#'
#' @param pobs Output from [enw_preprocess_data()].
#'
#' @param reference_effects A list of fixed and random design matrices
#' defining the date of reference model. Defaults to [enw_intercept_model()]
#' which is an intercept only model.
#'
#' @param report_effects A list of fixed and random design matrices
#' defining the date of reports model. Defaults to [enw_intercept_model()]
#' which is an intercept only model.
#'
#' @param dist Character string indicating the type of distribution to use for
#' reference date effects. The default is to use a lognormal but other options
#' available include: gamma distributed ("gamma").
#' @param likelihood Logical, defaults to `TRUE`. Should the likelihood be
#' included in the model
#'
#' @param output_loglik Logical, defaults to `FALSE`. Should the
#' log-likelihood be output. Disabling this will speed up fitting
#' if evaluating the model fit is not required.
#'
#' @param debug Logical, defaults to `FALSE`. Should within model debug
#' information be returned.
#'
#' @return A list as required by stan.
#'
#' @family model
#' @export
enw_as_data_list <- function(pobs,
                             reference_effects = enw_intercept_model(
                               pobs$metareference[[1]]
                             ),
                             report_effects = enw_intercept_model(
                               pobs$metareport[[1]]
                             ),
                             dist = "lognormal",
                             nowcast = TRUE, pp = FALSE,
                             likelihood = TRUE, debug = FALSE,
                             output_loglik = FALSE) {
  if (pp) {
    nowcast <- TRUE
  }
  # check dist type is supported and change to numeric
  dist <- match.arg(dist, c("lognormal", "gamma"))
  dist <- data.table::fcase(
    dist %in% "lognormal", 0,
    dist %in% "gamma", 1
  )
  # format latest matrix
  latest_matrix <- pobs$latest[[1]]
  latest_matrix <- data.table::dcast(
    latest_matrix, reference_date ~ group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])

  # format vector of snapshot lengths
  snap_length <- pobs$new_confirm[[1]]
  snap_length <- snap_length[, .SD[delay == max(delay)],
    by = c("reference_date", "group")
  ]
  snap_length <- snap_length$delay + 1

  # snap lookup
  snap_lookup <- unique(pobs$new_confirm[[1]][, .(reference_date, group)])
  snap_lookup[, s := 1:.N]
  snap_lookup <- data.table::dcast(
    snap_lookup, reference_date ~ group,
    value.var = "s"
  )
  snap_lookup <- as.matrix(snap_lookup[, -1])

  # snap time
  snap_time <- unique(pobs$new_confirm[[1]][, .(reference_date, group)])
  snap_time[, t := 1:.N, by = "group"]
  snap_time <- snap_time$t

  # Format indexing and observed data
  # See stan code for docs on what all of these are
  data <- list(
    t = pobs$time[[1]],
    s = pobs$snapshots[[1]],
    g = pobs$groups[[1]],
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    sg = unique(pobs$new_confirm[[1]][, .(reference_date, group)])$group,
    dmax = pobs$max_delay[[1]],
    obs = as.matrix(pobs$reporting_triangle[[1]][, -c(1:2)]),
    latest_obs = latest_matrix
  )

  # Add reference date data
  data <- c(data, list(
    npmfs = nrow(reference_effects$fixed$design),
    dpmfs = reference_effects$fixed$index,
    neffs = ncol(reference_effects$fixed$design) - 1,
    d_fixed = reference_effects$fixed$design,
    neff_sds = ncol(reference_effects$random$design) - 1,
    d_random = reference_effects$random$design
  ))

  # map report date effects to groups and days
  report_date_eff_ind <- matrix(
    report_effects$fixed$index,
    ncol = data$g, nrow = data$t + data$dmax - 1
  )

  # Add report date data
  data <- c(data, list(
    rd = data$t + data$dmax - 1,
    urds = nrow(report_effects$fixed$design),
    rdlurd = report_date_eff_ind,
    nrd_effs = ncol(report_effects$fixed$design) - 1,
    rd_fixed = report_effects$fixed$design,
    nrd_eff_sds = ncol(report_effects$random$design) - 1,
    rd_random = report_effects$random$design
  ))

  # Add model options
  data <- c(data, list(
    dist = dist,
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast)
  ))
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
#' @export
enw_inits <- function(data) {
  init_fn <- function() {
    init <- list(
      logmean_int = rnorm(1, 1, 0.1),
      logsd_int = abs(rnorm(1, 0.5, 0.1)),
      eobs_lsd = array(abs(rnorm(data$g, 0, 0.1))),
      sqrt_phi = abs(rnorm(1, 0, 0.1))
    )
    init$logmean <- rep(init$logmean_int, data$npmfs)
    init$logsd <- rep(init$logsd_int, data$npmfs)
    init$phi <- 1 / sqrt(init$sqrt_phi)
    # initialise reference date effects
    if (data$neffs > 0) {
      init$logmean_eff <- rnorm(data$neffs, 0, 0.01)
      init$logsd_eff <- rnorm(data$neffs, 0, 0.01)
    }
    if (data$neffs > 0) {
      init$logmean_eff <- rnorm(data$neffs, 0, 0.01)
      init$logsd_eff <- rnorm(data$neffs, 0, 0.01)
    }
    # initialise report date effects
    if (data$nrd_effs > 0) {
      init$rd_eff <- rnorm(data$nrd_effs, 0, 0.01)
    }
    return(init)
  }
  return(init_fn)
}

#' Load and compile the nowcasting model
#'
#' @param compile Logical, defaults to `TRUE`. Should the model
#' be loaded and compiled using [cmdstanr::cmdstan_model()].
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
enw_model <- function(compile = TRUE, ...) {
  model <- "stan/epinowcast.stan"

  model <- system.file(model, package = "epinowcast")
  if (compile) {
    suppressMessages(cmdstanr::cmdstan_model(model, ...))
  }
  return(model)
}

#' Fit a brancing process strain model
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
  model <- suppressMessages(cmdstanr::cmdstan_model(model))
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
    out[, time := timing]
  }
  return(out[])
}
