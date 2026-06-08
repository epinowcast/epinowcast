# Tests for the gp() formula helper, parser, and constructor.

obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][age_group == "00+"],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 60)
pobs <- suppressWarnings(enw_preprocess_data(
  obs,
  by = c("age_group", "location"), max_delay = 14
))
data <- pobs$metareference[[1]]

test_that("gp() returns an enw_gp_term with the expected fields", {
  a <- gp(week)
  expect_s3_class(a, "enw_gp_term")
  expect_identical(a$time, "week")
  expect_null(a$by)
  expect_identical(a$kernel, "matern32")
  expect_identical(a$basis_prop, 0.2)

  b <- gp(week, day_of_week, kernel = "se", basis_prop = 0.5)
  expect_identical(b$by, "day_of_week")
  expect_identical(b$kernel, "se")
  expect_identical(b$basis_prop, 0.5)
})

test_that("gp() maps kernel aliases to the right Stan gp_type/nu", {
  expect_identical(gp(week, kernel = "matern32")$gp_type, 2L)
  expect_identical(gp(week, kernel = "matern32")$nu, 1.5)
  expect_identical(gp(week, kernel = "ou")$nu, 0.5)
  expect_identical(gp(week, kernel = "se")$gp_type, 0L)
  expect_identical(gp(week, kernel = "periodic")$gp_type, 1L)
})

test_that("gp() rejects invalid hyperparameters", {
  expect_error(gp(week, kernel = "nonsense"), "kernel")
  expect_error(gp(week, basis_prop = 0), "basis_prop")
  expect_error(gp(week, basis_prop = -1), "basis_prop")
  expect_error(gp(week, basis_prop = "x"), "basis_prop")
  expect_error(gp(week, boundary_scale = 0), "boundary_scale")
})

test_that("gp() defaults to d = 0 and validates the differencing order", {
  expect_identical(gp(week)$d, 0L)
  expect_identical(gp(week, d = 1)$d, 1L)
  expect_identical(gp(week, d = 2)$d, 2L)
  expect_error(gp(week, d = -1), "non-negative integer")
  expect_error(gp(week, d = 1.5), "non-negative integer")
  expect_error(gp(week, d = "x"), "non-negative integer")
})

test_that("construct_gp() sizes the basis to T - d for differencing", {
  T_len <- length(unique(data$week))
  s0 <- construct_gp(gp(week, d = 0), data)
  expect_identical(s0$d, 0L)
  expect_identical(nrow(s0$PHI), T_len)
  expect_identical(s0$M, as.integer(ceiling(T_len * 0.2)))

  s1 <- construct_gp(gp(week, d = 1), data)
  expect_identical(s1$d, 1L)
  # Basis is built on the T - d free values that are integrated in Stan.
  expect_identical(nrow(s1$PHI), T_len - 1L)
  expect_identical(s1$M, as.integer(ceiling((T_len - 1L) * 0.2)))
  # The full integrated series is still length T.
  expect_identical(s1$T, T_len)
})

test_that("construct_gp() rejects a series too short for d", {
  expect_error(
    construct_gp(gp(week, d = 100), data),
    "only .* time points"
  )
})

test_that("gp() requires a time argument", {
  expect_error(gp(), "time")
})

test_that("gp_terms() picks out gp calls only", {
  expect_identical(
    gp_terms(~ 1 + age_group + gp(week)),
    "gp(week)"
  )
  expect_identical(
    gp_terms(~ 1 + gp(week, kernel = "se") + gp(day)),
    c("gp(week, kernel = \"se\")", "gp(day)")
  )
  expect_identical(gp_terms(~ 1 + age_group + arima(week)), character(0))
  # Must not match inside a random effect term.
  expect_identical(gp_terms(~ 1 + (1 | gp)), character(0))
})

test_that("remove_gp_terms() strips gp calls", {
  expect_identical(
    format(remove_gp_terms(~ 1 + age_group + gp(week))),
    "~1 + age_group"
  )
  expect_identical(
    format(remove_gp_terms(~ 1 + gp(week) + gp(day))),
    "~1"
  )
  # Leaves other terms (including arima) untouched.
  expect_identical(
    format(remove_gp_terms(~ 1 + arima(week) + gp(day))),
    "~1 + arima(week)"
  )
})

test_that("parse_formula() routes gp terms separately", {
  parsed <- parse_formula(~ 1 + age_group + gp(week) + arima(day))
  expect_identical(parsed$gp, "gp(week)")
  expect_identical(parsed$arima, "arima(day)")
  expect_identical(parsed$fixed, c("1", "age_group"))
})

test_that("construct_gp() builds correct basis metadata", {
  spec <- construct_gp(gp(week), data)
  expect_identical(spec$T, length(unique(data$week)))
  expect_identical(spec$G, 1L)
  expect_identical(length(spec$time_idx), nrow(data))
  expect_true(all(spec$time_idx >= 1L & spec$time_idx <= spec$T))
  expect_true(all(spec$group_idx == 1L))
  expect_identical(spec$gp_type, 2L)
  expect_identical(spec$nu, 1.5)
  # M = ceiling(T * basis_prop)
  expect_identical(spec$M, as.integer(ceiling(spec$T * 0.2)))
  # Basis matrix PHI is T x M.
  expect_identical(dim(spec$PHI), c(spec$T, spec$M))

  grouped <- construct_gp(gp(week, day_of_week), data)
  expect_identical(grouped$G, length(unique(data$day_of_week)))
  expect_true(all(grouped$group_idx >= 1L & grouped$group_idx <= grouped$G))
})

test_that("construct_gp() errors on missing or non-numeric time", {
  expect_error(construct_gp(gp(missing_var), data), "not present")
  data2 <- data.table::copy(data)
  data2[, day_of_week := as.character(day_of_week)]
  expect_error(construct_gp(gp(day_of_week), data2), "must be numeric")
})

test_that("construct_gp() rejects a term it did not build", {
  expect_error(
    construct_gp(list(time = "week"), data),
    "constructed by"
  )
})

test_that("enw_formula() collects gp specs alongside fixed/random", {
  f <- enw_formula(~ 1 + (1 | day_of_week) + gp(week), data, sparse = FALSE)
  expect_s3_class(f, "enw_formula")
  expect_length(f$gp, 1L)
  expect_identical(f$gp[[1]]$gp_type, 2L)
  expect_false(any(grepl("gp", colnames(f$fixed$design))))
})

test_that("enw_formula_as_data_list() ships the gp Stan data", {
  f <- enw_formula(~ 1 + gp(week, day_of_week), data, sparse = FALSE)
  dl <- enw_formula_as_data_list(f, "ref")

  expect_identical(dl$ref_gp_present, 1L)
  expect_identical(dl$ref_gp_type, 2L)
  expect_identical(dl$ref_gp_nu, 1.5)
  expect_identical(dl$ref_gp_d, 0L)
  expect_identical(dl$ref_gp_T, length(unique(data$week)))
  expect_identical(dl$ref_gp_G, length(unique(data$day_of_week)))
  expect_identical(dl$ref_gp_M, as.integer(ceiling(dl$ref_gp_T * 0.2)))
  expect_identical(dim(dl$ref_gp_PHI), c(dl$ref_gp_T, dl$ref_gp_M))

  spec <- construct_gp(gp(week, day_of_week), data)
  expect_identical(
    dl$ref_gp_flat_idx,
    as.integer((spec$group_idx - 1L) * spec$T + spec$time_idx)
  )
  expect_true(all(
    dl$ref_gp_flat_idx >= 1L &
      dl$ref_gp_flat_idx <= dl$ref_gp_T * dl$ref_gp_G
  ))
})

test_that("enw_formula_as_data_list() returns inert defaults without gp", {
  f <- enw_formula(~ 1 + (1 | day_of_week), data)
  dl <- enw_formula_as_data_list(f, "ref")
  expect_identical(dl$ref_gp_present, 0L)
  expect_identical(dl$ref_gp_T, 0L)
  expect_identical(dl$ref_gp_M, 0L)
  expect_identical(dl$ref_gp_d, 0L)
  expect_identical(dl$ref_gp_n_obs, 0L)
})

test_that("enw_formula_as_data_list() ships the gp differencing order", {
  f <- enw_formula(~ 1 + gp(week, d = 1), data, sparse = FALSE)
  dl <- enw_formula_as_data_list(f, "ref")
  expect_identical(dl$ref_gp_d, 1L)
  # The basis matrix has T - d rows; the integrated series stays length T.
  expect_identical(nrow(dl$ref_gp_PHI), dl$ref_gp_T - dl$ref_gp_d)
  expect_identical(dl$ref_gp_M, as.integer(ceiling(
    (dl$ref_gp_T - dl$ref_gp_d) * 0.2
  )))
})

test_that("gp_d flows through to Stan data on every supporting module", {
  exp <- enw_expectation(r = ~ 1 + gp(week, d = 1), data = pobs)
  expect_identical(exp$data$expr_gp_d, 1L)
  expect_identical(
    nrow(exp$data$expr_gp_PHI), exp$data$expr_gp_T - 1L
  )

  ref <- suppressWarnings(enw_reference(~ 1 + gp(week, d = 1), data = pobs))
  expect_identical(ref$data$refp_gp_d, 1L)

  rep_mod <- enw_report(~ 1 + gp(day, d = 1), data = pobs)
  expect_identical(rep_mod$data$rep_gp_d, 1L)
})

test_that("enw_formula_as_data_list() rejects multiple gp terms", {
  expect_error(
    enw_formula_as_data_list(
      enw_formula(~ 1 + gp(week) + gp(month), data, sparse = FALSE),
      "ref"
    ),
    "Only one `gp\\(\\)` term"
  )
})

test_that("enw_expectation() wires a gp() growth-rate term to Stan", {
  exp <- enw_expectation(r = ~ 1 + gp(week), data = pobs)
  expect_identical(exp$data$expr_gp_present, 1L)
  expect_identical(exp$data$expr_gp_type, 2L)
  expect_true(exp$data$expr_gp_M > 0L)
  # GP length-scale and magnitude priors must be exposed as data.
  expect_true("expr_gp_rho" %in% exp$priors$variable)
  expect_true("expr_gp_alpha" %in% exp$priors$variable)
})

test_that("enw_formula() supports a gp() term on a sparse design", {
  # GP works on sparse-design modules: the joint dedup must remap the GP
  # time/group indices onto the deduplicated fixed$index rows.
  f <- enw_formula(~ 1 + gp(week), data, sparse = TRUE)
  expect_s3_class(f, "enw_formula")
  expect_length(f$gp, 1L)
  # After dedup the GP lookup vectors are one entry per unique fdesign
  # row, and the flat_idx must point inside the (T x G) latent matrix.
  spec <- f$gp[[1]]
  expect_identical(length(spec$time_idx), nrow(f$fixed$design))
  expect_true(all(spec$time_idx >= 1L & spec$time_idx <= spec$T))
  expect_true(all(spec$group_idx >= 1L & spec$group_idx <= spec$G))
})

test_that("gp_specs time/group are remapped under the joint sparse dedup", {
  # With only a covariate that is constant in time, the dense design has
  # one row per (week) but the sparse dedup collapses identical covariate
  # rows; the GP lookup must follow the deduplicated index so the
  # column-major flat_idx still gathers the right latent cell.
  f <- enw_formula(~ 1 + gp(week), data, sparse = TRUE)
  spec <- f$gp[[1]]
  dl <- enw_formula_as_data_list(f, "ref")
  # flat_idx is rebuilt from the remapped indices and must be one per
  # fdesign row, all inside the (T x G) matrix.
  expect_identical(length(dl$ref_gp_flat_idx), nrow(f$fixed$design))
  expect_identical(
    dl$ref_gp_flat_idx,
    as.integer((spec$group_idx - 1L) * spec$T + spec$time_idx)
  )
  expect_true(all(
    dl$ref_gp_flat_idx >= 1L &
      dl$ref_gp_flat_idx <= dl$ref_gp_T * dl$ref_gp_G
  ))
  # The sparse findex must address every fdesign row.
  expect_identical(max(f$fixed$index), nrow(f$fixed$design))
})

test_that("a joint arima + gp sparse dedup keeps both lookups aligned", {
  f <- enw_formula(~ 1 + arima(week) + gp(week), data, sparse = TRUE)
  a <- f$arima[[1]]
  gpe <- f$gp[[1]]
  n_rows <- nrow(f$fixed$design)
  # Both terms' lookup vectors are one entry per deduplicated row.
  expect_identical(length(a$time_idx), n_rows)
  expect_identical(length(gpe$time_idx), n_rows)
  # findex addresses exactly the deduplicated rows.
  expect_identical(max(f$fixed$index), n_rows)
})

test_that("epinowcast() fits a gp() growth-rate term in compiled Stan", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  # This is the only path that exercises apply_gp_term() / update_gp() in
  # compiled Stan, so without it a regression would pass CI silently.
  fit_pobs <- enw_example("preprocessed")
  exp <- enw_expectation(r = ~ 1 + gp(week), data = fit_pobs)
  nowcast_gp <- suppressWarnings(epinowcast(
    fit_pobs,
    expectation = exp,
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
      iter_warmup = 250, iter_sampling = 250, show_messages = FALSE,
      show_exceptions = FALSE, refresh = 0, adapt_delta = 0.95,
      max_treedepth = 12
    )
  ))
  expect_convergence(nowcast_gp, rhat = 1.1)
  # GP hyperparameters must be present and finite in the fit.
  draws <- suppressWarnings(summary(nowcast_gp, type = "fit"))
  gp_pars <- draws[grepl("expr_gp_(rho|alpha)", variable)]
  expect_true(nrow(gp_pars) >= 2)
  expect_true(all(is.finite(gp_pars$mean)))
})

test_that("gp(d = 0) reproduces the stationary fit and d = 1 integrates", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  fit_pobs <- enw_example("preprocessed")
  # The d = 1 integrated GP is funnel-prone, so it needs a stronger sampler
  # and more warmup to converge robustly (a borderline adapt_delta tips into
  # divergences under small perturbations, e.g. covr instrumentation).
  fit_opts <- enw_fit_opts(
    save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
    iter_warmup = 500, iter_sampling = 500, show_messages = FALSE,
    show_exceptions = FALSE, refresh = 0, adapt_delta = 0.99, seed = 1,
    max_treedepth = 12
  )
  # d = 0 must reproduce the default stationary gp() exactly: same data
  # shipped to Stan (the differencing path is inert).
  exp_default <- enw_expectation(r = ~ 1 + gp(week), data = fit_pobs)
  exp_d0 <- enw_expectation(r = ~ 1 + gp(week, d = 0), data = fit_pobs)
  expect_identical(exp_d0$data$expr_gp_d, 0L)
  expect_identical(
    exp_default$data$expr_gp_PHI, exp_d0$data$expr_gp_PHI
  )
  expect_identical(
    exp_default$data$expr_gp_M, exp_d0$data$expr_gp_M
  )

  # d = 1 integrates the growth-rate process once: it fits and the
  # basis is built on T - 1 free values.
  exp_d1 <- enw_expectation(r = ~ 1 + gp(week, d = 1), data = fit_pobs)
  expect_identical(exp_d1$data$expr_gp_d, 1L)
  expect_identical(
    nrow(exp_d1$data$expr_gp_PHI), exp_d1$data$expr_gp_T - 1L
  )
  nowcast_d1 <- suppressWarnings(epinowcast(
    fit_pobs,
    expectation = exp_d1,
    obs = enw_obs(family = "poisson", data = fit_pobs),
    fit = fit_opts
  ))
  expect_convergence(nowcast_d1, rhat = 1.1)
})

test_that("a d = 1 gp() recovers a known integrated (drifting) trend", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  # Standalone HSGP model with d = 1 must integrate the latent process
  # and anchor f[1] = 0, recovering a smooth drifting trend.
  stan_dir <- system.file("stan", package = "epinowcast")
  model_code <- paste(
    "functions {",
    "  #include functions/gaussian_process.stan",
    "}",
    "data {",
    "  int<lower=1> T; int<lower=1> M; real<lower=0> L;",
    "  matrix[T - 1, M] PHI; vector[T] y; real<lower=0> obs_sd;",
    "}",
    "transformed data {",
    "  array[T] int idx; for (i in 1:T) idx[i] = i;",
    "}",
    "parameters {",
    "  vector[M] eta; real<lower=0> rho; real<lower=0> alpha;",
    "}",
    "transformed parameters {",
    "  vector[T] f = apply_gp_term(",
    "    rep_vector(0.0, T), 1, T, 1, M, L, 2, 1.5, 1,",
    "    PHI, to_matrix(eta, M, 1), {rho}, {alpha}, idx);",
    "}",
    "model {",
    "  eta ~ std_normal(); rho ~ lognormal(log(10), 0.5);",
    "  alpha ~ normal(0, 1); y ~ normal(f, obs_sd);",
    "}",
    sep = "\n"
  )
  mod <- cmdstanr::cmdstan_model(
    cmdstanr::write_stan_file(model_code),
    include_paths = stan_dir
  )
  T_len <- 40L
  L <- 1.5
  M <- ceiling((T_len - 1L) * 0.4)
  # A smooth drifting trend that starts at zero (matching the d = 1
  # anchoring) so the GP carries the whole shape.
  x <- seq_len(T_len)
  true_f <- cumsum(c(0, 0.3 * sin(2 * pi * x[-1] / T_len)))
  obs_sd <- 0.1
  set.seed(1)
  y <- true_f + rnorm(T_len, 0, obs_sd)
  fit <- mod$sample(
    data = list(
      T = T_len, M = M, L = L,
      PHI = {
        xs <- seq_len(T_len - 1L)
        xs <- 2 * (xs - mean(xs)) / (max(xs) - 1)
        sin(outer(pi / (2 * L) * (xs + L), seq_len(M))) / sqrt(L)
      },
      y = y, obs_sd = obs_sd
    ),
    chains = 2, parallel_chains = 2, iter_warmup = 1000,
    iter_sampling = 500, adapt_delta = 0.95, seed = 1, refresh = 0,
    show_messages = FALSE, show_exceptions = FALSE
  )
  fsum <- fit$summary("f")
  fhat <- fsum$mean
  # The first value is anchored to zero by construction.
  expect_lt(abs(fhat[1]), 1e-8)
  # The posterior mean tracks the integrated trend.
  expect_lt(sqrt(mean((fhat - true_f)^2)), 0.15)
  expect_true(all(fit$summary(c("rho", "alpha"))$rhat < 1.1))
})

test_that("gp() wires data and priors into every supporting module", {
  # Every module that builds a predictor via regression_predictor() can
  # take a gp() term: the parametric/non-parametric reference, the
  # report-time hazards, and the missing-reference proportion.
  ref <- suppressWarnings(enw_reference(~ 1 + gp(week), data = pobs))
  expect_identical(ref$data$refp_gp_present, 1L)
  expect_true("refp_gp_rho" %in% ref$priors$variable)
  expect_true("refp_gp_alpha" %in% ref$priors$variable)
  expect_true("refp_gp_sd_alpha" %in% ref$priors$variable)

  refnp <- suppressWarnings(
    enw_reference(~1, non_parametric = ~ 1 + gp(delay), data = pobs)
  )
  expect_identical(refnp$data$refnp_gp_present, 1L)
  expect_true("refnp_gp_rho" %in% refnp$priors$variable)

  rep_mod <- enw_report(~ 1 + gp(day), data = pobs)
  expect_identical(rep_mod$data$rep_gp_present, 1L)
  expect_true("rep_gp_rho" %in% rep_mod$priors$variable)
})

test_that("epinowcast() fits a gp() term on a sparse reference module", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  # The parametric reference-delay mean uses a sparse design with the
  # joint (covariate row x time x group) dedup. This exercises the GP
  # sparse-dedup remap end-to-end in compiled Stan.
  fit_pobs <- enw_example("preprocessed")
  ref_gp <- suppressWarnings(enw_reference(~ 1 + gp(week), data = fit_pobs))
  expect_identical(ref_gp$data$refp_gp_present, 1L)
  nowcast_gp <- suppressWarnings(epinowcast(
    fit_pobs,
    expectation = enw_expectation(~1, data = fit_pobs),
    reference = ref_gp,
    obs = enw_obs(family = "poisson", data = fit_pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
      iter_warmup = 250, iter_sampling = 250, show_messages = FALSE,
      show_exceptions = FALSE, refresh = 0, adapt_delta = 0.95
    )
  ))
  expect_convergence(nowcast_gp, rhat = 1.1)
  draws <- suppressWarnings(summary(nowcast_gp, type = "fit"))
  gp_pars <- draws[grepl("refp_gp_(rho|alpha)", variable)]
  expect_true(nrow(gp_pars) >= 2)
  expect_true(all(is.finite(gp_pars$mean)))
})

test_that("a grouped gp() term gives differing per-group realisations", {
  skip_on_cran()
  skip_on_os("windows")
  skip_on_local()
  # Build a small two-group preprocessed object so the by-group GP has
  # more than one level to realise independently.
  grp_obs <- germany_covid19_hosp[
    location == "DE" & age_group %in% c("00-04", "80+")
  ]
  grp_obs <- enw_filter_report_dates(grp_obs, remove_days = 30)
  grp_obs <- enw_filter_reference_dates(grp_obs, include_days = 30)
  grp_pobs <- suppressWarnings(
    enw_preprocess_data(grp_obs, by = "age_group", max_delay = 10)
  )
  exp <- enw_expectation(r = ~ 1 + gp(week, age_group), data = grp_pobs)
  # The grouped term must declare two GP groups.
  expect_identical(exp$data$expr_gp_G, 2L)

  nowcast_gp <- suppressWarnings(epinowcast(
    grp_pobs,
    expectation = exp,
    reference = suppressWarnings(enw_reference(~1, data = grp_pobs)),
    obs = enw_obs(family = "poisson", data = grp_pobs),
    fit = enw_fit_opts(
      save_warmup = FALSE, pp = FALSE, chains = 2, parallel_chains = 2,
      iter_warmup = 250, iter_sampling = 250, show_messages = FALSE,
      show_exceptions = FALSE, refresh = 0, adapt_delta = 0.95
    )
  ))
  # The non-centred spectral coefficients are stored as a (basis x group)
  # matrix; the two groups must realise independently rather than share a
  # single column.
  eta <- suppressWarnings(
    summary(nowcast_gp, type = "fit")[grepl("expr_gp_eta", variable)]
  )
  expect_true(nrow(eta) > 0)
  g1 <- eta[grepl("\\[[0-9]+,1\\]$", variable)]$mean
  g2 <- eta[grepl("\\[[0-9]+,2\\]$", variable)]$mean
  expect_identical(length(g1), length(g2))
  expect_true(length(g1) > 0)
  # Independent realisations: the per-group coefficient vectors differ.
  expect_gt(max(abs(g1 - g2)), 1e-6)
})
