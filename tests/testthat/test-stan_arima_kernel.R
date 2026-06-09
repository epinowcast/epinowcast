skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Reference R implementations matching inst/stan/functions/arima_kernel.stan

arma_impulse_R <- function(phi, theta, T) {
  p <- length(phi)
  q <- length(theta)
  psi <- numeric(T)
  psi[1] <- 1
  if (T >= 2) {
    for (t in 2:T) {
      s <- 0
      kmax <- min(p, t - 1)
      if (kmax > 0) {
        for (k in 1:kmax) s <- s + phi[k] * psi[t - k]
      }
      if (t - 1 <= q) s <- s + theta[t - 1]
      psi[t] <- s
    }
  }
  psi
}

lower_toeplitz_R <- function(psi) {
  T <- length(psi)
  K <- matrix(0, T, T)
  for (t in 1:T) for (s in 1:t) K[t, s] <- psi[t - s + 1]
  K
}

cumulative_op_R <- function(T, d) {
  if (d == 0) return(diag(T))
  D1 <- matrix(0, T, T)
  D1[lower.tri(D1, diag = TRUE)] <- 1
  Reduce(`%*%`, replicate(d, D1, simplify = FALSE))
}

arima_kernel_R <- function(phi, theta, d, T) {
  K <- lower_toeplitz_R(arma_impulse_R(phi, theta, T))
  if (d == 0) K else cumulative_op_R(T, d) %*% K
}

pacf_to_phi_R <- function(r) {
  p <- length(r)
  if (p == 0) return(r)
  phi <- r
  if (p >= 2) {
    for (k in 2:p) {
      work <- phi
      for (j in 1:(k - 1)) work[j] <- phi[j] - r[k] * phi[k - j]
      phi[1:(k - 1)] <- work[1:(k - 1)]
      phi[k] <- r[k]
    }
  }
  phi
}

test_that("arma_impulse() matches the R reference for AR/MA/ARMA cases", {
  configs <- list(
    list(phi = numeric(0), theta = numeric(0)),
    list(phi = 0.7, theta = numeric(0)),
    list(phi = c(0.5, -0.2), theta = numeric(0)),
    list(phi = numeric(0), theta = 0.3),
    list(phi = 0.5, theta = 0.3),
    list(phi = c(0.4, 0.2), theta = c(0.3, -0.1))
  )
  for (cfg in configs) {
    T <- 12L
    ref <- arma_impulse_R(cfg$phi, cfg$theta, T)
    out <- arma_impulse(as.array(cfg$phi), as.array(cfg$theta), T)
    expect_lt(max(abs(out - ref)), 1e-10)
  }
})

test_that("arma_impulse() AR(1) impulse equals phi^k", {
  phi <- 0.6
  expect_equal(
    arma_impulse(as.array(phi), as.array(numeric(0)), 6L),
    phi^(0:5)
  )
})

test_that("arma_impulse() ARMA(1,1) matches stats::ARMAtoMA", {
  out <- arma_impulse(as.array(0.5), as.array(0.3), 8L)
  ref <- c(1, ARMAtoMA(ar = 0.5, ma = 0.3, lag.max = 7))
  expect_lt(max(abs(out - ref)), 1e-10)
})

test_that("arima_kernel_matrix(d = 1) equals the cumulative-sum operator", {
  T <- 6L
  out <- arima_kernel_matrix(
    as.array(numeric(0)), as.array(numeric(0)), 1L, T
  )
  ref <- matrix(0, T, T)
  ref[lower.tri(ref, diag = TRUE)] <- 1
  expect_equal(out, ref)
})

test_that("arima_kernel_matrix(d = 2) maps shocks to double cumulative sum", {
  T <- 8L
  K <- arima_kernel_matrix(
    as.array(numeric(0)), as.array(numeric(0)), 2L, T
  )
  set.seed(1)
  z <- rnorm(T)
  expect_equal(as.numeric(K %*% z), cumsum(cumsum(z)))
})

test_that("arima_filter() matches an R-side ARMA(1,1) recursion", {
  T <- 50L
  phi <- 0.7
  theta <- 0.4
  set.seed(42)
  Z <- matrix(rnorm(T * 3), T, 3)
  out <- arima_filter(Z, as.array(phi), as.array(theta), 0L)
  ref <- matrix(0, T, 3)
  for (g in seq_len(3)) {
    ref[1, g] <- Z[1, g]
    for (t in 2:T) {
      ref[t, g] <- phi * ref[t - 1, g] + Z[t, g] + theta * Z[t - 1, g]
    }
  }
  expect_lt(max(abs(out - ref)), 1e-10)
})

test_that("pacf_to_phi() yields stationary AR(p) for p in 1..4", {
  for (p in 1:4) {
    set.seed(p)
    r <- runif(p, -0.9, 0.9)
    phi <- pacf_to_phi(as.array(r))
    expect_equal(phi, pacf_to_phi_R(r))
    roots <- polyroot(c(1, -phi))
    expect_true(all(Mod(roots) > 1.0001))
  }
})

test_that("a small Stan model recovers known ARIMA parameters", {
  skip_if_not_installed("cmdstanr")
  # covr instruments R, not Stan, so this end-to-end sampling fit adds no
  # coverage the algebra tests above do not already provide. Skip it under
  # covr where the extra sampler runs are prone to being killed for resource
  # use, producing spurious failures.
  skip_if(
    identical(Sys.getenv("R_COVR"), "true"),
    "Sampling recovery fit skipped under covr"
  )
  # Simulate a latent series from known parameters using the same kernel,
  # observe it with small noise, then fit a minimal model built from the
  # package's ARIMA Stan functions and check the posteriors recover the
  # generating values. This is the end-to-end correctness check the
  # algebra tests above do not provide.
  stan_dir <- system.file("stan", package = "epinowcast")
  model_code <- paste(
    "functions {",
    "  #include functions/arima_kernel.stan",
    "}",
    "data {",
    "  int<lower=1> T;",
    "  vector[T] y;",
    "  int<lower=0> p;",
    "  int<lower=0> q;",
    "  int<lower=0> d;",
    "  real<lower=0> obs_sd;",
    "}",
    "parameters {",
    "  vector<lower=-1, upper=1>[p] pacf;",
    "  vector[q] theta;",
    "  real<lower=0> sigma;",
    "  vector[T] z;",
    "}",
    "transformed parameters {",
    "  vector[p] phi = pacf_to_phi(pacf);",
    "  vector[T] eps = sigma * arima_filter(to_matrix(z, T, 1), phi, theta, d)[, 1];", # nolint: line_length_linter.
    "}",
    "model {",
    "  z ~ std_normal();",
    "  theta ~ std_normal();",
    "  sigma ~ normal(0, 1);",
    "  y ~ normal(eps, obs_sd);",
    "}",
    sep = "\n"
  )
  mod <- cmdstanr::cmdstan_model(
    cmdstanr::write_stan_file(model_code),
    include_paths = stan_dir
  )

  obs_sd <- 0.1
  simulate_y <- function(phi, theta, d, sigma, T, seed) {
    set.seed(seed)
    z <- rnorm(T)
    eps <- sigma * as.numeric(arima_kernel_R(phi, theta, d, T) %*% z)
    eps + rnorm(T, 0, obs_sd)
  }
  fit_recover <- function(y, p, q, d, seed) {
    # Start every chain from a stable point. With the default init range a
    # chain can draw a large sigma, making sigma * cumsum(z) huge against the
    # tight obs_sd likelihood; the gradient overflows and the chain fails to
    # initialise. Initialising z at zero and sigma near the prior scale keeps
    # the d = 1 fit well behaved.
    init <- function() {
      list(
        z = rep(0, length(y)),
        sigma = 0.5,
        pacf = rep(0, p),
        theta = rep(0, q)
      )
    }
    # A chain still occasionally fails to write its output on CI (producing no
    # CSV), independent of platform or seed. The crash can be silent --
    # `$sample()` returns without error but a chain's CSV is missing, so the
    # failure only surfaces later when the draws are read. Force the read
    # inside the retry so a transient crash triggers a fresh-seed retry
    # rather than failing the test; recovery is robust to the seed change.
    for (attempt in 0:3) {
      fit <- tryCatch(
        {
          f <- mod$sample(
            data = list(
              T = length(y), y = y, p = p, q = q, d = d, obs_sd = obs_sd
            ),
            chains = 2, parallel_chains = 2, iter_warmup = 1000,
            iter_sampling = 500, adapt_delta = 0.95, init = init,
            seed = seed + attempt, refresh = 0,
            show_messages = FALSE, show_exceptions = FALSE
          )
          f$draws()
          f
        },
        error = function(e) NULL
      )
      if (!is.null(fit)) {
        return(fit)
      }
    }
    stop("Stan sampler failed to produce output after retries")
  }

  # Stationary AR(1): recover phi and sigma.
  y_ar <- simulate_y(0.6, numeric(0), 0L, 0.4, 60L, seed = 1)
  s_ar <- fit_recover(y_ar, p = 1L, q = 0L, d = 0L, seed = 1)$summary(
    c("phi", "sigma")
  )
  phi_hat <- s_ar$mean[s_ar$variable == "phi[1]"]
  sigma_hat <- s_ar$mean[s_ar$variable == "sigma"]
  expect_lt(abs(phi_hat - 0.6), 0.25)
  expect_lt(abs(sigma_hat - 0.4), 0.15)
  expect_true(all(s_ar$rhat < 1.1))

  # Integrated random walk (d = 1): recover sigma.
  y_rw <- simulate_y(numeric(0), numeric(0), 1L, 0.3, 60L, seed = 1)
  s_rw <- fit_recover(y_rw, p = 0L, q = 0L, d = 1L, seed = 1)$summary("sigma")
  expect_lt(abs(s_rw$mean - 0.3), 0.15)
  expect_true(all(s_rw$rhat < 1.1))
})
