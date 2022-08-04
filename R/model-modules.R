#' Reference date logit hazard reporting  model module
#'
#' @param parametric A formula (as implemented in [enw_formula()]) describing
#' the parametric reference date delay model. This can use features
#' defined by report date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. Note that this formula will be applied to all
#' summary statistics of the chosen parametric distribution but each summary
#' parameter will have separate effects. Use `~ 0` to not use a parametric
#' model (note not recommended until the `non_parametric` model is implemented).
#'
#' @param distribution A character vector describing the parametric delay
#' distribution to use. Current options are: "none", "lognormal", "gamma",
#' "exponential", and "loglogistic", with the default being "lognormal".
#'
#' @param non_parametric A formula (as implemented in [enw_formula()])
#' describing the non-parametric logit hazard model. This can use features
#' defined by reference date and by delay. It draws on a linked `data.frame`
#' using `metareference` and `metadelay` as produced by [enw_preprocess_data()].
#' When an effect per delay is specified this approximates the cox proportional
#' hazard model in discrete time with a single strata. Note that this model is
#' currently not available for users.
#'
#' @return A list containing the supplied formulas, data passed into a list
#' describing the models, a `data.frame` describing the priors used, and a
#' function that takes the output data and priors and returns a function that
#' can be used to sample from a tightened version of the prior distribution.
#'
#' @inheritParams enw_obs
#' @family modelmodules
#' @export
#' @examples
#' enw_reference(data = enw_example("preprocessed"))
enw_reference <- function(parametric = ~1, distribution = "lognormal",
                          non_parametric = ~0, data) {
  if (as_string_formula(parametric) %in% "~0") {
    distribution <- "none"
    parametric <- "~1"
  }
  if (!as_string_formula(non_parametric) %in% "~0") {
    stop("The non-parametric reference model has not yet been implemented")
  }
  distribution <- match.arg(
    distribution, c("none", "exponential", "lognormal", "gamma", "loglogistic")
  )
  if (distribution %in% "none") {
    warning(
      "As non-parametric hazards have yet to be implemented a parametric hazard
       is likely required for all real-world use cases"
    )
  }
  distribution <- data.table::fcase(
    distribution %in% "none", 0,
    distribution %in% "exponential", 1,
    distribution %in% "lognormal", 2,
    distribution %in% "gamma", 3,
    distribution %in% "loglogistic", 4
  )

  pform <- enw_formula(parametric, data$metareference[[1]], sparse = TRUE)
  pdata <- enw_formula_as_data_list(
    pform,
    prefix = "refp", drop_intercept = TRUE
  )
  pdata$model_refp <- distribution

  out <- list()
  out$formula$parametric <- pform$formula
  out$data <- pdata
  out$priors <- data.table::data.table(
    variable = c(
      "refp_mean_int", "refp_sd_int", "refp_mean_beta_sd", "refp_sd_beta_sd"
    ),
    description = c(
      "Log mean intercept for parametric reference date delay",
      "Log standard deviation for the parametric reference date delay",
      "Standard deviation of scaled pooled parametric mean effects",
      "Standard deviation of scaled pooled parametric sd effects"
    ),
    distribution = c("Normal", rep("Zero truncated normal", 3)),
    mean = c(1, 0.5, 0, 0),
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        refp_mean_int = numeric(0),
        refp_sd_int = numeric(0),
        refp_mean_beta = numeric(0),
        refp_sd_beta = numeric(0),
        refp_mean_beta_sd = numeric(0),
        refp_sd_beta_sd = numeric(0)
      )
      if (data$model_refp > 0) {
        init$refp_mean_int <- rnorm(
          1, priors$refp_mean_int[1], priors$refp_mean_int[2] / 10
        )
      }
      if (data$model_refp > 1) {
        init$refp_sd_int <- abs(
          rnorm(1, priors$refp_sd_int[1], priors$refp_sd_int[2] / 10)
        )
      }
      init$refp_mean <- rep(init$refp_mean_int, data$refp_fnrow)
      init$refp_sd <- rep(init$refp_sd_int, data$refp_fnrow)
      if (data$refp_fncol > 0) {
        init$refp_mean_beta <- rnorm(data$refp_fncol, 0, 0.01)
        if (data$model_refp > 1) {
          init$refp_sd_beta <- rnorm(data$refp_fncol, 0, 0.01)
        }
      }
      if (data$refp_rncol > 0) {
        init$refp_mean_beta_sd <- abs(rnorm(
          data$refp_rncol, priors$refp_mean_beta_sd_p[1],
          priors$refp_mean_beta_sd_p[2] / 10
        ))
        if (data$model_refp > 1) {
          init$refp_sd_beta_sd <- abs(rnorm(
            data$refp_rncol, priors$refp_sd_beta_sd_p[1],
            priors$refp_sd_beta_sd_p[2] / 10
          ))
        }
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Report date logit hazard reporting  model module
#'
#' @param non_parametric A formula (as implemented in [enw_formula()])
#' describing the non-parametric logit hazard model. This can use features
#' defined by report date as defined in `metareport` as produced by
#' [enw_preprocess_data()]. Note that the intercept for this model is set to 0
#' as it should be used for specifying report date related hazards vs time
#' invariant hazards which should instead be modelled using the
#' `non_parametric` argument of [enw_reference()]
#'
#' @param structural A formula with fixed effects and using only binary
#' variables, and factors describing the known reporting structure (i.e weekday
#' only reporting). The base case (i.e the first factor entry) should describe
#' the dates for which reporting is possible. Internally dates with a non-zero
#' element in the design matrix have their hazard set to 0. This can use
#' features defined by report date as defined in `metareport` as produced by
#' [enw_preprocess_data()]. Note that the intercept for this model is set to 0
#' in order to allow all dates without other structural reasons to not be
#' reported to be reported. Note that this feature is not yet available to
#' users.
#'
#' @inherit enw_reference return
#' @inheritParams enw_obs
#' @inheritParams enw_formula
#' @family modelmodules
#' @export
#' @examples
#' enw_report(data = enw_example("preprocessed"))
enw_report <- function(non_parametric = ~0, structural = ~0, data) {
  if (!as_string_formula(structural) %in% "~0") {
    stop("The structural reporting model has not yet been implemented")
  }

  if (as_string_formula(non_parametric) %in% "~0") {
    non_parametric <- ~1
  }

  form <- enw_formula(non_parametric, data$metareport[[1]], sparse = TRUE)
  data_list <- enw_formula_as_data_list(
    form,
    prefix = "rep", drop_intercept = TRUE
  )

  # map report date effects to groups and times
  data_list$rep_findex <- t(
    matrix(
      data_list$rep_findex,
      ncol = data$groups[[1]],
      nrow = data$time[[1]] + data$max_delay[[1]] - 1
    )
  )
  data_list$rep_t <- data$time[[1]] + data$max_delay[[1]] - 1
  data_list$model_rep <- as.numeric(
    !as_string_formula(non_parametric) %in% "~1"
  )

  out <- list()
  out$formula$non_parametric <- form$formula
  out$data <- data_list
  out$priors <- data.table::data.table(
    variable = c("rep_beta_sd"),
    description = c("Standard deviation of scaled pooled report date effects"),
    distribution = c("Zero truncated normal"),
    mean = 0,
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        rep_beta = numeric(0),
        rep_beta_sd = numeric(0)
      )
      if (data$rep_fncol > 0) {
        init$rep_beta <- rnorm(data$rep_fncol, 0, 0.01)
      }
      if (data$rep_rncol > 0) {
        init$rep_beta_sd <- abs(rnorm(
          data$rep_rncol, priors$rep_beta_sd_p[1],
          priors$rep_beta_sd_p[2] / 10
        ))
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Expectation model module
#'
#' @param formula A formula (as implemented in [enw_formula()]) describing
#' the generative process used for expected incidence. This can use features
#' defined by reference date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. By default this is set to use a daily group
#' specific random walk. Note that the daily group specific random walk is
#' currently the only option supported by [epinowcast()].
#'
#' @param order Integer, defaults to 1. The order of the expectation process
#' with 1 being a simple log scale generative process, 2 being a log scale
#' generative process where each time point is offset by the log count from
#' previous time points.
#'
#' @inherit enw_report return
#' @inheritParams enw_obs
#' @family modelmodules
#' @export
#' @examples
#' enw_expectation(data = enw_example("preprocessed"))
enw_expectation <- function(formula = ~ rw(day, .group), order = 1, data) {
  if (as_string_formula(formula) %in% "~0") {
    stop("An expectation model formula must be specified")
  }
  order <- match.arg(as.character(order), choices = c("1", "2"))
  order <- as.integer(order)

  form <- enw_formula(formula, data$metareference[[1]], sparse = FALSE)
  data <- enw_formula_as_data_list(
    form,
    prefix = "exp", drop_intercept = order == 1
  )
  data$exp_order <- as.numeric(order)

  out <- list()
  out$formula$expectation <- form$formula
  out$data <- data
  out$priors <- data.table::data.table(
    variable = c("exp_beta_sd", "eobs_lsd"),
    description = c(
      "Standard deviation of scaled pooled expectation effects",
      "Standard deviation for expected final observations"
    ),
    distribution = c("Zero truncated normal", "Zero truncated normal"),
    mean = rep(0, 2),
    sd = rep(1, 2)
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        exp_beta = numeric(0),
        exp_beta_sd = numeric(0),
        leobs_init = array(purrr::map_dbl(
          data$latest_obs[1, ] + 1,
          ~ rnorm(1, log(.), 1)
        )),
        eobs_lsd = array(abs(rnorm(
          data$g, priors$eobs_lsd_p[1], priors$eobs_lsd_p[2] / 10
        ))),
        leobs_resids = array(
          rnorm((data$t - 1) * data$g, 0, 0.01),
          dim = c(data$t - 1, data$g)
        )
      )
      if (data$exp_fncol > 0) {
        init$exp_beta <- rnorm(data$exp_fncol, 0, 0.01)
      }
      if (data$exp_rncol > 0) {
        init$exp_beta_sd <- abs(rnorm(
          data$exp_rncol, priors$exp_beta_sd_p[1],
          priors$exp_beta_sd_p[2] / 10
        ))
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Missing reference data model module
#'
#' @param formula A formula (as implemented in [enw_formula()]) describing
#' the missing data proportion on the logit scale by reference date. This can
#' use features defined by reference date as defined in `metareference` as
#' produced by [enw_preprocess_data()].
#'
#' @inherit enw_reference return
#' @inheritParams enw_obs
#' @inheritParams enw_formula
#' @family modelmodules
#' @export
#' @examples
#' enw_missing(data = enw_example("preprocessed"))
enw_missing <- function(formula = ~1, data) {
  if (as_string_formula(formula) %in% "~0") {
    stop("At least an intercept must be used if this module is in use.")
  }
  if (nrow(data$missing_reference[[1]]) == 0) {
    stop("A missingness model has been specified but data on  the proportion of
          observations without reference dates is not available.")
  }

  form <- enw_formula(formula, data$metareference[[1]], sparse = FALSE)
  data_list <- enw_formula_as_data_list(
    form,
    prefix = "miss", drop_intercept = FALSE
  )
  missing_reference <- data.table::copy(data$missing_reference[[1]])
  data.table::setorderv(missing_reference, c(".group", "report_date"))
  missing_reference <- as.matrix(
    data.table::dcast(
      missing_reference, .group ~ report_date,
      value.var = "confirm",
      fill = 0
    )[, -1]
  )
  data_list$missing_ref <- missing_reference
  data_list$model_missing <- 1

  out <- list()
  out$formula <- as_string_formula(formula)
  out$data <- data_list
  out$priors <- data.table::data.table(
    variable = c("miss_beta_sd"),
    description = c("Standard deviation of scaled pooled logit missing
        reference date effects"),
    distribution = c("Zero truncated normal"),
    mean = 0,
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        miss_beta = numeric(0),
        miss_beta_sd = numeric(0)
      )
      if (data$miss_fncol > 0) {
        init$miss_beta <- rnorm(data$miss_fncol, 0, 0.01)
      }
      if (data$miss_rncol > 0) {
        init$miss_beta_sd <- abs(rnorm(
          data$miss_rncol, priors$miss_beta_sd_p[1],
          priors$miss_beta_sd_p[2] / 10
        ))
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Setup observation model and data
#'
#' @param family A character string describing the observation model to
#' use in the likelihood. By default this is a negative binomial ("negbin")
#' with Poisson ("poisson") also being available. Support for additional
#' observation models is planned, please open an issue with suggestions.
#'
#' @param data Output from [enw_preprocess_data()].
#'
#' @return A list as required by stan.
#' @family modelmodules
#' @export
#' @examples
#' enw_obs(data = enw_example("preprocessed"))
enw_obs <- function(family = "negbin", data) {
  family <- match.arg(family, c("negbin", "poisson"))

  model_obs <- data.table::fcase(
    family %in% "poisson", 0,
    family %in% "negbin", 1
  )

  # format latest matrix
  latest_matrix <- data$latest[[1]]
  latest_matrix <- data.table::dcast(
    latest_matrix, reference_date ~ .group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])

  # get new confirm for processing
  new_confirm <- data.table::copy(data$new_confirm[[1]])
  data.table::setorderv(new_confirm, c("reference_date", ".group", "delay"))

  # get flat observations
  flat_obs <- new_confirm$new_confirm

  # format vector of snapshot lengths
  snap_length <- new_confirm
  snap_length <- snap_length[, .SD[delay == max(delay)],
    by = c("reference_date", ".group")
  ]
  snap_length <- snap_length$delay + 1

  # snap lookup
  snap_lookup <- unique(new_confirm[, .(reference_date, .group)])
  snap_lookup[, s := 1:.N]
  snap_lookup <- data.table::dcast(
    snap_lookup, reference_date ~ .group,
    value.var = "s"
  )
  snap_lookup <- as.matrix(snap_lookup[, -1])

  # snap time
  snap_time <- unique(new_confirm[, .(reference_date, .group)])
  snap_time[, t := 1:.N, by = ".group"]
  snap_time <- snap_time$t

  # Format indexing and observed data
  # See stan code for docs on what all of these are
  data <- list(
    n = length(flat_obs),
    t = data$time[[1]],
    s = data$snapshots[[1]],
    g = data$groups[[1]],
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    csl = cumsum(snap_length),
    sg = unique(new_confirm[, .(reference_date, .group)])$.group,
    dmax = data$max_delay[[1]],
    obs = as.matrix(data$reporting_triangle[[1]][, -c(1:2)]),
    flat_obs = flat_obs,
    latest_obs = latest_matrix,
    model_obs = model_obs
  )

  out <- list()
  out$family <- family
  out$data <- data
  out$priors <- data.table::data.table(
    variable = c("sqrt_phi"),
    description = c("One over the square root of the reporting overdispersion"),
    distribution = c("Zero truncated normal"),
    mean = 0,
    sd = 1
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        sqrt_phi = numeric(0),
        phi = numeric(0)
      )
      if (data$model_obs == 1) {
        init$sqrt_phi <- array(abs(rnorm(
          1, priors$sqrt_phi_p[1], priors$sqrt_phi_p[2] / 10
        )))
        init$phi <- 1 / (init$sqrt_phi^2)
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Format model fitting options for use with stan
#'
#' @param sampler A function that creates an object that be used to extract
#' posterior samples from the specified model. By default this is [enw_sample()]
#' which makes use of [cmdstanr::sample()].
#'
#' @param nowcast Logical, defaults to `TRUE`. Should a nowcast be made using
#' posterior predictions of the unobserved future reported notifications.
#'
#' @param pp Logical, defaults to `FALSE`. Should posterior predictions be made
#' for observed data. Useful for evaluating the performance of the model.
#'
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
#' @param ... Additional arguments to pass to the fitting function being used
#' by [epinowcast()]. By default this will be [enw_sample()] and so `cmdstanr`
#' options should be used.
#'
#' @return A list containing the specified sampler function, data as a list
#' specifying the fitting options to use, and additional arguments to pass
#' to the sampler function when it is called.
#'
#' @importFrom data.table fcase
#' @family modelmodules
#' @export
#' @examples
#' # Default options along with settings to pass to enw_sample
#' enw_fit_opts(iter_sampling = 1000, iter_warmup = 1000)
enw_fit_opts <- function(sampler = epinowcast::enw_sample,
                         nowcast = TRUE, pp = FALSE, likelihood = TRUE,
                         debug = FALSE, output_loglik = FALSE, ...) {
  if (pp) {
    nowcast <- TRUE
  }
  out <- list(sampler = sampler)
  out$data <- list(
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast),
    ologlik = as.numeric(output_loglik)
  )
  out$args <- list(...)
  return(out)
}
