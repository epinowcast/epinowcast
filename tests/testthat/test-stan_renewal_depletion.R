# Tests for the renewal_depletion() C++ adjoint, which replaces the
# `gt_n > 1` loop in log_expected_latent_from_r(). Values and gradients
# are compared against the retained pure-Stan reference
# renewal_depletion_stan(), an R version of the recurrence and central
# finite differences. Log densities and gradients come from the compiled
# executables via cmdstan_log_prob() (helper-functions.R), because
# cmdstanr's $grad_log_prob() cannot link a user_header and $diagnose()
# prints six significant figures.

skip_if_no_cmdstan_log_prob <- function() {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")
  skip_on_local()
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")
  skip_if(
    cmdstanr::cmdstan_version() < "2.31.0",
    "CmdStan's log_prob method needs CmdStan >= 2.31"
  )
}

compile_renewal_model <- function() {
  cmdstanr::cmdstan_model(
    test_path("stan", "renewal_depletion_gradient.stan"),
    include_paths = system.file("stan", package = "epinowcast"),
    user_header = epinowcast_stan_header(),
    dir = withr::local_tempdir(.local_envir = parent.frame()),
    quiet = TRUE
  )
}

# The recurrence in R, for an independent check of the forward pass.
renewal_depletion_r <- function(seed, R, rgt, pop, use_pop, pop_floor) {
  n0 <- length(seed)
  inf <- c(seed, numeric(length(R)))
  cum_cases <- sum(seed)
  for (i in seq_along(R)) {
    lambda <- sum(rgt * inf[i:(i + n0 - 1)])
    if (use_pop) {
      remaining <- max(0, pop - cum_cases)
      denom <- max(pop_floor, remaining)
      inf[n0 + i] <- max(1e-8, remaining * (1 - exp(-R[i] * lambda / denom)))
      cum_cases <- cum_cases + inf[n0 + i]
    } else {
      inf[n0 + i] <- R[i] * lambda
    }
  }
  inf
}

# Edge cases: no depletion, a large pool, a generation time of length one,
# a floor that binds (pop_floor above the remaining pool), a tiny pool that
# is exhausted, and a single renewal step.
renewal_edge_cases <- list(
  list(n0 = 3, r_t = 20, use_pop = 0, pop = 0, pop_floor = 1),
  list(n0 = 3, r_t = 20, use_pop = 1, pop = 1e4, pop_floor = 1),
  list(n0 = 1, r_t = 15, use_pop = 1, pop = 1e3, pop_floor = 1),
  list(n0 = 5, r_t = 30, use_pop = 1, pop = 100, pop_floor = 50),
  list(n0 = 3, r_t = 10, use_pop = 1, pop = 5, pop_floor = 1),
  list(n0 = 4, r_t = 1, use_pop = 1, pop = 200, pop_floor = 1)
)

# Randomised cases. The pool is set in renewal_random_inputs() against
# the undepleted cumulative count, so that depletion ranges from
# negligible to exhausting the pool.
renewal_random_case <- function() {
  list(
    n0 = sample(c(1:5, 7, 14), 1), r_t = sample(c(1, 5, 20, 60), 1),
    use_pop = sample(0:1, 1), pop_floor = sample(c(0.5, 1, 50), 1)
  )
}

renewal_inputs <- function(case) {
  gt <- rexp(case$n0)
  list(
    seed = signif(5 * exp(rnorm(case$n0)), 12),
    R = signif(exp(0.2 * rnorm(case$r_t) + 0.2), 12),
    rgt = signif(gt / sum(gt), 12),
    w = signif(rnorm(case$n0 + case$r_t), 12)
  )
}

renewal_random_inputs <- function(case) {
  x <- renewal_inputs(case)
  undepleted <- sum(renewal_depletion_r(x$seed, x$R, x$rgt, 0, 0, 1))
  case$pop <- signif(undepleted * 10^runif(1, -0.5, 1), 12)
  list(case = case, x = x)
}

# Whether central differences with this step could cross one of the
# depletion branch points (pool at zero, floor on the denominator, floor
# on the output), where they do not estimate the gradient.
renewal_near_kink <- function(case, upars, step) {
  theta <- exp(upars)
  n0 <- case$n0
  r_t <- case$r_t
  pop <- theta[length(theta)]
  inf <- renewal_depletion_r(
    theta[seq_len(n0)], theta[n0 + seq_len(r_t)],
    theta[n0 + r_t + seq_len(n0)], pop, 1, case$pop_floor
  )
  cum_before <- cumsum(inf)[n0 + seq_len(r_t) - 1]
  remaining <- pmax(0, pop - cum_before)
  new <- inf[-seq_len(n0)]
  margin <- 1e3 * step
  any(abs(pop - cum_before) < margin * pop) ||
    any(abs(remaining - case$pop_floor) < margin * case$pop_floor) ||
    any(new < 1e-8 * (1 + margin) & new > 1e-8 * (1 - margin)) ||
    any(new < 1e-6 & new > 1e-10)
}

renewal_data <- function(case, x, params, use_cpp) {
  c(
    list(
      n0 = case$n0, r_t = case$r_t, use_pop = case$use_pop,
      pop_floor = case$pop_floor, seed_data = as.array(x$seed),
      R_data = as.array(x$R), rgt_data = as.array(x$rgt),
      pop_data = case$pop, w = as.array(x$w), use_cpp = use_cpp
    ),
    stats::setNames(as.list(as.integer(params)), paste0(names(params), "_param"))
  )
}

# Unconstrained parameters (log scale) for the parameterised inputs, in
# declaration order, jittered around the inputs across `n` rows.
renewal_upars <- function(case, x, params, n = 3) {
  centre <- c(
    if (params$seed) log(x$seed),
    if (params$R) log(x$R),
    if (params$rgt) log(x$rgt),
    if (params$pop) log(case$pop)
  )
  jitter <- matrix(rnorm(n * length(centre), sd = 0.05), nrow = n)
  signif(sweep(jitter, 2, centre, `+`), 12)
}

# Every combination of seed, R, rgt and pop as parameter or data, except
# all data (covered by the generated quantities value check).
renewal_param_grid <- expand.grid(
  seed = 0:1, R = 0:1, rgt = 0:1, pop = 0:1
)[-1, ]

test_that("renewal_depletion() values match the Stan reference and R", {
  skip_if_no_cmdstan_log_prob()
  model <- compile_renewal_model()
  set.seed(123)
  random <- replicate(
    20, renewal_random_inputs(renewal_random_case()), FALSE
  )
  cases <- c(
    lapply(renewal_edge_cases, function(case) {
      list(case = case, x = renewal_inputs(case))
    }),
    random
  )
  for (inputs in cases) {
    case <- inputs$case
    x <- inputs$x
    fit <- model$sample(
      data = renewal_data(case, x, renewal_param_grid[1, ] * 0, 1L),
      fixed_param = TRUE, iter_sampling = 1, chains = 1, sig_figs = 18,
      refresh = 0, show_messages = FALSE
    )
    z_cpp <- as.vector(fit$draws("z_cpp", format = "matrix")[1, ])
    z_stan <- as.vector(fit$draws("z_stan", format = "matrix")[1, ])
    expect_equal(z_cpp[seq_len(case$n0)], x$seed, tolerance = 1e-14)
    expect_equal(z_cpp, z_stan, tolerance = 1e-12)
    expect_equal(
      z_cpp,
      renewal_depletion_r(
        x$seed, x$R, x$rgt, case$pop, case$use_pop, case$pop_floor
      ),
      tolerance = 1e-12
    )
  }
})

test_that("renewal_depletion() gradients match the Stan reference for every var/data combination", { # nolint
  skip_if_no_cmdstan_log_prob()
  model <- compile_renewal_model()
  set.seed(321)
  for (case in renewal_edge_cases) {
    x <- renewal_inputs(case)
    for (i in seq_len(nrow(renewal_param_grid))) {
      params <- renewal_param_grid[i, ]
      upars <- renewal_upars(case, x, params)
      cpp <- cmdstan_log_prob(model, renewal_data(case, x, params, 1L), upars)
      stan <- cmdstan_log_prob(model, renewal_data(case, x, params, 0L), upars)
      expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
      expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
    }
  }
})

test_that("renewal_depletion() matches the Stan reference and finite differences on random cases", { # nolint
  skip_if_no_cmdstan_log_prob()
  model <- compile_renewal_model()
  set.seed(20260928)
  all_params <- renewal_param_grid[nrow(renewal_param_grid), ]
  n_fd <- 0
  for (k in 1:30) {
    random <- renewal_random_inputs(renewal_random_case())
    case <- random$case
    x <- random$x
    upars <- renewal_upars(case, x, all_params, n = 2)
    data_cpp <- renewal_data(case, x, all_params, 1L)
    cpp <- cmdstan_log_prob(model, data_cpp, upars)
    stan <- cmdstan_log_prob(model, renewal_data(case, x, all_params, 0L), upars)
    expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
    expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)

    # Central finite differences of the C++ log density itself.
    step <- 1e-5
    n_par <- ncol(upars)
    shifts <- diag(step, n_par)
    for (j in seq_len(nrow(upars))) {
      if (case$use_pop && renewal_near_kink(case, upars[j, ], step)) next
      n_fd <- n_fd + 1
      up <- sweep(shifts, 2, upars[j, ], `+`)
      down <- sweep(-shifts, 2, upars[j, ], `+`)
      fd <- cmdstan_log_prob(model, data_cpp, rbind(up, down))
      expect_equal(
        cpp$grad[j, ],
        (fd$lp[seq_len(n_par)] - fd$lp[-seq_len(n_par)]) / (2 * step),
        tolerance = 1e-6
      )
    }
  }
  # Most points are away from a branch point.
  expect_gt(n_fd, 40)
})

test_that("log_expected_latent_from_r() passes its inputs to renewal_depletion() correctly", { # nolint
  skip_if_no_cmdstan_log_prob()
  # log_expected_latent_from_r() is exposed globally in setup.R on Linux CI,
  # with renewal_depletion() compiled from its pure-Stan fallback.
  skip_if_not(exists("log_expected_latent_from_r"))
  set.seed(456)
  # A generation time of length one uses exponential growth instead, and
  # enw_expectation() turns depletion off for it.
  for (case in Filter(function(case) case$n0 > 1, renewal_edge_cases)) {
    x <- renewal_inputs(case)
    # log_expected_latent_from_r() uses exp(lrgt) in the same dot product
    # as renewal_depletion(), so lrgt = log(rgt) here.
    out <- log_expected_latent_from_r(
      matrix(log(x$seed), ncol = 1), log(x$R), array(0L), case$r_t,
      case$n0, case$n0, log(x$rgt), case$n0 + case$r_t, 1L,
      array(case$pop), case$use_pop, case$pop_floor
    )
    expect_equal(
      exp(out[[1]]),
      renewal_depletion_r(
        x$seed, x$R, x$rgt, case$pop, case$use_pop, case$pop_floor
      ),
      tolerance = 1e-10
    )
  }
})

test_that("epinowcast renewal models agree in log density and gradient with use_cpp on and off", { # nolint
  skip_if_no_cmdstan_log_prob()
  target_dir <- withr::local_tempdir()
  # Same target_dir for both, to check they do not share a binary.
  mod_cpp <- enw_model(verbose = FALSE, use_cpp = TRUE, target_dir = target_dir)
  mod_stan <- enw_model(
    verbose = FALSE, use_cpp = FALSE, target_dir = target_dir
  )
  expect_false(identical(mod_cpp$exe_file(), mod_stan$exe_file()))

  # A depleting epidemic with the pool close to the final cumulative count,
  # so the fitted model reaches the depletion branches.
  set.seed(999)
  gt <- c(0.3, 0.4, 0.3)
  inc <- renewal_depletion_r(
    rep(5, 3), rep(1.6, 27), rev(gt), 500, 1, 1
  )
  n_days <- length(inc)
  dates <- as.Date("2021-01-01") + seq_len(n_days) - 1
  obs <- data.table::data.table(
    reference_date = dates, report_date = dates,
    confirm = rpois(n_days, pmax(inc, 1e-3))
  )
  pobs <- suppressWarnings(enw_preprocess_data(
    enw_complete_dates(obs, max_delay = 2),
    max_delay = 2
  ))
  inputs <- suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(
      r = ~ 0 + (1 | day:.group), generation_time = gt,
      population = 500, population_floor = 1, data = pobs
    ),
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        data.table::data.table(init = list(init), data = list(data))
      }
    ),
    model = NULL
  ))
  stan_data <- inputs$data[[1]]
  expect_gt(stan_data$expr_gt_n, 1)
  expect_identical(stan_data$expr_pop_use, 1L)

  fit <- suppressMessages(mod_cpp$sample(
    data = stan_data, init = inputs$init[[1]], chains = 1,
    threads_per_chain = 1, iter_warmup = 100, iter_sampling = 10,
    seed = 1, refresh = 0, show_messages = FALSE, sig_figs = 18
  ))
  draws <- fit$output_files()
  cpp <- cmdstan_log_prob(mod_cpp, fit$data_file(), constrained_csv = draws)
  stan <- cmdstan_log_prob(mod_stan, fit$data_file(), constrained_csv = draws)
  expect_length(cpp$lp, 10)
  expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
  expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
})
