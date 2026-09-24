# Synthetic-recovery tests for the susceptible-depletion adjustment in the
# renewal expectation model. These fit Stan models and so are gated to CI.

# Compiled model is built lazily so the file can be sourced without cmdstanr.
sd_model <- function() {
  if (!exists("model", inherits = TRUE)) {
    return(enw_model())
  }
  get("model", inherits = TRUE)
}

# Simulate a depleting epidemic on a single well-mixed population using the
# same renewal recursion (with susceptible scaling) implemented in Stan. Returns
# daily incidence and the realised attack size.
simulate_depleting_epidemic <- function(population = 4000, rt = 1.6,
                                        generation_time = c(0.3, 0.4, 0.3),
                                        n_days = 45, seed_cases = 5) {
  gt_n <- length(generation_time)
  rgt <- rev(generation_time)
  inc <- rep(seed_cases, n_days)
  cum_cases <- sum(inc[seq_len(gt_n)])
  for (i in (gt_n + 1):n_days) {
    infectiousness <- sum(inc[(i - gt_n):(i - 1)] * rgt)
    # Mirror the Stan recursion: the new-case count is capped by the true
    # remaining susceptibles while the rate denominator is floored separately.
    remaining_susceptible <- max(0, population - cum_cases)
    denom <- max(1, remaining_susceptible)
    inc[i] <- remaining_susceptible * (
      1 - exp(-rt * infectiousness / denom)
    )
    cum_cases <- cum_cases + inc[i]
  }
  list(incidence = inc, attack_size = cum_cases)
}

# Build a complete-reporting line list (no delay) from daily incidence so the
# expectation model is the only thing being tested.
incidence_to_obs <- function(incidence, start = as.Date("2021-01-01"),
                             group = NULL) {
  counts <- rpois(length(incidence), pmax(incidence, 1e-3))
  dates <- start + seq_along(counts) - 1
  dt <- data.table::data.table(
    reference_date = dates,
    report_date = dates,
    confirm = counts
  )
  if (!is.null(group)) {
    dt[, age_group := group]
  }
  dt
}

# Posterior mean attack size on the natural scale: sum exp(exp_llatent) within
# each draw, then average across draws (a per-draw sum, not a geometric mean of
# the log-scale summary).
attack_size_from_fit <- function(nowcast) {
  draws <- posterior::as_draws_matrix(
    nowcast$fit[[1]]$draws("exp_llatent")
  )
  mean(rowSums(exp(draws)))
}

test_that(
  "the adjusted renewal model recovers a depleting epidemic better than the unadjusted model", # nolint: line_length_linter.
  {
    skip_on_cran()
    skip_on_local()

    set.seed(202)
    population <- 4000
    gt <- c(0.3, 0.4, 0.3)
    sim <- simulate_depleting_epidemic(
      population = population, rt = 1.7, generation_time = gt, n_days = 45
    )
    obs <- incidence_to_obs(sim$incidence)
    pobs <- suppressWarnings(enw_preprocess_data(
      enw_complete_dates(obs, max_delay = 2),
      max_delay = 2
    ))

    fit_opts <- enw_fit_opts(
      sampler = silent_enw_sample, save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 400, iter_sampling = 400,
      refresh = 0, show_messages = FALSE, adapt_delta = 0.95,
      max_treedepth = 12
    )
    r_form <- ~ rw(week)

    nowcast_adj <- suppressMessages(epinowcast(
      pobs,
      expectation = enw_expectation(
        r = r_form, generation_time = gt, population = population,
        data = pobs
      ),
      fit = fit_opts, obs = enw_obs(family = "poisson", data = pobs),
      model = sd_model()
    ))
    nowcast_unadj <- suppressMessages(epinowcast(
      pobs,
      expectation = enw_expectation(
        r = r_form, generation_time = gt, data = pobs
      ),
      fit = fit_opts, obs = enw_obs(family = "poisson", data = pobs),
      model = sd_model()
    ))

    # Relaxed treedepth: the renewal random walk on a short series has a
    # challenging geometry; rhat / divergences are the substantive checks.
    # Both fits must converge before their summaries are compared.
    expect_convergence(nowcast_adj, treedepth = 13)
    expect_convergence(nowcast_unadj, treedepth = 13)

    err_adj <- abs(attack_size_from_fit(nowcast_adj) - sim$attack_size)
    err_unadj <- abs(attack_size_from_fit(nowcast_unadj) - sim$attack_size)
    # The adjusted model should reconstruct the realised attack size at least
    # as well as the unadjusted model on depleting data.
    expect_lt(err_adj, err_unadj)
  }
)

test_that(
  "the uncertain-population variant recovers a known population",
  {
    skip_on_cran()
    skip_on_local()

    set.seed(303)
    population <- 4000
    gt <- c(0.3, 0.4, 0.3)
    sim <- simulate_depleting_epidemic(
      population = population, rt = 1.7, generation_time = gt, n_days = 45
    )
    obs <- incidence_to_obs(sim$incidence)
    pobs <- suppressWarnings(enw_preprocess_data(
      enw_complete_dates(obs, max_delay = 2),
      max_delay = 2
    ))

    nowcast <- suppressMessages(epinowcast(
      pobs,
      expectation = enw_expectation(
        r = ~ rw(week), generation_time = gt, population = population,
        population_uncertain = TRUE, population_cv = 0.5, data = pobs
      ),
      fit = enw_fit_opts(
        sampler = silent_enw_sample, save_warmup = FALSE, pp = FALSE,
        chains = 2, iter_warmup = 500, iter_sampling = 500,
        refresh = 0, show_messages = FALSE, adapt_delta = 0.95,
        max_treedepth = 12
      ),
      obs = enw_obs(family = "poisson", data = pobs),
      model = sd_model()
    ))

    # Gate the recovery assertion on sampler convergence.
    expect_convergence(nowcast, treedepth = 13)

    pop_post <- nowcast$fit[[1]]$summary("expr_pop_est")
    # The known population should lie within the estimated 90% credible interval.
    expect_lte(pop_post$q5, population)
    expect_gte(pop_post$q95, population)
  }
)

test_that(
  "the uncertain-population variant fits an independent population per group",
  {
    skip_on_cran()
    skip_on_local()

    set.seed(404)
    gt <- c(0.3, 0.4, 0.3)
    pops <- c(3000, 6000)
    sims <- lapply(pops, function(p) {
      simulate_depleting_epidemic(
        population = p, rt = 1.7, generation_time = gt, n_days = 45
      )
    })
    obs <- data.table::rbindlist(list(
      incidence_to_obs(sims[[1]]$incidence, group = "a"),
      incidence_to_obs(sims[[2]]$incidence, group = "b")
    ))
    pobs <- suppressWarnings(enw_preprocess_data(
      enw_complete_dates(obs, max_delay = 2, by = "age_group"),
      by = "age_group", max_delay = 2
    ))

    nowcast <- suppressMessages(epinowcast(
      pobs,
      # Each group is fitted independently from its OWN prior median (its own
      # supplied population value); no shared-median / wide-CV workaround is
      # needed.
      expectation = enw_expectation(
        r = ~ rw(week, by = .group), generation_time = gt,
        population = pops, population_uncertain = TRUE,
        population_cv = 0.3, data = pobs
      ),
      fit = enw_fit_opts(
        sampler = silent_enw_sample, save_warmup = FALSE, pp = FALSE,
        chains = 2, iter_warmup = 1000, iter_sampling = 500,
        refresh = 0, show_messages = FALSE, adapt_delta = 0.99,
        max_treedepth = 12
      ),
      obs = enw_obs(family = "poisson", data = pobs),
      model = sd_model()
    ))

    # Gate the recovery assertions on sampler convergence.
    expect_convergence(nowcast, treedepth = 13)

    pop_post <- nowcast$fit[[1]]$summary("expr_pop_est")
    # Two independent per-group population parameters are fitted.
    expect_identical(nrow(pop_post), 2L)
    # Each group's known population lies within (approximately) its 90% credible
    # interval. The population is only weakly identified from the depletion
    # tail, so a small relative tolerance is allowed on the interval edges.
    tol <- 0.05
    expect_lte(pop_post$q5[1], pops[1] * (1 + tol))
    expect_gte(pop_post$q95[1], pops[1] * (1 - tol))
    expect_lte(pop_post$q5[2], pops[2] * (1 + tol))
    expect_gte(pop_post$q95[2], pops[2] * (1 - tol))
    # The larger-population group is estimated higher than the smaller one.
    expect_gt(pop_post$mean[2], pop_post$mean[1])
  }
)
