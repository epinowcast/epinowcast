skip_on_cran()
skip_on_local()

# Compile the standalone test model once per file
delay_multinomial_model <- function() {
  cmdstanr::cmdstan_model(
    file.path("stan", "test_delay_multinomial.stan"),
    include_paths = system.file("stan", package = "epinowcast")
  )
}

eval_delay_multinomial <- function(obs, log_exp_obs) {
  model <- delay_multinomial_model()
  fit <- model$sample(
    data = list(
      n = length(obs), obs = as.integer(obs), log_exp_obs = log_exp_obs
    ),
    fixed_param = TRUE, iter_sampling = 1, chains = 1, refresh = 0,
    show_messages = FALSE
  )
  as.numeric(fit$draws("lpmf", format = "matrix")[1, 1])
}

test_that("delay_multinomial_lpmf() matches dmultinom for full cells", {
  pmf <- (plnorm(1:5, 1.2, 0.6) - plnorm(0:4, 1.2, 0.6))
  pmf <- pmf / sum(pmf)
  obs <- c(40, 25, 15, 12, 8)
  # log_exp_obs is log(total) + log(p_d); the total offset cancels
  log_exp_obs <- log(100) + log(pmf)
  expect_equal(
    eval_delay_multinomial(obs, log_exp_obs),
    stats::dmultinom(obs, prob = pmf, log = TRUE),
    tolerance = 1e-6
  )
})

test_that("delay_multinomial_lpmf() is invariant to the total offset", {
  pmf <- c(0.5, 0.3, 0.15, 0.05)
  obs <- c(50, 30, 15, 5)
  expect_equal(
    eval_delay_multinomial(obs, log(7) + log(pmf)),
    eval_delay_multinomial(obs, log(999) + log(pmf)),
    tolerance = 1e-6
  )
})

test_that("delay_multinomial_lpmf() truncates by renormalising cells", {
  # Truncated multinomial: only the first three delays observed.
  # Renormalising over the observed cells divides by F(2), matching the
  # truncated multinomial with probs p_d / F(T - t).
  pmf <- c(0.4, 0.3, 0.2, 0.1)
  obs <- c(40, 30, 20)
  trunc_pmf <- pmf[1:3] / sum(pmf[1:3])
  expect_equal(
    eval_delay_multinomial(obs, log(90) + log(pmf[1:3])),
    stats::dmultinom(obs, prob = trunc_pmf, log = TRUE),
    tolerance = 1e-6
  )
})
