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

test_that("update_gp() returns PHI %*% (diagSPD .* eta)", {
  M <- 6L
  L <- 1.5
  alpha <- 1.0
  rho <- 3.0
  set.seed(1)
  eta <- rnorm(M)
  phi <- phi_basis_R(12L, M, L)
  out <- update_gp(phi, M, L, alpha, rho, eta, 2L, 1.5)
  ref <- as.numeric(phi %*% (diagSPD_Matern32_R(alpha, rho, L, M) * eta))
  expect_lt(max(abs(out - ref)), 1e-10)
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
    "  vector[T] f = update_gp(PHI, M, L, alpha, rho, eta, 2, 1.5);",
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

  fit <- mod$sample(
    data = list(T = T, M = M, L = L, PHI = PHI, y = y, obs_sd = obs_sd),
    chains = 2, parallel_chains = 2, iter_warmup = 1000,
    iter_sampling = 500, adapt_delta = 0.95, seed = 1, refresh = 0,
    show_messages = FALSE, show_exceptions = FALSE
  )
  fhat <- fit$summary("f")$mean
  # The posterior mean should track the true smooth trend closely.
  expect_lt(sqrt(mean((fhat - true_f)^2)), 0.15)
  expect_true(all(fit$summary(c("rho", "alpha"))$rhat < 1.1))
})
