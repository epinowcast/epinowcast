# Tests for the logit_hazard_to_log_prob() C++ adjoint: value and gradient
# parity between the C++ implementation and the retained pure-Stan
# reference logit_hazard_to_log_prob_stan(), the epinowcast.use_cpp
# toggle's wiring, and full-model parity between the two compile paths.

# Boundary/edge-case grid: l = 1, small and moderate l, all-zero-hazard and
# near-saturated-hazard extremes (h -> 0 and h -> 1, where 1 / h and
# 1 / (1 - h) blow up), and a mix of extremes within one vector.
logit_hazard_cases <- local({
  set.seed(20260928)
  list(
    list(l = 1L, lh = c(0.3)),
    list(l = 1L, lh = c(-8)),
    # h saturates to exactly 1 in double precision (a regression case: an
    # earlier version of the C++ forward pass called log1m() on this
    # element unconditionally, even though its result is never used for
    # l == 1, and Stan Math's log1m() throws a domain_error once its
    # argument reaches exactly 1).
    list(l = 1L, lh = c(50)),
    list(l = 3L, lh = c(0, 0, 0)),
    list(l = 5L, lh = rnorm(5)),
    list(l = 20L, lh = rnorm(20, sd = 2)),
    list(l = 30L, lh = rnorm(30, sd = 5)),
    list(l = 8L, lh = rep(-20, 8)),
    list(l = 8L, lh = rep(20, 8)),
    list(l = 6L, lh = c(-20, 20, -20, 20, 0, 5))
  )
})

test_that(
  "logit_hazard_to_log_prob() C++ matches the pure-Stan reference in value and gradient", # nolint
  {
    skip_on_cran()
    skip_on_os("windows")
    skip_on_os("mac")
    skip_on_local()
    skip_if_not_installed("cmdstanr")

    model <- cmdstanr::cmdstan_model(
      test_path("stan", "logit_hazard_gradient.stan"),
      include_paths = system.file("stan", package = "epinowcast"),
      user_header = epinowcast_stan_header(),
      stanc_options = list("allow-undefined"),
      quiet = TRUE,
      # cmdstanr's rebuild-detection only tracks the .stan file; changes
      # to the C++ header alone would otherwise not trigger a rebuild.
      force_recompile = TRUE
    )

    for (case in logit_hazard_cases) {
      l <- case$l
      lh <- case$lh
      r <- rnorm(l)

      # Value parity: both implementations computed in one fixed_param draw.
      fit_gq <- model$sample(
        data = list(l = l, r = r, use_cpp = 1L), fixed_param = TRUE,
        iter_sampling = 1, chains = 1, seed = 1,
        init = list(list(lh = lh)), refresh = 0, show_messages = FALSE
      )
      logp_cpp <- as.numeric(
        fit_gq$draws("logp_cpp", format = "matrix")[1, ]
      )
      logp_stan <- as.numeric(
        fit_gq$draws("logp_stan", format = "matrix")[1, ]
      )
      expect_equal(logp_cpp, logp_stan, tolerance = 1e-12)

      # Gradient parity: log_prob()/grad_log_prob(), via CmdStan's own
      # gradient-test diagnostic, compared between the use_cpp branches of
      # the same compiled model. epsilon is widened for the near-saturated
      # cases (h -> 0/1), where the default 1e-6 step is dominated by
      # roundoff; error is widened so CmdStan's own pass/fail check (which
      # is more conservative than the comparisons below) does not abort
      # the run.
      diag_cpp <- suppressMessages(model$diagnose(
        data = list(l = l, r = r, use_cpp = 1L),
        init = list(list(lh = lh)), seed = 1, epsilon = 1e-4, error = 100
      ))
      diag_stan <- suppressMessages(model$diagnose(
        data = list(l = l, r = r, use_cpp = 0L),
        init = list(list(lh = lh)), seed = 1, epsilon = 1e-4, error = 100
      ))

      expect_equal(diag_cpp$lp(), diag_stan$lp(), tolerance = 1e-10)
      expect_equal(
        diag_cpp$gradients()$model, diag_stan$gradients()$model,
        tolerance = 1e-8
      )
      # Independent check against central finite differences (CmdStan's
      # own, computed during the same diagnostic run).
      expect_equal(
        diag_cpp$gradients()$model, diag_cpp$gradients()$finite_diff,
        tolerance = 1e-2
      )
    }
  }
)

test_that("enw_model() wires the C++ header only when use_cpp = TRUE", {
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

  suppressMessages(enw_model(
    compile = TRUE, verbose = FALSE, use_cpp = TRUE, profile = TRUE
  ))
  expect_identical(captured$user_header, epinowcast_stan_header())

  captured <- NULL
  suppressMessages(enw_model(
    compile = TRUE, verbose = FALSE, use_cpp = FALSE, profile = TRUE,
    target_dir = target_dir
  ))
  expect_null(captured$user_header)

  # An explicitly supplied user_header is never overridden.
  captured <- NULL
  suppressMessages(enw_model(
    compile = TRUE, verbose = FALSE, use_cpp = TRUE, profile = TRUE,
    user_header = "custom.hpp"
  ))
  expect_identical(captured$user_header, "custom.hpp")
})

test_that("enw_model() compiles with the C++ adjoint path on and off", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_os("mac")
  skip_on_local()
  skip_if_not_installed("cmdstanr")
  skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")

  mod_cpp <- enw_model(
    verbose = FALSE, use_cpp = TRUE, target_dir = withr::local_tempdir()
  )
  expect_s3_class(mod_cpp, "CmdStanModel")
  expect_true(file.exists(mod_cpp$exe_file()))

  mod_stan <- enw_model(
    verbose = FALSE, use_cpp = FALSE, target_dir = withr::local_tempdir()
  )
  expect_s3_class(mod_stan, "CmdStanModel")
  expect_true(file.exists(mod_stan$exe_file()))
})

test_that(
  "epinowcast() gives matching posterior summaries with the C++ adjoint path on and off", # nolint
  {
    skip_on_cran()
    skip_on_os("windows")
    skip_on_os("mac")
    skip_on_local()
    skip_if_not_installed("cmdstanr")
    skip_if(is.null(cmdstanr::cmdstan_path()), "CmdStan is not installed")

    pobs <- enw_example("preprocessed")
    fit <- enw_fit_opts(
      sampler = enw_sample,
      save_warmup = FALSE, pp = FALSE, chains = 1, parallel_chains = 1,
      iter_warmup = 50, iter_sampling = 50, seed = 101,
      show_messages = FALSE, show_exceptions = FALSE, refresh = 0
    )
    expectation <- enw_expectation(data = pobs)
    reference <- enw_reference(data = pobs)
    report <- enw_report(~ 1 + day_of_week, data = pobs)

    nowcast_cpp <- suppressWarnings(suppressMessages(epinowcast(
      pobs,
      expectation = expectation, reference = reference, report = report,
      fit = fit,
      model = enw_model(
        verbose = FALSE, use_cpp = TRUE, target_dir = withr::local_tempdir()
      )
    )))
    nowcast_stan <- suppressWarnings(suppressMessages(epinowcast(
      pobs,
      expectation = expectation, reference = reference, report = report,
      fit = fit,
      model = enw_model(
        verbose = FALSE, use_cpp = FALSE, target_dir = withr::local_tempdir()
      )
    )))

    summary_cpp <- summary(nowcast_cpp, type = "fit")
    summary_stan <- summary(nowcast_stan, type = "fit")
    expect_identical(summary_cpp$variable, summary_stan$variable)

    # log_prob()/grad_log_prob() parity is already checked exactly (to
    # 1e-10/1e-8) above, function-by-function and on the boundary-case
    # grid; a full model fit adds a different, complementary check: that
    # the C++ path is wired correctly into the whole model, not just the
    # one function. Matching *draws* is not the right bar for that,
    # though: HMC is a chaotic dynamical system, so two separately
    # compiled (if mathematically identical) binaries, even sampled with
    # the same seed, diverge in trajectory once floating-point rounding
    # differs by even one ULP at some leapfrog step -- this is expected,
    # not a sign of a wiring bug. Instead check the two posteriors agree
    # up to sampling noise: most parameters' cpp-vs-stan posterior mean
    # difference should be small relative to their posterior sd.
    standardised_diff <- abs(summary_cpp$mean - summary_stan$mean) /
      pmax(summary_cpp$sd, summary_stan$sd, 1e-8)
    expect_lt(stats::median(standardised_diff, na.rm = TRUE), 1)
  }
)
