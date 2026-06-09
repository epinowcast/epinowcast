suppressMessages({
  library(cmdstanr)
  library(data.table)
})
set.seed(42)

## --- simulate a reporting triangle -------------------------------------
T <- 40L          # reference dates
D <- 15L          # max delay
# smooth latent log-rate (a deterministic curve stands in for the GP truth)
tt <- seq_len(T)
log_lambda <- 4.5 + 0.8 * sin(2 * pi * tt / 25) + 0.015 * tt
lambda <- exp(log_lambda)
# lognormal delay pmf truncated to 0..D
dmu <- 1.5; dsigma <- 0.5
cdf_hi <- plnorm(seq_len(D + 1), dmu, dsigma)
pmf <- diff(c(0, cdf_hi)); pmf <- pmf / sum(pmf)
phi_true <- 10

# full counts y[t, d]
ymat <- matrix(0L, T, D + 1)
for (t in seq_len(T)) {
  mu_cell <- lambda[t] * pmf
  ymat[t, ] <- rnbinom(D + 1, mu = mu_cell, size = phi_true)
}
true_total <- rowSums(ymat)

# triangle: observe cell (t, d) if t + d <= T  (delay d <= T - t)
cells <- data.table(expand.grid(t = seq_len(T), d = 0:D))
cells <- cells[d <= T - t]
cells[, y := ymat[cbind(t, d + 1)]]
row_obs_sum <- vapply(seq_len(T), function(t) {
  sum(ymat[t, seq_len(min(T - t, D) + 1)])
}, numeric(1))

standata <- list(
  T = T, D = D, n_obs = nrow(cells),
  y = cells$y, cell_t = cells$t, cell_d = cells$d,
  ref_x = as.numeric(tt), row_obs_sum = as.integer(row_obs_sum)
)

## --- compile -----------------------------------------------------------
message("compiling embedded-laplace model ...")
m_lap <- cmdstan_model("m2_nowcast.stan", cpp_options = list(stan_threads = FALSE))
message("compiling NUTS reference ...")
m_nuts <- cmdstan_model("m3_nuts.stan", cpp_options = list(stan_threads = FALSE))

## --- fit ---------------------------------------------------------------
t_lap <- system.time(
  f_lap <- m_lap$sample(
    standata, chains = 2, parallel_chains = 2,
    iter_warmup = 500, iter_sampling = 500, seed = 1, refresh = 0,
    show_messages = FALSE
  )
)
t_nuts <- system.time(
  f_nuts <- m_nuts$sample(
    standata, chains = 2, parallel_chains = 2,
    iter_warmup = 500, iter_sampling = 500, seed = 1, refresh = 0,
    show_messages = FALSE
  )
)

## --- compare hyperparameters ------------------------------------------
vars <- c("intercept", "gp_alpha", "gp_rho", "delay_mu", "delay_sigma", "phi")
s_lap <- f_lap$summary(vars)
s_nuts <- f_nuts$summary(vars)
cat("\n=== hyperparameters: embedded-laplace vs NUTS ===\n")
cmp <- data.table(
  var = vars,
  lap_mean = round(s_lap$mean, 3), nuts_mean = round(s_nuts$mean, 3),
  lap_q5 = round(s_lap$q5, 3), nuts_q5 = round(s_nuts$q5, 3),
  lap_q95 = round(s_lap$q95, 3), nuts_q95 = round(s_nuts$q95, 3)
)
print(cmp)

## --- compare nowcast (last 12 ref dates, where truncation bites) -------
nc_lap <- f_lap$summary("nowcast", "median", ~quantile(.x, c(0.05, 0.95)))
nc_nuts <- f_nuts$summary("nowcast", "median", ~quantile(.x, c(0.05, 0.95)))
setDT(nc_lap); setDT(nc_nuts)
nc_lap[, t := seq_len(T)]; nc_nuts[, t := seq_len(T)]
tail_t <- (T - 11):T
cat("\n=== nowcast totals, last 12 reference dates ===\n")
nccmp <- data.table(
  t = tail_t,
  truth = true_total[tail_t],
  obs = row_obs_sum[tail_t],
  lap_med = round(nc_lap$median[tail_t]),
  nuts_med = round(nc_nuts$median[tail_t]),
  lap_w = round(nc_lap$`95%`[tail_t] - nc_lap$`5%`[tail_t]),
  nuts_w = round(nc_nuts$`95%`[tail_t] - nc_nuts$`5%`[tail_t])
)
print(nccmp)

cat(sprintf("\nruntime: laplace %.1fs | NUTS %.1fs\n",
            t_lap["elapsed"], t_nuts["elapsed"]))
cat(sprintf("median |lap-nuts| nowcast diff (last 12): %.1f\n",
            median(abs(nccmp$lap_med - nccmp$nuts_med))))
cat(sprintf("median nowcast CrI width ratio lap/nuts (last 12): %.2f\n",
            median(nccmp$lap_w / nccmp$nuts_w)))
