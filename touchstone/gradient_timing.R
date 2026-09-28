#!/usr/bin/env Rscript
# Standalone per-gradient-evaluation timing script.
#
# NOT run by CI: the benchmarks GitHub Actions workflow only executes
# `touchstone/script.R` (via `touchstone::run_script()`); files in
# `touchstone/` that `script.R` does not `source()` are never picked up.
# Run this manually from the package root, e.g.:
#   Rscript touchstone/gradient_timing.R
#
# Purpose: touchstone's `benchmark_run()` cells measure whole-fit wall
# time, which conflates compilation, I/O, warm-up and sampler-path
# length (number of leapfrog steps) with the per-gradient cost of a
# change. A custom-adjoint PR changes the cost of one gradient
# evaluation, not the number of them, so this script reports time per
# gradient evaluation, for the C++ adjoints on (`use_cpp = TRUE`) and off
# (`use_cpp = FALSE`, the pure-Stan fallback), on the same data.
#
# Method: for each case, a short adapted chain gives a realistic starting
# point, step size and metric. Each arm then runs NUTS from that point
# with adaptation off and the same seed, step size and metric, and the
# time per gradient is the sampling time divided by the total number of
# leapfrog steps (one gradient each). This runs the compiled executables
# themselves: cmdstanr's `log_prob()`/`grad_log_prob()` model methods are
# compiled separately and cannot link the C++ header (`user_header`).

suppressMessages(library(data.table))
# Always load the local package source (not an installed copy): the
# point of this script is to time *this checkout's* Stan/R code, e.g. an
# adjoint PR's branch, so silently falling back to whatever version of
# epinowcast happens to be installed globally would defeat the purpose.
suppressMessages(devtools::load_all(".", quiet = TRUE))

cmdstanr::set_cmdstan_path()
options(mc.cores = 2)

# ---- Configuration ---------------------------------------------------

iter_timed <- 200 # NUTS iterations timed per arm and repeat
n_reps <- 3 # repeats per arm, alternating arms
seed <- 123

models <- list(
  cpp = enw_model(target_dir = "touchstone", verbose = FALSE),
  stan = enw_model(target_dir = "touchstone", use_cpp = FALSE, verbose = FALSE)
)

# One `build()` function per case: returns the preprocessed data (`pobs`)
# and the `epinowcast()` arguments (everything except `data`, `fit`,
# `model`), following the same configurations as the matching
# `touchstone/script.R` cells so the numbers here map directly onto
# them.
cases <- list(
  default = function() {
    source(file.path("touchstone", "preprocessing.R"), local = TRUE)
    list(
      pobs = pobs,
      expectation = enw_expectation(~1, data = pobs),
      obs = enw_obs(family = "poisson", data = pobs)
    )
  },
  renewal_gt4 = function() {
    source(file.path("touchstone", "preprocessing.R"), local = TRUE)
    list(
      pobs = pobs,
      expectation = enw_expectation(
        r = ~ 1 + rw(week),
        generation_time = c(0.1, 0.4, 0.4, 0.1),
        observation = ~ (1 | day_of_week),
        latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
        data = pobs
      ),
      reference = enw_reference(~1, data = pobs),
      report = enw_report(~ (1 | day_of_week), data = pobs),
      obs = enw_obs(family = "negbin", data = pobs)
    )
  },
  many_snapshots_dow = function() {
    source(file.path("touchstone", "many-snapshots-setup.R"), local = TRUE)
    list(
      pobs = pobs,
      report = enw_report(~ (1 | day_of_week), data = pobs),
      obs = enw_obs(family = "negbin", data = pobs)
    )
  },
  # Identical to `renewal_gt4` but with `population`/`population_floor`
  # added to the `enw_expectation()` call (PR #831), so the
  # `fmax(0, pop - cum_cases)` depletion-floor branches in
  # `log_expected_latent_from_r.stan` are exercised. This is the case
  # an adjoint's gradient-equivalence test (speed-up review, candidate
  # 2.1) should be timed against, since it is the only one that reaches
  # those branches.
  renewal_gt4_depletion = function() {
    source("touchstone/preprocessing.R", local = TRUE)
    list(
      pobs = pobs,
      expectation = enw_expectation(
        r = ~ 1 + rw(week),
        generation_time = c(0.1, 0.4, 0.4, 0.1),
        observation = ~ (1 | day_of_week),
        latent_reporting_delay = 0.4 * c(0.05, 0.3, 0.6, 0.05),
        population = 8000,
        population_floor = 1,
        data = pobs
      ),
      reference = enw_reference(~1, data = pobs),
      report = enw_report(~ (1 | day_of_week), data = pobs),
      obs = enw_obs(family = "negbin", data = pobs)
    )
  }
)

# ---- Timing helpers ----------------------------------------------------

#' Stan data and a short adapted chain for a case
#'
#' The chain is not a converged fit: it only supplies a realistic starting
#' point, step size and metric for the timed runs.
.setup_case <- function(case_args) {
  extra <- case_args[setdiff(names(case_args), "pobs")]
  inputs <- suppressMessages(do.call(epinowcast, c(
    list(
      data = case_args$pobs,
      fit = enw_fit_opts(
        sampler = function(init, data, ...) {
          data.table::data.table(init = list(init), data = list(data))
        }
      ),
      model = NULL
    ),
    extra
  )))
  stan_data <- inputs$data[[1]]
  adapted <- models$cpp$sample(
    data = stan_data, init = inputs$init[[1]], chains = 1,
    threads_per_chain = 1, iter_warmup = 200, iter_sampling = 1, seed = seed, refresh = 0,
    show_messages = FALSE
  )
  list(stan_data = stan_data, adapted = adapted)
}

#' Seconds per gradient evaluation for one arm
.time_per_gradient <- function(model, setup) {
  adapted <- setup$adapted
  fit <- model$sample(
    data = setup$stan_data, init = adapted, chains = 1,
    threads_per_chain = 1, iter_warmup = 0, iter_sampling = iter_timed, adapt_engaged = FALSE,
    step_size = adapted$metadata()$step_size_adaptation,
    inv_metric = adapted$inv_metric(matrix = FALSE)[[1]],
    seed = seed, refresh = 0, show_messages = FALSE
  )
  n_leapfrog <- sum(fit$sampler_diagnostics(format = "df")$n_leapfrog__)
  c(
    seconds = fit$time()$chains$sampling / n_leapfrog,
    n_leapfrog = n_leapfrog
  )
}

# ---- Run ---------------------------------------------------------------

results <- data.table::rbindlist(lapply(names(cases), function(case_name) {
  cat(sprintf("Timing case: %s\n", case_name))
  case_args <- cases[[case_name]]()
  setup <- .setup_case(case_args)
  timings <- data.table::rbindlist(lapply(seq_len(n_reps), function(rep) {
    data.table::rbindlist(lapply(names(models), function(arm) {
      t <- .time_per_gradient(models[[arm]], setup)
      data.table::data.table(
        arm = arm, rep = rep,
        us_per_gradient = t[["seconds"]] * 1e6,
        n_leapfrog = t[["n_leapfrog"]]
      )
    }))
  }))
  pobs <- case_args$pobs
  timings[, .(
    us_per_gradient = mean(us_per_gradient),
    us_per_gradient_sd = stats::sd(us_per_gradient),
    n_leapfrog = mean(n_leapfrog)
  ), by = arm][, `:=`(
    case = case_name,
    t = pobs$time[[1]],
    g = pobs$groups[[1]],
    s = pobs$snapshots[[1]],
    dmax = pobs$max_delay[[1]]
  )][]
}))

speedup <- data.table::dcast(results, case ~ arm, value.var = "us_per_gradient")
speedup[, speedup := stan / cpp]

cat("\n--- Machine ---\n")
cat("R version:", R.version.string, "\n")
cat("cmdstanr version:", as.character(utils::packageVersion("cmdstanr")), "\n")
cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")
cat("OS:", Sys.info()[["sysname"]], Sys.info()[["release"]], "\n")
cat("machine:", Sys.info()[["machine"]], "\n")

cat("\n--- Per-gradient-evaluation timing (microseconds) ---\n")
print(results)
cat("\n--- Speed-up of use_cpp = TRUE over use_cpp = FALSE ---\n")
print(speedup)
