# Synthetic-recovery tests for uncertain delay distributions (#177, #178).
# These run a short fit and are gated to CI only (skipped locally and on CRAN).

build_fully_reported <- function(y, start = "2021-01-01") {
  dates <- data.table::as.IDate(start) + seq_along(y) - 1L
  dt <- data.table::data.table(
    reference_date = dates, report_date = dates, confirm = cumsum(y)
  )
  dt <- enw_complete_dates(dt, max_delay = 2)
  enw_preprocess_data(dt, max_delay = 2)
}

test_that("an uncertain latent reporting delay is recovered (#177)", {
  skip_on_cran()
  skip_on_local()

  set.seed(42)
  # Truth: a gamma latent reporting delay (Stan gamma uses shape = exp(mu),
  # rate = sigma).
  truth_mu <- 1.4
  truth_sigma <- 1.5
  dmax <- 8L
  pmf <- diff(pgamma(0:dmax, exp(truth_mu), truth_sigma))
  pmf <- pmf / sum(pmf)

  # A purely exponential latent series so the delay is identifiable from the
  # lag/curvature of the observations (a flexible latent process would trade
  # off against the delay; see the discussion in #177/#178).
  tn <- 100L
  latent <- 300 * exp(0.05 * seq_len(tn))
  obs <- vapply(seq_len(tn), function(s) {
    d <- 0:(dmax - 1)
    keep <- s - d >= 1
    sum(latent[s - d[keep]] * pmf[d[keep] + 1])
  }, numeric(1))
  y <- rpois(tn, obs)
  pobs <- build_fully_reported(y)

  lrd_spec <- enw_uncertain(
    "gamma",
    mean = c(1.4, 0.3), sd = c(1.5, 0.4), max = dmax
  )
  expectation <- enw_expectation(
    r = ~1, latent_reporting_delay = lrd_spec, data = pobs
  )
  reference <- enw_reference(
    ~0,
    non_parametric = ~ 0 + (1 | delay), data = pobs
  )
  nowcast <- suppressMessages(epinowcast(
    pobs,
    expectation = expectation, reference = reference,
    fit = enw_fit_opts(
      chains = 2, parallel_chains = 2, iter_warmup = 500,
      iter_sampling = 500, pp = FALSE, show_messages = FALSE,
      refresh = 0, adapt_delta = 0.95
    )
  ))

  draws <- nowcast$fit[[1]]$summary(c("expl_lrd_mean", "expl_lrd_sd"))
  expect_lt(nowcast$max_rhat, 1.1)
  # 90% credible intervals should cover the truth.
  mean_row <- draws[draws$variable == "expl_lrd_mean[1]", ]
  sd_row <- draws[draws$variable == "expl_lrd_sd[1]", ]
  expect_gt(truth_mu, mean_row$q5)
  expect_lt(truth_mu, mean_row$q95)
  expect_gt(truth_sigma, sd_row$q5)
  expect_lt(truth_sigma, sd_row$q95)
})

test_that("an uncertain generation time samples and mixes (#178)", {
  skip_on_cran()
  skip_on_local()

  set.seed(101)
  # The generation time is only weakly identified from incidence alone (see
  # #178), so here we check that the in-model discretisation and renewal
  # convolution run and mix, with an informative prior, rather than asserting
  # unbiased recovery.
  truth_mu <- 1.5
  truth_sigma <- 0.4
  gmax <- 12L
  pmf <- diff(plnorm(0:gmax, truth_mu, truth_sigma))
  pmf <- pmf / sum(pmf)

  tn <- 70L
  inc <- numeric(tn)
  inc[seq_len(gmax)] <- 30
  for (t in (gmax + 1):tn) {
    inc[t] <- 1.1 * sum(rev(inc[(t - gmax):(t - 1)]) * pmf)
  }
  y <- rpois(tn, inc)
  pobs <- build_fully_reported(y)

  gt_spec <- enw_uncertain(
    "lognormal",
    mean = c(1.5, 0.1), sd = c(0.4, 0.05), max = gmax
  )
  expectation <- enw_expectation(
    r = ~ rw(week), generation_time = gt_spec, data = pobs
  )
  reference <- enw_reference(
    ~0,
    non_parametric = ~ 0 + (1 | delay), data = pobs
  )
  nowcast <- suppressMessages(epinowcast(
    pobs,
    expectation = expectation, reference = reference,
    fit = enw_fit_opts(
      chains = 2, parallel_chains = 2, iter_warmup = 500,
      iter_sampling = 500, pp = FALSE, show_messages = FALSE,
      refresh = 0, adapt_delta = 0.95
    )
  ))

  draws <- nowcast$fit[[1]]$summary(c("expr_gt_mean", "expr_gt_sd"))
  # Parameters are sampled (finite, well-mixed) and consistent with the
  # informative prior centred on the truth.
  expect_true(all(is.finite(draws$mean)))
  expect_true(all(draws$rhat < 1.2))
})
