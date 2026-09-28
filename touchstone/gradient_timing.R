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
# length (number of leapfrog steps) with the actual per-gradient cost of
# a change. A custom-adjoint PR (see the speed-up review, candidate 2.1)
# changes the cost of a single `grad_log_prob()` call, not the number of
# times it is called, so the number that actually demonstrates its
# payoff is per-gradient-evaluation time at a *fixed* set of parameter
# draws -- comparing before/after touchstone wall times is confounded by
# NUTS trajectory-length variance (see the PR #804 review note in the
# scratchpad: "full wall-clock fit time on this small test fixture is
# noisy and seed-dependent").
#
# Method: for each benchmark case, fit a short chain to get realistic
# posterior-region draws, fix those draws, then repeatedly call
# cmdstanr's `log_prob()` (forward pass only) and `grad_log_prob()`
# (forward + reverse) at each fixed draw and report the mean per-call
# time. This is the same `log_prob`/`grad_log_prob` mechanism, and the
# same forward-vs-total framing, used in the PR #804 review
# (`scratchpad/pr-804-csr.md`), adapted from Stan-profile-block timing
# to cmdstanr's direct model-method interface so it works for any case,
# not just ones with `profile(...)` blocks around the target code.

suppressMessages(library(data.table))
# Always load the local package source (not an installed copy): the
# point of this script is to time *this checkout's* Stan/R code, e.g. an
# adjoint PR's branch, so silently falling back to whatever version of
# epinowcast happens to be installed globally would defeat the purpose.
suppressMessages(devtools::load_all(".", quiet = TRUE))

cmdstanr::set_cmdstan_path()
options(mc.cores = 2)

# ---- Configuration ---------------------------------------------------

n_draws <- 20 # fixed number of parameter draws timed per case
n_reps <- 50 # repeat calls per draw, for stable per-call timing
seed <- 123

# `compile_model_methods` builds the Rcpp bindings `log_prob()` /
# `grad_log_prob()` need; `force_recompile` is required because
# `target_dir = "touchstone"` may already hold a cached executable built
# without those bindings (e.g. from `touchstone/script.R`'s own
# `enw_model(target_dir = "touchstone")` calls).
model <- enw_model(
  target_dir = "touchstone",
  compile_model_methods = TRUE,
  force_recompile = TRUE
)

# One `build()` function per case: returns the preprocessed data (`pobs`)
# and the `epinowcast()` arguments (everything except `data`, `fit`,
# `model`), following the same configurations as the matching
# `touchstone/script.R` cells so the numbers here map directly onto
# them.
cases <- list(
  default = function() {
    source("touchstone/preprocessing.R", local = TRUE)
    list(
      pobs = pobs,
      expectation = enw_expectation(~1, data = pobs),
      obs = enw_obs(family = "poisson", data = pobs)
    )
  },
  renewal_gt4 = function() {
    source("touchstone/preprocessing.R", local = TRUE)
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
    source("touchstone/many-snapshots-setup.R", local = TRUE)
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

#' Fit a case briefly and return a fixed set of unconstrained draws
#'
#' A short chain (not a converged fit) is enough: we only need parameter
#' values in a realistic posterior region, not inference, since we are
#' timing the cost of one gradient evaluation, not the sampler.
.fixed_draws <- function(case_args, n_draws, seed) {
  extra <- case_args[setdiff(names(case_args), "pobs")]
  fit <- suppressMessages(do.call(epinowcast, c(
    list(
      data = case_args$pobs,
      fit = enw_fit_opts(
        sampler = enw_sample,
        save_warmup = FALSE, pp = FALSE,
        chains = 1, parallel_chains = 1,
        iter_warmup = 200, iter_sampling = n_draws,
        refresh = 0, show_messages = FALSE, seed = seed
      ),
      model = model
    ),
    extra
  )))
  fit_obj <- fit$fit[[1]]
  fit_obj$init_model_methods(seed = seed, verbose = FALSE)
  # `format = "draws_matrix"` gives an iterations x unconstrained-
  # parameters matrix; each row is one draw's unconstrained-parameter
  # vector, exactly what `log_prob()`/`grad_log_prob()` expect.
  unconstrained <- fit_obj$unconstrain_draws(format = "draws_matrix")
  n <- min(n_draws, nrow(unconstrained))
  draws <- lapply(seq_len(n), function(i) as.numeric(unconstrained[i, ]))
  list(fit_obj = fit_obj, draws = draws)
}

#' Mean per-call time (microseconds) of `f` applied to each element of
#' `draws`, each repeated `n_reps` times.
.time_calls <- function(f, draws, n_reps) {
  per_draw_us <- vapply(draws, function(draw) {
    t0 <- proc.time()[["elapsed"]]
    for (i in seq_len(n_reps)) f(draw)
    elapsed <- proc.time()[["elapsed"]] - t0
    (elapsed / n_reps) * 1e6
  }, numeric(1))
  c(mean = mean(per_draw_us), sd = stats::sd(per_draw_us))
}

# ---- Run ---------------------------------------------------------------

results <- data.table::rbindlist(lapply(names(cases), function(case_name) {
  cat(sprintf("Timing case: %s\n", case_name))
  case_args <- cases[[case_name]]()
  fd <- .fixed_draws(case_args, n_draws = n_draws, seed = seed)
  fit_obj <- fd$fit_obj
  draws <- fd$draws

  # Untimed warm-up call: the first `log_prob()`/`grad_log_prob()` call
  # after `init_model_methods()` pays a one-off cache/JIT cost that can
  # otherwise dominate the mean of a small `n_reps`.
  invisible(fit_obj$grad_log_prob(draws[[1]], jacobian = TRUE))

  logprob_us <- .time_calls(
    function(d) fit_obj$log_prob(d, jacobian = TRUE), draws, n_reps
  )
  grad_us <- .time_calls(
    function(d) fit_obj$grad_log_prob(d, jacobian = TRUE), draws, n_reps
  )

  pobs <- case_args$pobs
  data.table::data.table(
    case = case_name,
    n_draws = length(draws),
    n_reps = n_reps,
    t = pobs$time[[1]],
    g = pobs$groups[[1]],
    s = pobs$snapshots[[1]],
    dmax = pobs$max_delay[[1]],
    log_prob_us_mean = logprob_us[["mean"]],
    log_prob_us_sd = logprob_us[["sd"]],
    grad_log_prob_us_mean = grad_us[["mean"]],
    grad_log_prob_us_sd = grad_us[["sd"]]
  )
}))

cat("\n--- Machine ---\n")
cat("R version:", R.version.string, "\n")
cat("cmdstanr version:", as.character(utils::packageVersion("cmdstanr")), "\n")
cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")
cat("OS:", Sys.info()[["sysname"]], Sys.info()[["release"]], "\n")
cat("machine:", Sys.info()[["machine"]], "\n")

cat("\n--- Per-gradient-evaluation timing ---\n")
cat("(fixed draws, n_draws x n_reps calls each)\n")
print(results)
