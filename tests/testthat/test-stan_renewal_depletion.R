skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Tests for the custom reverse-mode adjoint renewal_depletion(), which
# replaces the `gt_n > 1` loop in log_expected_latent_from_r() (see
# inst/stan/functions/log_expected_latent_from_r.stan and the derivation
# in scratchpad/renewal-adjoint-log.md). Both test models below include
# the package's real inst/stan/functions/renewal_depletion.stan and
# renewal_depletion_stan.stan (via include_paths) rather than local
# copies, so they stay byte-identical to what enw_model() compiles.

stan_include <- function() {
  system.file("stan", package = "epinowcast")
}

# Stan-only model (no undefined-function declaration), usable without a
# C++ toolchain.
renewal_stan_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_renewal_depletion_stan.stan"),
    include_paths = stan_include(),
    quiet = TRUE
  )
}

# Always calls the C++ renewal_depletion(). Needs the package's C++
# header (epinowcast_stan_header()) as user_header, which cmdstanr's
# compile() passes `allow-undefined` for automatically.
renewal_cpp_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_renewal_depletion_cpp.stan"),
    include_paths = stan_include(),
    user_header = epinowcast_stan_header(),
    quiet = TRUE
  )
}

# Dispatcher model switching between renewal_depletion() and
# renewal_depletion_stan() on a runtime use_cpp data flag; used only for
# the fixed_param value-parity test below, not for gradients (cmdstanr's
# compile_model_methods build does not link a user_header, so
# log_prob()/grad_log_prob() are unavailable on a C++-backed model; the
# gradient tests use $diagnose() against renewal_cpp_model() and
# renewal_stan_model() instead, which needs no such support).
renewal_dispatch_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_renewal_depletion.stan"),
    include_paths = stan_include(),
    user_header = epinowcast_stan_header(),
    quiet = TRUE
  )
}

# Cases spanning both branches (use_pop 0/1), the pop_floor boundary, a
# generation time of length one, a tiny pool (floor binds) and a large one.
renewal_cases <- list(
  list(n0 = 3, r_t = 20, use_pop = 0, pop = 0, floor = 1),
  list(n0 = 3, r_t = 20, use_pop = 1, pop = 1e4, floor = 1),
  list(n0 = 1, r_t = 15, use_pop = 1, pop = 1e3, floor = 1),
  list(n0 = 5, r_t = 30, use_pop = 1, pop = 100, floor = 50),
  list(n0 = 3, r_t = 10, use_pop = 1, pop = 5, floor = 1)
)

renewal_inputs <- function(case) {
  gt <- rexp(case$n0)
  list(
    seed = as.array(5 * exp(rnorm(case$n0))),
    R = as.array(exp(0.2 * rnorm(case$r_t) + 0.2)),
    rgt = as.array(gt / sum(gt))
  )
}

no_param_data <- function(case, x) {
  list(
    n0 = case$n0, r_t = case$r_t, use_pop = case$use_pop,
    pop_floor = case$floor, seed_data = x$seed, R_data = x$R,
    rgt_data = x$rgt, pop_data = case$pop,
    r = as.array(rep(0, case$n0 + case$r_t)),
    seed_param = 0L, R_param = 0L, rgt_param = 0L, pop_param = 0L
  )
}

run_stan_case <- function(model, case, x) {
  fit <- model$sample(
    data = no_param_data(case, x),
    fixed_param = TRUE, iter_sampling = 1, chains = 1, sig_figs = 18,
    refresh = 0, show_messages = FALSE
  )
  as.vector(fit$draws("z_data", format = "matrix")[1, ])
}

# The defining identity of each new value, evaluated on the past values of
# the output itself: I_u = R_i * lambda_i, or remaining * (1 - exp(-R_i *
# lambda_i / denom)) with depletion, where remaining = max(0, pop - cum
# cases before step i) and denom = max(pop_floor, remaining).
renewal_identity <- function(inf, case, x) {
  n0 <- case$n0
  vapply(seq_len(case$r_t), function(i) {
    lambda <- sum(x$rgt * inf[i:(i + n0 - 1)])
    if (case$use_pop) {
      cum_before <- sum(inf[seq_len(n0 + i - 1)])
      remaining <- max(0, case$pop - cum_before)
      denom <- max(case$floor, remaining)
      max(1e-8, remaining * (1 - exp(-x$R[i] * lambda / denom)))
    } else {
      x$R[i] * lambda
    }
  }, numeric(1))
}

test_that("renewal_depletion_stan passes the seeds through unchanged", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model <- renewal_stan_model()
  set.seed(123)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    inf <- run_stan_case(model, case, x)
    expect_length(inf, case$n0 + case$r_t)
    expect_equal(inf[seq_len(case$n0)], as.vector(x$seed), tolerance = 1e-10)
  }
})

test_that("renewal_depletion_stan satisfies the renewal identity", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model <- renewal_stan_model()
  set.seed(123)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    inf <- run_stan_case(model, case, x)
    expect_equal(
      inf[-seq_len(case$n0)], renewal_identity(inf, case, x),
      tolerance = 1e-9
    )
  }
})

test_that("renewal_depletion_stan matches log_expected_latent_from_r", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  # log_expected_latent_from_r() is exposed globally in setup.R on Linux CI;
  # elsewhere this test is skipped along with the rest of the file.
  skip_if_not(exists("log_expected_latent_from_r"))
  model <- renewal_stan_model()
  set.seed(456)
  for (case in renewal_cases[vapply(renewal_cases, `[[`, logical(1), "use_pop") == 1]) { # nolint: line_length_linter.
    x <- renewal_inputs(case)
    inf_stan <- run_stan_case(model, case, x)
    # log_expected_latent_from_r() takes lrgt (exponentiated internally),
    # and test-stan_log_expected_latent_from_r.R's own run_renewal() helper
    # establishes that lrgt = rev(log(generation_time)), i.e. the rgt used
    # inside the dot product is rev(generation_time). Passing the same
    # reversed vector as this test's `rgt` keeps both functions' internal
    # `rgt` identical.
    lexp_latent_int <- matrix(log(x$seed), nrow = case$n0, ncol = 1)
    out <- log_expected_latent_from_r(
      lexp_latent_int, log(as.numeric(x$R)), array(0L), case$r_t, case$n0,
      case$n0, log(rev(x$rgt)), case$n0 + case$r_t, 1L, array(case$pop), 1L,
      case$floor
    )
    inf_model <- exp(out[[1]])
    expect_equal(inf_stan, inf_model, tolerance = 1e-9)
  }
})

test_that("renewal_depletion_stan log_prob gradients match finite differences", { # nolint: line_length_linter.
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model <- renewal_stan_model()
  params <- expand.grid(seed = 0:1, R = 0:1, rgt = 0:1, pop = 0:1)[-1, ]
  set.seed(789)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    for (i in seq_len(nrow(params))) {
      p <- params[i, ]
      data <- c(
        list(
          n0 = case$n0, r_t = case$r_t, use_pop = case$use_pop,
          pop_floor = case$floor, seed_data = x$seed, R_data = x$R,
          rgt_data = x$rgt, pop_data = case$pop,
          r = as.array(rnorm(case$n0 + case$r_t))
        ),
        setNames(as.list(as.integer(p)), paste0(names(p), "_param"))
      )
      # $diagnose() (CmdStan's own gradient-check mode) evaluates the
      # analytic ("model") and central-finite-difference gradients at a
      # random init point on the unconstrained scale; comparing them
      # here needs no model_methods support, unlike log_prob()/
      # grad_log_prob(). error = 1e-3 (looser than CmdStan's 1e-6
      # default) stops $diagnose() itself erroring out on ordinary
      # finite-difference noise; the actual comparison below uses its
      # own, explicit tolerance.
      diag <- model$diagnose(data = data, seed = i, error = 1e-3)
      grads <- diag$gradients()
      # Central finite differences (epsilon = 1e-6 default) of a chained
      # r_t-step recurrence accumulate more rounding error than the
      # tight analytic-vs-analytic comparisons below, so this tolerance
      # is looser.
      expect_equal(grads$model, grads$finite_diff, tolerance = 1e-4)
    }
  }
})

test_that("renewal_depletion() C++ adjoint matches the Stan reference", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model <- renewal_dispatch_model()
  run_dispatch_case <- function(use_cpp, case, x) {
    fit <- model$sample(
      data = c(no_param_data(case, x), list(use_cpp = use_cpp)),
      fixed_param = TRUE, iter_sampling = 1, chains = 1, sig_figs = 18,
      refresh = 0, show_messages = FALSE
    )
    as.vector(fit$draws("z_data", format = "matrix")[1, ])
  }
  set.seed(123)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    inf_stan <- run_dispatch_case(0L, case, x)
    inf_cpp <- run_dispatch_case(1L, case, x)
    expect_equal(inf_cpp, inf_stan, tolerance = 1e-12)
  }
})

test_that("renewal_depletion() gradients match the Stan reference", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model_cpp <- renewal_cpp_model()
  model_stan <- renewal_stan_model()
  params <- expand.grid(seed = 0:1, R = 0:1, rgt = 0:1, pop = 0:1)[-1, ]
  set.seed(321)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    for (i in seq_len(nrow(params))) {
      p <- params[i, ]
      data <- c(
        list(
          n0 = case$n0, r_t = case$r_t, use_pop = case$use_pop,
          pop_floor = case$floor, seed_data = x$seed, R_data = x$R,
          rgt_data = x$rgt, pop_data = case$pop,
          r = as.array(rnorm(case$n0 + case$r_t))
        ),
        setNames(as.list(as.integer(p)), paste0(names(p), "_param"))
      )
      # Same data and the same $diagnose() seed give both models the
      # same (random) unconstrained init point, so their analytic
      # gradients ("model") and log-densities can be compared directly.
      # error = 1e-3: see the note in the finite-differences test above.
      diag_cpp <- model_cpp$diagnose(data = data, seed = i, error = 1e-3)
      diag_stan <- model_stan$diagnose(data = data, seed = i, error = 1e-3)
      expect_equal(diag_cpp$lp(), diag_stan$lp(), tolerance = 1e-10)
      expect_equal(
        diag_cpp$gradients()$model, diag_stan$gradients()$model,
        tolerance = 1e-8
      )
    }
  }
})

test_that("renewal_depletion() full-model log_prob/grad_log_prob parity", {
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")

  # A small line list with a real generation time and susceptible
  # depletion enabled, so the compiled model actually exercises
  # renewal_depletion() (gt_n > 1, use_pop = 1) rather than the
  # exponential-growth branch.
  set.seed(999)
  gt <- c(0.3, 0.4, 0.3)
  population <- 500
  n_days <- 30
  inc <- rep(5, n_days)
  cum_cases <- sum(inc[seq_len(length(gt))])
  for (i in (length(gt) + 1):n_days) {
    infectiousness <- sum(inc[(i - length(gt)):(i - 1)] * rev(gt))
    remaining <- max(0, population - cum_cases)
    inc[i] <- remaining * (1 - exp(-1.6 * infectiousness / max(1, remaining)))
    cum_cases <- cum_cases + inc[i]
  }
  counts <- rpois(n_days, pmax(inc, 1e-3))
  dates <- as.Date("2021-01-01") + seq_len(n_days) - 1
  obs <- data.table::data.table(
    reference_date = dates, report_date = dates, confirm = counts
  )
  pobs <- suppressWarnings(enw_preprocess_data(
    enw_complete_dates(obs, max_delay = 2), max_delay = 2
  ))

  # Capture the assembled Stan data list without sampling (same trick as
  # helper-functions.R's epinowcast_as_data()).
  built <- epinowcast(
    data = pobs,
    expectation = enw_expectation(
      r = ~ 0 + (1 | day:.group), generation_time = gt,
      population = population, population_floor = 1, data = pobs
    ),
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        data.table::data.table(init = list(init), data = list(data))
      }
    ),
    model = NULL
  )
  stan_data <- built$data[[1]]

  # $diagnose() with the same seed gives both models the same random
  # unconstrained init point across the full parameter set, without
  # needing compile_model_methods (which does not link a user_header).
  diag_cpp <- enw_model(use_cpp = TRUE, verbose = FALSE)$diagnose(
    data = stan_data, seed = 2026, error = 1e-3
  )
  diag_stan <- enw_model(use_cpp = FALSE, verbose = FALSE)$diagnose(
    data = stan_data, seed = 2026, error = 1e-3
  )
  expect_equal(diag_cpp$lp(), diag_stan$lp(), tolerance = 1e-10)
  expect_equal(
    diag_cpp$gradients()$model, diag_stan$gradients()$model,
    tolerance = 1e-6
  )
})
