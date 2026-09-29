#!/usr/bin/env Rscript
# Benchmark the convolve_with_rev_pmf() C++ adjoint against the pure-Stan
# fallback (enw_model(use_cpp = TRUE) vs use_cpp = FALSE).
#
# Uses a model with an exponential-growth expectation (r = ~1,
# generation_time = 1, so log_expected_latent_from_r() takes its O(1)
# cumulative_sum() branch, not the renewal-loop branch) and a long
# latent_reporting_delay, so cost inside the
# profile("transformed_expected_final_observations") block (which wraps
# both the growth-rate step and the delay convolution together; there is
# no finer-grained profile block that isolates the convolution alone) is
# dominated by log_expected_obs_from_latent()'s convolve_with_rev_pmf()
# call, not by the growth-rate step.
#
# Not wired into CI or touchstone; a one-off script to produce the numbers
# quoted in the delay-convolution adjoint PR description. Run with:
#   Rscript inst/dev/benchmark-cpp-adjoints-convolve.R
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
delay_pmf <- stats::dgamma(1:15, shape = 3, rate = 0.5)
delay_pmf <- delay_pmf / sum(delay_pmf)
expectation <- enw_expectation(
  r = ~1, generation_time = 1, latent_reporting_delay = delay_pmf,
  data = pobs
)
reference <- enw_reference(data = pobs)

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
    expectation = expectation, reference = reference, fit = fit_opts,
    model = model
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
speedup_expectation <- summary_dt[
  use_cpp == FALSE, mean_expectation_block_time_s
] / summary_dt[use_cpp == TRUE, mean_expectation_block_time_s]

cli::cli_alert_info("Total sampling time speed-up (cpp vs pure-Stan): {round(speedup_total, 2)}x") # nolint
cli::cli_alert_info("Expectation-block (growth rate + convolution) speed-up (cpp vs pure-Stan): {round(speedup_expectation, 2)}x") # nolint
