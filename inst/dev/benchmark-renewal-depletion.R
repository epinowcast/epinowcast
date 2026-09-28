#!/usr/bin/env Rscript
# Benchmark the renewal_depletion() C++ adjoint against the pure-Stan
# fallback (enw_model(use_cpp = TRUE) vs use_cpp = FALSE).
#
# Measures two things, on a synthetic single-group line list with a
# length-4 generation time (gt_n > 1, so the renewal loop replaced by
# renewal_depletion() is actually exercised) and susceptible depletion
# enabled with the population set close to the cumulative case count
# (so the fmax()-guarded depletion branches bind, not just the
# unconstrained renewal recursion):
#
#  - Profiled time in `profile("transformed_expected_final_observations")`
#    (epinowcast.stan), which wraps the expectation-model block including
#    the growth-rate regression and log_expected_latent_from_r() (and so
#    renewal_depletion()) -- the same granularity the existing model
#    exposes; not an isolated timer for renewal_depletion() alone
#    (enw_model(profile = TRUE) is needed to keep profiling statements,
#    since enw_model()'s default strips them).
#  - Total sampling wall-clock time for the whole fit ($time()$total).
#
# Not wired into CI or touchstone; a one-off script to produce the
# numbers quoted in the renewal adjoint PR description. Run with:
#   Rscript inst/dev/benchmark-renewal-depletion.R
# from the package root, with cmdstanr and a working CmdStan installed.

suppressPackageStartupMessages({
  library(epinowcast)
  library(data.table)
})

n_reps <- 5L
iter_warmup <- 500L
iter_sampling <- 500L
seed <- 101L

# A depleting epidemic: population close to the cumulative case count so
# the fmax(0, pop - cum_cases) / fmax(pop_floor, .) branches actually bind
# over the series, not just the unconstrained renewal recursion.
simulate_depleting_epidemic <- function(population, rt, generation_time,
                                        n_days, seed_cases) {
  gt_n <- length(generation_time)
  rgt <- rev(generation_time)
  inc <- rep(seed_cases, n_days)
  cum_cases <- sum(inc[seq_len(gt_n)])
  for (i in (gt_n + 1):n_days) {
    infectiousness <- sum(inc[(i - gt_n):(i - 1)] * rgt)
    remaining <- max(0, population - cum_cases)
    inc[i] <- remaining * (1 - exp(-rt * infectiousness / max(1, remaining)))
    cum_cases <- cum_cases + inc[i]
  }
  inc
}

set.seed(seed)
gt <- c(0.2, 0.3, 0.3, 0.2)
population <- 8000
n_days <- 60
inc <- simulate_depleting_epidemic(
  population = population, rt = 1.6, generation_time = gt,
  n_days = n_days, seed_cases = 5
)
counts <- rpois(n_days, pmax(inc, 1e-3))
dates <- as.Date("2021-01-01") + seq_len(n_days) - 1
obs <- data.table(reference_date = dates, report_date = dates, confirm = counts) # nolint
pobs <- suppressWarnings(enw_preprocess_data(
  enw_complete_dates(obs, max_delay = 2), max_delay = 2
))

expectation <- enw_expectation(
  r = ~ 0 + (1 | day:.group), generation_time = gt,
  population = population, population_floor = 1, data = pobs
)
reference <- enw_reference(data = pobs)
report <- enw_report(data = pobs)

fit_opts <- enw_fit_opts(
  sampler = enw_sample,
  save_warmup = FALSE, pp = FALSE, chains = 1, parallel_chains = 1,
  iter_warmup = iter_warmup, iter_sampling = iter_sampling, seed = seed,
  show_messages = FALSE, show_exceptions = FALSE, refresh = 0
)

run_once <- function(use_cpp) {
  model <- enw_model(
    verbose = FALSE, use_cpp = use_cpp, profile = TRUE,
    target_dir = withr::local_tempdir(), dir = withr::local_tempdir()
  )
  nowcast <- suppressWarnings(suppressMessages(epinowcast(
    pobs,
    expectation = expectation, reference = reference, report = report,
    fit = fit_opts, model = model
  )))
  fit <- nowcast$fit[[1]]
  profiles <- fit$profiles()[[1]]
  expectation_row <- profiles[
    profiles$name == "transformed_expected_final_observations",
  ]
  data.table(
    use_cpp = use_cpp,
    total_time_s = fit$time()$total,
    expectation_block_time_s = sum(expectation_row$total_time),
    expectation_block_calls = sum(expectation_row$autodiff_calls)
  )
}

cli::cli_alert_info("Compiling and running {n_reps} reps per arm...")
results <- rbindlist(lapply(seq_len(n_reps), function(i) {
  rbindlist(list(run_once(TRUE), run_once(FALSE)))
}))

summary_dt <- results[, .(
  mean_total_time_s = mean(total_time_s),
  mean_expectation_block_time_s = mean(expectation_block_time_s),
  mean_expectation_block_calls = mean(expectation_block_calls)
), by = use_cpp]

cli::cli_h1("Benchmark results ({n_reps} reps each)")
print(summary_dt)

speedup_total <- summary_dt[use_cpp == FALSE, mean_total_time_s] /
  summary_dt[use_cpp == TRUE, mean_total_time_s]
speedup_expectation <-
  summary_dt[use_cpp == FALSE, mean_expectation_block_time_s] /
  summary_dt[use_cpp == TRUE, mean_expectation_block_time_s]

cli::cli_alert_info("Total sampling time speed-up (cpp vs pure-Stan): {round(speedup_total, 2)}x") # nolint
cli::cli_alert_info("Expectation-block speed-up (cpp vs pure-Stan): {round(speedup_expectation, 2)}x") # nolint
