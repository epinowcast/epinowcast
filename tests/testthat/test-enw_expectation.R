# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_expectation produces the expected default model", {
  expect_snapshot({
    expectation <- enw_expectation(data = pobs)
    expectation$inits <- NULL
    expectation
  })
  exp <- enw_expectation(~ 1 + day_of_week, data = pobs)
  obs <- enw_obs(data = pobs)
  expect_named(
    exp$inits(c(exp$data, obs$data), exp$priors)(),
    c(
      "expr_beta", "expr_beta_sd", "expr_lelatent_int", "expr_r_int",
      "expl_beta", "expl_beta_sd",
      "expr_arima_pacf", "expr_arima_theta", "expr_arima_sigma",
      "expr_gp_rho", "expr_gp_alpha",
      "expl_arima_pacf", "expl_arima_theta", "expl_arima_sigma",
      "expl_gp_rho", "expl_gp_alpha"
    )
  )
})

test_that(
  "enw_expectation passes a 2D fdesign to Stan for a weekly timestep with a single numeric covariate (#783)", # nolint: line_length_linter.
  {
    df <- data.frame(
      reference_date = as.Date(rep(
        c("1990-01-01", "1990-01-08", "1990-01-15"), c(7L, 6L, 7L)
      )),
      report_date = as.Date(c(
        "1990-01-01", "1990-01-08", "1990-01-15", "1990-01-22", "1990-01-29",
        "1990-02-12", "1990-03-05", "1990-01-08", "1990-01-15", "1990-01-22",
        "1990-01-29", "1990-02-05", "1990-02-12", "1990-01-15", "1990-01-22",
        "1990-01-29", "1990-02-05", "1990-02-12", "1990-02-19", "1990-03-05"
      )),
      confirm = c(
        3L, 27L, 50L, 58L, 59L, 60L, 61L, 2L, 35L, 41L, 45L, 48L, 50L,
        6L, 25L, 36L, 38L, 42L, 43L, 44L
      )
    )
    weekly_pobs <- enw_preprocess_data(
      enw_complete_dates(df, max_delay = 5, timestep = "week"),
      max_delay = 5, timestep = "week"
    )
    rep_module <- enw_expectation(r = ~ 1 + week, data = weekly_pobs)
    expect_true(is.matrix(rep_module$data$expr_fdesign))
    expect_identical(
      nrow(rep_module$data$expr_fdesign),
      as.integer(rep_module$data$expr_fnrow)
    )
    expect_identical(
      ncol(rep_module$data$expr_fdesign),
      as.integer(rep_module$data$expr_fncol)
    )
    expect_identical(rep_module$data$expr_fncol, 1)
  }
)

test_that("enw_expectation supports custom expectation models", {
  expect_snapshot({
    expectation <- enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
    expectation$inits <- NULL
    expectation
  })
  expect_error(enw_expectation(~0, data = pobs))
})

test_that(
  "enw_expectation works as expected when multiple timeseries are present",
  {
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
    expectation_module <- enw_expectation(
      ~ 1 + (1 | .group),
      observation = ~ (1 | week:.group),
      generation_time = c(0.1, 0.9),
      latent_reporting_delay = c(0.1, 0.9),
      data = pobs
    )
    expect_snapshot(
      expectation_module[setdiff(names(expectation_module), "inits")]
    )
    expect_identical(
      purrr::map(
        expectation_module$inits(
          c(expectation_module$data, list(g = 3)),
          expectation_module$priors
        )(),
        dim
      ),
      list(
        expr_beta = 3L, expr_beta_sd = 1L, expr_lelatent_int = c(2L, 3L),
        expr_r_int = 1L, expl_beta = 6L, expl_beta_sd = 3L,
        expr_arima_pacf = NULL, expr_arima_theta = NULL,
        expr_arima_sigma = NULL,
        expr_gp_rho = NULL, expr_gp_alpha = NULL,
        expl_arima_pacf = NULL,
        expl_arima_theta = NULL, expl_arima_sigma = NULL,
        expl_gp_rho = NULL, expl_gp_alpha = NULL
      )
    )
  }
)

test_that("enw_expectation defaults to no susceptible-depletion adjustment", {
  expectation <- enw_expectation(data = pobs)
  expect_identical(expectation$data$expr_pop_use, 0L)
  expect_identical(expectation$data$expr_pop_uncertain, 0L)
  expect_identical(expectation$data$expr_pop_floor, 1)
  expect_length(expectation$data$expr_pop_fixed, pobs$groups[[1]])
  expect_true(all(expectation$data$expr_pop_fixed == 0))
  # The population prior is always supplied as data but only used when the
  # population is estimated.
  expect_true("expr_pop" %in% expectation$priors$variable)
})

test_that("enw_expectation accepts a fixed population for depletion", {
  expectation <- enw_expectation(
    generation_time = c(0.2, 0.5, 0.3), population = 1000, data = pobs
  )
  expect_identical(expectation$data$expr_pop_use, 2L)
  expect_identical(expectation$data$expr_pop_uncertain, 0L)
  expect_true(all(expectation$data$expr_pop_fixed == 1000))
})

test_that("enw_expectation restricts depletion to the forecast period", {
  expectation <- enw_expectation(
    generation_time = c(0.2, 0.5, 0.3), population = 1000,
    population_period = "forecast", data = pobs
  )
  expect_identical(expectation$data$expr_pop_use, 1L)
  expect_gte(expectation$data$expr_pop_nht, 0L)
  expect_lte(expectation$data$expr_pop_nht, expectation$data$expr_t)
})

test_that("enw_expectation supports an uncertain (fitted) population", {
  expectation <- enw_expectation(
    generation_time = c(0.2, 0.5, 0.3), population = 1000,
    population_uncertain = TRUE, data = pobs
  )
  expect_identical(expectation$data$expr_pop_use, 2L)
  expect_identical(expectation$data$expr_pop_uncertain, 1L)
  expect_true("expr_pop" %in% expectation$priors$variable)
  pop_prior <- expectation$priors[variable == "expr_pop"]
  expect_identical(pop_prior$distribution, "Log normal")
  # LogNormal log-mean recovers the supplied population on the natural scale
  expect_equal(exp(pop_prior$mean), 1000, tolerance = 1e-6)
  pop_init <- expectation$inits(
    c(expectation$data, list(g = pobs$groups[[1]])), expectation$priors
  )()$expr_pop_est
  expect_length(pop_init, 1L)
  expect_gt(pop_init, 0)
})

test_that("enw_expectation validates population arguments", {
  expect_error(
    enw_expectation(population = -1, data = pobs),
    "population"
  )
  expect_error(
    enw_expectation(population = c(1, 2), data = pobs),
    "population"
  )
  expect_error(
    enw_expectation(population_floor = -1, data = pobs),
    "population_floor"
  )
  expect_error(
    enw_expectation(
      population_uncertain = TRUE, population = NULL, data = pobs
    ),
    "population"
  )
})
