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
  out <- log_expected_latent_from_r(
    lexp_latent_int, as.numeric(log_r), array(0L), r_t, gt_n, gt_n,
    rev(log(generation_time)), ft, 1L, array(population), 1L, pop_floor
  )
  exp(out[[1]])
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
