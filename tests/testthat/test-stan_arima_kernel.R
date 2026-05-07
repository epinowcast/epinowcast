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
