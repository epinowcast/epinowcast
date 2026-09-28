#!/usr/bin/env Rscript
# Benchmark the logit_hazard_to_log_prob() C++ adjoint against the pure-Stan
# fallback (enw_model(use_cpp = TRUE) vs use_cpp = FALSE).
#
# Measures two things, on the package's small day-of-week example model
# (enw_example("preprocessed") with a `~ 1 + day_of_week` report model, so
# ref_as_p == 0 and the hazard-conversion code path is actually exercised):
#
#  - Profiled time in the hazard-conversion block specifically, via the
#    `profile("model_likelihood_expected_obs_logit_hazard_to_log_prob")`
#    block already in expected_obs.stan (enw_model(profile = TRUE) is
#    needed to keep profiling statements in; enw_model()'s default strips
#    them, since profiling has its own small overhead). This isolates the
#    changed code from the rest of the model's cost.
#  - Total sampling wall-clock time for the whole fit ($time()$total).
#
# Not wired into CI or touchstone; a one-off script to produce the numbers
# quoted in the C++ adjoints PR description. Run with:
#   Rscript inst/dev/benchmark-cpp-adjoints.R
# from the package root, with cmdstanr and a working CmdStan installed.

suppressPackageStartupMessages({
  library(epinowcast)
  library(data.table)
})

n_reps <- 5L
iter_warmup <- 500L
iter_sampling <- 500L
seed <- 101L

pobs <- enw_example("preprocessed")
expectation <- enw_expectation(data = pobs)
reference <- enw_reference(data = pobs)
report <- enw_report(~ 1 + day_of_week, data = pobs)

fit_opts <- enw_fit_opts(
  sampler = enw_sample,
  save_warmup = FALSE, pp = FALSE, chains = 1, parallel_chains = 1,
  iter_warmup = iter_warmup, iter_sampling = iter_sampling, seed = seed,
  show_messages = FALSE, show_exceptions = FALSE, refresh = 0
)

run_once <- function(use_cpp) {
  # `dir` is passed through to cmdstan_model(): with profile = TRUE (kept
  # so the profile() blocks used below survive), enw_model() compiles
  # in place next to the (unmodified) installed .stan file unless `dir`
  # is given, which needs a writable package install location.
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
  hazard_row <- profiles[
    profiles$name == "model_likelihood_expected_obs_logit_hazard_to_log_prob",
  ]
  data.table(
    use_cpp = use_cpp,
    total_time_s = fit$time()$total,
    hazard_block_time_s = sum(hazard_row$total_time),
    hazard_block_calls = sum(hazard_row$autodiff_calls)
  )
}

cli::cli_alert_info("Compiling and running {n_reps} reps per arm...")
results <- rbindlist(lapply(seq_len(n_reps), function(i) {
  rbindlist(list(run_once(TRUE), run_once(FALSE)))
}))

summary_dt <- results[, .(
  mean_total_time_s = mean(total_time_s),
  mean_hazard_block_time_s = mean(hazard_block_time_s),
  mean_hazard_block_calls = mean(hazard_block_calls)
), by = use_cpp]

cli::cli_h1("Benchmark results ({n_reps} reps each)")
print(summary_dt)

speedup_total <- summary_dt[use_cpp == FALSE, mean_total_time_s] /
  summary_dt[use_cpp == TRUE, mean_total_time_s]
speedup_hazard <- summary_dt[use_cpp == FALSE, mean_hazard_block_time_s] /
  summary_dt[use_cpp == TRUE, mean_hazard_block_time_s]

cli::cli_alert_info("Total sampling time speed-up (cpp vs pure-Stan): {round(speedup_total, 2)}x") # nolint
cli::cli_alert_info("Hazard-conversion block speed-up (cpp vs pure-Stan): {round(speedup_hazard, 2)}x") # nolint
