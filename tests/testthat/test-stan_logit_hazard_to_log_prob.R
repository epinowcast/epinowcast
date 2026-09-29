# Tests for the logit_hazard_to_log_prob() C++ adjoint: values and
# gradients against the retained pure-Stan reference
# logit_hazard_to_log_prob_stan(), an R closed form and central finite
# differences; the use_cpp toggle's wiring; and full-model parity between
# the two compile paths. Values and gradients come from the compiled
# executables via cmdstan_log_prob() (helper-functions.R), because
# cmdstanr's $grad_log_prob() cannot link a user_header.

# log p_d = log(h_d) + sum_{j < d} log(1 - h_j), h = inv_logit(lh), on the
# log scale so it stays accurate where h rounds to 0 or 1.
logit_hazard_log_prob_r <- function(lh) {
  log_h <- stats::plogis(lh, log.p = TRUE)
  log1m_h <- stats::plogis(lh, lower.tail = FALSE, log.p = TRUE)
  log_h + c(0, cumsum(log1m_h)[-length(lh)])
}

# Gradient of the test model's target, sum(r * logp) - sum(logp^2) / 2,
# with respect to lh: pbar = r - logp, then
# lhbar_j = pbar_j * (1 - h_j) - h_j * sum_{d > j} pbar_d.
logit_hazard_target_grad_r <- function(lh, r) {
  h <- stats::plogis(lh)
  pbar <- r - logit_hazard_log_prob_r(lh)
  suffix <- rev(cumsum(rev(pbar))) - pbar
  pbar * (1 - h) - h * suffix
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

compile_logit_hazard_model <- function() {
  cmdstanr::cmdstan_model(
    test_path("stan", "logit_hazard_gradient.stan"),
    include_paths = system.file("stan", package = "epinowcast"),
    user_header = epinowcast_stan_header(),
    dir = withr::local_tempdir(.local_envir = parent.frame()),
    quiet = TRUE
  )
}

test_that(
  "logit_hazard_to_log_prob() matches the Stan reference, closed form and finite differences", # nolint
  {
    skip_if_no_cmdstan_log_prob()
    model <- compile_logit_hazard_model()
    set.seed(20260928)

    # Randomised cases, with |lh| small enough that the Stan reference is
    # accurate to double precision, so the two can be compared tightly.
    for (i in 1:50) {
      l <- sample(c(1:6, 10, 20, 40), 1)
      r <- signif(rnorm(l), 12)
      lh <- matrix(
        signif(rnorm(4 * l, sd = sample(c(0.5, 2, 4), 1)), 12),
        ncol = l
      )
      data <- list(l = l, r = as.array(r))
      cpp <- cmdstan_log_prob(model, c(data, use_cpp = 1L), lh)
      stan <- cmdstan_log_prob(model, c(data, use_cpp = 0L), lh)

      expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
      expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
      closed_form <- do.call(rbind, lapply(
        seq_len(nrow(lh)), function(k) logit_hazard_target_grad_r(lh[k, ], r)
      ))
      expect_equal(cpp$grad, closed_form, tolerance = 1e-10)

      # Central finite differences of the C++ log density itself.
      step <- 1e-5
      shifts <- diag(step, l)
      for (k in seq_len(nrow(lh))) {
        up <- sweep(shifts, 2, lh[k, ], `+`)
        down <- sweep(-shifts, 2, lh[k, ], `+`)
        fd <- cmdstan_log_prob(model, c(data, use_cpp = 1L), rbind(up, down))
        expect_equal(
          cpp$grad[k, ], (fd$lp[1:l] - fd$lp[-(1:l)]) / (2 * step),
          tolerance = 1e-6
        )
      }
    }
  }
)

test_that("logit_hazard_to_log_prob() is finite where hazards saturate", {
  skip_if_no_cmdstan_log_prob()
  model <- compile_logit_hazard_model()
  # l = 1; h rounding to exactly 0 or 1 in double precision (|lh| > ~37);
  # saturation in a non-final slot, where the Stan reference's
  # log1m(inv_logit(lh)) is -inf; and a mix of extremes in one vector.
  cases <- list(
    0.3, -8, 50, -50, 800, -800,
    rep(40, 4), rep(-40, 4), rep(20, 8), rep(-20, 8),
    c(1, 2, 740, 3), c(1, 2, -740, 3), c(-20, 20, -20, 20, 0, 5)
  )
  for (lh in cases) {
    l <- length(lh)
    r <- signif(seq(-1, 1, length.out = l), 12)
    cpp <- cmdstan_log_prob(
      model, list(l = l, r = as.array(r), use_cpp = 1L), lh
    )
    expect_true(is.finite(cpp$lp))
    expect_true(all(is.finite(cpp$grad)))
    logp <- logit_hazard_log_prob_r(lh)
    expect_equal(
      cpp$lp, sum(r * logp) - 0.5 * sum(logp^2),
      tolerance = 1e-12
    )
    expect_equal(
      as.numeric(cpp$grad), logit_hazard_target_grad_r(lh, r),
      tolerance = 1e-10
    )
  }
})

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

  enw_model(verbose = FALSE, use_cpp = TRUE, target_dir = target_dir)
  # A copy of the installed header, kept next to the model, since CmdStan
  # cannot use a header path containing spaces or `%`.
  expect_identical(
    captured$user_header, file.path(target_dir, "include", "epinowcast.hpp")
  )
  expect_identical(
    unname(tools::md5sum(captured$user_header)),
    unname(tools::md5sum(epinowcast_stan_header()))
  )
  cpp_model_file <- captured[[1]]

  enw_model(verbose = FALSE, use_cpp = FALSE, target_dir = target_dir)
  expect_null(captured$user_header)
  # The pure-Stan build is cached separately, so switching use_cpp in one
  # cache never reuses the other build's binary.
  expect_false(identical(captured[[1]], cpp_model_file))
  fallback <- readLines(file.path(
    captured$include_paths, "functions", "logit_hazard_to_log_prob.stan"
  ))
  expect_true(any(grepl("logit_hazard_to_log_prob_stan(lh, l)",
    fallback,
    fixed = TRUE
  )))

  # An explicitly supplied user_header is never overridden.
  enw_model(
    verbose = FALSE, use_cpp = TRUE, target_dir = target_dir,
    user_header = "custom.hpp"
  )
  expect_identical(captured$user_header, "custom.hpp")
})

test_that("stage_stan_header() copies the header once, keeping its mtime", {
  target_dir <- withr::local_tempdir()
  header <- stage_stan_header(target_dir)
  installed <- dirname(epinowcast_stan_header())
  files <- list.files(installed, recursive = TRUE)
  expect_identical(
    unname(tools::md5sum(file.path(dirname(header), files))),
    unname(tools::md5sum(file.path(installed, files)))
  )
  expect_identical(
    file.mtime(header), file.mtime(epinowcast_stan_header())
  )
  staged_mtime <- file.mtime(header)
  Sys.sleep(1)
  stage_stan_header(target_dir)
  expect_identical(file.mtime(header), staged_mtime)
})

test_that("epinowcast models agree in log density and gradient with use_cpp on and off", { # nolint
  skip_if_no_cmdstan_log_prob()
  target_dir <- withr::local_tempdir()
  # Same target_dir for both, to check they do not share a binary.
  mod_cpp <- enw_model(verbose = FALSE, use_cpp = TRUE, target_dir = target_dir)
  mod_stan <- enw_model(
    verbose = FALSE, use_cpp = FALSE, target_dir = target_dir
  )
  expect_false(identical(mod_cpp$exe_file(), mod_stan$exe_file()))

  pobs <- enw_example("preprocessed")
  # A report-date model makes expected_obs() call logit_hazard_to_log_prob().
  inputs <- suppressMessages(epinowcast(
    pobs,
    reference = enw_reference(~1, data = pobs),
    report = enw_report(~ (1 | day_of_week), data = pobs),
    fit = enw_fit_opts(
      sampler = function(init, data, ...) {
        data.table::data.table(init = list(init), data = list(data))
      }
    ),
    model = NULL
  ))
  stan_data <- inputs$data[[1]]
  expect_identical(stan_data$model_rep, 1)

  # Draws from a short chain give realistic parameter values to evaluate
  # both builds at.
  fit <- suppressMessages(mod_cpp$sample(
    data = stan_data, init = inputs$init[[1]], chains = 1,
    threads_per_chain = 1, iter_warmup = 100, iter_sampling = 10, seed = 1, refresh = 0,
    show_messages = FALSE, sig_figs = 18
  ))
  draws <- fit$output_files()
  cpp <- cmdstan_log_prob(mod_cpp, fit$data_file(), constrained_csv = draws)
  stan <- cmdstan_log_prob(
    mod_stan, fit$data_file(),
    constrained_csv = draws
  )
  expect_length(cpp$lp, 10)
  expect_equal(cpp$lp, stan$lp, tolerance = 1e-12)
  expect_equal(cpp$grad, stan$grad, tolerance = 1e-10)
})
