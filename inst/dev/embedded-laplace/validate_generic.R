## Validate the generic embedded-Laplace nowcast against a matched NUTS
## reference. Exercises: a fixed-effect design (intercept + day-of-week),
## a full-rank GP latent trend, 2 groups, and an NB2 observation family.
suppressMessages({
  library(cmdstanr)
  library(data.table)
})
set.seed(42)

here <- function(f) {
  file.path(
    "/Users/lshsa2/code/epinowcast/epinowcast/worktrees",
    "embedded-laplace/inst/dev/embedded-laplace", f
  )
}

## --- simulation settings ----------------------------------------------
G <- 2L           # groups
T <- 40L          # reference dates per group
D <- 15L          # max delay
tt <- seq_len(T)
dow <- ((tt - 1) %% 7) + 1            # day-of-week index 1..7

## fixed-effect design: intercept + 6 day-of-week dummies (ref = dow 1),
## shared structure across groups but a different intercept per group.
## We build X with a per-group intercept column and shared dow columns.
make_X <- function() {
  dow_dum <- model.matrix(~ factor(dow))[, -1, drop = FALSE]  # 6 cols
  # per-group intercepts (G cols) + shared dow effects (6 cols)
  P <- G + ncol(dow_dum)
  X <- matrix(0, G * T, P)
  for (g in seq_len(G)) {
    rows <- (g - 1) * T + seq_len(T)
    X[rows, g] <- 1                      # group g intercept
    X[rows, (G + 1):P] <- dow_dum        # shared dow effects
  }
  list(X = X, P = P)
}
xd <- make_X()
X_fixed <- xd$X
P <- xd$P

## true fixed effects: group intercepts + dow effects
beta_int <- c(4.3, 4.7)                 # per-group intercepts
beta_dow <- c(0.15, 0.25, 0.10, -0.05, -0.30, -0.45)  # 6 dow contrasts
beta_true <- c(beta_int, beta_dow)

## true GP latent trend per group (smooth, group-specific deviations)
gp_true <- matrix(0, T, G)
gp_true[, 1] <- 0.5 * sin(2 * pi * tt / 22)
gp_true[, 2] <- 0.4 * cos(2 * pi * tt / 18) - 0.2

## delay pmf (lognormal, truncated 0..D)
dmu <- 1.5; dsigma <- 0.5
cdf_hi <- plnorm(seq_len(D + 1), dmu, dsigma)
pmf <- diff(c(0, cdf_hi)); pmf <- pmf / sum(pmf)
phi_true <- 10

## --- simulate full counts and triangle --------------------------------
mu_flat <- as.vector(X_fixed %*% beta_true)   # length G*T
mu_ref <- matrix(mu_flat, T, G)               # column g = group g (byrow=F)
# X rows are ordered group-major: row (g-1)*T + t, so reshape accordingly
mu_ref <- t(matrix(mu_flat, nrow = T, ncol = G))  # G x T
log_lambda <- matrix(0, G, T)
for (g in seq_len(G)) {
  log_lambda[g, ] <- mu_ref[g, ] + gp_true[, g]
}
lambda <- exp(log_lambda)

ymat <- array(0L, dim = c(G, T, D + 1))
for (g in seq_len(G)) {
  for (t in seq_len(T)) {
    ymat[g, t, ] <- rnbinom(D + 1, mu = lambda[g, t] * pmf, size = phi_true)
  }
}
true_total <- apply(ymat, c(1, 2), sum)       # G x T

## triangle cells: observe (g, t, d) if t + d <= T
cells <- CJ(g = seq_len(G), t = seq_len(T), d = 0:D)
cells <- cells[d <= T - t]
setorder(cells, g, t, d)                       # group-major for segment()
cells[, y := ymat[cbind(g, t, d + 1)]]

row_obs_sum <- matrix(0L, G, T)
for (g in seq_len(G)) {
  for (t in seq_len(T)) {
    row_obs_sum[g, t] <- sum(ymat[g, t, seq_len(min(T - t, D) + 1)])
  }
}

## --- HSGP basis (built but switched off here; satisfies the data block) -
M_hsgp <- 10L
L_hsgp <- 1.5 * (max(tt) - min(tt)) / 2       # boundary factor * half-range
xc <- tt - mean(tt)                            # centred coords
PHI <- matrix(0, T, M_hsgp)
hsgp_lambda <- numeric(M_hsgp)
for (m in seq_len(M_hsgp)) {
  hsgp_lambda[m] <- (m * pi / (2 * L_hsgp))^2
  PHI[, m] <- 1 / sqrt(L_hsgp) *
    sin(m * pi * (xc + L_hsgp) / (2 * L_hsgp))
}

## RE design placeholder (switched off): single dummy column
Z <- matrix(0, T, 1)

standata <- list(
  G = G, T = T, D = D, n_obs = nrow(cells),
  y = cells$y, cell_g = cells$g, cell_t = cells$t, cell_d = cells$d,
  P = P, X_fixed = X_fixed,
  use_re = 0L, q_re = 1L, Z = Z,
  use_gp = 1L, gp_kernel = 1L, ref_x = as.numeric(tt),
  use_hsgp = 0L, M_hsgp = M_hsgp, PHI = PHI, hsgp_lambda = hsgp_lambda,
  jitter = 1e-6,
  obs_family = 1L,
  prior_beta_mean = rep(0, P), prior_beta_sd = rep(5, P),
  prior_sigma_re_sd = 1,
  prior_gp_alpha_sd = 1,
  prior_gp_rho_a = 5, prior_gp_rho_b = 5,
  prior_hsgp_alpha_sd = 1,
  prior_hsgp_rho_a = 5, prior_hsgp_rho_b = 5,
  prior_delay_mu_mean = 1.5, prior_delay_mu_sd = 1,
  prior_delay_sigma_sd = 0.5,
  prior_phi_sd = 5,
  row_obs_sum = row_obs_sum
)
# better intercept priors centred near data scale
standata$prior_beta_mean[seq_len(G)] <- 4.5

## --- compile -----------------------------------------------------------
message("compiling generic embedded-laplace model ...")
m_lap <- cmdstan_model(here("generic_nowcast_laplace.stan"))
message("compiling generic NUTS reference ...")
m_nuts <- cmdstan_model(here("generic_nowcast_nuts.stan"))

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
vars <- c(
  paste0("beta_fixed[", seq_len(P), "]"),
  "gp_alpha", "gp_rho", "delay_mu", "delay_sigma", "phi"
)
s_lap <- f_lap$summary(vars)
s_nuts <- f_nuts$summary(vars)
true_vals <- c(beta_true, NA, NA, dmu, dsigma, phi_true)
cat("\n=== hyperparameters: embedded-laplace vs NUTS ===\n")
cmp <- data.table(
  var = vars, truth = round(true_vals, 3),
  lap_mean = round(s_lap$mean, 3), nuts_mean = round(s_nuts$mean, 3),
  lap_q5 = round(s_lap$q5, 3), nuts_q5 = round(s_nuts$q5, 3),
  lap_q95 = round(s_lap$q95, 3), nuts_q95 = round(s_nuts$q95, 3)
)
print(cmp)

## --- compare nowcasts per group, last 10 ref dates --------------------
nc_lap <- f_lap$summary("nowcast", "median", ~quantile(.x, c(0.05, 0.95)))
nc_nuts <- f_nuts$summary("nowcast", "median", ~quantile(.x, c(0.05, 0.95)))
setDT(nc_lap); setDT(nc_nuts)
# nowcast is array[G, T] -> Stan column-major: index = g + (t-1)*G
idx <- function(g, t) g + (t - 1) * G
tail_t <- (T - 9):T
all_ratios <- c(); all_absdiff <- c()
for (g in seq_len(G)) {
  rows <- idx(g, tail_t)
  lm <- nc_lap$median[rows];  nm <- nc_nuts$median[rows]
  lw <- nc_lap$`95%`[rows] - nc_lap$`5%`[rows]
  nw <- nc_nuts$`95%`[rows] - nc_nuts$`5%`[rows]
  cat(sprintf("\n=== group %d nowcast, last 10 ref dates ===\n", g))
  print(data.table(
    t = tail_t, truth = true_total[g, tail_t],
    obs = row_obs_sum[g, tail_t],
    lap_med = round(lm), nuts_med = round(nm),
    lap_w = round(lw), nuts_w = round(nw)
  ))
  all_ratios <- c(all_ratios, lw / nw)
  all_absdiff <- c(all_absdiff, abs(lm - nm))
}

cat(sprintf("\nruntime: laplace %.1fs | NUTS %.1fs (speedup %.1fx)\n",
            t_lap["elapsed"], t_nuts["elapsed"],
            t_nuts["elapsed"] / t_lap["elapsed"]))
cat(sprintf("median |lap-nuts| nowcast-median diff (last 10, both grps): %.1f\n",
            median(all_absdiff)))
cat(sprintf("median nowcast CrI width ratio lap/nuts (last 10): %.2f\n",
            median(all_ratios)))

## hyperparameter agreement metric (relative mean diff)
hp <- !is.na(true_vals)
rel <- abs(s_lap$mean - s_nuts$mean) /
  pmax(abs(s_nuts$mean), 1e-6)
cat(sprintf("max relative hyperparam mean diff (lap vs nuts): %.3f\n",
            max(rel)))
