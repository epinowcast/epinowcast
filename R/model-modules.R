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
enw_reference <- function(parametric = ~1, distribution = c(
                            "lognormal", "none", "exponential", "gamma",
                            "loglogistic"
                          ), non_parametric = ~0, data) {
  if (as_string_formula(parametric) %in% "~0") {
    distribution <- "none"
    parametric <- "~1"
  }
  if (!as_string_formula(non_parametric) %in% "~0") {
    stop("The non-parametric reference model has not yet been implemented")
  }
  distribution <- match.arg(distribution)
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
#' @param r A formula (as implemented in [enw_formula()]) describing
#' the generative process used for expected incidence. This can use features
#' defined by reference date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. By default this is set to use a daily group
#' specific random walk.
#'
#' @param generation_time A numeric vector that sums to 1 and defaults to 1.
#' Describes the weighting to apply to previous generations (i.e as part of a
#' renewal equation). When set to 1 (the default) this corresponds to modelling
#' the daily growth rate.
#'
#' @param observation A formula (as implemented in [enw_formula()]) describing
#' the modifiers used to adjust expected observations. This can use features
#' defined by reference date as defined in `metareference` as produced by
#' [enw_preprocess_data()]. By default no modifiers are used but a common choice
#' might be to adjust for the day of the week. Note as the baseline is no
#' modification an intercept is always used and it is set to 0.
#'
#' @param latent_reporting_delay A numeric vector that defaults to 1.
#' Describes the weighting to apply to past and current latent expected
#' observations (from most recent to least). This can be used both to convolve
#' based on some assumed reporting delay and to rescale obserations (by
#' multiplying a probability mass function by some fraction) to account
#' ascertainment etc.
#'
#' @param ... Additional parameters passed to [enw_add_metaobs_features()]. The
#' same arguments as passed to `enw_preprocess_data()` should be used here.
#' @inherit enw_report return
#' @inheritParams enw_obs
#' @family modelmodules
#' @export
#' @examples
#' enw_expectation(data = enw_example("preprocessed"))
enw_expectation <- function(r = ~ rw(day, by = .group), generation_time = c(1),
                            observation = ~1, latent_reporting_delay = c(1),
                            data, ...) {
  if (as_string_formula(r) %in% "~0") {
    stop("An expectation model formula for r must be specified")
  }
  if (as_string_formula(observation) %in% "~0") {
    observation <- ~1
  }
  if (sum(generation_time) != 1) {
    stop("The generation time must sum to 1")
  }

  # Set up growth rate features
  r_features <- data$metareference[[1]]
  if (length(latent_reporting_delay) > 1) {
    r_features <- enw_extend_date(
      r_features,
      days = length(latent_reporting_delay) - 1, direction = "start"
    )
    enw_add_metaobs_features(r_features, ...)
  }
  r_features <- r_features[
    date >= (min(date) + length(generation_time))
  ]

  # Growth rate indicator variables
  r_list <- list(
    r_seed = length(generation_time),
    gt_n = length(generation_time),
    lrgt = log(rev(generation_time)),
    t = nrow(r_features),
    obs = 0
  )

  r_list$g <- cumsum(rep(r_list$t, data$groups[[1]])) - r_list$t
  r_list$ft <- r_list$t + r_list$r_seed

  # Initial prior for seeding observations
  latest_matrix <- latest_obs_as_matrix(data$latest[[1]])
  seed_obs <- latest_matrix[1, ] + 1
  seed_obs <- purrr::map(seed_obs, ~ rep(log(.), r_list$gt_n))
  seed_obs <- round(unlist(seed_obs), 1)

  # Growth rate model formula
  r_form <- enw_formula(r, r_features, sparse = FALSE)
  r_data <- enw_formula_as_data_list(
    r_form,
    prefix = "expr", drop_intercept = TRUE
  )

  # Observation indicator variables
  obs_list <- list(
    lrd_n = length(latent_reporting_delay),
    lrlrd = log(rev(latent_reporting_delay))
  )
  obs_list$obs <- ifelse(
    sum(latent_reporting_delay) == 1 && obs_list$lrd_n == 1 &&
      as_string_formula(observation) %in% "~1",
    0, 1
  )
  # Observation formula
  obs_form <- enw_formula(observation, data$metareference[[1]], sparse = FALSE)
  obs_data <- enw_formula_as_data_list(
    obs_form,
    prefix = "expl", drop_intercept = TRUE
  )

  out <- list()
  out$formula$r <- r_form$formula
  out$formula$observation <- obs_form$formula
  out$data_raw$r <- r_features
  out$data_raw$observation <- data$metareference[[1]]

  names(r_list) <- paste0("expr_", names(r_list))
  names(obs_list) <- paste0("expl_", names(obs_list))
  out$data <- c(r_list, r_data, obs_list, obs_data)

  out$priors <- data.table::data.table(
    variable = c(
      "expr_r_int", "expr_beta_sd",
      rep("expr_lelatent_int", length(seed_obs)),
      "expl_beta_sd"
    ),
    dimension = c(1, 1, seq_along(seed_obs), 1),
    description = c(
      "Intercept of the log growth rate",
      "Standard deviation of scaled pooled log growth rate effects",
      rep("Intercept for initial log observations (ordered by group and then
          time)", length(seed_obs)),
      "Standard deviation of scaled pooled log growth rate effects"
    ),
    distribution = c(
      "Normal", "Zero truncated normal", rep("Normal", length(seed_obs)),
      "Zero truncated normal"
    ),
    mean = c(0, 0, seed_obs, 0),
    sd = c(0.2, 1, rep(1, length(seed_obs)), 1)
  )
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        expr_beta = numeric(0),
        expr_beta_sd = numeric(0),
        expr_lelatent_int = array(matrix(
          rnorm(
            1,
            as.vector(priors$expr_lelatent_int_p[1]),
            as.vector(priors$expr_lelatent_int_p[2]) * 0.1
          ),
          nrow = data$expr_gt_n
        )),
        expr_r_int = rnorm(
          1, priors$expr_r_int[1], priors$expr_r_int[2] * 0.1
        ),
        expl_beta = numeric(0),
        expl_beta_sd = numeric(0)
      )
      if (data$expr_fncol > 0) {
        init$expr_beta <- rnorm(data$expr_fncol, 0, 0.01)
      }
      if (data$expr_rncol > 0) {
        init$expr_beta_sd <- abs(rnorm(
          data$expr_rncol, priors$expr_beta_sd_p[1],
          priors$expr_beta_sd_p[2] / 10
        ))
      }
      if (data$expl_fncol > 0) {
        init$expl_beta <- rnorm(data$expl_fncol, 0, 0.01)
      }
      if (data$expl_rncol > 0) {
        init$expl_beta_sd <- abs(rnorm(
          data$expl_rncol, priors$expl_beta_sd_p[1],
          priors$expl_beta_sd_p[2] / 10
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
#' produced by [enw_preprocess_data()]. "~0" implies no model is required.
#' Otherwise an intercept is always needed
#'
#' @inherit enw_reference return
#' @inheritParams enw_obs
#' @inheritParams enw_formula
#' @family modelmodules
#' @importFrom data.table setorderv copy dcast
#' @importFrom purrr map
#' @export
#' @examples
#' # Missing model with a fixed intercept only
#' enw_missing(data = enw_example("preprocessed"))
#'
#' # No missingness model specified
#' enw_missing(~0, data = enw_example("preprocessed"))
enw_missing <- function(formula = ~1, data) {
  if (nrow(data$missing_reference[[1]]) == 0 &&
    !(as_string_formula(formula) %in% "~0")) {
    stop("A missingness model has been specified but data on the proportion of
          observations without reference dates is not available.")
  }

  if (as_string_formula(formula) %in% "~0") {
    # empty data list required by stan
    data_list <- enw_formula_as_data_list(
      prefix = "miss", drop_intercept = FALSE
    )
    data_list$missing_reference <- numeric(0)
    data_list$obs_by_report <- numeric(0)
    data_list$miss_st <- numeric(0)
    data_list$miss_cst <- numeric(0)
    data_list$model_miss <- 0
    data_list$miss_obs <- 0
  } else {
    # Make formula for effects
    form <- enw_formula(formula, data$metareference[[1]], sparse = FALSE)
    data_list <- enw_formula_as_data_list(
      form,
      prefix = "miss",
      drop_intercept = TRUE
    )

    # Get report dates that cover all reference dates up to the max delay
    rep_w_complete_ref <- enw_reps_with_complete_refs(
      data$new_confirm[[1]],
      max_delay = data$max_delay[[1]],
      by = ".group"
    )

    # Get the indexes for when grouped observations start and end
    miss_lookup <- data.table::copy(rep_w_complete_ref)
    data_list$miss_st <- miss_lookup[, n := 1:.N, by = ".group"]
    data_list$miss_st <- data_list$miss_st[, .(n = max(n)), by = ".group"]$n
    data_list$miss_cst <- miss_lookup[, n := 1:.N]
    data_list$miss_cst <- data_list$miss_cst[, .(n = max(n)), by = ".group"]$n

    # Get (and order) reported cases with a missing reference date
    missing_reference <- data.table::copy(data$missing_reference[[1]])
    data.table::setkeyv(missing_reference, c(".group", "report_date"))
    data_list$missing_reference <- data.table::copy(missing_reference)[
      rep_w_complete_ref,
      on = c("report_date", ".group")
    ][, confirm]

    # Build a look up between reports and reference dates
    reference_by_report <- enw_reference_by_report(
      missing_reference,
      reps_with_complete_refs = rep_w_complete_ref,
      metareference = data$metareference[[1]],
      max_delay = data$max_delay[[1]]
    )
    data_list$obs_by_report <- as.matrix(reference_by_report[, -1])

    # Add indicator and length/shape variables
    data_list$model_miss <- 1
    data_list$miss_obs <- length(data_list$missing_reference)
  }

  out <- list()
  out$formula <- as_string_formula(formula)
  out$data <- data_list
  # Define default priors
  out$priors <- data.table::data.table(
    variable = c("miss_int", "miss_beta_sd"),
    description = c(
      "Intercept on the logit scale for the proportion missing reference dates",
      "Standard deviation of scaled pooled logit missing reference date
       effects"
    ),
    distribution = c("Normal", "Zero truncated normal"),
    mean = c(0, 0),
    sd = c(1, 1)
  )
  # Define a function for sampling from the priors and data
  out$inits <- function(data, priors) {
    priors <- enw_priors_as_data_list(priors)
    fn <- function() {
      init <- list(
        miss_int = numeric(0),
        miss_beta = numeric(0),
        miss_beta_sd = numeric(0)
      )
      if (data$model_miss) {
        init$miss_int <- rnorm(1, priors$miss_int_p[1], priors$miss_int_p[2])
        if (data$miss_fncol > 0) {
          init$miss_beta <- rnorm(data$miss_fncol, 0, 0.01)
        }
        if (data$miss_rncol > 0) {
          init$miss_beta_sd <- abs(rnorm(
            data$miss_rncol, priors$miss_beta_sd_p[1],
            priors$miss_beta_sd_p[2] / 10
          ))
        }
      }
      return(init)
    }
    return(fn)
  }
  return(out)
}

#' Setup observation model and data
#'
#' @param family Character string, the observation model to use in the
#' likelihood; enforced by [base::match.arg()]. By default this is a
#' negative binomial ("negbin") with Poisson ("poisson") also being
#' available. Support for additional observation models is planned,
#' please open an issue with suggestions.
#'
#' @param data Output from [enw_preprocess_data()].
#'
#' @return A list as required by stan.
#' @family modelmodules
#' @export
#' @examples
#' enw_obs(data = enw_example("preprocessed"))
enw_obs <- function(family = c("negbin", "poisson"), data) {
  family <- match.arg(family)

  model_obs <- data.table::fcase(
    family %in% "poisson", 0,
    family %in% "negbin", 1
  )

  # format latest matrix
  latest_matrix <- latest_obs_as_matrix(data$latest[[1]])

  # get new confirm for processing
  new_confirm <- data.table::copy(data$new_confirm[[1]])
  data.table::setkeyv(new_confirm, c(".group", "reference_date", "delay"))

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
    groups = 1:data$groups[[1]],
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    csl = cumsum(snap_length),
    sg = unique(new_confirm[, .(reference_date, .group)])$.group,
    dmax = data$max_delay[[1]],
    sdmax = rep(data$max_delay[[1]], data$snapshots[[1]]),
    csdmax = cumsum(rep(data$max_delay[[1]], data$snapshots[[1]])),
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
#' @param likelihood_aggregation Character string, aggregation over which
#' stratify the likelihood when `threads = TRUE`; enforced by
#' [base::match.arg()]. Currently supported options:
#'  * "snapshots" which aggregates over report dates and groups (i.e the lowest
#' level that observations are reported at),
#'  * "groups" which aggregates across user defined groups.
#'
#' Note that some model modules override this setting depending on model
#' requirements. For example, the [enw_missing()] module model forces
#' "groups" option. Generally, Users should typically want the default
#' "snapshots" aggregation.
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
                         likelihood_aggregation = c("snapshots", "groups"),
                         debug = FALSE, output_loglik = FALSE, ...) {
  if (pp) {
    nowcast <- TRUE
  }
  likelihood_aggregation <- match.arg(likelihood_aggregation)
  likelihood_aggregation <- fcase(
    likelihood_aggregation %in% "snapshots", 0,
    likelihood_aggregation %in% "groups", 1
  )

  out <- list(sampler = sampler)
  out$data <- list(
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    likelihood_aggregation = likelihood_aggregation,
    pp = as.numeric(pp),
    cast = as.numeric(nowcast),
    ologlik = as.numeric(output_loglik)
  )
  out$args <- list(...)
  return(out)
}
