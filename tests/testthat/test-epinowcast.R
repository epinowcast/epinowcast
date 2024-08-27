# load example preprocessed data (already regression tested)
pobs <- enw_example("preprocessed")
if (not_on_cran() && on_ci()) {
  model <- enw_model()
  options(mc.cores = 2)
}

test_that("epinowcast() preprocesses data and model modules as expected", {
  nowcast <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        return(data.table::data.table(init = list(init), data = list(data)))
      },
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500
    ),
    model = NULL
  ))
  expect_type(nowcast$data[[1]], "list")
  expect_error(nowcast$init())
  class(pobs) <- c("epinowcast", class(pobs))
  expect_identical(nowcast[, c("init", "data", "priors") := NULL], pobs)
})

test_that("epinowcast() runs using default arguments only", {
  skip_on_cran()
  skip_on_local()

  obs <- run_window_filter(
    germany_covid19_hosp[age_group == "00+"][location == "DE"]
  )
  pobs <- enw_preprocess_data(obs, max_delay = 5)
  nowcast <- suppressMessages(epinowcast(pobs))
  expect_identical(
    setdiff(colnames(nowcast), colnames(pobs)),
    c(
      "priors", "fit", "data", "fit_args", "init_method_output",
      "samples", "max_rhat", "divergent_transitions",
      "per_divergent_transitions", "max_treedepth",
      "no_at_max_treedepth", "per_at_max_treedepth", "run_time"
    )
  )
  expect_identical(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
  expect_error(
    nowcast$fit[[1]]$summary(
      c("refp_mean_int", "refp_sd_int")
    ), NA
  )
  expect_error(nowcast$fit[[1]]$summary("refp_beta"))
  expect_error(nowcast$fit[[1]]$summary("rep_beta"))
  expect_data_table(nowcast$priors[[1]])
  expect_identical(nrow(nowcast$priors[[1]]), 14L)
  expect_named(
    nowcast$priors[[1]],
    c("variable", "dimension", "description", "distribution", "mean", "sd")
  )
  expect_identical(
    nowcast$priors[[1]][, variable],
    c(
      "expr_r_int", "expr_beta_sd", "expr_lelatent_int", "expl_beta_sd",
      "refp_mean_int", "refp_sd_int", "refp_mean_beta_sd", "refp_sd_beta_sd",
      "refnp_int", "refnp_beta_sd", "rep_beta_sd", "miss_int", "miss_beta_sd",
      "sqrt_phi"
    )
  )
  expect_identical(
    nowcast$priors[[1]][, mean],
    c(0.0, 0.0, 5.5, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
  )
  expect_identical(
    nowcast$priors[[1]][, sd],
    c(0.2, rep(1, 12), 0.5)
  )
  expect_identical(
    nowcast$priors[[1]][variable %like% "exp", dimension],
    c(1, 1, 1, 1)
  )
  expect_identical(
    nowcast$priors[[1]][!variable %like% "exp", dimension],
    rep(NA_real_, 10)
  )
})

test_that("epinowcast() runs with within-chain parallelisation", {
  skip_on_cran()
  skip_on_local()
  obs <- run_window_filter(
    germany_covid19_hosp[age_group == "00+"][location == "DE"]
  )
  pobs <- enw_preprocess_data(obs, max_delay = 5)
  nowcast <- suppressMessages(
    epinowcast(
      pobs, fit = enw_fit_opts(
        sampler = silent_enw_sample,
        threads_per_chain = 2
      )
    )
  )
  expect_identical(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
})

test_that("epinowcast() can fit a simple reporting model", {
  skip_on_cran()
  skip_on_local()

  nowcast <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 250, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ))

  expect_identical(
    setdiff(colnames(nowcast), colnames(pobs)),
    c(
      "priors", "fit", "data", "fit_args", "init_method_output",
      "samples", "max_rhat", "divergent_transitions",
      "per_divergent_transitions", "max_treedepth",
      "no_at_max_treedepth", "per_at_max_treedepth", "run_time"
    )
  )
  expect_convergence(nowcast)
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_error(
    nowcast$fit[[1]]$summary(
      c("refp_mean_int", "refp_sd_int")
    ), NA
  )
  expect_error(nowcast$fit[[1]]$summary("refp_beta"))
  expect_error(nowcast$fit[[1]]$summary("rep_beta"))
})

test_that("epinowcast() can fit a simple reporting model where the max delay is
          greater than the empirical max delay", {
  skip_on_cran()
  skip_on_local()

  pobs_long_delay <- suppressWarnings(
    enw_preprocess_data(
      enw_filter_reference_dates(
        pobs$obs[[1]][, .group := NULL],
        include_days = 20
      ),
      max_delay = 30
    )
  )

  nowcast <- suppressWarnings(suppressMessages(epinowcast(pobs_long_delay,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 250, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    obs = enw_obs(family = "poisson", data = pobs_long_delay),
    model = model
  )))

  expect_convergence(nowcast)
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_error(
    nowcast$fit[[1]]$summary(
      c("refp_mean_int", "refp_sd_int")
    ), NA
  )
  expect_error(nowcast$fit[[1]]$summary("refp_beta"))
  expect_error(nowcast$fit[[1]]$summary("rep_beta"))
  expect_identical(nrow(nowcast$fit[[1]]$summary("refp_lh")), 30L)
  expect_identical(nrow(nowcast$fit[[1]]$summary("pp_inf_obs")), 21L)
})

test_that("epinowcast() can fit a reporting model with a day of the week random
           effect for the date of report", {
  skip_on_cran()
  skip_on_local()

  regression_nowcast <- enw_example("nowcast")
  nowcast <- suppressMessages(epinowcast(pobs,
    report = enw_report(~ 1 + (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 250, iter_sampling = 1000,
      refresh = 0, show_messages = FALSE
    ),
    model = model
  ))
  expect_convergence(nowcast)
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")

  posterior <- as.data.table(nowcast$fit[[1]]$summary())
  regression_posterior <- as.data.table(regression_nowcast$fit[[1]]$summary())
  expect_identical(
    posterior$variable,
    regression_posterior$variable
  )
  # Nowcast median has not changed by more than 10 in total
  expect_diff_sum_abs_lt(
    posterior[variable %like% "pp_inf_obs", median],
    regression_posterior[variable %like% "pp_inf_obs", median],
    20
  )
  # Posterior predictions have not changed by more than in total
  expect_diff_sum_abs_lt(
    posterior[variable %like% "pp_obs", median],
    regression_posterior[variable %like% "pp_obs", median],
    150
  )
  # Day of the week effects are equal to within 25%
  expect_diff_abs_lt_per(
    posterior[variable %like% "rep_beta", median],
    regression_posterior[variable %like% "rep_beta", median],
    0.25
  )
  # Reporting distribution mean is equal to within 25%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_mean", median],
    regression_posterior[variable %like% "refp_mean", median],
    0.25
  )
  # Reporting distribution sd is equal to within 25%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_sd", median],
    regression_posterior[variable %like% "refp_sd", median],
    0.25
  )
})

test_that("epinowcast() reproduces HMC results when fit using Pathfinder on a
           simple case", {
  skip_on_cran()
  skip_on_local()

  regression_nowcast <- enw_example("nowcast")
  nowcast <- suppressMessages(epinowcast(pobs,
    report = enw_report(~ 1 + (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      sampler = silent_enw_pathfinder, num_paths = 10, pp = TRUE
    ),
    model = model
  ))
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")

  posterior <- as.data.table(nowcast$fit[[1]]$summary())
  regression_posterior <- as.data.table(regression_nowcast$fit[[1]]$summary())
  expect_identical(
    posterior$variable,
    c("lp_approx__", regression_posterior$variable)
  )
  # Nowcast median has not changed by more than 400 in total
  expect_diff_sum_abs_lt(
    posterior[variable %like% "pp_inf_obs", median],
    regression_posterior[variable %like% "pp_inf_obs", median],
    500
  )
  # Posterior predictions have not changed by more than in total
  expect_diff_sum_abs_lt(
    posterior[variable %like% "pp_obs", median],
    regression_posterior[variable %like% "pp_obs", median],
    2000
  )
  # Day of the week effects are equal to within 100%
  expect_diff_abs_lt_per(
    posterior[variable %like% "rep_beta", median],
    regression_posterior[variable %like% "rep_beta", median],
    1
  )
  # Reporting distribution mean is equal to within 50%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_mean", median],
    regression_posterior[variable %like% "refp_mean", median],
    0.5
  )
  # Reporting distribution sd is equal to within 25%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_sd", median],
    regression_posterior[variable %like% "refp_sd", median],
    0.25
  )
})

test_that("epinowcast() can fit a simple missing data model", {
  skip_on_cran()
  skip_on_local()

  # Load and filter germany hospitalisations
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][age_group == "00+"]
  nat_germany_hosp <- enw_filter_report_dates(
    nat_germany_hosp,
    latest_date = "2021-08-01"
  )
  # Make sure observations are complete
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group"),
    missing_reference = FALSE
  )
  # Set proportion missing at 35%
  prop_miss <- 0.35
  # Simulate using this function
  nat_germany_hosp <- enw_simulate_missing_reference(
    nat_germany_hosp,
    proportion = prop_miss, by = c("location", "age_group")
  )

  # Make a retrospective dataset
  retro_nat_germany <- enw_filter_report_dates(
    nat_germany_hosp,
    remove_days = 40
  )
  retro_nat_germany <- enw_filter_reference_dates(
    retro_nat_germany,
    include_days = 40
  )
  # Preprocess observations (note this maximum delay is likely too short)
  pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)
  # Fit options
  fit <- enw_fit_opts(
    sample = silent_enw_sample,
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 250, iter_sampling = 1000,
    likelihood_aggregation = "groups", adapt_delta = 0.9,
    refresh = 0, show_messages = FALSE
  )
  # Fit missing data model
  nowcast <- suppressWarnings(suppressMessages(epinowcast(pobs,
    missing = enw_missing(~ (1 | week), data = pobs),
    fit = fit,
    model = model
  )))
  # Comparison nowcast without missingness
  no_missing_nowcast <- suppressMessages(epinowcast(pobs,
    fit = fit, model = model
  ))
  # Check convergence
  expect_convergence(nowcast)
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")

  # Extract posteriors
  posterior <- as.data.table(nowcast$fit[[1]]$summary())
  no_missing_posterior <- as.data.table(no_missing_nowcast$fit[[1]]$summary())
  # Check proportion missing
  miss_prop <- enw_posterior(nowcast$fit[[1]], variables = "miss_ref_lprop")
  cols <- c("mean", "median", "q5", "q20", "q80", "q95")
  miss_prop[, (cols) := lapply(.SD, exp), .SDcols = cols]

  # expect_diff_sum_abs_lt(
  #   miss_prop[1, median], prop_miss, 0.02
  # )
  # Posterior predictions have not changed by more than in total
  expect_diff_sum_abs_lt(
    posterior[variable %like% "pp_obs", median],
    no_missing_posterior[variable %like% "pp_obs", median],
    175
  )
  # Reporting distribution mean is equal to within 10%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_mean", median],
    no_missing_posterior[variable %like% "refp_mean", median],
    0.1
  )
  # Reporting distribution sd is equal to within 10%
  expect_diff_abs_lt_per(
    posterior[variable %like% "refp_sd", median],
    no_missing_posterior[variable %like% "refp_sd", median],
    0.1
  )
})

test_that("epinowcast() can fit multiple time series at once", {
  skip_on_cran()
  skip_on_local()
  # Load and filter germany hospitalisations
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][
      age_group %in% c("00+", "00-04", "80+")
    ]
  nat_germany_hosp <- enw_filter_report_dates(
    nat_germany_hosp,
    latest_date = "2021-10-01"
  )
  # Make sure observations are complete
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group")
  )
  # Make a retrospective dataset
  retro_nat_germany <- enw_filter_report_dates(
    nat_germany_hosp,
    remove_days = 40
  )
  retro_nat_germany <- enw_filter_reference_dates(
    retro_nat_germany,
    include_days = 10
  )
  # Preprocess observations (note this maximum delay is likely too short)
  pobs <- enw_preprocess_data(
    retro_nat_germany,
    by = "age_group", max_delay = 10
  )
  nowcast <- suppressWarnings(
    suppressMessages(
      epinowcast(
        data = pobs,
        expectation = enw_expectation(
          r = ~ 1 + (1 | .group),
          generation_time = c(0.1, 0.4, 0.4, 0.1),
          observation = ~ (1 | day_of_week),
          latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
          data = pobs
        ),
        reference = enw_reference(~1, data = pobs),
        report = enw_report(~ (1 | day_of_week), data = pobs),
        fit = enw_fit_opts(
          sampler = silent_enw_sample,
          save_warmup = FALSE, pp = FALSE,
          chains = 2, iter_warmup = 500, iter_sampling = 500,
          parallel_chains = 2, adapt_delta = 0.95,
          refresh = 0, show_messages = FALSE
        ),
        obs = enw_obs(family = "negbin", data = pobs),
        model = model
      )
    )
  )
  expect_convergence(nowcast)
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
})

test_that("epinowcast() can fit a simple non-parametric reference date model", {
  skip_on_cran()
  skip_on_local()

  nowcast <- suppressMessages(epinowcast(pobs,
    reference = enw_reference(
      parametric = ~0, non_parametric = ~ 1 + (1 | delay),
      data = pobs
    ),
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 1000,
      refresh = 0, show_messages = FALSE, max_treedepth = 12
    ),
    model = model
  ))
  expect_convergence(nowcast, treedepth = 12)
  expect_identical(
    nrow(summary(nowcast, type = "fit", variables = "refnp_beta")), 20L
  )
  expect_equal(
    summary(nowcast, type = "fit", variables = "refnp_int")$mean, -1.66,
    tolerance = 0.1
  )
  expect_error(
    summary(
      nowcast,
      type = "fit",
      variables = c(
        "refp_mean_int", "refp_sd_int", "refp_mean_beta", "refp_sd_beta"
      )
    ),
    "refp_mean_int, refp_sd_int, refp_mean_beta, refp_sd_beta"
  )
})

test_that("epinowcast() can fit a simple combined parametric and non-parametric
          reference date model", {
  skip_on_cran()
  skip_on_local()

  nowcast <- suppressMessages(epinowcast(pobs,
    reference = enw_reference(
      parametric = ~1, non_parametric = ~ 0 + (1 | delay_cat),
      data = pobs
    ),
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 1000,
      refresh = 0, show_messages = FALSE
    ),
    model = model
  ))
  expect_convergence(nowcast)
  expect_equal(
    summary(
      nowcast,
      type = "fit", variables = c("refnp_beta_sd", "refnp_beta")
    )$mean,
    c(0.27, -0.47, 0.57, 0.56, -0.64),
    tolerance = 0.1
  )
  expect_equal(
    summary(nowcast, type = "fit", variables = c("refp_mean", "refp_sd"))$mean,
    c(1.5, 3.29),
    tolerance = 0.1
  )
  expect_error(
    summary(
      nowcast,
      type = "fit",
      variables = c(
        "refp_mean_beta", "refnp_int"
      )
    ),
    "refp_mean_beta, refnp_int"
  )
})

test_that("epinowcast() works with different init_methods", {
  skip_on_cran()
  skip_on_local()

  # Test with random initialization
  nowcast_random <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      init_method = "prior",
      chains = 2, iter_warmup = 250, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ))
  expect_s3_class(nowcast_random, "epinowcast")
  expect_true("init_method" %in% names(nowcast_random$fit_args[[1]]))
  expect_identical(nowcast_random$fit_args[[1]]$init_method, "random")
  expect_convergence(nowcast_random)

  # Test with pathfinder initialization
  nowcast_pathfinder <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      save_warmup = FALSE, pp = TRUE,
      init_method = "pathfinder",
      chains = 2, iter_warmup = 250, iter_sampling = 500,
      refresh = 0, show_messages = FALSE
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ))
  expect_s3_class(nowcast_pathfinder, "epinowcast")
  expect_true("init_method" %in% names(nowcast_pathfinder$fit_args[[1]]))
  expect_identical(nowcast_pathfinder$fit_args[[1]]$init_method, "pathfinder")
  expect_true("init_method_output" %in% names(nowcast_pathfinder))
  expect_null(nowcast_pathfinder$init_method_output$fit_args)
  expect_convergence(nowcast_pathfinder)

  # Compare results between random and pathfinder initialization
  pathfinder_posterior <- as.data.table(nowcast_pathfinder$fit[[1]]$summary())
  random_posterior <- as.data.table(nowcast_random$fit[[1]]$summary())

  # Nowcast median should be similar between methods
  expect_diff_sum_abs_lt(
    random_posterior[variable %like% "pp_inf_obs", median],
    pathfinder_posterior[variable %like% "pp_inf_obs", median],
    50
  )

  # Reporting distribution parameters should be similar between methods
  expect_diff_abs_lt_per(
    random_posterior[variable %like% "refp_mean", median],
    pathfinder_posterior[variable %like% "refp_mean", median],
    0.25
  )
  expect_diff_abs_lt_per(
    random_posterior[variable %like% "refp_sd", median],
    pathfinder_posterior[variable %like% "refp_sd", median],
    0.25
  )

  # Test that invalid init_method throws an error
  expect_error(
    epinowcast(pobs,
      fit = enw_fit_opts(
        sampler = silent_enw_sample,
        init_method = "invalid"
      ),
      obs = enw_obs(family = "poisson", data = pobs),
      model = model
    ),
    "`init_method` must be one of"
  )

  # Correct passes init_method_args
  nowcast_pathfinder_args <- suppressMessages(epinowcast(pobs,
    fit = enw_fit_opts(
      sampler = silent_enw_sample,
      init_method = "pathfinder",
      init_method_args = list(num_paths = 2)
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ))
  expect_identical(
    nowcast_pathfinder_args$init_method_output[[1]]$fit_args[[1]]$num_paths, 2
  )
})
