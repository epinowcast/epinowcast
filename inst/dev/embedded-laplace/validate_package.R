## Validate the package embedded-Laplace path against a matched NUTS reference.
##
## IMPORTANT modelling note. The standard `epinowcast()` expectation models the
## log GROWTH RATE: `r` effects are integrated into a latent incidence curve
## via the renewal/growth recursion (lexp[t] = lexp[t-1] + r[t]). The
## embedded-Laplace model here instead treats the linear predictor as the log
## LEVEL of expected counts (a zero-mean Gaussian field around a fixed-effect
## mean). These are different parameterisations, so a direct `epinowcast()`
## vs `enw_laplace()` comparison on the same formula compares different models
## and is NOT a valid test of the Laplace approximation.
##
## To isolate the approximation itself, this script compares the package
## Laplace path against a NUTS reference that uses the IDENTICAL log-level model
## (same data list from `enw_laplace_data()`, same priors, same delay and
## observation family) but samples the latent field theta ~ MVN(0, K) instead
## of marginalising it. Any difference is then attributable to the Laplace
## approximation, not to a specification mismatch.
##
## Acceptance: nowcast medians agree within Monte Carlo noise and the CrI width
## ratio (laplace / NUTS) sits in ~0.9-1.1.
suppressMessages({
  library(cmdstanr)
  library(data.table)
})
root <- "/Users/lshsa2/code/epinowcast/epinowcast/worktrees/embedded-laplace"
devtools::load_all(root, quiet = TRUE)
set.seed(1)

here <- function(f) file.path(root, "inst/dev/embedded-laplace", f)

## Models: the package Laplace model and the matched NUTS reference.
message("compiling embedded-Laplace model ...")
m_lap <- enw_laplace_model(verbose = FALSE)
message("compiling matched NUTS reference ...")
m_nuts <- cmdstan_model(
  here("epinowcast_laplace_nuts.stan"),
  include_paths = file.path(root, "inst/stan"),
  cpp_options = list(stan_threads = TRUE)
)

fit_both <- function(pobs, label, expectation, chains = 2,
                     warmup = 500, sampling = 500) {
  dl <- enw_laplace_data(pobs, expectation = expectation)
  init_fn <- enw_laplace_inits(dl)
  t_lap <- system.time(
    f_lap <- m_lap$sample(
      data = dl, init = init_fn, chains = chains, parallel_chains = chains,
      iter_warmup = warmup, iter_sampling = sampling, seed = 1,
      refresh = 0, show_messages = FALSE, threads_per_chain = 1
    )
  )
  t_nuts <- system.time(
    f_nuts <- m_nuts$sample(
      data = dl, init = init_fn, chains = chains, parallel_chains = chains,
      iter_warmup = warmup, iter_sampling = sampling, seed = 1,
      refresh = 0, show_messages = FALSE, threads_per_chain = 1
    )
  )
  list(
    lap = f_lap, nuts = f_nuts, dl = dl,
    t_lap = t_lap["elapsed"], t_nuts = t_nuts["elapsed"], label = label
  )
}

compare <- function(res) {
  cat(sprintf("\n========== %s ==========\n", res$label))
  g <- res$dl$g
  nc_t <- res$dl$nc_t
  nc_lap <- res$lap$summary(
    "pp_inf_obs", "median", ~quantile(.x, c(0.05, 0.95))
  )
  nc_nuts <- res$nuts$summary(
    "pp_inf_obs", "median", ~quantile(.x, c(0.05, 0.95))
  )
  setDT(nc_lap)
  setDT(nc_nuts)
  ## pp_inf_obs is group-major; index = (gg - 1) * nc_t + j.
  abs_diff <- c()
  width_ratio <- c()
  for (gg in seq_len(g)) {
    rows <- ((gg - 1) * nc_t + 1):(gg * nc_t)
    tail_rows <- tail(rows, 10)
    lm <- nc_lap$median[tail_rows]
    nm <- nc_nuts$median[tail_rows]
    lw <- nc_lap$`95%`[tail_rows] - nc_lap$`5%`[tail_rows]
    nw <- nc_nuts$`95%`[tail_rows] - nc_nuts$`5%`[tail_rows]
    cat(sprintf("\n--- group %d nowcast (last 10) ---\n", gg))
    print(data.table(
      lap_med = round(lm), nuts_med = round(nm),
      lap_w = round(lw), nuts_w = round(nw)
    ))
    abs_diff <- c(abs_diff, abs(lm - nm))
    width_ratio <- c(width_ratio, lw / nw)
  }
  cat(sprintf(
    "\nmedian |lap-nuts| nowcast-median diff (last 10): %.1f\n",
    median(abs_diff)
  ))
  cat(sprintf(
    "median nowcast CrI width ratio lap/nuts (last 10): %.2f\n",
    median(width_ratio)
  ))

  hp_lap <- c("refp_mean_int", "refp_sd_int", "sqrt_phi", "sigma_re")
  s_lap <- res$lap$summary(hp_lap)
  s_nuts <- res$nuts$summary(hp_lap)
  setDT(s_lap)
  setDT(s_nuts)
  cmp <- merge(
    s_lap[, .(variable, lap_mean = round(mean, 3),
              lap_q5 = round(q5, 3), lap_q95 = round(q95, 3))],
    s_nuts[, .(variable, nuts_mean = round(mean, 3),
               nuts_q5 = round(q5, 3), nuts_q95 = round(q95, 3))],
    by = "variable"
  )
  cat("\n--- hyperparameters ---\n")
  print(cmp)

  cat(sprintf(
    "\nruntime: laplace %.1fs | NUTS %.1fs (speedup %.2fx)\n",
    res$t_lap, res$t_nuts, res$t_nuts / res$t_lap
  ))
  invisible(list(abs_diff = abs_diff, width_ratio = width_ratio))
}

## --- 1. Example size (T = 40, max_delay = 20, 1 group) ----------------
pobs_small <- enw_example("preprocessed")
res_small <- fit_both(
  pobs_small, "example (T=40, D=20, G=1)",
  expectation = enw_expectation(~ 1 + (1 | day_of_week), data = pobs_small)
)
cmp_small <- compare(res_small)

## --- 2. Larger simulated size (T = 120, max_delay = 30, 2 groups) -----
simulate_obs <- function(t_len = 120, dmax = 30, groups = 2) {
  dates <- seq.Date(as.Date("2021-01-01"), by = "day", length.out = t_len)
  dmu <- 1.6
  dsigma <- 0.6
  pmf <- diff(plnorm(0:dmax, dmu, dsigma))
  pmf <- pmf / sum(pmf)
  out <- list()
  for (gg in seq_len(groups)) {
    base <- 4.2 + 0.3 * gg
    trend <- 0.4 * sin(2 * pi * seq_len(t_len) / 60 + gg)
    lambda <- exp(base + trend)
    rows <- list()
    for (tt in seq_len(t_len)) {
      counts <- rnbinom(dmax, mu = lambda[tt] * pmf, size = 10)
      for (d in 0:(dmax - 1)) {
        rows[[length(rows) + 1]] <- data.table(
          reference_date = dates[tt], report_date = dates[tt] + d,
          confirm = counts[d + 1], gid = gg
        )
      }
    }
    out[[gg]] <- rbindlist(rows)
  }
  dt <- rbindlist(out)
  dt <- dt[, .(confirm = sum(confirm)),
           by = .(reference_date, report_date, gid)]
  setorder(dt, gid, reference_date, report_date)
  dt[, confirm := cumsum(confirm), by = .(reference_date, gid)]
  dt[, location := factor(gid)]
  dt[, gid := NULL]
  dt[]
}

obs_large <- simulate_obs()
obs_large <- enw_complete_dates(obs_large, by = "location")
pobs_large <- enw_preprocess_data(obs_large, by = "location", max_delay = 30)
res_large <- fit_both(
  pobs_large, "simulated (T=120, D=30, G=2)",
  expectation = enw_expectation(~ 1 + (1 | day_of_week), data = pobs_large),
  warmup = 400, sampling = 400
)
cmp_large <- compare(res_large)

## --- acceptance summary -----------------------------------------------
cat("\n========== ACCEPTANCE ==========\n")
for (nm in c("example", "large")) {
  cmp <- if (nm == "example") cmp_small else cmp_large
  wr <- median(cmp$width_ratio)
  ad <- median(cmp$abs_diff)
  ok <- wr > 0.85 && wr < 1.15
  cat(sprintf(
    "%s: median width ratio %.2f, median |diff| %.1f (%s)\n",
    nm, wr, ad, if (ok) "PASS" else "CHECK"
  ))
}
