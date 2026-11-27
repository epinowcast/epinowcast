skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Reference R implementations matching
# inst/stan/functions/gaussian_process.stan

matern_indices_R <- function(M, L) {
  (pi / (2 * L) * seq_len(M))^2
}

diagSPD_Matern32_R <- function(alpha, rho, L, M) {
  factor <- 2 * alpha * (sqrt(3) / rho)^1.5
  factor / (3 / rho^2 + matern_indices_R(M, L))
}

diagSPD_EQ_R <- function(alpha, rho, L, M) {
  factor <- alpha * sqrt(sqrt(2 * pi) * rho)
  factor * exp(-0.25 * (rho * pi / 2 / L)^2 * seq_len(M)^2)
}

diagSPD_Periodic_R <- function(alpha, rho, M) {
  a <- 1 / rho^2
  q <- exp(log(alpha) + 0.5 * (log(2) - a + log(besselI(a, seq_len(M)))))
  c(q, q)
}

phi_basis_R <- function(T, M, L) {
  x <- seq_len(T)
  x <- 2 * (x - mean(x)) / (max(x) - 1)
  sin(outer(pi / (2 * L) * (x + L), seq_len(M))) / sqrt(L)
}

test_that("matern_indices() matches the R reference", {
  out <- matern_indices(8L, 1.5)
  expect_lt(max(abs(out - matern_indices_R(8L, 1.5))), 1e-10)
})

test_that("diagSPD_Matern32() matches the R reference", {
  out <- diagSPD_Matern32(1.2, 3.0, 1.5, 10L)
  expect_lt(max(abs(out - diagSPD_Matern32_R(1.2, 3.0, 1.5, 10L))), 1e-10)
})

test_that("diagSPD_EQ() matches the R reference", {
  out <- diagSPD_EQ(0.8, 2.0, 1.5, 10L)
  expect_lt(max(abs(out - diagSPD_EQ_R(0.8, 2.0, 1.5, 10L))), 1e-10)
})

test_that("gp_diag_spd() dispatches to the matching kernel spectral density", {
  M <- 5L
  L <- 1.5
  alpha <- 1.2
  rho <- 2.5
  out_se <- gp_diag_spd(alpha, rho, L, M, 0L, 1.5)
  expect_lt(max(abs(out_se - diagSPD_EQ_R(alpha, rho, L, M))), 1e-10)
  out_matern <- gp_diag_spd(alpha, rho, L, M, 2L, 1.5)
  expect_lt(
    max(abs(out_matern - diagSPD_Matern32_R(alpha, rho, L, M))), 1e-10
  )
})

test_that("update_gp() centres eta[1] when low_freq_centred = 1", {
  # eta[1] is the smoothest, most strongly data-identified coefficient.
  # When low_freq_centred = 1 (the stationary, d = 0 case; see
  # gp_latent_matrix()) update_gp() uses it directly (a centred
  # parameterisation) instead of scaling it by the spectral density; the
  # rest stay non-centred. The matching prior lives in gp_priors_lp()
  # (regression.stan, not exposed here; see test-gp.R for the R-level
  # coverage of the paired init change).
  M <- 6L
  L <- 1.5
  alpha <- 1.0
  rho <- 3.0
  set.seed(1)
  eta <- rnorm(M)
  phi <- phi_basis_R(12L, M, L)
  out <- update_gp(phi, M, L, alpha, rho, eta, 2L, 1.5, 1L)
  diag_spd <- diagSPD_Matern32_R(alpha, rho, L, M)
  weights <- diag_spd * eta
  weights[1] <- eta[1]
  ref <- as.numeric(phi %*% weights)
  expect_lt(max(abs(out - ref)), 1e-10)
})

test_that("update_gp() also centres eta[M + 1] for the periodic kernel", {
  M <- 4L
  set.seed(2)
  eta <- rnorm(2L * M)
  alpha <- 0.8
  rho <- 2.0
  phi <- matrix(runif(10 * 2L * M), nrow = 10) # 10 observations, 2M basis
  out <- update_gp(phi, M, 1.5, alpha, rho, eta, 1L, 1.5, 1L)
  diag_spd <- diagSPD_Periodic_R(alpha, rho, M)
  weights <- diag_spd * eta
  weights[1] <- eta[1]
  weights[M + 1] <- eta[M + 1]
  ref <- as.numeric(phi %*% weights)
  expect_lt(max(abs(out - ref)), 1e-10)
})

test_that("update_gp() is fully non-centred when low_freq_centred = 0", {
  # d >= 1 (integrated) processes pass low_freq_centred = 0 from
  # gp_latent_matrix(), recovering the original PHI %*% (diagSPD .* eta).
  M <- 6L
  L <- 1.5
  alpha <- 1.0
  rho <- 3.0
  set.seed(1)
  eta <- rnorm(M)
  phi <- phi_basis_R(12L, M, L)
  out <- update_gp(phi, M, L, alpha, rho, eta, 2L, 1.5, 0L)
  ref <- as.numeric(phi %*% (diagSPD_Matern32_R(alpha, rho, L, M) * eta))
  expect_lt(max(abs(out - ref)), 1e-10)
})

test_that("apply_gp_term() integrates and anchors under differencing", {
  # Single group, base = 0, flat_idx = identity, so the output is the
  # latent gp_eps. Exercise d = 0 (stationary), d = 1 and d = 2.
  T_full <- 12L
  L <- 1.5
  alpha <- 1.0
  rho <- 3.0
  make_phi <- function(n, M) {
    x <- seq_len(n)
    x <- 2 * (x - mean(x)) / (max(x) - 1)
    sin(outer(pi / (2 * L) * (x + L), seq_len(M))) / sqrt(L)
  }
  run <- function(d, eta, phi, M, centre = 0L) {
    eta_m <- matrix(eta, ncol = 1)
    apply_gp_term(
      rep(0, T_full), 1L, centre, T_full, 1L, M, L, 2L, 1.5, d,
      phi, eta_m, array(rho), array(alpha), seq_len(T_full)
    )
  }
  set.seed(1)
  # d = 0: basis on all T points; output equals update_gp() directly.
  # gp_latent_matrix() centres the lowest-frequency coefficient only for
  # d = 0 (low_freq_centred = 1), so the reference call matches that.
  M0 <- 5L
  phi0 <- make_phi(T_full, M0)
  eta0 <- rnorm(M0)
  out0 <- run(0L, eta0, phi0, M0)
  ref0 <- update_gp(phi0, M0, L, alpha, rho, eta0, 2L, 1.5, 1L)
  expect_lt(max(abs(out0 - ref0)), 1e-10)

  # d = 1: basis on T - 1 points; first value anchored to zero and the
  # series is the cumulative sum of c(0, free). low_freq_centred = 0 for
  # d >= 1 (see gp_latent_matrix()).
  M1 <- 5L
  phi1 <- make_phi(T_full - 1L, M1)
  eta1 <- rnorm(M1)
  out1 <- run(1L, eta1, phi1, M1)
  free1 <- update_gp(phi1, M1, L, alpha, rho, eta1, 2L, 1.5, 0L)
  expect_lt(abs(out1[1]), 1e-12)
  expect_lt(max(abs(out1 - cumsum(c(0, free1)))), 1e-10)

  # d = 2: first two values anchored to zero, double cumulative sum.
  M2 <- 4L
  phi2 <- make_phi(T_full - 2L, M2)
  eta2 <- rnorm(M2)
  out2 <- run(2L, eta2, phi2, M2)
  free2 <- update_gp(phi2, M2, L, alpha, rho, eta2, 2L, 1.5, 0L)
  expect_lt(max(abs(out2[1:2])), 1e-12)
  expect_lt(
    max(abs(out2 - cumsum(cumsum(c(0, 0, free2))))), 1e-10
  )
})

test_that("apply_gp_term() grand-mean centres the integrated GP", {
  T_full <- 12L
  L <- 1.5
  alpha <- 1.0
  rho <- 3.0
  make_phi <- function(n, M) {
    x <- seq_len(n)
    x <- 2 * (x - mean(x)) / (max(x) - 1)
    sin(outer(pi / (2 * L) * (x + L), seq_len(M))) / sqrt(L)
  }
  set.seed(2)
  M <- 5L
  phi <- make_phi(T_full - 1L, M)
  eta_m <- matrix(rnorm(M), ncol = 1)
  base <- rep(0, T_full)
  idx <- seq_len(T_full)
  raw <- apply_gp_term(
    base, 1L, 0L, T_full, 1L, M, L, 2L, 1.5, 1L,
    phi, eta_m, array(rho), array(alpha), idx
  )
  cen <- apply_gp_term(
    base, 1L, 1L, T_full, 1L, M, L, 2L, 1.5, 1L,
    phi, eta_m, array(rho), array(alpha), idx
  )
  # centred output is mean-zero and equals raw minus its grand mean
  expect_lt(abs(mean(cen)), 1e-10)
  expect_lt(max(abs(cen - (raw - mean(raw)))), 1e-10)
  # the recovered offset equals the removed grand mean
  off <- gp_latent_mean_offset(
    1L, 1L, T_full, 1L, M, L, 2L, 1.5, 1L,
    phi, eta_m, array(rho), array(alpha)
  )
  expect_lt(abs(off - mean(raw)), 1e-10)
  # a stationary GP (d = 0) is never centred and has zero offset
  phi0 <- make_phi(T_full, M)
  raw0 <- apply_gp_term(
    base, 1L, 0L, T_full, 1L, M, L, 2L, 1.5, 0L,
    phi0, eta_m, array(rho), array(alpha), idx
  )
  cen0 <- apply_gp_term(
    base, 1L, 1L, T_full, 1L, M, L, 2L, 1.5, 0L,
    phi0, eta_m, array(rho), array(alpha), idx
  )
  expect_lt(max(abs(raw0 - cen0)), 1e-12)
  off0 <- gp_latent_mean_offset(
    1L, 1L, T_full, 1L, M, L, 2L, 1.5, 0L,
    phi0, eta_m, array(rho), array(alpha)
  )
  expect_equal(off0, 0)
})

test_that("a small Stan model recovers a smooth GP trend", {
  skip_if_not_installed("cmdstanr")
  skip_if(
    identical(Sys.getenv("R_COVR"), "true"),
    "Sampling recovery fit skipped under covr"
  )
  # Simulate a smooth latent trend, observe with small noise, and fit a
  # minimal HSGP model built from the package GP functions. Check the
  # posterior mean of the latent process tracks the true smooth trend.
  stan_dir <- system.file("stan", package = "epinowcast")
  model_code <- paste(
    "functions {",
    "  #include functions/gaussian_process.stan",
    "}",
    "data {",
    "  int<lower=1> T;",
    "  int<lower=1> M;",
    "  real<lower=0> L;",
    "  matrix[T, M] PHI;",
    "  vector[T] y;",
    "  real<lower=0> obs_sd;",
    "}",
    "parameters {",
    "  vector[M] eta;",
    "  real<lower=0> rho;",
    "  real<lower=0> alpha;",
    "}",
    "transformed parameters {",
    "  vector[T] f = update_gp(PHI, M, L, alpha, rho, eta, 2, 1.5, 0);",
    "}",
    "model {",
    "  eta ~ std_normal();",
    "  rho ~ lognormal(log(10), 0.5);",
    "  alpha ~ normal(0, 1);",
    "  y ~ normal(f, obs_sd);",
    "}",
    sep = "\n"
  )
  mod <- cmdstanr::cmdstan_model(
    cmdstanr::write_stan_file(model_code),
    include_paths = stan_dir
  )

  T <- 40L
  L <- 1.5
  M <- ceiling(T * 0.3)
  x <- seq_len(T)
  xs <- 2 * (x - mean(x)) / (max(x) - 1)
  PHI <- sin(outer(pi / (2 * L) * (xs + L), seq_len(M))) / sqrt(L)
  true_f <- sin(2 * pi * x / T) + 0.5 * cos(2 * pi * x / (T / 2))
  obs_sd <- 0.15
  set.seed(1)
  y <- true_f + rnorm(T, 0, obs_sd)

  # A chain can silently fail to write its CSV on CI (`$sample()` returns
  # but a chain's output is missing). Force the draws read inside the retry
  # so a transient crash retries with a fresh seed rather than failing the
  # test later at summary().
  fit <- NULL
  for (attempt in 0:3) {
    fit <- tryCatch(
      {
        f <- mod$sample(
          data = list(T = T, M = M, L = L, PHI = PHI, y = y, obs_sd = obs_sd),
          chains = 2, parallel_chains = 2, iter_warmup = 1000,
          iter_sampling = 500, adapt_delta = 0.95, seed = 1 + attempt,
          refresh = 0, show_messages = FALSE, show_exceptions = FALSE
        )
        f$draws()
        f
      },
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      break
    }
  }
  if (is.null(fit)) {
    stop("Stan sampler failed to produce output after retries")
  }
  fhat <- fit$summary("f")$mean
  # The posterior mean should track the true smooth trend closely.
  expect_lt(sqrt(mean((fhat - true_f)^2)), 0.15)
  expect_true(all(fit$summary(c("rho", "alpha"))$rhat < 1.1))
})

test_that("gp_priors_lp() runs without error at one, two, and many basis functions", { # nolint
  skip_if_not_installed("cmdstanr")
  # gp_priors_lp() lives in regression.stan, which enw_stan_to_r() cannot
  # expose standalone (it calls the overloaded effect_priors_lp()), so it
  # is otherwise never exercised in compiled Stan: a regression here would
  # previously have passed CI silently. Build a minimal model that calls
  # only gp_priors_lp(), covering the M == 1 edge case (reachable with
  # default gp() settings and a handful of time points) that the
  # non-centred slices `gp_eta[2:gp_M, ]` etc. must not fall over on, plus
  # M = 2 and a "many basis functions" case, for every kernel family and
  # both the stationary (d = 0, centred) and integrated (d >= 1,
  # non-centred) branches.
  stan_dir <- system.file("stan", package = "epinowcast")
  model_code <- paste(
    "functions {",
    "  #include functions/utils.stan",
    "  #include functions/combine_effects.stan",
    "  #include functions/effects_priors_lp.stan",
    "  #include functions/arima_kernel.stan",
    "  #include functions/gaussian_process.stan",
    "  #include functions/regression.stan",
    "}",
    "data {",
    "  int<lower=1> gp_M;",
    "  int<lower=0, upper=2> gp_type;",
    "  int<lower=0, upper=1> gp_d;",
    "}",
    "transformed data {",
    "  int gp_rows = gp_type == 1 ? 2 * gp_M : gp_M;",
    "}",
    "parameters {",
    "  matrix[gp_rows, 1] gp_eta;",
    "  array[1] real<lower=0> gp_rho;",
    "  array[1] real<lower=0> gp_alpha;",
    "}",
    "model {",
    "  array[2, 1] real gp_rho_p;",
    "  array[2, 1] real gp_alpha_p;",
    "  gp_rho_p[1, 1] = 0; gp_rho_p[2, 1] = 1;",
    "  gp_alpha_p[1, 1] = 0; gp_alpha_p[2, 1] = 1;",
    "  gp_priors_lp(",
    "    1, gp_eta, gp_rho, gp_alpha, gp_rho_p, gp_alpha_p,",
    "    gp_M, 1.5, gp_type, 1.5, gp_d",
    "  );",
    "}",
    sep = "\n"
  )
  mod <- cmdstanr::cmdstan_model(
    cmdstanr::write_stan_file(model_code),
    include_paths = stan_dir
  )
  for (gp_type in c(0L, 1L, 2L)) { # SE, periodic, Matern
    for (gp_d in c(0L, 1L)) { # stationary (centred), integrated
      for (gp_M in c(1L, 2L, 6L)) { # one, two, many basis functions
        # Only finiteness is checked below, not convergence, and the
        # short warmup is deliberate (a fast smoke test across many
        # combinations); suppress the sampler's own divergence
        # warnings so they don't fail the suite's blanket
        # no-warnings check (see other fit calls in this file).
        fit <- suppressWarnings(mod$sample(
          data = list(gp_M = gp_M, gp_type = gp_type, gp_d = gp_d),
          chains = 1, iter_warmup = 20, iter_sampling = 20,
          refresh = 0, show_messages = FALSE, show_exceptions = FALSE,
          seed = 1
        ))
        expect_true(
          all(is.finite(fit$draws("gp_rho"))),
          label = sprintf(
            "gp_type=%d, gp_d=%d, gp_M=%d", gp_type, gp_d, gp_M
          )
        )
      }
    }
  }
})

test_that("rescaling the shared centred coefficient(s) by alpha's ratio keeps update_gp() proportional to alpha", { # nolint
  skip_if_not_installed("cmdstanr")
  # update_gp()'s weights - including the centred low-frequency one(s) -
  # must scale linearly with alpha for every kernel, so refp's shared
  # eta must be rescaled by alpha's ratio to move it from the mean
  # path's scale to the sd path's (see epinowcast.stan's
  # `refp_gp_sd_eta`). The ratio's denominator is floored at 1e-8
  # (matching epinowcast.stan) since refp_gp_alpha can get arbitrarily
  # close to zero.
  stan_dir <- system.file("stan", package = "epinowcast")
  model_code <- paste(
    "functions {",
    "  #include functions/gaussian_process.stan",
    "}",
    "data {",
    "  int<lower=1> M;",
    "  int<lower=0, upper=2> type;",
    "  vector[type == 1 ? 2 * M : M] eta;",
    "  real<lower=0> rho;",
    "  real<lower=0> alpha;",
    "  real<lower=0> sd_alpha;",
    "}",
    "transformed data {",
    "  int rows_eta = type == 1 ? 2 * M : M;",
    "}",
    "parameters {}",
    "generated quantities {",
    "  vector[rows_eta] sd_eta = eta;",
    "  {",
    "    real centred_ratio = sd_alpha / fmax(alpha, 1e-8);",
    "    sd_eta[1] = eta[1] * centred_ratio;",
    "    if (type == 1) {",
    "      sd_eta[M + 1] = eta[M + 1] * centred_ratio;",
    "    }",
    "  }",
    "  matrix[rows_eta, rows_eta] I = diag_matrix(rep_vector(1.0, rows_eta));", # nolint
    "  vector[rows_eta] mean_weights = update_gp(",
    "    I, M, 1.5, alpha, rho, eta, type, 1.5, 1",
    "  );",
    "  vector[rows_eta] sd_weights = update_gp(",
    "    I, M, 1.5, sd_alpha, rho, sd_eta, type, 1.5, 1",
    "  );",
    "}",
    sep = "\n"
  )
  mod <- cmdstanr::cmdstan_model(
    cmdstanr::write_stan_file(model_code),
    include_paths = stan_dir
  )
  cases <- list(
    list(M = 1L, type = 2L, alpha = 1.0, sd_alpha = 3.0),
    list(M = 1L, type = 1L, alpha = 1.0, sd_alpha = 3.0),
    list(M = 4L, type = 2L, alpha = 1.0, sd_alpha = 0.3),
    list(M = 4L, type = 1L, alpha = 0.5, sd_alpha = 2.5),
    list(M = 6L, type = 0L, alpha = 1.2, sd_alpha = 0.4),
    # Near the fmax() floor: refp_gp_alpha close to zero, the
    # weakly-identified-magnitude regime the floor guards against.
    list(M = 2L, type = 0L, alpha = 1e-10, sd_alpha = 1.5)
  )
  set.seed(1)
  for (case in cases) {
    n_eta <- if (case$type == 1) 2L * case$M else case$M
    eta <- rnorm(n_eta)
    fit <- mod$sample(
      data = list(
        M = case$M, type = case$type, eta = eta, rho = 2.0,
        alpha = case$alpha, sd_alpha = case$sd_alpha
      ),
      # Full double precision: the small-alpha case pushes the centred
      # weight to ~1e8, where CmdStan's default CSV output precision
      # (~6-7 significant figures) would otherwise fail the tight
      # absolute tolerance below on rounding alone, not a real error.
      fixed_param = TRUE, chains = 1, iter_sampling = 1, refresh = 0,
      sig_figs = 18
    )
    mean_weights <- as.numeric(fit$draws("mean_weights", format = "matrix"))
    sd_weights <- as.numeric(fit$draws("sd_weights", format = "matrix"))
    expect_true(
      all(is.finite(sd_weights)),
      label = sprintf("M=%d, type=%d", case$M, case$type)
    )
    # Every non-centred row scales by the raw (unfloored) alpha ratio,
    # exactly, via update_gp()'s own alpha-linear diagSPD() for each
    # path; only the shared centred row(s) go through the fmax()-floored
    # ratio applied above, since fmax() only matters as alpha
    # approaches 0 with sd_alpha fixed, and that never affects the two
    # independently-computed non-centred weights.
    raw_ratio <- case$sd_alpha / case$alpha
    floored_ratio <- case$sd_alpha / max(case$alpha, 1e-8)
    centred_idx <- if (case$type == 1) c(1L, case$M + 1L) else 1L
    expected <- mean_weights * raw_ratio
    expected[centred_idx] <- mean_weights[centred_idx] * floored_ratio
    expect_lt(
      max(abs(sd_weights - expected)), 1e-6,
      label = sprintf("M=%d, type=%d", case$M, case$type)
    )
  }
})
