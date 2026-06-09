#' Compile the experimental embedded-Laplace nowcast model
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Compiles the opt-in, experimental embedded-Laplace nowcast model shipped
#' in `inst/stan/models/epinowcast_laplace.stan`. This model marginalises the
#' latent log-expected-count field analytically using Stan's embedded Laplace
#' approximation (`laplace_marginal_*`, available from cmdstan 2.39) rather
#' than sampling it with NUTS. It is a thin wrapper around [enw_model()] that
#' points at the Laplace model and the package Stan include directory.
#'
#' This inference path is experimental and supports only a subset of the full
#' [epinowcast()] model (see [enw_laplace()]). It requires cmdstan >= 2.39.
#'
#' @inheritParams enw_model
#'
#' @return A `cmdstanr` model.
#'
#' @family modeltools
#' @export
#' @examplesIf interactive()
#' mod <- enw_laplace_model()
enw_laplace_model <- function(model = system.file(
                                "stan", "models", "epinowcast_laplace.stan",
                                package = "epinowcast"
                              ),
                              include = system.file(
                                "stan",
                                package = "epinowcast"
                              ),
                              compile = TRUE, threads = TRUE,
                              profile = FALSE,
                              target_dir = epinowcast::enw_get_cache(),
                              stanc_options = list(),
                              cpp_options = list(), verbose = TRUE, ...) {
  enw_model(
    model = model, include = include, compile = compile, threads = threads,
    profile = profile, target_dir = target_dir, stanc_options = stanc_options,
    cpp_options = cpp_options, verbose = verbose, ...
  )
}

#' Validate that a specification is within the embedded-Laplace subset
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Checks the model modules passed to [enw_laplace()] and raises a clear error
#' for any configuration outside the supported v1 subset. The supported subset
#' is: a linear expectation with fixed effects, random effects, and/or a single
#' `gp()` term; a static parametric reference delay (lognormal, gamma or
#' exponential); and a negative binomial (NB2) or Poisson observation family.
#'
#' @param reference A reference module as returned by [enw_reference()].
#' @param report A report module as returned by [enw_report()].
#' @param expectation An expectation module as returned by [enw_expectation()].
#' @param missing A missing module as returned by [enw_missing()].
#' @param obs An observation module as returned by [enw_obs()].
#'
#' @return Invisibly `TRUE` if the specification is supported; otherwise an
#' error is raised.
#' @family laplace
#' @importFrom cli cli_abort
#' @keywords internal
check_laplace_supported <- function(reference, report, expectation, missing,
                                    obs) {
  rd <- reference$data
  # Non-parametric reference hazards are not supported.
  if (isTRUE(rd$model_refnp == 1)) {
    cli::cli_abort(
      paste0(
        "The embedded-Laplace path does not support non-parametric reference ",
        "hazards (`non_parametric` in `enw_reference()`). Use a static ",
        "parametric delay only."
      )
    )
  }
  # A parametric distribution must be present.
  if (isTRUE(rd$model_refp == 0)) {
    cli::cli_abort(
      "The embedded-Laplace path requires a parametric reference delay."
    )
  }
  # Time-varying delay (effects on the parametric delay) is not supported.
  if (isTRUE(rd$refp_fncol > 0) || isTRUE(rd$refp_rncol > 0) ||
        isTRUE(rd$refp_arima_present == 1) || isTRUE(rd$refp_gp_present == 1)) {
    cli::cli_abort(
      paste0(
        "The embedded-Laplace path only supports a static parametric delay. ",
        "Covariate, random-effect, ARIMA or GP effects on the delay are not ",
        "supported."
      )
    )
  }
  # Report-date hazard effects are not supported.
  if (isTRUE(report$data$model_rep == 1)) {
    cli::cli_abort(
      "The embedded-Laplace path does not support a report-date model."
    )
  }
  # Missing-reference model is not supported.
  if (!is.null(missing$formula) && missing$formula != "~0") {
    cli::cli_abort(
      "The embedded-Laplace path does not support a missing-reference model."
    )
  }
  # Renewal (generation time length > 1) is not supported.
  if (isTRUE(expectation$data$expr_gt_n > 1)) {
    cli::cli_abort(
      paste0(
        "The embedded-Laplace path does not support the renewal expectation ",
        "(generation time length > 1). Use a linear expectation."
      )
    )
  }
  # Latent reporting delay / observation-to-latent process is not supported.
  if (isTRUE(expectation$data$expl_obs == 1)) {
    cli::cli_abort(
      paste0(
        "The embedded-Laplace path does not support a latent reporting delay ",
        "or observation process on the expectation."
      )
    )
  }
  # Only NB2 and Poisson observation families are log-concave per cell.
  if (!isTRUE(obs$data$model_obs %in% c(0, 1))) {
    cli::cli_abort(
      paste0(
        "The embedded-Laplace path only supports the \"negbin\" (NB2) and ",
        "\"poisson\" observation families."
      )
    )
  }
  invisible(TRUE)
}

#' Split an expectation design into fixed and random covariance blocks
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Takes an [enw_formula()] expectation design and splits it into the fixed
#' effect design `X` (intercept plus unscaled columns) and the random effect
#' design `Z` (columns scaled by a random-effect standard deviation), together
#' with a per-`Z`-column index into the random-effect standard deviation
#' vector. This implements epinowcast's scaled random-effect encoding (see
#' `combine_effects.stan`), where random effects are expanded into the fixed
#' design and `random$design` maps each expanded column to its scaling
#' standard deviation.
#'
#' @param formula An object of class `enw_formula` as produced by
#' [enw_formula()].
#'
#' @return A list with `X` (the fixed design, intercept first if present),
#' `Z` (the random design), `re_index` (a per-`Z`-column integer index into
#' the random-effect standard deviation vector), `q_re` (the number of `Z`
#' columns), `n_re` (the number of random-effect standard deviations) and
#' `fintercept` (1 if an intercept is present, else 0).
#' @family laplace
#' @keywords internal
split_laplace_design <- function(formula) {
  fdesign <- formula$fixed$design
  fintercept <- as.numeric(any(grepl(
    "(Intercept)", colnames(fdesign), fixed = TRUE
  )))
  if (fintercept) {
    intercept_col <- fdesign[, 1, drop = FALSE]
    fdesign <- fdesign[, -1, drop = FALSE]
  }
  rdesign <- formula$random$design
  # rdesign rows align with fdesign (non-intercept) columns; column 1 is the
  # unscaled "fixed" indicator, remaining columns are random-effect groups.
  n_re <- ncol(rdesign) - 1L
  if (ncol(fdesign) == 0) {
    is_random <- logical(0)
  } else {
    is_random <- rdesign[, 1] == 0
  }
  fixed_cols <- which(!is_random)
  random_cols <- which(is_random)

  # Fixed design: intercept (if present) + unscaled fixed columns.
  x_parts <- list()
  if (fintercept) {
    x_parts[[length(x_parts) + 1]] <- intercept_col
  }
  if (length(fixed_cols) > 0) {
    x_parts[[length(x_parts) + 1]] <- fdesign[, fixed_cols, drop = FALSE]
  }
  if (length(x_parts) > 0) {
    x_mat <- do.call(cbind, x_parts)
  } else {
    x_mat <- matrix(numeric(0), nrow = nrow(formula$fixed$design), ncol = 0)
  }

  # Random design Z and per-column index into the sd vector.
  if (length(random_cols) > 0) {
    z_mat <- fdesign[, random_cols, drop = FALSE]
    # Map each random column to its random-effect group (sd index).
    re_index <- apply(
      rdesign[random_cols, -1, drop = FALSE], 1, function(r) which(r == 1)[1]
    )
    re_index <- as.integer(re_index)
  } else {
    z_mat <- matrix(numeric(0), nrow = nrow(formula$fixed$design), ncol = 0)
    re_index <- integer(0)
  }

  list(
    X = x_mat, Z = z_mat, re_index = re_index, q_re = ncol(z_mat),
    n_re = n_re, fintercept = fintercept
  )
}

#' Build the embedded-Laplace nowcast data list
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Assembles the Stan data list for the experimental embedded-Laplace nowcast
#' model from a preprocessed observation object (as produced by
#' [enw_preprocess_data()]) and the standard model modules. The expectation
#' design (fixed effects, random effects and/or a `gp()` term), the static
#' parametric reference delay, and the observation family are reused from the
#' supplied modules; the latent field is marginalised analytically rather than
#' sampled.
#'
#' Only the supported v1 subset is accepted (see [check_laplace_supported()]).
#' The covariance is assembled per group from the first group's design block,
#' which assumes the random-effect and Gaussian process basis structure is
#' shared across groups (the usual case for `(1 | feature)` and `gp()` terms).
#'
#' @param data A preprocessed observation object from [enw_preprocess_data()].
#'
#' @param expectation An expectation module from [enw_expectation()] supplying
#' the linear predictor design via its `r` formula. The formula is re-fit on
#' the reference-date metadata to extract the fixed and random effect designs.
#'
#' @param reference A reference module from [enw_reference()] supplying the
#' static parametric delay distribution.
#'
#' @param obs An observation module from [enw_obs()] supplying the observation
#' family and reporting triangle.
#'
#' @param report A report module from [enw_report()]. Only the default
#' (no report-date model) is supported.
#'
#' @param missing A missing module from [enw_missing()]. Only the default
#' (no missing-reference model) is supported.
#'
#' @param priors A `data.frame` of priors as merged in [epinowcast()]. If
#' missing, the module default priors are used.
#'
#' @param jitter Numeric diagonal jitter added to the covariance for numerical
#' stability. Defaults to `1e-6`.
#'
#' @return A named list suitable as the `data` argument to a model compiled by
#' [enw_laplace_model()].
#' @family laplace
#' @importFrom data.table data.table CJ setorder as.data.table
#' @importFrom cli cli_abort
#' @export
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#' enw_laplace_data(
#'   pobs,
#'   expectation = enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
#' )
enw_laplace_data <- function(data,
                             expectation = epinowcast::enw_expectation(
                               r = ~1, data = data
                             ),
                             reference = epinowcast::enw_reference(
                               parametric = ~1,
                               distribution = "lognormal",
                               data = data
                             ),
                             obs = epinowcast::enw_obs(
                               family = "negbin", data = data
                             ),
                             report = epinowcast::enw_report(data = data),
                             missing = epinowcast::enw_missing(
                               formula = ~0, data = data
                             ),
                             priors = NULL,
                             jitter = 1e-6) {
  check_laplace_supported(reference, report, expectation, missing, obs)

  groups <- data$groups[[1]]
  t_len <- data$time[[1]]
  dmax <- data$max_delay[[1]]

  # Reporting triangle: rows are (group, ref date) group-major, columns the
  # delays 0..(dmax - 1). A cell (group, tt, d) is observed iff tt + d <= t.
  triangle <- data.table::as.data.table(data$reporting_triangle[[1]])
  delay_cols <- setdiff(names(triangle), c(".group", "reference_date"))
  if (length(delay_cols) != dmax) {
    cli::cli_abort(
      "Reporting triangle delay columns do not match the maximum delay."
    )
  }
  tri_mat <- as.matrix(triangle[, delay_cols, with = FALSE])

  # Build flat observed cells in group-major, ref-date, delay order. A cell
  # (group, ref date, delay) is observed iff ref date + delay <= t.
  grid <- expand.grid(
    cell_d = 0:(dmax - 1), cell_t = seq_len(t_len), cell_g = seq_len(groups)
  )
  keep <- grid$cell_d <= (t_len - grid$cell_t)
  cell_g <- grid$cell_g[keep]
  cell_t <- grid$cell_t[keep]
  cell_d <- grid$cell_d[keep]
  ord <- order(cell_g, cell_t, cell_d)
  cell_g <- cell_g[ord]
  cell_t <- cell_t[ord]
  cell_d <- cell_d[ord]
  # Triangle row for (group, ref date) is (group - 1) * t + ref date.
  tri_row <- (cell_g - 1L) * t_len + cell_t
  cell_obs <- tri_mat[cbind(tri_row, cell_d + 1L)]
  if (anyNA(cell_obs)) {
    cli::cli_abort(
      "Observed reporting-triangle cells contain missing values."
    )
  }

  # Observed total per (group, ref date) for the nowcast reconstruction.
  row_obs_sum <- matrix(0L, groups, t_len)
  for (gg in seq_len(groups)) {
    for (tt in seq_len(t_len)) {
      n_obs_delays <- min(t_len - tt, dmax - 1)
      r <- (gg - 1L) * t_len + tt
      row_obs_sum[gg, tt] <- sum(tri_mat[r, seq_len(n_obs_delays + 1)])
    }
  }

  # Expectation design: re-fit the expectation `r` formula on the reference
  # metadata (one row per group/ref date) to obtain fixed and random designs.
  meta <- data.table::as.data.table(data$metareference[[1]])
  r_formula <- stats::as.formula(expectation$formula$r)
  r_form <- enw_formula(r_formula, meta, sparse = FALSE)
  split <- split_laplace_design(r_form)
  x_fixed <- split$X
  if (nrow(x_fixed) != groups * t_len) {
    cli::cli_abort(
      "Expectation design rows do not match groups x reference dates."
    )
  }

  # Per-group random-effect design. The per-group marginalisation uses one
  # shared T x q_re block, so the random-effect structure must be identical
  # across groups (e.g. `(1 | day_of_week)`). Group-specific interactions such
  # as `(1 | day_of_week:.group)` give a different block per group and are not
  # supported by this v1 path; reject them with a clear error.
  use_re <- as.integer(split$q_re > 0)
  if (use_re == 1) {
    z_full <- split$Z
    z_g <- z_full[seq_len(t_len), , drop = FALSE]
    if (groups > 1) {
      for (gg in 2:groups) {
        z_other <- z_full[((gg - 1) * t_len + 1):(gg * t_len), , drop = FALSE]
        if (!isTRUE(all.equal(unname(z_other), unname(z_g)))) {
          cli::cli_abort(
            paste0(
              "The embedded-Laplace path requires the random-effect design to ",
              "be shared across groups. Group-specific interactions such as ",
              "`(1 | feature:.group)` are not supported; use `(1 | feature)`."
            )
          )
        }
      }
    }
    q_re <- ncol(z_g)
    re_index <- split$re_index
    n_re <- split$n_re
  } else {
    z_g <- matrix(numeric(0), t_len, 0)
    q_re <- 0L
    re_index <- integer(0)
    n_re <- 0L
  }

  # Gaussian process term (Hilbert-space basis), if present.
  gp_terms <- r_form$gp
  use_gp <- as.integer(length(gp_terms) > 0)
  if (use_gp == 1) {
    if (length(gp_terms) > 1) {
      cli::cli_abort("Only one `gp()` term is supported.")
    }
    gpt <- gp_terms[[1]]
    if (gpt$d > 0) {
      cli::cli_abort(
        "The embedded-Laplace path only supports `gp()` with `d = 0`."
      )
    }
    phi <- gpt$PHI
    gp_m <- gpt$M
    gp_type <- gpt$gp_type
    gp_nu <- gpt$nu
    gp_l <- gpt$boundary_scale
    if (nrow(phi) != t_len) {
      cli::cli_abort(
        "Gaussian process basis rows do not match the number of ref dates."
      )
    }
  } else {
    phi <- matrix(numeric(0), t_len, 0)
    gp_m <- 0L
    gp_type <- 0L
    gp_nu <- 0
    gp_l <- 1
  }

  # Priors: merge module defaults with any user priors and pull the entries
  # the Laplace model needs.
  default_priors <- data.table::rbindlist(
    list(expectation$priors, reference$priors, obs$priors),
    fill = TRUE, use.names = TRUE
  )
  if (is.null(priors)) {
    priors <- default_priors
  } else {
    priors <- enw_replace_priors(default_priors, priors)
  }
  pr <- function(name, default_mean, default_sd) {
    row <- priors[variable == name]
    if (nrow(row) == 0) {
      return(c(default_mean, default_sd))
    }
    c(row$mean[1], row$sd[1])
  }

  out <- list(
    g = groups, t = t_len, dmax = dmax,
    n_obs = length(cell_obs), obs = cell_obs,
    cell_g = cell_g, cell_t = cell_t, cell_d = cell_d,
    nc_t = min(dmax, t_len),
    row_obs_sum = row_obs_sum,
    expr_fncol = ncol(x_fixed) - as.integer(split$fintercept),
    expr_fintercept = as.integer(split$fintercept),
    X_fixed = x_fixed,
    use_re = use_re, q_re = q_re, n_re = n_re, Z = z_g,
    re_index = if (q_re > 0) re_index else array(1L, dim = 0),
    use_gp = use_gp, gp_M = gp_m, gp_type = gp_type, gp_nu = gp_nu,
    gp_L = gp_l, PHI = phi,
    jitter = jitter,
    obs_family = as.integer(obs$data$model_obs == 1),
    model_refp = as.integer(reference$data$model_refp),
    # The Laplace expectation models the level of log-expected counts, so the
    # intercept and fixed-effect priors are dedicated (the expectation module's
    # `expr_*` priors are growth-rate scaled and not reused here). The
    # random-effect sd, GP and delay priors are reused from the modules.
    prior_beta_int = c(0, 5),
    prior_beta = c(0, 1),
    prior_sigma_re = pr("expr_beta_sd", 0, 1),
    prior_gp_alpha = pr("expr_gp_alpha", 0, 0.05),
    prior_gp_rho = pr("expr_gp_rho", log(3), 0.5),
    prior_refp_mean = pr("refp_mean_int", 1, 1),
    prior_refp_sd = pr("refp_sd_int", 0.5, 1),
    prior_sqrt_phi = pr("sqrt_phi", 0, 0.5)
  )
  out
}

#' Initial values for the embedded-Laplace nowcast model
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Builds a randomised initialisation function for the embedded-Laplace model
#' that starts the level intercept near the scale of the observed counts and
#' the delay and overdispersion parameters near their priors. This avoids the
#' non-finite log-likelihood rejections that occur when the default wide
#' initialisation places the linear predictor far from the data.
#'
#' @param data A data list as produced by [enw_laplace_data()].
#'
#' @return A function with no arguments returning a named list of initial
#' values suitable for the `init` argument of a `cmdstanr` `$sample()` call.
#' @family laplace
#' @export
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#' dl <- enw_laplace_data(pobs)
#' init_fn <- enw_laplace_inits(dl)
#' init_fn()
enw_laplace_inits <- function(data) {
  # Rough level for the intercept: log of the mean per-cell observed count.
  mean_obs <- mean(data$obs[data$obs > 0])
  level <- if (is.finite(mean_obs) && mean_obs > 0) log(mean_obs) else 0
  n_beta <- data$expr_fncol + data$expr_fintercept
  function() {
    init <- list()
    if (n_beta > 0) {
      beta <- rnorm(n_beta, 0, 0.1)
      if (data$expr_fintercept == 1) {
        beta[1] <- level + rnorm(1, 0, 0.1)
      }
      init$beta_fixed <- array(beta, dim = n_beta)
    }
    if (data$n_re > 0) {
      init$sigma_re <- array(abs(rnorm(data$n_re, 0.1, 0.05)), dim = data$n_re)
    }
    if (data$use_gp == 1) {
      init$gp_alpha <- array(abs(rnorm(1, 0.1, 0.05)), dim = 1)
      init$gp_rho <- array(exp(data$prior_gp_rho[1]), dim = 1)
    }
    if (data$model_refp > 0) {
      init$refp_mean_int <- array(
        rnorm(1, data$prior_refp_mean[1], 0.1), dim = 1
      )
    }
    if (data$model_refp > 1) {
      init$refp_sd_int <- array(
        max(rnorm(1, data$prior_refp_sd[1], 0.1), 0.1), dim = 1
      )
    }
    if (data$obs_family == 1) {
      init$sqrt_phi <- array(abs(rnorm(1, 0.2, 0.05)), dim = 1)
    }
    init
  }
}

#' Nowcast using the experimental embedded-Laplace path
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' An opt-in, experimental alternative to [epinowcast()] that marginalises the
#' latent log-expected-count field analytically using Stan's embedded Laplace
#' approximation (`laplace_marginal_*`, cmdstan >= 2.39) instead of sampling it
#' with NUTS. The hyperparameters (fixed effects, random-effect standard
#' deviations, Gaussian process magnitude and length scale, delay parameters
#' and overdispersion) are still sampled with NUTS; only the high-dimensional
#' latent field is integrated out.
#'
#' This path supports a subset of the full model: a linear expectation with
#' fixed effects, random effects and/or a single `gp()` term; a static
#' parametric reference delay (lognormal, gamma or exponential); and a negative
#' binomial (NB2) or Poisson observation family. The renewal expectation,
#' non-parametric reference hazards, report-date models, missing-reference
#' models and time-varying delays are not supported and raise a clear error.
#'
#' The returned object has the same structure as an [epinowcast()] fit (a
#' `data.table` carrying `fit`, `data`, `fit_args` and `run_time`) joined to
#' the preprocessed data, so [summary.epinowcast()] and the nowcast extractors
#' work as usual.
#'
#' @inheritParams enw_laplace_data
#'
#' @param model A compiled embedded-Laplace `cmdstanr` model as returned by
#' [enw_laplace_model()].
#'
#' @param fit Model fit options as defined using [enw_fit_opts()].
#'
#' @param priors A `data.frame` with columns `variable`, `mean` and `sd`
#' describing normal priors that replace the module defaults.
#'
#' @return An object of class "epinowcast" combining the input data, priors and
#' the embedded-Laplace fit.
#' @family laplace
#' @importFrom data.table data.table
#' @importFrom cli cli_alert_info cli_warn
#' @export
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#' nowcast <- enw_laplace(
#'   pobs,
#'   expectation = enw_expectation(~ 1 + (1 | day_of_week), data = pobs),
#'   fit = enw_fit_opts(
#'     chains = 2, iter_warmup = 500, iter_sampling = 500
#'   )
#' )
#' summary(nowcast, type = "nowcast")
enw_laplace <- function(data,
                        expectation = epinowcast::enw_expectation(
                          r = ~1, data = data
                        ),
                        reference = epinowcast::enw_reference(
                          parametric = ~1,
                          distribution = "lognormal",
                          data = data
                        ),
                        obs = epinowcast::enw_obs(
                          family = "negbin", data = data
                        ),
                        report = epinowcast::enw_report(data = data),
                        missing = epinowcast::enw_missing(
                          formula = ~0, data = data
                        ),
                        fit = epinowcast::enw_fit_opts(
                          sampler = epinowcast::enw_sample,
                          nowcast = TRUE, pp = FALSE, likelihood = TRUE
                        ),
                        model = epinowcast::enw_laplace_model(),
                        priors = NULL,
                        jitter = 1e-6) {
  cli::cli_warn(
    paste0(
      "`enw_laplace()` is experimental. The embedded-Laplace inference path ",
      "is opt-in and supports only a subset of the full `epinowcast()` model."
    )
  )

  data_as_list <- enw_laplace_data(
    data,
    expectation = expectation, reference = reference, obs = obs,
    report = report, missing = missing, priors = priors, jitter = jitter
  )

  sampler <- fit$sampler
  fit_obj <- do.call(
    sampler, c(
      list(
        data = data_as_list, model = model,
        init = enw_laplace_inits(data_as_list)
      ),
      fit$args
    )
  )

  # Record the merged priors for reproducibility, mirroring epinowcast().
  merged_priors <- data.table::rbindlist(
    list(expectation$priors, reference$priors, obs$priors),
    fill = TRUE, use.names = TRUE
  )
  if (!is.null(priors)) {
    merged_priors <- enw_replace_priors(merged_priors, priors)
  }

  out <- cbind(data, priors = list(merged_priors), fit_obj)
  class(out) <- c("epinowcast", "enw_preprocess_data", class(out))
  out[]
}
