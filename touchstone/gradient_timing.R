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
# draws.
#
# Method (in-sampler, no R round trip): fit each case with a fixed
# warm-up and sampling length, then take the primary per-gradient number
# straight from CmdStan's own accounting -- total chain time divided by
# the total leapfrog count (warm-up included). Each leapfrog step is one
# `grad_log_prob()` call, so this ratio is CmdStan's own per-gradient
# cost with no R call overhead in it at all.
#
# This replaces the previous method (repeatedly calling cmdstanr's
# `log_prob()`/`grad_log_prob()` R bindings on a fixed set of draws),
# which added 40-50 microseconds per call on the machine used for the
# adjoint-payoff analysis (`scratchpad/adjoint-payoff-analysis.md`,
# section 1.3): enough to swamp the few-microsecond differences a single
# adjoint is expected to make. That R-based number is still reported
# alongside the new one (as `*_r_call_us_*`), so the gap between the two
# stays visible rather than silently disappearing.

suppressMessages(library(data.table))
# Always load the local package source (not an installed copy): the
# point of this script is to time *this checkout's* Stan/R code, e.g. an
# adjoint PR's branch, so silently falling back to whatever version of
# epinowcast happens to be installed globally would defeat the purpose.
suppressMessages(devtools::load_all(".", quiet = TRUE))

cmdstanr::set_cmdstan_path()
options(mc.cores = 2)

# ---- Configuration ---------------------------------------------------

n_warmup <- 300 # matches the adjoint-payoff analysis's method
n_sampling <- 300
n_draws <- 20 # fixed draws re-used for the R-call comparison numbers
n_reps <- 50 # repeat calls per draw, for stable per-call timing
seed <- 123

# ---- Per-adjoint C++ toggle --------------------------------------------
#
# `enw_model(use_cpp = )` (once an adjoint PR merges) switches every
# custom C++ adjoint on the checkout at once. That is too coarse to
# attribute a whole-model change to one adjoint (adjoint-payoff
# analysis, section 1.3, "`use_cpp` switches every adjoint at once"):
# comparing only "all adjoints on" against "all off" cannot separate,
# say, the renewal adjoint's payoff from the hazard adjoint's. The
# helpers below let each case be timed once per named subset of
# adjoints, and fall back to a plain `enw_model()` call unchanged when
# the checkout has none (origin/main today).

#' Names of the C++ adjoints available on this checkout, if any.
.available_adjoints <- function() {
  ns <- asNamespace("epinowcast")
  if (!exists("stan_cpp_adjoint_files", envir = ns, inherits = FALSE)) {
    return(character(0))
  }
  fn <- utils::getFromNamespace("stan_cpp_adjoint_files", "epinowcast")
  unname(fn())
}

#' Build a model with exactly the requested adjoints compiled to C++.
#'
#' @param enabled Character vector of adjoint names to compile as C++
#' (from `.available_adjoints()`). Ignored, with a message, on a
#' checkout with no adjoints.
#' @param ... Passed to `enw_model()`.
.enw_model_for_adjoints <- function(enabled, ...) {
  has_use_cpp <- "use_cpp" %in% names(formals(epinowcast::enw_model))
  all_adj <- .available_adjoints()
  if (!has_use_cpp || length(all_adj) == 0) {
    return(epinowcast::enw_model(...))
  }
  if (!all(enabled %in% all_adj)) {
    cli::cli_abort("Unknown adjoint(s): {setdiff(enabled, all_adj)}.")
  }
  if (length(enabled) == 0) {
    return(epinowcast::enw_model(..., use_cpp = FALSE))
  }
  if (setequal(enabled, all_adj)) {
    return(epinowcast::enw_model(..., use_cpp = TRUE))
  }
  # `use_cpp` on every adjoint PR to date is an all-or-nothing switch
  # (one C++ header, compiled in or not), so an exact subset needs
  # per-function fallback-body substitution that does not exist yet.
  # Fail loudly rather than silently timing the wrong configuration.
  cli::cli_abort(c(
    "This checkout's {.fn enw_model} only supports all-or-nothing",
    "{.arg use_cpp}, not the requested subset {toString(enabled)}.",
    i = "Pass all of {toString(all_adj)} or none."
  ))
}

# One run per adjoint configuration: `character(0)` (every adjoint off,
# i.e. this checkout's pure-Stan state) always runs; if the checkout has
# adjoints, an "all adjoints on" run is added too. Edit this list to
# isolate a single adjoint, e.g. `list(renewal_only = "renewal_depletion")`,
# once more than one is available.
adjoint_configs <- local({
  all_adj <- .available_adjoints()
  cfg <- list(pure_stan = character(0))
  if (length(all_adj) > 0) cfg$all_adjoints <- all_adj
  cfg
})

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

#' Fit a case at a fixed warm-up/sampling length and return the fit
#' object plus a fixed set of unconstrained draws.
#'
#' `save_warmup = TRUE` and a realistic warm-up/sampling length (rather
#' than a short throwaway chain) matter here because the primary
#' per-gradient number comes straight from CmdStan's own chain-time and
#' leapfrog-count accounting (warm-up included), not from re-calling
#' `grad_log_prob()` in R.
.fit_case <- function(case_args, model, n_warmup, n_sampling, n_draws,
                      seed) {
  extra <- case_args[setdiff(names(case_args), "pobs")]
  fit <- suppressMessages(do.call(epinowcast, c(
    list(
      data = case_args$pobs,
      fit = enw_fit_opts(
        sampler = enw_sample,
        save_warmup = TRUE, pp = FALSE,
        chains = 1, parallel_chains = 1,
        iter_warmup = n_warmup, iter_sampling = n_sampling,
        refresh = 0, show_messages = FALSE, seed = seed
      ),
      model = model
    ),
    extra
  )))
  fit_obj <- fit$fit[[1]]

  diagnostics <- fit_obj$sampler_diagnostics(inc_warmup = TRUE)
  n_leapfrog <- sum(diagnostics[, , "n_leapfrog__"])
  chain_time_s <- fit_obj$time()$chains$total

  fit_obj$init_model_methods(seed = seed, verbose = FALSE)
  # `format = "draws_matrix"` gives an iterations x unconstrained-
  # parameters matrix; each row is one draw's unconstrained-parameter
  # vector, exactly what `log_prob()`/`grad_log_prob()` expect. Strided
  # rather than the first `n_draws` rows so the fixed draws spread
  # across the whole post-warm-up trajectory rather than its start.
  unconstrained <- fit_obj$unconstrain_draws(
    format = "draws_matrix", inc_warmup = FALSE
  )
  stride <- max(1, floor(nrow(unconstrained) / n_draws))
  idx <- pmin(seq_len(n_draws) * stride, nrow(unconstrained))
  draws <- lapply(idx, function(i) as.numeric(unconstrained[i, ]))

  list(
    fit_obj = fit_obj, draws = draws,
    n_leapfrog = n_leapfrog, chain_time_s = chain_time_s
  )
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

results <- data.table::rbindlist(lapply(
  names(adjoint_configs),
  function(config_name) {
    enabled <- adjoint_configs[[config_name]]
    cat(sprintf("Adjoint configuration: %s\n", config_name))
    # `compile_model_methods` builds the Rcpp bindings `log_prob()` /
    # `grad_log_prob()` need (still used for the R-call comparison
    # numbers); `force_recompile` is required because `target_dir` may
    # already hold a cached executable built without those bindings.
    model <- .enw_model_for_adjoints(
      enabled,
      target_dir = file.path("touchstone", config_name),
      compile_model_methods = TRUE,
      force_recompile = TRUE
    )

    data.table::rbindlist(lapply(names(cases), function(case_name) {
      cat(sprintf("  Timing case: %s\n", case_name))
      case_args <- cases[[case_name]]()
      fd <- .fit_case(
        case_args, model,
        n_warmup = n_warmup, n_sampling = n_sampling,
        n_draws = n_draws, seed = seed
      )
      fit_obj <- fd$fit_obj
      draws <- fd$draws
      grad_us_in_sampler <- 1e6 * fd$chain_time_s / fd$n_leapfrog

      # Untimed warm-up call: the first `log_prob()`/`grad_log_prob()`
      # call after `init_model_methods()` pays a one-off cache/JIT cost
      # that can otherwise dominate the mean of a small `n_reps`.
      invisible(fit_obj$grad_log_prob(draws[[1]], jacobian = TRUE))

      logprob_us <- .time_calls(
        function(d) fit_obj$log_prob(d, jacobian = TRUE), draws, n_reps
      )
      grad_us_r_call <- .time_calls(
        function(d) fit_obj$grad_log_prob(d, jacobian = TRUE), draws, n_reps
      )

      pobs <- case_args$pobs
      data.table::data.table(
        adjoint_config = config_name,
        case = case_name,
        n_draws = length(draws),
        n_reps = n_reps,
        t = pobs$time[[1]],
        g = pobs$groups[[1]],
        s = pobs$snapshots[[1]],
        dmax = pobs$max_delay[[1]],
        n_leapfrog = fd$n_leapfrog,
        chain_time_s = fd$chain_time_s,
        grad_log_prob_us_in_sampler = grad_us_in_sampler,
        log_prob_us_r_call_mean = logprob_us[["mean"]],
        log_prob_us_r_call_sd = logprob_us[["sd"]],
        grad_log_prob_us_r_call_mean = grad_us_r_call[["mean"]],
        grad_log_prob_us_r_call_sd = grad_us_r_call[["sd"]]
      )
    }))
  }
))

cat("\n--- Machine ---\n")
cat("R version:", R.version.string, "\n")
cat("cmdstanr version:", as.character(utils::packageVersion("cmdstanr")), "\n")
cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")
cat("OS:", Sys.info()[["sysname"]], Sys.info()[["release"]], "\n")
cat("machine:", Sys.info()[["machine"]], "\n")

cat("\n--- Per-gradient-evaluation timing ---\n")
cat("`grad_log_prob_us_in_sampler` is the primary number: CmdStan's own\n")
cat("chain time / total leapfrog count, no R call overhead.\n")
cat("The `*_r_call_*` columns are the previous (R round-trip) method,\n")
cat("kept for comparison; expect them to run ~40-50us higher.\n")
print(results)
