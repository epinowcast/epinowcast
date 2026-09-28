# see `help(run_script, package = 'touchstone')` on how to run this
# interactively

# installs branches to benchmark
touchstone::branch_install()

# run benchmarks
touchstone::benchmark_run(
  preprocessing = { source("touchstone/preprocessing.R") },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/threaded-setup.R") },
  simple_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(~1, data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 250,
      threads_per_chain = 2, parallel_chains = 1
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  simple_negbin_model_with_pp = { epinowcast(
    data = pobs,
    expectation = enw_expectation(~1, data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = TRUE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)


touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  day_of_week_model = { epinowcast(
    data = pobs,
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/missing-setup.R") },
  missingness_model = { epinowcast(
    data = pobs,
    missing = enw_missing(~ (1 | week), data = pobs),
    report = enw_report(~ (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  nonparametric_reference_model = { epinowcast(
    data = pobs,
    reference = enw_reference(
      parametric = ~0,
      non_parametric = ~ 1 + rw(delay) + (1 | day_of_week),
      data = pobs
    ),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ) },
  n = 3
)

# `latent_renewal_model` below is the renewal-expectation reference case
# (a non-trivial generation time, `generation_time` length 4, so
# `gt_n > 1` and the serial renewal loop in
# `log_expected_latent_from_r.stan` is exercised rather than the
# exponential-growth `gt_n == 1` shortcut). `simple_model` above is the
# plain intercept-only default case kept for reference.
touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  latent_renewal_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 1 + rw(week),
      generation_time = c(0.1, 0.4, 0.4, 0.1),
      observation = ~ (1 | day_of_week),
      latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
      data = pobs
    ),
    reference = enw_reference(~1, data = pobs),
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

# PENDING(#831): once PR #831 (susceptible-depletion adjustment for the
# renewal model, https://github.com/epinowcast/epinowcast/pull/831)
# merges, uncomment this cell below. It reuses the
# `latent_renewal_model` renewal configuration above (`generation_time`
# length 4, so `gt_n > 1`) and adds the susceptible-depletion adjustment
# via `enw_expectation()`'s new `population`, `population_floor`,
# `population_uncertain`, and `population_cv` arguments (see PR #831,
# `R/model-modules.R`). `population` is set deliberately small relative
# to the ~4800 cumulative confirmed cases in this window so the
# `fmax(0, pop - cum_cases)` / `1 - exp(-a_t)` floor branches in
# `log_expected_latent_from_r.stan` are actually exercised -- that is
# exactly where a custom reverse-mode adjoint (see the speed-up review,
# candidate 2.1) needs to match Stan's own `fmax` subgradient
# convention, so a benchmark/gradient-equivalence case that never
# reaches the floor is not useful.
# nolint start: commented_code_linter.
# touchstone::benchmark_run(
#   expr_before_benchmark = { source("touchstone/setup.R") },
#   latent_renewal_depletion_model = { epinowcast(
#     data = pobs,
#     expectation = enw_expectation(
#       r = ~ 1 + rw(week),
#       generation_time = c(0.1, 0.4, 0.4, 0.1),
#       observation = ~ (1 | day_of_week),
#       latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
#       population = 8000,
#       population_floor = 1,
#       data = pobs
#     ),
#     reference = enw_reference(~1, data = pobs),
#     report = enw_report(~(1 | day_of_week), data = pobs),
#     fit = enw_fit_opts(
#       save_warmup = FALSE, pp = FALSE,
#       chains = 2, iter_warmup = 500, iter_sampling = 500,
#       parallel_chains = 2
#     ),
#     obs = enw_obs(family = "negbin", data = pobs),
#     model = model
#   ) },
#   n = 3
# )
# nolint end

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  gp_growth_rate_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(r = ~ 1 + gp(week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "poisson", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/multigroup-setup.R") },
  multi_group_latent_renewal_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 1 + rw(week, by = .group),
      generation_time = c(0.1, 0.4, 0.4, 0.1),
      observation = ~ (1 | day_of_week),
      latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
      data = pobs
    ),
    reference = enw_reference(~1, data = pobs),
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

# Multi-group, day-of-week reporting model with many snapshots (six age
# groups x 60 reference dates, ~360 snapshots vs ~40 in the single-group
# default cells). Uses the default intercept-only expectation (no
# renewal loop) and reporting-date effects (`ref_as_p == 0`, so the
# hazard-to-probability conversion is not skipped), so the per-snapshot
# likelihood loop (`expected_obs_from_index()` /
# `combine_logit_hazards()` / `hazard_to_log_prob()`) dominates total
# cost rather than the renewal or reference-date submodules.
touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/many-snapshots-setup.R") },
  many_snapshots_dow_model = { epinowcast(
    data = pobs,
    report = enw_report(~(1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE,
      chains = 2, iter_warmup = 250, iter_sampling = 250,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

# Latent-dominated growth-rate models (no renewal), where the intercept
# centring of the integrated random-walk / GP drift has the most effect.
# The shared and grouped random-walk variants show the centring helps and
# that a grouped latent (each group its own series) still benefits; the
# integrated GP variant exercises the gp() centring. The centred geometry
# is sharper, so these run at the adapt_delta these models use (>= 0.95)
# rather than the cmdstanr default of 0.8.
touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  rw_growth_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(r = ~ 1 + rw(week), data = pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, adapt_delta = 0.95,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/multigroup-setup.R") },
  multi_group_rw_growth_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 1 + rw(week, by = .group), data = pobs
    ),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, adapt_delta = 0.95,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

touchstone::benchmark_run(
  expr_before_benchmark = { source("touchstone/setup.R") },
  gp_integrated_growth_model = { epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 1 + gp(week, d = 1), data = pobs
    ),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, adapt_delta = 0.99,
      chains = 2, iter_warmup = 500, iter_sampling = 500,
      parallel_chains = 2
    ),
    obs = enw_obs(family = "negbin", data = pobs),
    model = model
  ) },
  n = 3
)

# create artifacts used downstream in the GitHub Action.
touchstone::benchmark_analyze()
