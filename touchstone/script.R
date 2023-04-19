# see `help(run_script, package = 'touchstone')` on how to run this
# interactively

# installs branches to benchmark
touchstone::branch_install()

touchstone::pin_assets("touchstone")

# run benchmarks
touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  simple = { epinowcast(
    data = pobs,
    expectation = enw_expectation(~1, data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
    ),
    obs = enw_obs(family = "poisson", data = pobs)
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  day_of_week = { epinowcast(
    data = pobs,
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
    ),
    obs = enw_obs(family = "poisson", data = pobs)
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/missing-setup.R") },
  missingness = { epinowcast(
    data = pobs,
    missing = enw_missing(~ (1 | week), data = pobs),
    report = enw_report(~ (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
    ),
    obs = enw_obs(family = "poisson", data = pobs)
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  latent_renewal = { epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 0 + (1 | day),
      generation_time = c(0.1, 0.4, 0.4, 0.1),
      observation = ~ (1 | day_of_week),
      latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
      data = pobs
    ),
    reference = enw_reference(~1, data = pobs),
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
    ),
    obs = enw_obs(family = "poisson", data = pobs)
  ) },
  n = 3
)

# create artifacts used downstream in the GitHub Action.
touchstone::benchmark_analyze()
