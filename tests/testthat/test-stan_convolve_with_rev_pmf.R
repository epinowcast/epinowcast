# Tests for the convolve_with_rev_pmf() C++ adjoint: values and
# gradients against the retained pure-Stan reference
# convolve_with_rev_pmf_stan(), an R closed form and central finite
# differences; the use_cpp toggle's wiring; and full-model parity between
# the two compile paths. Values and gradients come from the compiled
# executables via cmdstan_log_prob() (helper-functions.R), because
# cmdstanr's $grad_log_prob() cannot link a user_header.

# z_t = sum_{d=0}^{D-1} w_d x_{t-d}, w_d = y[D-d] (1-indexed, y already
# reversed), x_s = 0 outside 1:n.
convolve_r <- function(x, y, len) {
  n <- length(x)
  D <- length(y)
  z <- numeric(len)
  for (d in 0:(D - 1)) {
    m <- min(n, len - d)
    if (m <= 0) break
    idx <- (d + 1):(d + m)
    z[idx] <- z[idx] + y[D - d] * x[1:m]
  }
  z
}

# Adjoint of the convolution: the matching correlation.
convolve_reverse_r <- function(x, y, len, zbar) {
  n <- length(x)
  D <- length(y)
  xbar <- numeric(n)
  ybar <- numeric(D)
  for (d in 0:(D - 1)) {
    m <- min(n, len - d)
    if (m <= 0) break
    idx <- (d + 1):(d + m)
    xbar[1:m] <- xbar[1:m] + y[D - d] * zbar[idx]
    ybar[D - d] <- ybar[D - d] + sum(zbar[idx] * x[1:m])
  }
  list(xbar = xbar, ybar = ybar)
}

# Gradient of the test model's target, dot(r, z) - dot(z, z) / 2, so
# zbar = r - z.
convolve_target_grad_r <- function(x, y, len, r) {
  z <- convolve_r(x, y, len)
  convolve_reverse_r(x, y, len, r - z)
}

# The convolution matrix used before the adjoint: column s holds the PMF
# (rev(y)) from row s, as built by convolution_matrix(). Its first n
# columns act on x, so conv_mat %*% x is the previous implementation.
old_conv_mat <- function(y, n, len) {
  convolution_matrix(rev(y), len, include_partial = TRUE)[,
    seq_len(n),
    drop = FALSE
  ]
}

# Central finite differences of the test model's log density.
convolve_fd <- function(model, data, upars, step = 1e-5) {
  vapply(seq_along(upars), function(i) {
    shift <- replace(numeric(length(upars)), i, step)
    up <- cmdstan_log_prob(model, data, upars + shift)$lp
    down <- cmdstan_log_prob(model, data, upars - shift)$lp
    (up - down) / (2 * step)
  }, numeric(1))
}

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

compile_convolve_model <- function() {
  cmdstanr::cmdstan_model(
    test_path("stan", "convolve_gradient.stan"),
    include_paths = system.file("stan", package = "epinowcast"),
    user_header = epinowcast_stan_header(),
    dir = withr::local_tempdir(.local_envir = parent.frame()),
    quiet = TRUE
  )
}

# Both x and y are data (no free parameters): CmdStan's log_prob method
# rejects an unconstrained_params file with zero elements, so the
# generated quantities z_cpp/z_stan are read via a fixed_param draw
# instead of cmdstan_log_prob().
convolve_generated_quantities <- function(model, data) {
  fit <- model$sample(
    data = data, fixed_param = TRUE, chains = 1, iter_sampling = 1,
    iter_warmup = 0, refresh = 0, show_messages = FALSE,
    show_exceptions = FALSE, sig_figs = 18
  )
  vars <- c("z_cpp", "z_stan", "z_matrix")
  draws <- posterior::as_draws_matrix(fit$draws(vars))
  len <- data$len
  lapply(stats::setNames(vars, vars), function(v) {
    as.numeric(draws[1, paste0(v, "[", 1:len, "]")])
  })
}

# Boundary-case grid: len == n, len == n + D - 1, len in between; D = 1,
# D = 2, D > n; n = 1.
convolve_cases <- function() {
  list(
    list(n = 5, D = 1, len = 5), # D = 1, len == n
    list(n = 5, D = 3, len = 5), # len == n, D < n
    list(n = 5, D = 3, len = 7), # len == n + D - 1 (full convolution)
    list(n = 5, D = 3, len = 6), # len strictly between n and n + D - 1
    list(n = 1, D = 1, len = 1), # n = 1
    list(n = 1, D = 4, len = 4), # n = 1, D > n, len == n + D - 1
    list(n = 3, D = 8, len = 8), # D > n
    list(n = 6, D = 6, len = 6) # D == n
  )
}

test_that(
  "convolve_with_rev_pmf() matches the Stan reference, closed form and finite differences", # nolint
  {
    skip_if_no_cmdstan_log_prob()
    model <- compile_convolve_model()
    set.seed(20260928)

    for (case in convolve_cases()) {
      for (x_param in c(0L, 1L)) {
        for (y_param in c(0L, 1L)) {
          n <- case$n
          D <- case$D
          len <- case$len
          x <- signif(rnorm(n), 12)
          y <- signif(rnorm(D), 12)
          r <- signif(rnorm(len), 12)
          data <- list(
            n = n, D = D, len = len,
            x_data = as.array(x), y_data = as.array(y), r = as.array(r),
            conv_mat = old_conv_mat(y, n, len),
            x_param = x_param, y_param = y_param
          )
          upars <- c(
            if (x_param) x else numeric(0),
            if (y_param) y else numeric(0)
          )

          if (!x_param && !y_param) {
            # No free parameters: CmdStan's log_prob method cannot take an
            # empty unconstrained_params file, so only values are checked
            # here (via generated quantities); see the dedicated edge-case
            # test below for more of this case's coverage.
            gq <- convolve_generated_quantities(model, c(data, use_cpp = 1L))
            expect_equal(gq$z_cpp, gq$z_stan, tolerance = 1e-12)
            expect_equal(gq$z_cpp, gq$z_matrix, tolerance = 1e-12)
            next
          }

          cpp <- cmdstan_log_prob(model, c(data, use_cpp = 1L), upars)
          stan <- cmdstan_log_prob(model, c(data, use_cpp = 0L), upars)
          expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
          expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)

          closed <- convolve_target_grad_r(x, y, len, r)
          closed_grad <- c(
            if (x_param) closed$xbar else numeric(0),
            if (y_param) closed$ybar else numeric(0)
          )
          expect_equal(as.numeric(cpp$grad), closed_grad, tolerance = 1e-9)

          # The target is quadratic, so central differences are exact up
          # to rounding and the tolerance can be tight.
          fd <- convolve_fd(model, c(data, use_cpp = 1L), upars)
          expect_equal(as.numeric(cpp$grad), fd, tolerance = 1e-8)
        }
      }
    }
  }
)

test_that("convolve_with_rev_pmf() handles edge cases: D = 1, D > n, zero PMF entries", { # nolint
  skip_if_no_cmdstan_log_prob()
  model <- compile_convolve_model()

  cases <- list(
    # Maximum delay 1 (immediate reporting): a single scaling weight.
    list(x = c(1, 2, 3), y = 0.4, len = 3),
    # Delay longer than the series (D > n).
    list(x = c(2, 5), y = c(0.1, 0.2, 0.3, 0.4), len = 5),
    # Zero PMF entries interleaved with non-zero ones.
    list(x = c(1, 1, 1, 1), y = c(0, 0.5, 0, 0.5), len = 4),
    # All-zero PMF.
    list(x = c(1, 2, 3), y = c(0, 0), len = 4)
  )
  for (case in cases) {
    n <- length(case$x)
    D <- length(case$y)
    len <- case$len
    r <- signif(seq(-1, 1, length.out = len), 12)
    data <- list(
      n = n, D = D, len = len,
      x_data = as.array(case$x), y_data = as.array(case$y), r = as.array(r),
      conv_mat = old_conv_mat(case$y, n, len),
      x_param = 0L, y_param = 0L, use_cpp = 1L
    )
    gq <- convolve_generated_quantities(model, data)
    expected_z <- convolve_r(case$x, case$y, len)
    expect_equal(gq$z_cpp, expected_z, tolerance = 1e-9)
    expect_equal(gq$z_cpp, gq$z_stan, tolerance = 1e-12)
    expect_equal(gq$z_cpp, gq$z_matrix, tolerance = 1e-12)
  }
})

test_that(
  "convolve_with_rev_pmf() matches the reference, the previous matrix product and finite differences over random inputs", # nolint
  {
    skip_if_no_cmdstan_log_prob()
    model <- compile_convolve_model()

    for (seed in 1:5) {
      set.seed(seed)
      n <- sample(1:12, 1)
      D <- sample(1:10, 1)
      len <- n + sample(0:(D - 1), 1)
      x <- signif(rnorm(n), 12)
      pmf <- stats::runif(D)
      y <- signif(pmf / sum(pmf), 12)
      r <- signif(rnorm(len), 12)
      data <- list(
        n = n, D = D, len = len,
        x_data = as.array(x), y_data = as.array(y), r = as.array(r),
        conv_mat = old_conv_mat(y, n, len)
      )

      gq <- convolve_generated_quantities(
        model, c(data, x_param = 0L, y_param = 0L, use_cpp = 1L)
      )
      expect_equal(gq$z_cpp, gq$z_stan, tolerance = 1e-12)
      expect_equal(gq$z_cpp, gq$z_matrix, tolerance = 1e-12)

      data <- c(data, x_param = 1L, y_param = 1L)
      upars <- c(x, y)
      cpp <- cmdstan_log_prob(model, c(data, use_cpp = 1L), upars)
      stan <- cmdstan_log_prob(model, c(data, use_cpp = 0L), upars)
      expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
      expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
      closed <- convolve_target_grad_r(x, y, len, r)
      expect_equal(
        as.numeric(cpp$grad), c(closed$xbar, closed$ybar),
        tolerance = 1e-9
      )
      fd <- convolve_fd(model, c(data, use_cpp = 1L), upars)
      expect_equal(as.numeric(cpp$grad), fd, tolerance = 1e-8)
    }
  }
)

test_that("convolve_with_rev_pmf() errors when len is out of range", {
  skip_if_no_cmdstan_log_prob()
  model <- compile_convolve_model()
  base <- list(
    x_data = as.array(c(1, 2, 3)), y_data = as.array(c(0.2, 0.8)),
    x_param = 0L, y_param = 0L, use_cpp = 1L
  )
  # len shorter than x (n = 3, len = 2).
  expect_error(
    suppressWarnings(convolve_generated_quantities(
      model, c(base, list(
        n = 3, D = 2, len = 2, r = as.array(c(1, 2)),
        conv_mat = matrix(0, 2, 3)
      ))
    ))
  )
  # len longer than the full convolution (n = 3, D = 2, max len = 4).
  expect_error(
    suppressWarnings(convolve_generated_quantities(
      model, c(base, list(
        n = 3, D = 2, len = 5, r = as.array(rep(1, 5)),
        conv_mat = matrix(0, 5, 3)
      ))
    ))
  )
})

test_that("enw_model() swaps convolve_with_rev_pmf() for its pure-Stan fallback when use_cpp = FALSE", { # nolint
  skip_if_not_installed("cmdstanr")
  target_dir <- withr::local_tempdir()
  captured <- NULL
  testthat::local_mocked_bindings(
    cmdstan_model = function(...) {
      captured <<- list(...)
      structure(list(), class = "CmdStanModel")
    },
    .package = "cmdstanr"
  )
  enw_model(verbose = FALSE, use_cpp = FALSE, target_dir = target_dir)
  fallback <- readLines(file.path(
    captured$include_paths, "functions", "convolve_with_rev_pmf.stan"
  ))
  expect_true(any(grepl("convolve_with_rev_pmf_stan(x, y, len)",
    fallback,
    fixed = TRUE
  )))
})

test_that("epinowcast models agree in log density and gradient with use_cpp on and off (delay convolution)", { # nolint
  skip_if_no_cmdstan_log_prob()
  target_dir <- withr::local_tempdir()
  mod_cpp <- enw_model(verbose = FALSE, use_cpp = TRUE, target_dir = target_dir)
  mod_stan <- enw_model(
    verbose = FALSE, use_cpp = FALSE, target_dir = target_dir
  )
  expect_false(identical(mod_cpp$exe_file(), mod_stan$exe_file()))

  pobs <- enw_example("preprocessed")
  # A latent-to-obs reporting delay of length > 1 makes
  # log_expected_obs_from_latent() call convolve_with_rev_pmf().
  inputs <- suppressMessages(epinowcast(
    pobs,
    expectation = enw_expectation(
      r = ~1, generation_time = 1,
      latent_reporting_delay = c(0.2, 0.5, 0.3),
      data = pobs
    ),
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        data.table::data.table(init = list(init), data = list(data))
      }
    ),
    model = NULL
  ))
  stan_data <- inputs$data[[1]]
  expect_identical(stan_data$expl_lrd_n, 3L)

  fit <- suppressMessages(mod_cpp$sample(
    data = stan_data, init = inputs$init[[1]], chains = 1,
    threads_per_chain = 1, iter_warmup = 100, iter_sampling = 10, seed = 1,
    refresh = 0, show_messages = FALSE, sig_figs = 18
  ))
  draws <- fit$output_files()
  cpp <- cmdstan_log_prob(mod_cpp, fit$data_file(), constrained_csv = draws)
  stan <- cmdstan_log_prob(
    mod_stan, fit$data_file(), constrained_csv = draws
  )
  expect_length(cpp$lp, 10)
  expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
  expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
})
