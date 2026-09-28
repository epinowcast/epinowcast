skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Tests for the custom reverse-mode adjoint renewal_depletion(), which will
# replace the `gt_n > 1` loop in log_expected_latent_from_r() (see
# inst/stan/functions/log_expected_latent_from_r.stan and the derivation in
# scratchpad/renewal-adjoint-log.md). The C++ implementation itself lands
# once the inst/include plumbing from branch feat/cpp-adjoints is merged
# here (tracked in the same log); until then `cpp_adjoint_available` gates
# every test that needs it, and only the pure-Stan reference
# (renewal_depletion_stan(), tests/testthat/stan/renewal_depletion_stan.stan)
# is exercised.
cpp_adjoint_available <- FALSE

# Stan-only model (no undefined-function declaration), usable today.
# compile_model_methods = TRUE enables fit$log_prob()/grad_log_prob() below;
# force_recompile = TRUE avoids cmdstanr reusing a cached executable that
# was built without model methods (e.g. from a plain syntax check).
renewal_stan_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_renewal_depletion_stan.stan"),
    compile_model_methods = TRUE,
    force_recompile = TRUE,
    quiet = TRUE
  )
}

# Dispatcher model with the C++ declaration, only ever compiled once
# cpp_adjoint_available is TRUE (it needs allow_undefined and a header).
renewal_dispatch_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_renewal_depletion.stan"),
    stanc_options = list("allow-undefined" = TRUE),
    compile_model_methods = TRUE,
    force_recompile = TRUE,
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
  fd_grad <- function(fit, upars, h = 1e-4) {
    vapply(seq_along(upars), function(i) {
      e <- replace(numeric(length(upars)), i, h)
      (fit$log_prob(upars + e) - fit$log_prob(upars - e)) / (2 * h)
    }, numeric(1))
  }
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
      fit <- model$sample(
        data = data, chains = 1, iter_warmup = 1, iter_sampling = 1,
        refresh = 0, show_messages = FALSE
      )
      fit$init_model_methods()
      upars <- c(
        if (p$seed) log(x$seed), if (p$R) log(x$R), if (p$rgt) log(x$rgt),
        if (p$pop) log(case$pop)
      )
      upars <- upars + rnorm(length(upars), sd = 0.01)
      # grad_log_prob() attaches a log_prob attribute; drop it for the
      # comparison against fd_grad()'s plain vector. The tolerance is
      # looser than the C++-vs-Stan comparisons above: central
      # differences of a chained r_t-step recurrence (especially near
      # the pop_floor / fmax(1e-8, .) kinks) accumulate more rounding
      # error than comparing two exact reverse-mode gradients.
      grad <- as.vector(fit$grad_log_prob(upars))
      expect_equal(grad, fd_grad(fit, upars), tolerance = 2e-3)
    }
  }
})

test_that("renewal_depletion() C++ adjoint matches the Stan reference", {
  skip_if_not(
    cpp_adjoint_available,
    paste(
      "C++ adjoint plumbing (branch feat/cpp-adjoints) is not yet merged;",
      "see scratchpad/renewal-adjoint-log.md."
    )
  )
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
  skip_if_not(
    cpp_adjoint_available,
    paste(
      "C++ adjoint plumbing (branch feat/cpp-adjoints) is not yet merged;",
      "see scratchpad/renewal-adjoint-log.md."
    )
  )
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  model <- renewal_dispatch_model()
  params <- expand.grid(seed = 0:1, R = 0:1, rgt = 0:1, pop = 0:1)[-1, ]
  set.seed(321)
  for (case in renewal_cases) {
    x <- renewal_inputs(case)
    for (i in seq_len(nrow(params))) {
      p <- params[i, ]
      base_data <- list(
        n0 = case$n0, r_t = case$r_t, use_pop = case$use_pop,
        pop_floor = case$floor, seed_data = x$seed, R_data = x$R,
        rgt_data = x$rgt, pop_data = case$pop,
        r = as.array(rnorm(case$n0 + case$r_t))
      )
      param_flags <- setNames(as.list(as.integer(p)), paste0(names(p), "_param")) # nolint: line_length_linter.
      fits <- lapply(c(cpp = 1L, stan = 0L), function(use_cpp) {
        data <- c(base_data, param_flags, list(use_cpp = use_cpp))
        fit <- model$sample(
          data = data, chains = 1, iter_warmup = 1, iter_sampling = 1,
          refresh = 0, show_messages = FALSE
        )
        fit$init_model_methods()
        fit
      })
      upars <- c(
        if (p$seed) log(x$seed), if (p$R) log(x$R), if (p$rgt) log(x$rgt),
        if (p$pop) log(case$pop)
      )
      upars <- upars + rnorm(length(upars), sd = 0.01)
      expect_equal(
        fits$cpp$log_prob(upars), fits$stan$log_prob(upars),
        tolerance = 1e-10
      )
      expect_equal(
        as.vector(fits$cpp$grad_log_prob(upars)),
        as.vector(fits$stan$grad_log_prob(upars)),
        tolerance = 1e-8
      )
    }
  }
})

test_that("renewal_depletion() full-model log_prob/grad_log_prob parity", {
  skip_if_not(
    cpp_adjoint_available,
    paste(
      "C++ adjoint plumbing (branch feat/cpp-adjoints) is not yet merged,",
      "and log_expected_latent_from_r() does not yet dispatch on use_cpp;",
      "see scratchpad/renewal-adjoint-log.md."
    )
  )
  skip("full-model parity is added once epinowcast.stan wires in use_cpp")
})
