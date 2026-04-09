if (not_on_cran() && on_ci()) {
  model <- enw_model()
  options(mc.cores = 2)
}

test_that(
  "epinowcast() fits retrospective Rt model with max_delay = 1", {
    skip_on_cran()
    skip_on_local()

    # Simulate simple incidence data with known growth
    set.seed(12345)
    n <- 30
    dates <- as.Date("2021-01-01") + 0:(n - 1)
    # Exponential growth then decline
    lambda <- c(
      round(50 * exp(0.05 * (1:15))),
      round(50 * exp(0.05 * 15) * exp(-0.03 * (1:15)))
    )
    counts <- rpois(n, lambda)

    obs <- data.table::data.table(
      reference_date = dates,
      report_date = dates,
      confirm = counts
    )

    pobs <- enw_preprocess_data(obs, max_delay = 1)
    expect_equal(pobs$max_delay, 1)

    # All delay models off, expectation with Rt
    nowcast <- suppressMessages(epinowcast(
      pobs,
      reference = enw_reference(
        parametric = ~0, non_parametric = ~0, data = pobs
      ),
      report = enw_report(non_parametric = ~0, data = pobs),
      expectation = enw_expectation(
        r = ~1,
        generation_time = c(0.3, 0.4, 0.2, 0.1),
        data = pobs
      ),
      obs = enw_obs(family = "poisson", data = pobs),
      fit = enw_fit_opts(
        sampler = silent_enw_sample,
        save_warmup = FALSE, pp = TRUE,
        chains = 2, iter_warmup = 500, iter_sampling = 500,
        refresh = 0, show_messages = FALSE
      ),
      model = model
    ))

    # Model ran successfully
    expect_identical(
      class(nowcast$fit[[1]])[1], "CmdStanMCMC"
    )

    # Check convergence
    expect_lt(nowcast$max_rhat, 1.05)
    expect_lt(nowcast$per_divergent_transitions, 0.05)

    # Stan data should have delay models off
    expect_identical(nowcast$data[[1]]$model_refp, 0L)
    expect_identical(nowcast$data[[1]]$model_refnp, 0L)
    expect_identical(nowcast$data[[1]]$model_rep, 0L)

    # Expected obs should be close to actual counts
    # (no delay adjustment, just latent process)
    posterior <- as.data.table(
      nowcast$fit[[1]]$summary("pp_inf_obs")
    )
    expect_identical(nrow(posterior), as.integer(n))

    # Median posterior predictions should be within 50% of
    # true lambda on average
    rel_error <- abs(posterior$median - lambda) / lambda
    expect_lt(mean(rel_error), 0.5)
  }
)

test_that(
  "epinowcast() retrospective Rt via enw_retrospective()", {
    skip_on_cran()
    skip_on_local()

    # Use real data, preprocess with delays, then convert
    obs <- run_window_filter(
      germany_covid19_hosp[age_group == "00+"][location == "DE"]
    )
    pobs <- enw_preprocess_data(obs, max_delay = 5)
    retro <- enw_retrospective(pobs)

    expect_equal(retro$max_delay, 1)

    nowcast <- suppressMessages(epinowcast(
      retro,
      reference = enw_reference(
        parametric = ~0, non_parametric = ~0, data = retro
      ),
      report = enw_report(non_parametric = ~0, data = retro),
      expectation = enw_expectation(
        r = ~1,
        generation_time = c(0.3, 0.4, 0.2, 0.1),
        data = retro
      ),
      obs = enw_obs(family = "negbin", data = retro),
      fit = enw_fit_opts(
        sampler = silent_enw_sample,
        save_warmup = FALSE, pp = FALSE,
        chains = 2, iter_warmup = 500, iter_sampling = 500,
        refresh = 0, show_messages = FALSE
      ),
      model = model
    ))

    expect_identical(
      class(nowcast$fit[[1]])[1], "CmdStanMCMC"
    )
    expect_lt(nowcast$max_rhat, 1.05)
    expect_lt(nowcast$per_divergent_transitions, 0.05)
  }
)
