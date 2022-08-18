# load example preprocessed data (already regression tested)
pobs <- enw_example("preprocessed")
if (not_on_cran() & on_ci()) {
  model <- enw_model()
  options(mc.cores = 2)
  silent_enw_sample <- function(...) {
    utils::capture.output(
      fit <- suppressMessages(enw_sample(...))
    )
    return(fit)
  }
}

test_that("epinowcast preprocesses data and model modules as expected", {
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
  expect_true(is.list(nowcast$data[[1]]))
  expect_error(nowcast$init())
  class(pobs) <- c("epinowcast", class(pobs))
  expect_equal(nowcast[, c("init", "data") := NULL], pobs)
})

test_that("epinowcast can fit a simple reporting model", {
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

  expect_equal(
    setdiff(colnames(nowcast), colnames(pobs)),
    c(
      "fit", "data", "fit_args", "samples", "max_rhat",
      "divergent_transitions", "per_divergent_transitions", "max_treedepth",
      "no_at_max_treedepth", "per_at_max_treedepth", "run_time"
    )
  )
  expect_equal(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
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
})

test_that("epinowcast can fit a reporting model with a day of the week random
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
  expect_equal(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
  posterior <- as.data.table(nowcast$fit[[1]]$summary())
  regression_posterior <- as.data.table(regression_nowcast$fit[[1]]$summary())
  expect_equal(
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

test_that("epinowcast can fit a simple missing data model", {
  skip_on_cran()
  skip_on_local()

  # Load and filter germany hospitalisations
  nat_germany_hosp <-
    germany_covid19_hosp[location == "DE"][age_group %in% "00+"]
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
    sampler = silent_enw_sample,
    save_warmup = FALSE, pp = TRUE,
    chains = 2, iter_warmup = 250, iter_sampling = 1000,
    likelihood_aggregation = "groups", adapt_delta = 0.9,
    refresh = 0, show_messages = FALSE
  )
  # Fit missing data model
  nowcast <- suppressMessages(epinowcast(pobs,
    missing = enw_missing(~ (1 | week), data = pobs),
    fit = fit,
    model = model
  ))
  # Comparison nowcast without missingness
  no_missing_nowcast <- suppressMessages(epinowcast(pobs,
    fit = fit, model = model
  ))
  # Check convergence
  expect_equal(class(nowcast$fit[[1]])[1], "CmdStanMCMC")
  expect_type(nowcast$fit_args[[1]], "list")
  expect_type(nowcast$data[[1]], "list")
  expect_lt(nowcast$per_divergent_transitions, 0.05)
  expect_lt(nowcast$max_treedepth, 10)
  expect_lt(nowcast$max_rhat, 1.05)
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
    150
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
