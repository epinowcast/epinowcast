# Use example data
pobs <- enw_example("preprocessed")

# A small two-group preprocessed dataset for per-group population tests.
multi_group_pobs <- function() {
  nat_germany_hosp <- germany_covid19_hosp[location == "DE"][
    age_group %in% c("00+", "80+")
  ]
  nat_germany_hosp <- enw_filter_report_dates(
    nat_germany_hosp,
    latest_date = "2021-10-01"
  )
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group")
  )
  suppressWarnings(enw_preprocess_data(
    enw_filter_reference_dates(nat_germany_hosp, include_days = 10),
    by = "age_group", max_delay = 10
  ))
}

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
  expect_identical(expectation$data$expr_pop_use, 1L)
  expect_identical(expectation$data$expr_pop_uncertain, 0L)
  expect_true(all(expectation$data$expr_pop_fixed == 1000))
})

test_that("enw_expectation supports an uncertain (fitted) population", {
  population <- 1000
  population_cv <- 0.1
  expectation <- enw_expectation(
    generation_time = c(0.2, 0.5, 0.3), population = population,
    population_uncertain = TRUE, population_cv = population_cv, data = pobs
  )
  expect_identical(expectation$data$expr_pop_use, 1L)
  expect_identical(expectation$data$expr_pop_uncertain, 1L)
  expect_true("expr_pop" %in% expectation$priors$variable)
  pop_prior <- expectation$priors[variable == "expr_pop"]
  expect_identical(unique(pop_prior$distribution), "Log normal")
  # One prior row per group.
  expect_identical(nrow(pop_prior), pobs$groups[[1]])
  # LogNormal log-median recovers the supplied population on the natural scale
  expect_equal(exp(pop_prior$mean), population, tolerance = 1e-6)
  # CV -> sdlog derivation is sqrt(log1p(cv^2))
  expect_equal(pop_prior$sd, sqrt(log1p(population_cv^2)), tolerance = 1e-12)
  # Inits are one independent value per group
  pop_init <- expectation$inits(
    c(expectation$data, list(g = pobs$groups[[1]])), expectation$priors
  )()$expr_pop_est
  expect_length(pop_init, pobs$groups[[1]])
  expect_true(all(pop_init > 0))
})

test_that("enw_expectation accepts per-group fixed populations", {
  multi_pobs <- multi_group_pobs()
  expectation <- enw_expectation(
    r = ~ 1 + (1 | .group), generation_time = c(0.2, 0.5, 0.3),
    population = c(1000, 2000), data = multi_pobs
  )
  expect_length(expectation$data$expr_pop_fixed, multi_pobs$groups[[1]])
  expect_identical(expectation$data$expr_pop_fixed, c(1000, 2000))
  # A scalar with multiple groups recycles with a warning.
  expect_warning(
    enw_expectation(
      r = ~ 1 + (1 | .group), generation_time = c(0.2, 0.5, 0.3),
      population = 1500, data = multi_pobs
    ),
    "recycling"
  )
})

test_that("enw_expectation fits per-group population prior medians", {
  multi_pobs <- multi_group_pobs()
  population <- c(1000, 4000)
  population_cv <- 0.2
  expectation <- suppressWarnings(enw_expectation(
    r = ~ 1 + (1 | .group), generation_time = c(0.2, 0.5, 0.3),
    population = population, population_uncertain = TRUE,
    population_cv = population_cv, data = multi_pobs
  ))
  pop_prior <- expectation$priors[variable == "expr_pop"]
  # One prior row per group, each centred on its own supplied population.
  expect_identical(nrow(pop_prior), multi_pobs$groups[[1]])
  expect_equal(exp(pop_prior$mean), population, tolerance = 1e-6)
  # A single shared log sd from the CV.
  expect_equal(
    pop_prior$sd, rep(sqrt(log1p(population_cv^2)), length(population)),
    tolerance = 1e-12
  )
  # Stan data carries a per-group prior (2 x g) via expr_pop_p.
  pop_p <- enw_priors_as_data_list(pop_prior)$expr_pop_p
  expect_identical(dim(pop_p), c(2L, length(population)))
  expect_equal(exp(pop_p[1, ]), population, tolerance = 1e-6)
})

test_that("enw_expectation validates population arguments", {
  expect_error(
    enw_expectation(population = -1, data = pobs),
    "population"
  )
  # Length 2 vector with a single group is invalid.
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

test_that("enw_expectation rejects NA / non-finite population inputs", {
  gt <- c(0.2, 0.5, 0.3)
  # NA / non-finite population fails cleanly with the intended message.
  expect_error(
    enw_expectation(generation_time = gt, population = NA_real_, data = pobs),
    "`population` must be"
  )
  expect_error(
    enw_expectation(generation_time = gt, population = Inf, data = pobs),
    "`population` must be"
  )
  # NA / non-finite population_floor.
  expect_error(
    enw_expectation(population_floor = NA_real_, data = pobs),
    "`population_floor` must be"
  )
  expect_error(
    enw_expectation(population_floor = Inf, data = pobs),
    "`population_floor` must be"
  )
  # NA / non-finite population_cv (only checked when uncertain).
  expect_error(
    enw_expectation(
      generation_time = gt, population = 1000,
      population_uncertain = TRUE, population_cv = NA_real_, data = pobs
    ),
    "`population_cv` must be"
  )
})

test_that("enw_expectation warns when population is set without a renewal", {
  expect_warning(
    enw_expectation(population = 1000, data = pobs),
    "ignored for the daily growth rate model"
  )
  # The uncertain request is also flagged as dropped in this case.
  expect_warning(
    enw_expectation(
      population = 1000, population_uncertain = TRUE, data = pobs
    ),
    "uncertain"
  )
})

test_that("enw_expectation defaults to no cross-group mixing", {
  gt <- c(0.2, 0.5, 0.3)
  expectation <- enw_expectation(generation_time = gt, data = pobs)
  expect_identical(expectation$data$expr_mixing_use, 0L)
  expect_identical(expectation$data$expr_mixing, diag(pobs$groups[[1]]))
})

test_that("enw_expectation accepts a mixing matrix for the renewal path", {
  multi_pobs <- multi_group_pobs()
  groups <- multi_pobs$groups[[1]]
  gt <- c(0.2, 0.5, 0.3)
  K <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)

  expectation <- enw_expectation(
    generation_time = gt, mixing = K, data = multi_pobs
  )
  expect_identical(expectation$data$expr_mixing_use, 1L)
  expect_identical(expectation$data$expr_mixing, K)

  # The identity matrix is the explicit form of the (default) uncoupled model.
  identity_expectation <- enw_expectation(
    generation_time = gt, mixing = diag(groups), data = multi_pobs
  )
  expect_identical(identity_expectation$data$expr_mixing_use, 1L)
  no_mixing_expectation <- enw_expectation(
    generation_time = gt, data = multi_pobs
  )
  expect_identical(
    identity_expectation$data$expr_mixing,
    no_mixing_expectation$data$expr_mixing
  )
})

test_that("enw_expectation validates the mixing argument", {
  multi_pobs <- multi_group_pobs()
  groups <- multi_pobs$groups[[1]]
  gt <- c(0.2, 0.5, 0.3)

  # Wrong shape.
  expect_error(
    enw_expectation(
      generation_time = gt, mixing = matrix(1, 3, 3), data = multi_pobs
    ),
    "`mixing`"
  )
  # Not a matrix.
  expect_error(
    enw_expectation(
      generation_time = gt, mixing = seq_len(groups^2), data = multi_pobs
    ),
    "`mixing`"
  )
  # Non-finite entries.
  expect_error(
    enw_expectation(
      generation_time = gt,
      mixing = matrix(c(1, NA, 0, 1), nrow = 2), data = multi_pobs
    ),
    "`mixing`"
  )
  expect_error(
    enw_expectation(
      generation_time = gt,
      mixing = matrix(c(1, Inf, 0, 1), nrow = 2), data = multi_pobs
    ),
    "`mixing`"
  )
})

test_that("enw_expectation warns when mixing is set without a renewal", {
  multi_pobs <- multi_group_pobs()
  groups <- multi_pobs$groups[[1]]
  expect_warning(
    enw_expectation(mixing = diag(groups), data = multi_pobs),
    "ignored for the daily growth rate model"
  )
})

test_that("epinowcast() fits a non-identity mixing matrix in compiled Stan", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  # This is the only path that exercises the use_mixing == 1 branch of
  # log_expected_latent_from_r() in compiled Stan, so a wiring error (for
  # example the expr_mixing_use/expr_mixing argument order or a transposed
  # matrix) would pass the R-level data-list tests above and the exposed-
  # function tests in test-stan_log_expected_latent_from_r.R without being
  # caught.
  mix_pobs <- multi_group_pobs()
  groups <- mix_pobs$groups[[1]]
  gt <- c(0.2, 0.3, 0.5)
  K <- matrix(c(0.8, 0.2, 0.3, 0.7), nrow = groups, byrow = TRUE)
  fit_opts <- enw_fit_opts(
    save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
    iter_warmup = 250, iter_sampling = 250, show_messages = FALSE,
    show_exceptions = FALSE, refresh = 0, adapt_delta = 0.95, seed = 1,
    max_treedepth = 12
  )

  nowcast_mixed <- suppressWarnings(epinowcast(
    mix_pobs,
    expectation = enw_expectation(
      generation_time = gt, mixing = K, data = mix_pobs
    ),
    fit = fit_opts
  ))
  expect_convergence(nowcast_mixed, rhat = 1.1)

  nowcast_unmixed <- suppressWarnings(epinowcast(
    mix_pobs,
    expectation = enw_expectation(generation_time = gt, data = mix_pobs),
    fit = fit_opts
  ))
  expect_convergence(nowcast_unmixed, rhat = 1.1)

  # A real off-diagonal K changes the fitted latent trajectories relative to
  # the (default) uncoupled model.
  mixed_latent <- summary(nowcast_mixed, type = "fit")[
    grepl("^exp_llatent", variable)
  ]$mean
  unmixed_latent <- summary(nowcast_unmixed, type = "fit")[
    grepl("^exp_llatent", variable)
  ]$mean
  expect_false(isTRUE(all.equal(mixed_latent, unmixed_latent)))
})
