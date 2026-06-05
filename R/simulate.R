#' Simulate observations from known model parameters
#'
#' @description `r lifecycle::badge("experimental")`
#' Forward-generate synthetic observations from a fully specified model with
#' known or fixed parameters, without sampling against data. This reuses the
#' same Stan generated-quantities machinery as [epinowcast()], so simulated and
#' fitted outputs are directly comparable. It is useful for prior or posterior
#' predictive checks, synthetic-data recovery tests, and scenario analysis.
#'
#' @details
#' Simulation is performed by running the model with `algorithm = "fixed_param"`
#' and the likelihood disabled. The latent process is driven by a supplied log
#' growth rate trajectory (`growth_rate`). Every other model component can be
#' fixed through `parameters`, which sets any model parameter directly:
#' reporting-delay parameters (`refp_mean_int`, `refp_sd_int`, `refnp_*`),
#' report-date effects (`rep_*`), the latent-to-observation proportion
#' (`expl_*`), missingness (`miss_*`), and observation overdispersion
#' (`sqrt_phi`). Any parameter left unset is initialised from its prior. The
#' generated quantities (`pp_obs`, `pp_inf_obs`) then forward-generate
#' synthetic reported and final observations.
#'
#' The growth rate is handled separately from `parameters` because it is a
#' transformed quantity rather than a sampled parameter, so it is injected via
#' the same model data hook used by [enw_forecast()].
#'
#' The modules supplied (`reference`, `report`, `expectation`, `obs`, ...) must
#' be fully specified and define the structure of the simulation, exactly as
#' for [epinowcast()]. A preprocessed `data` object (see
#' [enw_preprocess_data()]) defines the dates, groups, and maximum delay to
#' simulate over.
#'
#' @param growth_rate A numeric vector of log growth rates of length 1
#' (recycled) or `expr_t * g` (one value per modelled time point and group,
#' ordered by group then time). The growth rate is the log of the effective
#' reproduction number when a generation time is supplied, or the log growth
#' rate otherwise (see [enw_expectation()]).
#'
#' @param parameters An optional named list of fixed parameter values for any
#' model parameter (for example `list(refp_mean_int = 1.5, sqrt_phi = 0.5)`).
#' These are merged over the model's prior-based initialisation (as used by
#' [epinowcast()]), so any parameter not supplied is initialised from its prior
#' rather than from `cmdstanr`'s default.
#'
#' @param draws Integer number of independent synthetic replicates to draw from
#' the observation model given the fixed parameters. Default: 1. Values greater
#' than 1 produce a posterior-predictive spread (the observation-model
#' uncertainty around the fixed expectation), so summaries and plots show
#' uncertainty rather than a single deterministic realisation.
#'
#' @param seed Integer random seed for reproducible simulation. Default: 1.
#'
#' @inheritParams epinowcast
#'
#' @return An object of class `epinowcast` containing the simulated generated
#' quantities, compatible with [summary.epinowcast()] and [plot.epinowcast()].
#'
#' @seealso [enw_forecast()] which projects a fitted model forward under new
#' inputs.
#' @family simulate
#' @family modeltools
#' @export
#' @importFrom cli cli_abort
#' @importFrom data.table data.table
#' @importFrom utils modifyList
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#' # Simulate from a flat growth rate and a known reporting delay
#' sims <- enw_simulate(
#'   pobs,
#'   growth_rate = 0.05,
#'   parameters = list(refp_mean_int = 1.5, refp_sd_int = 0.5),
#'   reference = enw_reference(~1, data = pobs)
#' )
#' summary(sims)
enw_simulate <- function(data, growth_rate,
                         parameters = list(),
                         reference = epinowcast::enw_reference(
                           parametric = ~1, distribution = "lognormal",
                           non_parametric = ~0, data = data
                         ),
                         report = epinowcast::enw_report(
                           non_parametric = ~0, structural = NULL, data = data
                         ),
                         expectation = epinowcast::enw_expectation(
                           r = ~1, generation_time = 1, observation = ~1,
                           latent_reporting_delay = 1, data = data
                         ),
                         missing = epinowcast::enw_missing(
                           formula = ~0, data = data
                         ),
                         obs = epinowcast::enw_obs(
                           family = "negbin", data = data
                         ),
                         model = epinowcast::enw_model(),
                         priors,
                         draws = 1L,
                         seed = 1, ...) {
  if (missing(growth_rate)) {
    cli::cli_abort(
      "{.arg growth_rate} must be supplied to simulate the latent process."
    )
  }
  expr_len <- expectation$data$expr_t * data$groups[[1]]
  growth_rate <- .resolve_growth_rate_length(growth_rate, expr_len)

  # Assemble the full Stan data list (and prior-based initialisation) by
  # routing through epinowcast() with a capturing sampler. This reuses
  # epinowcast()'s module assembly, prior handling, and init construction so
  # the simulated and fitted data paths are identical.
  capture_sampler <- function(data, init, ...) {
    data.table::data.table(data = list(data), init = list(init))
  }
  capture_fit <- epinowcast::enw_fit_opts(
    sampler = capture_sampler, nowcast = TRUE, pp = TRUE, likelihood = FALSE
  )
  args <- list(
    data = data, reference = reference, report = report,
    expectation = expectation, missing = missing, obs = obs,
    fit = capture_fit, model = NULL
  )
  if (!missing(priors)) {
    args$priors <- priors
  }
  prepared <- do.call(epinowcast::epinowcast, args)
  data_list <- enw_get_data(prepared, "data")

  # Inject the growth rate override into the assembled data list so the
  # latent process is driven by the supplied trajectory.
  data_list$expr_r_override <- 1L
  data_list$expr_r_override_value <- as.numeric(growth_rate)

  # Merge any user-supplied fixed parameters over the prior-based init so
  # parameters that are not supplied are still initialised from their prior.
  prior_init <- enw_get_data(prepared, "init")()
  init_values <- utils::modifyList(prior_init, parameters)

  # Fixed-parameter generation: parameters are taken from `parameters` where
  # supplied and from the prior-based initialisation otherwise. Each iteration
  # is an independent synthetic replicate from the observation model, so
  # `draws > 1` yields a posterior-predictive spread.
  gq <- model$sample(
    data = data_list, fixed_param = TRUE, chains = 1,
    iter_sampling = as.integer(draws), iter_warmup = 0, seed = seed,
    threads_per_chain = 1, init = function() init_values, ...
  )

  out <- data.table::copy(prepared)
  out$fit <- list(gq)
  out[]
}

#' Simulate observations with a missing reference date.
#'
#' A simple binomial simulator of missing data by reference date using simulated
#' or observed data as an input. This function may be used to validate missing
#' data models, as part of examples and case studies, or to explore the
#' implications of missing data for your use case.
#'
#' @param proportion Numeric, the proportion of observations that are missing a
#' reference date, indexed by reference date. Currently only a fixed proportion
#' are supported and this defaults to 0.2.
#'
#' @return A `data.table` of the same format as the input but with a simulated
#' proportion of observations now having a missing reference date.
#'
#' @inheritParams enw_add_incidence
#' @family simulate
#' @export
#' @examples
#' # Load and filter germany hospitalisations
#' nat_germany_hosp <- subset(
#'   germany_covid19_hosp, location == "DE" & age_group == "00+"
#' )
#' nat_germany_hosp <- enw_filter_report_dates(
#'   nat_germany_hosp,
#'   latest_date = "2021-08-01"
#' )
#'
#' # Make sure observations are complete
#' nat_germany_hosp <- enw_complete_dates(
#'   nat_germany_hosp,
#'   by = c("location", "age_group"), missing_reference = FALSE
#' )
#'
#' # Simulate
#' enw_simulate_missing_reference(
#'   nat_germany_hosp,
#'   proportion = 0.35, by = c("location", "age_group")
#' )
enw_simulate_missing_reference <- function(obs, proportion = 0.2, by = NULL) {
  obs <- enw_filter_reference_dates_by_report_start(
    obs,
    by = by, copy = FALSE
  )
  obs <- enw_add_incidence(obs, by = by)

  obs[, missing := purrr::map2_dbl(
    new_confirm, proportion, ~ rbinom(1, .x, .y)
  )]
  obs[, new_confirm := new_confirm - missing]

  complete_ref <- enw_add_cumulative(obs, by = by)
  complete_ref[, c("new_confirm", "delay", "missing") := NULL]

  missing_ref <- obs[, .(confirm = sum(missing)),
    by = c(by, "report_date")
  ]
  missing_ref[, reference_date := as.IDate(NA)]

  obs <- rbind(complete_ref, missing_ref, use.names = TRUE)
  data.table::setkeyv(obs, c(by, "reference_date", "report_date"))
  obs[]
}
