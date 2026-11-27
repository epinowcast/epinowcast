skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

# Helper to call the exposed Stan renewal function for a single group with the
# susceptible-depletion adjustment enabled. Returns the natural-scale latent
# series (seeds followed by modelled new cases).
run_renewal <- function(seeds, log_r, generation_time, population,
                        pop_floor = 1) {
  gt_n <- length(generation_time)
  r_t <- length(log_r)
  ft <- r_t + gt_n
  lexp_latent_int <- matrix(log(seeds), nrow = gt_n, ncol = 1)
  identity_mixing <- diag(1)
  out <- log_expected_latent_from_r(
    lexp_latent_int, as.numeric(log_r), array(0L), r_t, gt_n, gt_n,
    rev(log(generation_time)), ft, 1L, array(population), 1L, pop_floor,
    identity_mixing, 0L
  )
  exp(out[[1]])
}

# Helper to call the exposed Stan renewal function for several groups, with or
# without cross-group mixing and susceptible depletion. `seeds` and `log_r`
# are lists, one element per group. Returns a list of natural-scale latent
# series, one per group.
run_multigroup_renewal <- function(seeds, log_r, generation_time,
                                   mixing = NULL, population = NULL,
                                   pop_floor = 1) {
  g <- length(seeds)
  gt_n <- length(generation_time)
  r_t <- length(log_r[[1]])
  ft <- r_t + gt_n
  lexp_latent_int <- vapply(seeds, function(s) log(s), numeric(gt_n))
  dim(lexp_latent_int) <- c(gt_n, g)
  r_g <- (seq_len(g) - 1) * r_t
  r <- unlist(log_r)
  use_pop <- as.integer(!is.null(population))
  pop <- if (use_pop) population else rep(0, g)
  use_mixing <- as.integer(!is.null(mixing))
  mixing_matrix <- if (use_mixing) mixing else diag(g)
  out <- log_expected_latent_from_r(
    lexp_latent_int, r, array(as.integer(r_g)), r_t, gt_n, gt_n,
    rev(log(generation_time)), ft, g, array(pop), use_pop, pop_floor,
    mixing_matrix, use_mixing
  )
  purrr::map(out, exp)
}

test_that(
  "susceptible depletion never creates more cases than remaining susceptibles",
  {
    gt <- c(0.3, 0.4, 0.3)
    population <- 200
    seeds <- rep(5, length(gt))
    # A high, sustained reproduction number drives the pool to exhaustion.
    log_r <- rep(log(3), 60)

    latent <- run_renewal(seeds, log_r, gt, population, pop_floor = 1)

    # Cumulative latent cases must never exceed the initial susceptible pool
    # (allowing only the tiny 1e-8 per-step incidence floor).
    cum_cases <- cumsum(latent)
    n_steps <- length(latent)
    expect_lte(max(cum_cases), population + n_steps * 1e-8)
    # Each modelled new case (after the seeds) is non-negative.
    expect_true(all(latent >= 0))
  }
)

test_that("susceptible depletion with a tiny pool stays bounded", {
  gt <- c(0.3, 0.4, 0.3)
  # Pool smaller than the seeded cases: no new cases can be created and the
  # series must stay finite (no -Inf / NaN from log()).
  population <- 5
  seeds <- rep(5, length(gt))
  log_r <- rep(log(2), 30)

  latent <- run_renewal(seeds, log_r, gt, population, pop_floor = 1)

  expect_true(all(is.finite(log(latent))))
  # New cases beyond the seeds are pinned near zero (the 1e-8 floor).
  new_cases <- latent[(length(gt) + 1):length(latent)]
  expect_lt(max(new_cases), 1e-6)
})

# R reference implementation of the coupled two-group renewal recurrence,
# mirroring the Stan `use_mixing` branch line for line: mixing is applied to
# each group's own generation-time-weighted incidence pressure before `R_t`
# and before any susceptible-depletion adjustment.
hand_coupled_renewal <- function(seeds, log_r, generation_time, mixing,
                                 population = NULL, pop_floor = 1) {
  g <- length(seeds)
  gt_n <- length(generation_time)
  r_t <- length(log_r[[1]])
  # `generation_time[1]` is the lag-1 (most recent) weight, so the
  # oldest-to-newest window is dotted against the reversed vector, matching
  # the Stan function's own `rev(log(generation_time))` convention.
  rev_gt <- rev(generation_time)
  R <- lapply(log_r, exp)
  exp_obs <- lapply(seeds, as.numeric)
  cum_cases <- vapply(exp_obs, sum, numeric(1))
  use_pop <- !is.null(population)
  for (i in seq_len(r_t)) {
    lambda <- vapply(seq_len(g), function(h) {
      window <- tail(exp_obs[[h]], gt_n)
      sum(window * rev_gt)
    }, numeric(1))
    mixed <- as.numeric(mixing %*% lambda)
    for (k in seq_len(g)) {
      if (use_pop) {
        remaining <- max(0, population[k] - cum_cases[k])
        denom <- max(pop_floor, remaining)
        adj <- 1 - exp(-R[[k]][i] * mixed[k] / denom)
        new_case <- max(1e-8, remaining * adj)
        cum_cases[k] <- cum_cases[k] + new_case
      } else {
        new_case <- R[[k]][i] * mixed[k]
      }
      exp_obs[[k]] <- c(exp_obs[[k]], new_case)
    }
  }
  exp_obs
}

test_that("an identity mixing matrix reproduces the uncoupled result exactly", {
  gt <- c(0.2, 0.3, 0.5)
  seeds <- list(rep(8, length(gt)), rep(3, length(gt)))
  log_r <- list(rep(log(1.3), 20), rep(log(0.8), 20))

  uncoupled <- run_multigroup_renewal(seeds, log_r, gt)
  identity_coupled <- run_multigroup_renewal(
    seeds, log_r, gt, mixing = diag(length(seeds))
  )

  expect_identical(uncoupled, identity_coupled)
})

test_that("a two-patch mixing matrix matches a hand-computed recurrence", {
  gt <- c(0.2, 0.3, 0.5)
  seeds <- list(c(10, 8, 6), c(0.5, 0.4, 0.3))
  log_r <- list(rep(log(1.4), 15), rep(log(1.1), 15))
  K <- matrix(c(0.8, 0.2, 0.3, 0.7), nrow = 2, byrow = TRUE)

  stan_out <- run_multigroup_renewal(seeds, log_r, gt, mixing = K)
  hand_out <- hand_coupled_renewal(seeds, log_r, gt, K)

  expect_equal(stan_out, hand_out, tolerance = 1e-8)
  # Coupling must actually change the near-zero-seeded group's trajectory:
  # its modelled (post-seed) cases are higher than the uncoupled equivalent.
  uncoupled <- hand_coupled_renewal(seeds, log_r, gt, diag(2))
  new_cases <- function(x) x[-seq_along(gt)]
  expect_true(all(new_cases(stan_out[[2]]) > new_cases(uncoupled[[2]])))
})

test_that("mixing composes with susceptible depletion per group", {
  gt <- c(0.2, 0.3, 0.5)
  seeds <- list(c(10, 8, 6), c(10, 8, 6))
  log_r <- list(rep(log(2.5), 20), rep(log(2.5), 20))
  K <- matrix(c(0.7, 0.3, 0.1, 0.9), nrow = 2, byrow = TRUE)
  population <- c(150, 400)

  stan_out <- run_multigroup_renewal(
    seeds, log_r, gt, mixing = K, population = population, pop_floor = 1
  )
  hand_out <- hand_coupled_renewal(
    seeds, log_r, gt, K, population = population, pop_floor = 1
  )

  expect_equal(stan_out, hand_out, tolerance = 1e-8)
  # Depletion still tracks each group's own pool: cumulative cases in group k
  # never exceed group k's own population (plus the numerical floor).
  for (k in seq_along(population)) {
    cum_cases <- cumsum(stan_out[[k]])
    expect_lte(max(cum_cases), population[k] + length(cum_cases) * 1e-8)
  }
})

test_that("a row-stochastic K reproduces the single-group result for
identical groups", {
  # For two groups with identical seeds and R, both groups' own convolved
  # pressure lambda[h] is equal at every step, so `mixed[k] = sum_h K[k, h] *
  # lambda[h] = lambda * sum_h K[k, h] = lambda` for ANY row-stochastic K
  # (each row summing to 1), regardless of its off-diagonal structure. This
  # closed-form invariant holds independently of hand_coupled_renewal above,
  # and is only preserved by the correct `mixing %*% lambda` orientation: a
  # transposed matrix would instead require K's columns (not rows) to sum to
  # 1, which this asymmetric K does not satisfy.
  gt <- c(0.2, 0.3, 0.5)
  seeds <- list(rep(6, length(gt)), rep(6, length(gt)))
  log_r <- list(rep(log(1.2), 20), rep(log(1.2), 20))
  # Row-stochastic (rows sum to 1) but not column-stochastic (columns sum to
  # 1.2 and 0.8) and not symmetric.
  K <- matrix(c(0.9, 0.1, 0.3, 0.7), nrow = 2, byrow = TRUE)

  stan_out <- run_multigroup_renewal(seeds, log_r, gt, mixing = K)
  single_ref <- run_multigroup_renewal(seeds[1], log_r[1], gt)[[1]]

  expect_equal(stan_out[[1]], single_ref, tolerance = 1e-8)
  expect_equal(stan_out[[2]], single_ref, tolerance = 1e-8)
})
