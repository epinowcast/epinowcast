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
      "expl_beta", "expl_beta_sd"
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
        expr_r_int = 1L, expl_beta = 6L, expl_beta_sd = 3L
      )
    )
  }
)
