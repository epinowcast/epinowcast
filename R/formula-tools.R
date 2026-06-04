#' Define a model manually using fixed and random effects
#'
#' @description For most typical use cases [enw_formula()] should
#' provide sufficient flexibility to allow models to be defined. However,
#' there may be some instances where more manual model specification is
#' required. This function supports this by allowing the user to supply
#' vectors of fixed, random, and customised random effects (where they are
#' not first treated as fixed effect terms). Prior to `1.0.0` this was the
#' main interface for specifying models and it is still used internally to
#' handle some parts of the model specification process.
#'
#' @param fixed A character vector of fixed effects.
#'
#' @param random A character vector of random effects. Random effects
#' specified here will be added to the fixed effects.
#'
#' @param custom_random A vector of random effects. Random effects added here
#' will not be added to the vector of fixed effects. This can be used to random
#' effects for fixed effects that only have a partial name match.
#'
#' @param no_contrasts Logical, defaults to `FALSE`. `TRUE` means that no
#' variable uses contrast. Alternatively a character vector of variables can be
#' supplied indicating which variables should  not have contrasts.
#'
#' @param add_intercept Logical, defaults to `FALSE`. Should an intercept be
#' added to the fixed effects.
#'
#' @return A list specifying the fixed effects (formula, design matrix, and
#' design matrix index), and random effects (formula and design matrix).
#'
#' @inheritParams enw_formula
#' @family formulatools
#' @importFrom stats as.formula
#' @export
#' @examples
#' data <- enw_example("prep")$metareference[[1]]
#' enw_manual_formula(data, fixed = "week", random = "day_of_week")
enw_manual_formula <- function(data, fixed = NULL, random = NULL,
                               custom_random = NULL, no_contrasts = FALSE,
                               add_intercept = TRUE) {
  data <- coerce_dt(data)
  if (add_intercept) {
    form <- "1"
  } else {
    form <- NULL
  }

  cr_in_dt <- purrr::map(
    custom_random, ~ colnames(data)[startsWith(colnames(data), .)]
  )
  cr_in_dt <- unlist(cr_in_dt)

  form <- c(form, fixed, random, cr_in_dt)
  if (length(random) > 0) {
    no_contrasts <- c(random)
  }
  form <- as.formula(paste0("~ ", paste(form, collapse = " + ")))

  # build effects design matrix (with  no contrasts)
  fixed <- enw_design(form, data,
    no_contrasts = no_contrasts,
    sparse = TRUE
  )

  # get effects
  effects <- enw_effects_metadata(fixed$design)

  random <- c(random, custom_random)

  if (length(random) == 0) {
    random <- enw_design(~1, effects, sparse = FALSE)
  } else {
    for (i in random) {
      effects <- enw_add_pooling_effect(effects, var_name = i, prefix = i)
    }
    rand_form <- c("0", "fixed", random)
    rand_form <- as.formula(paste0("~ ", paste(rand_form, collapse = " + ")))
    random <- enw_design(rand_form, effects, sparse = FALSE)
  }
  list(fixed = fixed, random = random)
}

#' Converts formulas to strings
#'
#' @return A character string of the supplied formula
#' @inheritParams split_formula_to_terms
#' @family formulatools
#' @examples
#' epinowcast:::as_string_formula(~ 1 + age_group)
as_string_formula <- function(formula) {
  form <- paste(deparse(formula), collapse = " ")
  form <- gsub("\\s+", " ", form, perl = FALSE)
  form
}

#' Split formula into individual terms
#'
#' @return A character vector of formula terms
#' @inheritParams enw_formula
#' @family formulatools
#' @examples
#' epinowcast:::split_formula_to_terms(~ 1 + age_group + location)
split_formula_to_terms <- function(formula) {
  formula <- as_string_formula(formula)
  formula <- gsub("~", "", formula, fixed = TRUE)
  formula <- strsplit(formula, " + ", fixed = TRUE)[[1]]
  formula
}

#' Finds random walk terms in a formula object
#'
#' @description This function extracts random walk terms
#' denoted using [rw()] from a formula so that they can be
#' processed on their own.
#'
#' @section Reference:
#' This function was adapted from code written
#' by J Scott (under an MIT license) as part of
#' the `epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).
#'
#' @return A character vector containing the random walk terms that have been
#' identified in the supplied formula.
#'
#' @inheritParams enw_formula
#' @family formulatools
#' @examples
#' epinowcast:::rw_terms(~ 1 + age_group + location)
#'
#' epinowcast:::rw_terms(~ 1 + age_group + location + rw(week, location))
rw_terms <- function(formula) {
  # use regex to find random walk terms in formula
  trms <- attr(terms(formula), "term.labels")
  match <- grepl("(^(rw)\\([^:]*\\))$", trms)

  # ignore when included in a random effects term
  match <- match & !grepl("|", trms, fixed = TRUE)
  trms[match]
}

#' Remove random walk terms from a formula object
#'
#' @description This function removes random walk terms
#' denoted using [rw()] from a formula so that they can be
#' processed on their own.
#'
#' @section Reference:
#' This function was adapted from code written
#' by J Scott (under an MIT license) as part of
#' the `epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).
#'
#' @inheritParams split_formula_to_terms
#' @return A formula object with the random walk terms removed.
#' @family formulatools
#' @examples
#' epinowcast:::remove_rw_terms(~ 1 + age_group + location)
#'
#' epinowcast:::remove_rw_terms(~ 1 + age_group + location + rw(week, location))
remove_rw_terms <- function(formula) {
  form <- as_string_formula(formula)
  form <- gsub("rw\\(.*?\\) \\+ ", "", form)
  form <- gsub("\\+ rw\\(.*?\\)", "", form)
  form <- gsub("rw\\(.*?\\)", "", form)

  form <- tryCatch(
    {
      as.formula(form)
    },
    error = function(cond) {
      as.formula(paste(form, 1))
    }
  )
  form
}

#' Finds ARIMA terms in a formula object
#'
#' @description This function extracts ARIMA terms from a formula so that
#' they can be processed on their own. Matches all four user-facing
#' helpers that produce an `enw_arima_term`: [arima()], plus the
#' convenience aliases [ar()], [ma()], and [arma()].
#'
#' @return A character vector containing the ARIMA terms identified in
#' the supplied formula.
#'
#' @inheritParams enw_formula
#' @family formulatools
#' @examples
#' epinowcast:::arima_terms(~ 1 + age_group + arima(week))
#' epinowcast:::arima_terms(~ 1 + ar(week, p = 2))
#' epinowcast:::arima_terms(~ 1 + arma(week, location, p = 1, q = 1))
arima_terms <- function(formula) {
  trms <- attr(terms(formula), "term.labels")
  # Longer names first so the alternation matches `arima` and `arma`
  # before falling back to `ar`/`ma`.
  match <- grepl("^(arima|arma|ar|ma)\\(.*\\)$", trms)
  match <- match & !grepl("|", trms, fixed = TRUE)
  trms[match]
}

#' Remove ARIMA terms from a formula object
#'
#' @description This function removes ARIMA terms — `arima()`, `ar()`,
#' `ma()`, and `arma()` — from a formula so they can be processed on
#' their own.
#'
#' @inheritParams split_formula_to_terms
#' @return A formula object with the ARIMA terms removed.
#' @family formulatools
#' @examples
#' epinowcast:::remove_arima_terms(~ 1 + age_group + arima(week))
#' epinowcast:::remove_arima_terms(~ 1 + age_group + ar(week, p = 2))
remove_arima_terms <- function(formula) {
  form <- as_string_formula(formula)
  # Longer names first to avoid `ar(` matching inside `arima(`.
  for (fn in c("arima", "arma", "ar", "ma")) {
    form <- gsub(paste0(fn, "\\(.*?\\) \\+ "), "", form)
    form <- gsub(paste0("\\+ ", fn, "\\(.*?\\)"), "", form)
    form <- gsub(paste0(fn, "\\(.*?\\)"), "", form)
  }

  form <- tryCatch(
    {
      as.formula(form)
    },
    error = function(cond) {
      as.formula(paste(form, 1))
    }
  )
  form
}

#' Finds Gaussian process terms in a formula object
#'
#' @description This function extracts Gaussian process terms denoted
#' using [gp()] from a formula so that they can be processed on their
#' own.
#'
#' @return A character vector containing the Gaussian process terms
#' identified in the supplied formula.
#'
#' @inheritParams enw_formula
#' @family formulatools
#' @examples
#' epinowcast:::gp_terms(~ 1 + age_group + gp(week))
#' epinowcast:::gp_terms(~ 1 + gp(week, kernel = "se") + gp(day))
gp_terms <- function(formula) {
  trms <- attr(terms(formula), "term.labels")
  match <- grepl("^gp\\(.*\\)$", trms)
  match <- match & !grepl("|", trms, fixed = TRUE)
  trms[match]
}

#' Remove Gaussian process terms from a formula object
#'
#' @description This function removes Gaussian process terms denoted
#' using [gp()] from a formula so they can be processed on their own.
#'
#' @inheritParams split_formula_to_terms
#' @return A formula object with the Gaussian process terms removed.
#' @family formulatools
#' @examples
#' epinowcast:::remove_gp_terms(~ 1 + age_group + gp(week))
remove_gp_terms <- function(formula) {
  form <- as_string_formula(formula)
  form <- gsub("gp\\(.*?\\) \\+ ", "", form)
  form <- gsub("\\+ gp\\(.*?\\)", "", form)
  form <- gsub("gp\\(.*?\\)", "", form)

  form <- tryCatch(
    {
      as.formula(form)
    },
    error = function(cond) {
      as.formula(paste(form, 1))
    }
  )
  form
}

#' Parse a formula into components
#'
#' @description This function uses a series internal functions
#' to break an input formula into its component parts each of which
#' can then be handled separately. Currently supported components are
#' fixed effects, \link[lme4]{lme4} style random effects, and random walks
#' using the [rw()] helper function.
#'
#' @section Reference:
#' The random walk functions used internally by this function were
#' adapted from code written by J Scott (under an MIT license) as part of
#' the `epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).
#'
#' @return A list of formula components. These currently include:
#'  - `fixed`: A character vector of fixed effect terms
#'  - `random`: A list of of \link[lme4]{lme4} style random effects
#'  - `rw`: A character vector of [rw()] random walk terms.
#'  - `arima`: A character vector of [arima()] ARIMA(p, d, q) terms.
#'  - `gp`: A character vector of [gp()] Gaussian process terms.
#' @inheritParams enw_formula
#' @importFrom reformulas nobars findbars
#' @importFrom cli cli_abort
#' @family formulatools
#' @examples
#' epinowcast:::parse_formula(~ 1 + age_group + location)
#'
#' epinowcast:::parse_formula(~ 1 + age_group + (1 | location))
#'
#' epinowcast:::parse_formula(~ 1 + (age_group | location))
#'
#' epinowcast:::parse_formula(~ 1 + (1 | location) + rw(week, location))
parse_formula <- function(formula) {
  if (!inherits(formula, "formula")) {
    cli::cli_abort("`formula` must be a formula object.")
  }
  rw <- rw_terms(formula)
  formula <- remove_rw_terms(formula)
  arima <- arima_terms(formula)
  formula <- remove_arima_terms(formula)
  gp <- gp_terms(formula)
  formula <- remove_gp_terms(formula)
  fixed <- reformulas::nobars(formula)
  random <- reformulas::findbars(formula)

  model_terms <- list(
    fixed = split_formula_to_terms(fixed),
    random = random,
    rw = rw,
    arima = arima,
    gp = gp
  )
  model_terms
}

#' Adds random walks with Gaussian steps to the model.
#'
#' A call to `rw()` can be used in the `formula` argument of model
#' construction functions in the `epinowcast` package such as
#' [enw_formula()]. Mathematically a Gaussian random walk is exactly
#' an ARIMA(0, 1, 0) process; `rw(time, by, type)` is now a thin
#' wrapper over [arima()] with `p = 0`, `d = 1`, `q = 0`. It is kept
#' as a user-facing convenience because random walks are the most
#' common time-series structure in `epinowcast` formulas.
#'
#' Does not evaluate arguments but instead simply passes information
#' for use in model construction.
#'
#' @param time Defines the random walk time period.
#'
#' @param by Defines the grouping parameter used for the random walk.
#' If not specified no grouping is used. Currently this is limited to a single
#' variable. Each group draws an independent shock series; the latent
#' standard deviation is shared across groups (per-group standard
#' deviations are a planned extension).
#'
#' @return A list of class `enw_arima_term` (with `p = 0`, `d = 1`,
#' `q = 0`) that can be interpreted by [construct_arima()].
#' @export
#' @importFrom cli cli_abort
#' @family formulatools
#' @examples
#' rw(time)
#'
#' rw(time, location)
#'
#' rw(time, location)
rw <- function(time, by) {
  if (missing(time)) {
    cli::cli_abort("`time` must be present")
  } else {
    time <- deparse(substitute(time))
  }

  if (missing(by)) {
    by <- NULL
  } else {
    by <- deparse(substitute(by))
  }
  out <- list(
    time = time, by = by,
    p = 0L, d = 1L, q = 0L
  )
  class(out) <- "enw_arima_term"
  out
}

#' Adds an ARIMA(p, d, q) latent residual to the model.
#'
#' @description A call to `arima()` can be used in the `formula` argument
#' of model construction functions in the `epinowcast` package such as
#' [enw_formula()]. It declares an ARIMA(p, d, q) latent series indexed
#' by `time` (and optionally a grouping variable `by`) whose value at
#' each observation is added to the linear predictor. As with [rw()],
#' arguments are not evaluated; they are passed by name for use in
#' model construction. Setting `p = d = q = 0` is not allowed; use
#' [rw()] (equivalent to `arima(time, d = 1)`) for a random walk.
#'
#' @param time Defines the time index of the ARIMA process.
#'
#' @param by Optional grouping variable. If supplied, an independent
#' ARIMA series is fitted for each level of `by`. Currently limited to
#' a single variable.
#'
#' @param p Non-negative integer. Order of the autoregressive part.
#' Defaults to 1.
#'
#' @param d Non-negative integer. Order of differencing (`d = 1` gives
#' an integrated series, equivalent to `rw()` when `p = q = 0`).
#' Defaults to 0.
#'
#' @param q Non-negative integer. Order of the moving-average part.
#' Defaults to 0.
#'
#' @return A list of class `enw_arima_term` describing the ARIMA term,
#' interpretable by [construct_arima()]. Each group draws an independent
#' shock series; `phi`, `theta`, and `sigma` are shared across groups
#' (per-group parameters are a planned extension).
#' @export
#' @importFrom cli cli_abort
#' @family formulatools
#' @examples
#' arima(time)
#' arima(time, location)
#' arima(time, location, p = 2, d = 1, q = 1)
arima <- function(time, by, p = 1, d = 0, q = 0) {
  if (missing(time)) {
    cli::cli_abort("`time` must be present")
  }
  time <- deparse(substitute(time))
  by <- if (missing(by)) NULL else deparse(substitute(by))
  .arima_term(time, by, p, d, q)
}

#' Autoregressive alias for [arima()]
#'
#' Thin wrapper around [arima()] that fixes `d = 0` and `q = 0`. Matches
#' the in-formula `ar()` helper that `brms` users will be familiar with.
#' Equivalent to `arima(time, by, p = p, d = 0, q = 0)`.
#'
#' @param time Time variable for the latent series; numeric.
#' @param by Optional grouping variable. Each group draws an
#' independent shock series; AR/MA parameters and the latent standard
#' deviation are shared across groups.
#' @param p Autoregressive order. Defaults to `1`.
#'
#' @return An `enw_arima_term` interpretable by [construct_arima()].
#' @family formulatools
#' @export
#' @examples
#' ar(time)
#' ar(time, location, p = 2)
ar <- function(time, by, p = 1) {
  if (missing(time)) cli::cli_abort("`time` must be present")
  time <- deparse(substitute(time))
  by <- if (missing(by)) NULL else deparse(substitute(by))
  .arima_term(time, by, p = p, d = 0L, q = 0L)
}

#' Moving-average alias for [arima()]
#'
#' Thin wrapper around [arima()] that fixes `p = 0` and `d = 0`.
#' Equivalent to `arima(time, by, p = 0, d = 0, q = q)`.
#'
#' @inheritParams ar
#' @param q Moving-average order. Defaults to `1`.
#'
#' @return An `enw_arima_term` interpretable by [construct_arima()].
#' @family formulatools
#' @export
#' @examples
#' ma(time)
#' ma(time, location, q = 2)
ma <- function(time, by, q = 1) {
  if (missing(time)) cli::cli_abort("`time` must be present")
  time <- deparse(substitute(time))
  by <- if (missing(by)) NULL else deparse(substitute(by))
  .arima_term(time, by, p = 0L, d = 0L, q = q)
}

#' ARMA alias for [arima()]
#'
#' Thin wrapper around [arima()] that fixes `d = 0`. Equivalent to
#' `arima(time, by, p = p, d = 0, q = q)`. For an integrated
#' (random-walk) series use [rw()] or
#' `arima(time, by, p = 0, d = 1, q = 0)` directly.
#'
#' @inheritParams ar
#' @param p Autoregressive order. Defaults to `1`.
#' @param q Moving-average order. Defaults to `1`.
#'
#' @return An `enw_arima_term` interpretable by [construct_arima()].
#' @family formulatools
#' @export
#' @examples
#' arma(time)
#' arma(time, location, p = 1, q = 1)
arma <- function(time, by, p = 1, q = 1) {
  if (missing(time)) cli::cli_abort("`time` must be present")
  time <- deparse(substitute(time))
  by <- if (missing(by)) NULL else deparse(substitute(by))
  .arima_term(time, by, p = p, d = 0L, q = q)
}

# Internal: build an `enw_arima_term` from already-deparsed `time`/`by`
# strings and integer orders. Used by `arima()`, `ar()`, `ma()`,
# `arma()`, and `rw()` so order validation and the degenerate-order
# guard live in one place.
.arima_term <- function(time, by, p, d, q) {
  .check_arima_order(p, "p")
  .check_arima_order(d, "d")
  .check_arima_order(q, "q")
  if (p == 0 && d == 0 && q == 0) {
    cli::cli_abort(
      "`arima(p = 0, d = 0, q = 0)` is degenerate; use a fixed effect."
    )
  }
  out <- list(
    time = time, by = by,
    p = as.integer(p), d = as.integer(d), q = as.integer(q)
  )
  class(out) <- "enw_arima_term"
  out
}

# Internal helper: validate that an ARIMA order argument is a non-negative
# integer. Used to keep `arima()` cyclomatic complexity below the lint
# threshold without changing its public behaviour.
.check_arima_order <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
    !is.finite(value) || value < 0 || value != as.integer(value)) {
    cli::cli_abort("`{name}` must be a non-negative integer scalar.")
  }
  invisible(NULL)
}

#' Adds an approximate Gaussian process to the model.
#'
#' @description A call to `gp()` can be used in the `formula` argument of
#' model construction functions in the `epinowcast` package such as
#' [enw_formula()]. It declares a Hilbert-space reduced-rank
#' (spectral) approximate Gaussian process indexed by `time` (and
#' optionally a grouping variable `by`) whose value at each observation
#' is added to the linear predictor. As with [arima()], arguments are
#' not evaluated; they are passed by name for use in model construction.
#'
#' Like [arima()] and [rw()], a `gp()` term works on every module that
#' takes a formula, each with its own prior prefix:
#' - [enw_expectation()] — the growth rate (`expr`) and the latent-to-obs
#'   proportion (`expl`).
#' - [enw_reference()] — the parametric delay mean (`refp`) and the
#'   non-parametric logit hazards (`refnp`).
#' - [enw_report()] — report-date logit hazards (`rep`).
#' - [enw_missing()] — the missing-reference proportion (`miss`).
#'
#' At most one `gp()` term is currently supported per formula (the
#' multiple-term example shown for [gp_terms()] only illustrates term
#' detection, not a supported model). The default `alpha` (magnitude)
#' and length-scale priors are inherited from `EpiNow2` and are set on
#' `EpiNow2`'s scale; on a given module's scale (for example the log
#' growth rate or a logit hazard) they may need tuning with
#' [enw_replace_priors()].
#'
#' @section Reference:
#' The Stan implementation of the approximate Gaussian process is
#' adapted from `EpiNow2` (https://github.com/epiforecasts/EpiNow2,
#' MIT licensed). The Hilbert-space approximation follows
#' Riutort-Mayol et al. (2023), doi:10.1007/s11222-022-10167-2.
#'
#' @param time Defines the time index of the Gaussian process. Must be
#' numeric.
#'
#' @param by Optional grouping variable. If supplied, an independent
#' Gaussian process is fitted for each level of `by` (sharing the
#' length scale and magnitude hyperparameters). Currently limited to a
#' single variable.
#'
#' @param d Non-negative integer, defaults to `0`. Order of
#' differencing, matching the `d` of [arima()]: the per-group
#' realisation is integrated (cumulative-summed) `d` times before it is
#' added to the predictor. `d = 0` gives stationary deviations (the
#' default, equivalent to EpiNow2's `gp_on = "R0"`). `d = 1` integrates
#' once, giving a smoothly drifting, random-walk-like trajectory
#' (equivalent to EpiNow2's default `gp_on = "R_t-1"`). For `d >= 1` the
#' first `d` values of the realisation are anchored to zero, so the free
#' level (and, for `d >= 2`, slope) is carried by the module's fixed
#' effects rather than the GP. Differencing is intended for the latent
#' expectation modules (the growth rate `expr` and latent-to-obs
#' proportion `expl`); integrating a logit-hazard term (`refnp`, `rep`,
#' `miss`) is unusual but permitted for API consistency with [arima()].
#'
#' @param kernel Character string selecting the covariance kernel. One
#' of `"matern32"` (the default, a Matern 3/2 kernel), `"matern52"`
#' (Matern 5/2), `"ou"` (Ornstein-Uhlenbeck, equivalent to Matern
#' 1/2), `"se"` (squared exponential), or `"periodic"`.
#'
#' @param basis_prop Numeric in `(0, 1]`. Proportion of time points to
#' use as basis functions, controlling the accuracy-speed trade-off of
#' the reduced-rank approximation. Defaults to `0.2` (the `EpiNow2`
#' default). The number of basis functions is
#' `ceiling(basis_prop * T)`.
#'
#' @param boundary_scale Numeric, defaults to `1.5`. Boundary factor
#' `L` of the Hilbert-space approximation; the process is approximated
#' on the interval scaled by this factor. This has no effect when
#' `kernel = "periodic"`, which uses a fundamental-frequency basis
#' rather than the boundary-scaled basis.
#'
#' @return A list of class `enw_gp_term` describing the Gaussian
#' process term, interpretable by [construct_gp()].
#' @export
#' @importFrom cli cli_abort
#' @importFrom rlang arg_match
#' @family formulatools
#' @examples
#' gp(time)
#' gp(time, location)
#' gp(time, kernel = "se", basis_prop = 0.3)
#' gp(time, d = 1)
gp <- function(time, by, d = 0, kernel = c(
                 "matern32", "matern52", "ou", "se", "periodic"
               ), basis_prop = 0.2, boundary_scale = 1.5) {
  if (missing(time)) {
    cli::cli_abort("`time` must be present")
  }
  time <- deparse(substitute(time))
  by <- if (missing(by)) NULL else deparse(substitute(by))
  kernel <- rlang::arg_match(kernel)
  # `d` shares the non-negative-integer validation with arima()'s orders.
  .check_arima_order(d, "d")
  .check_gp_basis_prop(basis_prop)
  if (!is.numeric(boundary_scale) || length(boundary_scale) != 1L ||
    !is.finite(boundary_scale) || boundary_scale <= 0) {
    cli::cli_abort("`boundary_scale` must be a positive numeric scalar.")
  }
  # Map the user-facing kernel name to the Stan-side gp_type / nu that
  # the EpiNow2-derived `update_gp()` switch expects. gp_type: 0 = SE,
  # 1 = periodic, 2 = Matern; nu selects the Matern order.
  gp_type <- switch(kernel,
    se = 0L,
    periodic = 1L,
    2L
  )
  nu <- switch(kernel,
    ou = 0.5,
    matern32 = 1.5,
    matern52 = 2.5,
    1.5
  )
  out <- list(
    time = time, by = by, kernel = kernel,
    gp_type = gp_type, nu = nu, d = as.integer(d),
    basis_prop = basis_prop, boundary_scale = boundary_scale
  )
  class(out) <- "enw_gp_term"
  out
}

# Internal helper: validate that the GP `basis_prop` is a numeric scalar
# in (0, 1].
.check_gp_basis_prop <- function(value) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) ||
    !is.finite(value) || value <= 0 || value > 1) {
    cli::cli_abort("`basis_prop` must be a numeric scalar in (0, 1].")
  }
  invisible(NULL)
}

#' Constructs random walk terms
#'
#' @description This function takes random walks as defined
#' by [rw()], produces the required additional variables
#' (denoted using a "c" prefix and constructed using
#' [enw_add_cumulative_membership()]), and then returns the
#' extended `data.frame` along with the new fixed effects and the
#' random effect structure.
#'
#' @param rw A random walk term as defined by [rw()].
#'
#' @param data A `data.frame` of observations used to define the
#' random walk term. Must contain the time and grouping variables
#' defined in the [rw()] term specified.
#'
#' @return A list containing the following:
#'  - `data`: The input `data.frame` with the addition of the new variables
#' required by the specified random walk. These are added using
#' [enw_add_cumulative_membership()].
#'  -`terms`: A character vector of new fixed effects terms to add to a model
#' formula.
#'  - `effects`: A `data.frame` describing the random effect structure of the
#' new effects.
#' @importFrom cli cli_abort cli_inform
#' @family formulatools
#' @examples
#' data <- enw_example("preproc")$metareference[[1]]
#'
#' epinowcast:::construct_rw(rw(week), data)
#'
#' epinowcast:::construct_rw(rw(week, day_of_week), data)
construct_rw <- function(rw, data) {
  # rw() now returns an enw_arima_term with p = 0, d = 1, q = 0; this
  # function delegates to construct_arima() so callers see the unified
  # backend output. Older enw_rw_term inputs are coerced for compat.
  if (inherits(rw, "enw_rw_term")) {
    rw$p <- 0L
    rw$d <- 1L
    rw$q <- 0L
    class(rw) <- "enw_arima_term"
  }
  if (!inherits(rw, "enw_arima_term")) {
    cli::cli_abort(
      "`rw` must be a term constructed by `rw()` or `arima()`."
    )
  }
  construct_arima(rw, data)
}

#' Constructs ARIMA term metadata
#'
#' @description Takes an ARIMA term as defined by [arima()] and returns
#' the metadata required to wire the term into a Stan model. Unlike
#' [construct_rw()], this does not modify the data or produce design
#' matrix columns; ARIMA latent residuals enter the linear predictor
#' through a parameter-dependent kernel applied to unit-normal shocks
#' (see `inst/stan/functions/arima_kernel.stan`).
#'
#' @param arima An ARIMA term as defined by [arima()].
#'
#' @param data A `data.frame` of observations used to define the ARIMA
#' term. Must contain the time and (if specified) grouping variable.
#'
#' @return A list with the following elements:
#'   - `time`, `by`, `p`, `d`, `q`: passed through from the [arima()]
#'     term.
#'   - `T`: number of distinct time points in the series.
#'   - `G`: number of groups (1 if `by` is unspecified).
#'   - `time_idx`: integer vector mapping each row of `data` to a
#'     time index in `1:T`.
#'   - `group_idx`: integer vector mapping each row of `data` to a
#'     group index in `1:G`.
#'   - `time_vals`, `group_levels`: lookup vectors so the indices can
#'     be inverted.
#'   - `name`: a label for the term, suitable as a parameter prefix.
#' @family formulatools
#' @importFrom cli cli_abort
#' @examples
#' data <- enw_example("preproc")$metareference[[1]]
#' epinowcast:::construct_arima(arima(week), data)
#' epinowcast:::construct_arima(
#'   arima(week, day_of_week, p = 2, d = 1), data
#' )
construct_arima <- function(arima, data) {
  if (!inherits(arima, "enw_arima_term")) {
    cli::cli_abort(
      "Argument `arima` must be constructed by `epinowcast::arima()`."
    )
  }
  data <- coerce_dt(data)
  if (is.null(data[[arima$time]])) {
    cli::cli_abort(
      "Time variable `{arima$time}` is not present in the supplied data."
    )
  }
  if (!is.numeric(data[[arima$time]])) {
    cli::cli_abort(
      "Time variable `{arima$time}` must be numeric for an ARIMA term."
    )
  }
  if (anyNA(data[[arima$time]])) {
    cli::cli_abort(
      "Time variable `{arima$time}` contains missing values."
    )
  }

  time_vals <- sort(unique(data[[arima$time]]))
  T_len <- length(time_vals)
  time_idx <- match(data[[arima$time]], time_vals)

  if (is.null(arima$by)) {
    G <- 1L
    group_idx <- rep(1L, nrow(data))
    group_levels <- "1"
  } else {
    if (is.null(data[[arima$by]])) {
      cli::cli_abort(
        "Grouping variable `{arima$by}` is not present in the data."
      )
    }
    by_vals <- data[[arima$by]]
    if (anyNA(by_vals)) {
      cli::cli_abort(
        "Grouping variable `{arima$by}` contains missing values."
      )
    }
    group_levels <- if (is.factor(by_vals)) {
      levels(droplevels(by_vals))
    } else {
      sort(unique(by_vals))
    }
    G <- length(group_levels)
    if (G < 2) {
      cli::cli_inform(paste0(
        "Grouping variable `{arima$by}` has fewer than 2 levels; ",
        "ignoring `by`."
      ))
      G <- 1L
      group_idx <- rep(1L, nrow(data))
      group_levels <- "1"
    } else {
      group_idx <- match(as.character(by_vals), as.character(group_levels))
    }
  }

  if (T_len < arima$p + arima$d + arima$q + 1) {
    cli::cli_abort(paste0(
      "ARIMA series has only {T_len} time points; need at least ",
      "{arima$p + arima$d + arima$q + 1} for ARIMA(",
      "{arima$p}, {arima$d}, {arima$q})."
    ))
  }

  name <- paste0(
    "arima__", arima$time,
    if (!is.null(arima$by)) paste0("__", arima$by) else ""
  )

  list(
    time = arima$time, by = arima$by,
    p = arima$p, d = arima$d, q = arima$q,
    T = T_len, G = G,
    time_idx = time_idx, group_idx = group_idx,
    time_vals = time_vals, group_levels = group_levels,
    name = name
  )
}

#' Hilbert-space basis functions for the approximate Gaussian process
#'
#' @description Builds the `T x M` matrix of basis functions used by the
#' reduced-rank (spectral) approximate Gaussian process, mirroring the
#' `PHI()` / `PHI_periodic()` Stan functions adapted from `EpiNow2`. The
#' time index is rescaled to the symmetric interval used by the
#' approximation before evaluating the basis.
#'
#' @param T_len Integer number of distinct time points.
#' @param M Integer number of basis functions.
#' @param boundary_scale Numeric boundary factor `L`.
#' @param is_periodic Logical, whether to use the periodic basis.
#' @param w0 Numeric fundamental frequency for the periodic basis.
#'
#' @return A numeric matrix of basis functions with `T_len` rows.
#' @noRd
.gp_basis_matrix <- function(T_len, M, boundary_scale, is_periodic = FALSE,
                             w0 = 1.0) {
  x <- seq_len(T_len)
  x <- 2 * (x - mean(x)) / (max(x) - 1)
  if (is_periodic) {
    w0xk <- outer(w0 * x, seq_len(M))
    cbind(cos(w0xk), sin(w0xk))
  } else {
    sin(outer(pi / (2 * boundary_scale) * (x + boundary_scale), seq_len(M))) /
      sqrt(boundary_scale)
  }
}

#' Constructs Gaussian process term metadata
#'
#' @description Takes a Gaussian process term as defined by [gp()] and
#' returns the metadata required to wire the term into a Stan model.
#' Like [construct_arima()], this does not modify the data or produce
#' design matrix columns; the Gaussian process enters the linear
#' predictor through a Hilbert-space reduced-rank approximation (see
#' `inst/stan/functions/gaussian_process.stan`).
#'
#' @param gp A Gaussian process term as defined by [gp()].
#'
#' @param data A `data.frame` of observations used to define the term.
#' Must contain the time and (if specified) grouping variable.
#'
#' @return A list with the following elements:
#'   - `time`, `by`, `kernel`, `gp_type`, `nu`, `d`, `basis_prop`,
#'     `boundary_scale`: passed through from the [gp()] term.
#'   - `T`: number of distinct time points in the integrated series.
#'   - `G`: number of groups (1 if `by` is unspecified).
#'   - `M`: number of basis functions, `ceiling(basis_prop * (T - d))`.
#'   - `PHI`: the `(T - d) x M` basis matrix. For `d >= 1` the basis is
#'     built on the `T - d` free values that are integrated `d` times in
#'     Stan; the first `d` values of the realisation are anchored to
#'     zero.
#'   - `time_idx`, `group_idx`: per-observation lookup indices.
#'   - `time_vals`, `group_levels`: lookup vectors so the indices can
#'     be inverted.
#'   - `name`: a label for the term, suitable as a parameter prefix.
#' @family formulatools
#' @importFrom cli cli_abort
#' @examples
#' data <- enw_example("preproc")$metareference[[1]]
#' epinowcast:::construct_gp(gp(week), data)
#' epinowcast:::construct_gp(gp(week, day_of_week, kernel = "se"), data)
construct_gp <- function(gp, data) {
  if (!inherits(gp, "enw_gp_term")) {
    cli::cli_abort(
      "Argument `gp` must be constructed by `epinowcast::gp()`."
    )
  }
  idx <- .time_group_index(data, gp$time, gp$by, what = "Gaussian process")
  d <- gp$d
  # For d-fold differencing the GP generates the T - d free values that
  # are integrated d times in Stan (the first d values are anchored to
  # zero), so the basis is built on T - d points.
  n_free <- idx$T - d
  if (n_free < 2L) {
    cli::cli_abort(paste0(
      "Gaussian process series has only {idx$T} time points; need at ",
      "least {d + 2} for a `gp()` term with `d = {d}`."
    ))
  }
  M <- as.integer(ceiling(gp$basis_prop * n_free))
  PHI <- .gp_basis_matrix(
    n_free, M, gp$boundary_scale,
    is_periodic = gp$gp_type == 1L, w0 = 1.0
  )

  name <- paste0(
    "gp__", gp$time,
    if (!is.null(gp$by)) paste0("__", gp$by) else ""
  )

  list(
    time = gp$time, by = gp$by, kernel = gp$kernel,
    gp_type = gp$gp_type, nu = gp$nu, d = d,
    basis_prop = gp$basis_prop, boundary_scale = gp$boundary_scale,
    T = idx$T, G = idx$G, M = M, PHI = PHI,
    time_idx = idx$time_idx, group_idx = idx$group_idx,
    time_vals = idx$time_vals, group_levels = idx$group_levels,
    name = name
  )
}

# Internal: shared per-observation time/group indexing used by
# construct_arima() and construct_gp(). Validates the (numeric) time
# variable and the optional grouping variable, returning the distinct
# time/group counts and the per-row lookup indices.
.time_group_index <- function(data, time, by, what = "term") {
  data <- coerce_dt(data)
  if (is.null(data[[time]])) {
    cli::cli_abort(
      "Time variable `{time}` is not present in the supplied data."
    )
  }
  if (!is.numeric(data[[time]])) {
    cli::cli_abort(
      "Time variable `{time}` must be numeric for a {what} term."
    )
  }
  if (anyNA(data[[time]])) {
    cli::cli_abort("Time variable `{time}` contains missing values.")
  }

  time_vals <- sort(unique(data[[time]]))
  T_len <- length(time_vals)
  time_idx <- match(data[[time]], time_vals)

  if (is.null(by)) {
    return(list(
      T = T_len, G = 1L, time_idx = time_idx,
      group_idx = rep(1L, nrow(data)),
      time_vals = time_vals, group_levels = "1"
    ))
  }
  if (is.null(data[[by]])) {
    cli::cli_abort("Grouping variable `{by}` is not present in the data.")
  }
  by_vals <- data[[by]]
  if (anyNA(by_vals)) {
    cli::cli_abort("Grouping variable `{by}` contains missing values.")
  }
  group_levels <- if (is.factor(by_vals)) {
    levels(droplevels(by_vals))
  } else {
    sort(unique(by_vals))
  }
  G <- length(group_levels)
  if (G < 2) {
    cli::cli_inform(
      "Grouping variable `{by}` has fewer than 2 levels; ignoring `by`."
    )
    return(list(
      T = T_len, G = 1L, time_idx = time_idx,
      group_idx = rep(1L, nrow(data)),
      time_vals = time_vals, group_levels = "1"
    ))
  }
  list(
    T = T_len, G = G, time_idx = time_idx,
    group_idx = match(as.character(by_vals), as.character(group_levels)),
    time_vals = time_vals, group_levels = group_levels
  )
}

#' Defines random effect terms using the lme4 syntax
#'
#' @param formula A random effect as returned by \link[reformulas]{findbars}
#' when a random effect is defined using the \link[lme4]{lme4} syntax in
#' formula. Currently only simplified random effects (i.e
#'  LHS | RHS) are supported.
#'
#' @export
#' @return A list defining the fixed and random effects of the specified
#' random effect
#' @family formulatools
#' @examples
#' form <- epinowcast:::parse_formula(~ 1 + (1 | age_group))
#' re(form$random[[1]])
#'
#' form <- epinowcast:::parse_formula(~ 1 + (location | age_group))
#' re(form$random[[1]])
re <- function(formula) {
  terms <- strsplit(as_string_formula(formula), " | ", fixed = TRUE)[[1]]
  out <- list(fixed = terms[1], random = terms[2])
  class(out) <- "enw_re_term"
  out
}

#' Process random effect interactions
#'
#' @param random Character vector of random effects terms.
#' @param data Data frame containing the variables.
#'
#' @return A list with expanded_random (unique variables), random_int
#' (logical vector indicating interactions), and updated random vector.
#' @noRd
.process_random_interactions <- function(random, data) {
  expanded_random <- NULL
  random_int <- rep(FALSE, length(random))

  for (i in seq_along(random)) {
    current_random <- strsplit(random[i], ":", fixed = TRUE)[[1]]

    if (length(current_random) > 1) {
      if (length(current_random) > 2) {
        cli::cli_abort(
          paste0(
            "Interactions between more than 2 variables are not currently ",
            "supported on the right hand side of random effects"
          )
        )
      }
      if (!current_random[2] %in% colnames(data)) {
        cli::cli_abort(
          paste0(
            "Random effect variable {current_random[2]} is not present ",
            "in the data."
          )
        )
      }
      if (length(unique(data[[current_random[2]]])) < 2) {
        cli::cli_inform(
          paste0(
            "A random effect using {current_random[2]} is not possible as ",
            "this variable has fewer than 2 unique values."
          )
        )
        random[i] <- current_random[1]
      } else {
        random_int[i] <- TRUE
      }
    }
    expanded_random <- c(expanded_random, current_random)
  }

  list(
    expanded_random = unique(expanded_random),
    random_int = random_int,
    random = random
  )
}

#' Construct fixed effects terms from random and fixed components
#'
#' @param fixed Character vector of fixed effects.
#' @param random Character vector of random effects.
#' @param random_int Logical vector indicating which random effects are
#' interactions.
#'
#' @return A list with terms and terms_int.
#' @noRd
.construct_fe_terms <- function(fixed, random, random_int) {
  terms <- NULL
  terms_int <- NULL

  for (i in seq_along(random)) {
    terms <- c(terms, paste0(fixed, ":", random[i]))
    terms_int <- c(terms_int, rep(random_int[i], length(fixed)))
  }

  names(terms_int) <- terms
  terms <- gsub("1:", "", terms, fixed = TRUE)
  keep <- !startsWith(terms, "0:")
  terms <- terms[keep]
  terms_int <- terms_int[keep]

  list(terms = terms, terms_int = terms_int)
}

#' Add pooling effect for single term with interaction
#'
#' @param effects Effects data frame.
#' @param k Term components.
#'
#' @return Updated effects data frame.
#' @noRd
.add_pooling_single_interaction <- function(effects, k) {
  enw_add_pooling_effect(
    effects,
    var_name = gsub(":", "__", k, fixed = TRUE),
    finder_fn = function(effect, pattern) {
      grepl(pattern[1], effect) &
        grepl(pattern[2], effect, fixed = TRUE) &
        lengths(
          regmatches(effect, gregexpr(":", effect, fixed = TRUE))
        ) == 1
    },
    pattern = strsplit(k, ":", fixed = TRUE)[[1]]
  )
}

#' Add pooling effect for single term without interaction
#'
#' @param effects Effects data frame.
#' @param k Term components.
#'
#' @return Updated effects data frame.
#' @noRd
.add_pooling_single_no_interaction <- function(effects, k) {
  enw_add_pooling_effect(
    effects,
    var_name = k,
    finder_fn = function(effect, pattern) {
      grepl(pattern, effect) & !grepl(":", effect, fixed = TRUE)
    },
    pattern = k
  )
}

#' Add pooling effect for multiple terms with interaction
#'
#' @param effects Effects data frame.
#' @param k Term components.
#'
#' @return Updated effects data frame.
#' @noRd
.add_pooling_multi_interaction <- function(effects, k) {
  enw_add_pooling_effect(
    effects,
    var_name = paste(gsub(":", "__", k, fixed = TRUE), collapse = "__"),
    finder_fn = function(effect, pattern) {
      grepl(pattern[1], effect) & grepl(pattern[2], effect) &
        grepl(pattern[3], effect)
    },
    pattern = c(k[1], strsplit(k[-1], ":", fixed = TRUE)[[1]])
  )
}

#' Add pooling effect for multiple terms without interaction
#'
#' @param effects Effects data frame.
#' @param k Term components.
#'
#' @return Updated effects data frame.
#' @noRd
.add_pooling_multi_no_interaction <- function(effects, k) {
  enw_add_pooling_effect(
    effects,
    var_name = paste(k, collapse = "__"),
    finder_fn = function(effect, pattern) {
      grepl(pattern[1], effect) & grepl(pattern[2], effect)
    },
    pattern = rev(k)
  )
}

#' Add pooling effects for a single term
#'
#' @param effects Effects data frame.
#' @param k Term components.
#' @param is_interaction Logical indicating if term has interaction.
#'
#' @return Updated effects data frame.
#' @noRd
.add_pooling_for_term <- function(effects, k, is_interaction) {
  if (length(k) == 1 && is_interaction) {
    return(.add_pooling_single_interaction(effects, k))
  }
  if (length(k) == 1) {
    return(.add_pooling_single_no_interaction(effects, k))
  }
  if (is_interaction) {
    return(.add_pooling_multi_interaction(effects, k))
  }
  .add_pooling_multi_no_interaction(effects, k)
}

#' Implement random effects structure
#'
#' @param effects Effects metadata data frame.
#' @param terms Character vector of terms.
#' @param terms_int Named logical vector indicating interactions.
#' @param data Data frame containing the variables.
#'
#' @return Updated effects data frame.
#' @importFrom purrr map
#' @noRd
.implement_re_structure <- function(effects, terms, terms_int, data) {
  for (i in seq_along(terms)) {
    loc_terms <- strsplit(terms[i], ":", fixed = TRUE)[[1]]

    if (terms_int[i]) {
      expanded_int <- unique(data[[loc_terms[length(loc_terms)]]])
      expanded_int <- paste0(loc_terms[length(loc_terms)], expanded_int)
      j <- purrr::map(expanded_int, function(x) {
        j <- NULL
        if (length(loc_terms) > 2) {
          j <- loc_terms[1:(length(loc_terms) - 2)]
        }
        j <- c(j, paste0(loc_terms[length(loc_terms) - 1], ":", x))
        j
      })
    } else {
      j <- list(loc_terms)
    }

    for (k in j) {
      effects <- .add_pooling_for_term(effects, k, terms_int[i])
    }
  }
  effects
}

#' Constructs random effect terms
#'
#' @param re A random effect as defined using [re()] which itself takes
#' random effects specified in a model formula using the \link[lme4]{lme4}
#' syntax.
#'
#' @param data A `data.frame` of observations used to define the
#' random effects. Must contain the variables specified in the
#' [re()] term.
#'
#' @return A list containing the transformed data ("data"),
#' fixed effects terms ("terms") and a  `data.frame` specifying
#' the random effect structure between these terms (`effects`). Note
#' that if the specified random effect was not a factor it will have been
#' converted into one.
#'
#' @family formulatools
#' @importFrom purrr map
#' @importFrom cli cli_abort cli_inform
#' @examples
#' # Simple examples
#' form <- epinowcast:::parse_formula(~ 1 + (1 | day_of_week))
#' data <- enw_example("prepr")$metareference[[1]]
#' random_effect <- re(form$random[[1]])
#' epinowcast:::construct_re(random_effect, data)
#'
#' # A more complex example
#' form <- epinowcast:::parse_formula(
#'   ~ 1 + disp + (1 + gear | cyl) + (0 + wt | am)
#' )
#' random_effect <- re(form$random[[1]])
#' epinowcast:::construct_re(random_effect, mtcars)
#'
#' random_effect2 <- re(form$random[[2]])
#' epinowcast:::construct_re(random_effect2, mtcars)
construct_re <- function(re, data) {
  if (!inherits(re, "enw_re_term")) {
    cli::cli_abort(
      paste0(
        "Argument `re` must be a random effect term as constructed by ",
        "`epinowcast:::re`"
      )
    )
  }

  fixed <- strsplit(re$fixed, " + ", fixed = TRUE)[[1]]
  random <- strsplit(re$random, " + ", fixed = TRUE)[[1]]

  processed <- .process_random_interactions(random, data)
  random <- processed$random
  random_int <- processed$random_int
  expanded_random <- processed$expanded_random

  fe_terms <- .construct_fe_terms(fixed, random, random_int)
  terms <- fe_terms$terms
  terms_int <- fe_terms$terms_int

  data <- coerce_dt(data, required_cols = expanded_random)[,
    (expanded_random) := lapply(.SD, as.factor),
    .SDcols = expanded_random
  ]

  fixed <- enw_manual_formula(
    data,
    fixed = terms, no_contrasts = TRUE,
    add_intercept = FALSE
  )$fixed$design

  effects <- enw_effects_metadata(fixed)
  effects <- .implement_re_structure(effects, terms, terms_int, data)

  list(data = data, terms = terms, effects = effects)
}

#' Define a model using a formula interface
#'
#' @description This function allows models to be defined using a
#' flexible formula interface that supports fixed effects, random effects
#' (using \link[lme4]{lme4} syntax), and random walks. The formula syntax
#' builds on standard R formula notation and extends it with \link[lme4]{lme4}
#' style random effects and custom random walk terms. Users familiar with
#' mixed models in lme4 or brms will recognise the syntax. Note that the
#' returned fixed effects design matrix is sparse and so the index supplied
#' is required to link observations to the appropriate design matrix row.
#'
#' @param formula A model formula that may use standard fixed
#' effects, random effects using \link[lme4]{lme4} syntax (see [re()]), and
#' random walks defined using the [rw()] helper function. See the Details
#' section below for a comprehensive explanation of the supported syntax.
#'
#' @param data A `data.frame` of observations. It must include all
#' variables used in the supplied formula.
#'
#' @param sparse Logical, defaults to  `TRUE`. Should the fixed effects design
#' matrix be sparely defined.
#'
#' @details
#' ## Formula syntax overview
#'
#' The formula interface supports three types of model components:
#'
#' **Fixed effects**: Standard R formula syntax as used in [stats::lm()] and
#' similar functions. For example:
#' - `~ 1`: intercept only
#' - `~ age_group`: intercept plus categorical predictor
#' - `~ age_group + location`: multiple predictors
#' - `~ 0 + age_group`: no intercept (contrasts)
#'
#' **Random effects**: Uses \link[lme4]{lme4} syntax with vertical bar notation.
#' Random effects allow parameters to vary by group whilst sharing information
#' across groups through partial pooling. Note that `epinowcast` assumes
#' independent standard deviations for random effects rather than correlated
#' random effects as supported by \link[lme4]{lme4}. For example:
#' - `~ 1 + (1 | location)`: random intercepts by location
#' - `~ 1 + age_group + (1 | location)`: fixed age effect with random
#' location intercepts
#' - `~ (age_group | location)`: random slopes for age within each location
#' - `~ (1 + week | location:month)`: random intercepts and week effects
#' for each location-month combination (using interaction to create
#' independent random effects per strata)
#'
#' Interactions (e.g., `location:month`) can be used on the right-hand side
#' of the vertical bar to specify independent random effects for each
#' combination of the interacting variables.
#'
#' See the \link[lme4]{lme4} package documentation for more details on
#' random effects syntax.
#'
#' **Random walks**: Uses the [rw()] helper function to specify time-varying
#' effects that evolve smoothly over time. For example:
#' - `~ rw(week)`: a random walk over weeks
#' - `~ rw(week, location)`: independent random walks for each location
#' - `~ rw(week, location)`: random walks with shared variance across
#' locations (per-group variance is a planned extension)
#'
#' **ARIMA residuals**: Uses the [arima()] helper to add an ARIMA(p, d, q)
#' latent residual series to the linear predictor. Unlike [rw()], the
#' kernel that maps unit-normal shocks to the latent series depends on
#' the autoregressive and moving-average parameters, so the term does
#' not produce design-matrix columns; it carries lookup metadata that
#' the Stan layer uses with the kernel from
#' `inst/stan/functions/arima_kernel.stan`. For example:
#' - `~ arima(week)`: AR(1) on weekly residuals
#' - `~ arima(week, location, p = 2, d = 1, q = 1)`: ARIMA(2, 1, 1)
#' driven by independent shocks per location, with `phi`, `theta`,
#' and `sigma` shared across locations (per-group parameters are a
#' planned extension)
#' - `arima(time, d = 1, p = 0, q = 0)` is equivalent to `rw(time)`
#'
#' Convenience aliases match `brms`'s in-formula vocabulary:
#' - `ar(time, by, p)` is `arima(time, by, p = p, d = 0, q = 0)`
#' - `ma(time, by, q)` is `arima(time, by, p = 0, d = 0, q = q)`
#' - `arma(time, by, p, q)` is `arima(time, by, p = p, d = 0, q = q)`
#'
#' These four types of effects can be combined in a single formula,
#' for example: `~ 1 + age_group + (1 | location) + rw(week, location)`
#' specifies fixed age effects, random location intercepts, and
#' location-specific random walks over time.
#'
#' ## Turning off model components
#'
#' In `epinowcast` model specification functions (such as [enw_reference()],
#' [enw_report()], [enw_expectation()]), formula arguments can be set to `~0`
#' to disable that model component entirely. This is a package-specific
#' convention. Note that when a formula is specified as `~0`, it is typically
#' converted internally to `~1` (intercept only) to ensure valid model
#' structure, but the component is flagged as inactive.
#'
#' ## How formulas map to the model
#'
#' The formula you specify controls which covariates and effects enter the
#' linear predictor of the model. For instance, in the reference date model
#' ([enw_reference()]), the formula determines how reporting delay parameters
#' vary by covariates and groups. The formula is converted to design matrices:
#' a fixed effects matrix (which may be sparse for computational efficiency)
#' and a random effects matrix that defines the hierarchical structure.
#'
#' @references
#' For users new to formula syntax in R:
#' - **Fixed effects**: See `?formula` and the "Statistical Models in R"
#' chapter of "An Introduction to R" at the URL:
#'
#' <https://cran.r-project.org/doc/manuals/r-release/R-intro.html#Statistical-models-in-R> # nolint: line_length_linter
#'
#' - **Random effects**: See the \link[lme4]{lme4} package documentation
#' and vignettes.
#' - **Mixed models**: Bates et al. (2015) "Fitting Linear Mixed-Effects
#' Models Using lme4". Journal of Statistical Software, 67(1), 1-48.
#' doi:10.18637/jss.v067.i01
#'
#' @return A list containing the following:
#'  - `formula`: The user supplied formula
#'  - `parsed_formula`: The formula as parsed by [parse_formula()]
#'  - `expanded_formula`: The flattened version of the formula with
#'  both user supplied terms and terms added for the user supplied
#'  complex model components.
#'  - `fixed`:  A list containing the fixed effect formula, sparse design
#'  matrix, and the index linking the design matrix with observations.
#'  - `random`: A list containing the random effect formula, sparse design
#'  matrix, and the index linking the design matrix with random effects.
#'
#' @family formulatools
#' @export
#' @importFrom purrr map transpose
#' @importFrom data.table rbindlist setnafill
#' @importFrom cli cli_abort
#' @examples
#' # Use meta data for references dates from the Germany COVID-19
#' # hospitalisation data.
#' obs <- enw_filter_report_dates(
#'   germany_covid19_hosp[location == "DE"],
#'   remove_days = 40
#' )
#' obs <- enw_filter_reference_dates(obs, include_days = 40)
#' pobs <- enw_preprocess_data(
#'   obs,
#'   by = c("age_group", "location"), max_delay = 20
#' )
#' data <- pobs$metareference[[1]]
#'
#' # Intercept only
#' enw_formula(~1, data)
#'
#' # Fixed effect
#' enw_formula(~ 1 + age_group, data)
#'
#' # Random intercepts
#' enw_formula(~ 1 + (1 | age_group), data)
#'
#' # Random walk
#' enw_formula(~ 1 + rw(week), data)
#'
#' # Model with a random effect for age group and a random walk
#' enw_formula(~ 1 + (1 | age_group) + rw(week), data)
#'
#' # Model defined without a sparse fixed effects design matrix
#' enw_formula(~1, data[1:20, ], sparse = FALSE)
#'
#' # Model using an interaction in the right hand side of a random effect
#' # to specify an independent random effect per strata.
#' enw_formula(~ (1 + day | week:month), data = data)
enw_formula <- function(formula, data, sparse = TRUE) {
  data <- coerce_dt(data)

  # Parse formula
  parsed_formula <- parse_formula(formula)

  rw_terms <- NULL
  rw_metadata <- NULL

  # rw() and arima() now share a single backend: rw(time, by, type)
  # is exactly arima(time, by, p = 0, d = 1, q = 0, type = type) and
  # both produce enw_arima_term objects. Process them together
  # through construct_arima so they pick up the per-observation
  # lookup metadata used at the Stan layer to apply a
  # parameter-dependent kernel to unit-normal shocks.
  arima_calls <- c(parsed_formula$rw, parsed_formula$arima)
  if (length(arima_calls) > 0) {
    arima_specs <- purrr::map(
      arima_calls,
      ~ eval(parse(text = paste0("epinowcast::", .)))
    )
    arima_specs <- purrr::map(arima_specs, construct_arima, data = data)
  } else {
    arima_specs <- list()
  }

  # Gaussian process terms enter the linear predictor through a
  # Hilbert-space reduced-rank approximation. Like arima() terms they
  # carry per-observation lookup metadata rather than design columns.
  if (length(parsed_formula$gp) > 0) {
    gp_specs <- purrr::map(
      parsed_formula$gp,
      ~ eval(parse(text = paste0("epinowcast::", .)))
    )
    gp_specs <- purrr::map(gp_specs, construct_gp, data = data)
  } else {
    gp_specs <- list()
  }

  # Get random effects for all specified random effects
  # Happens last as converts all RHS variables to factors (which can interact)
  # with other formula terms (i.e. random walks)
  if (length(parsed_formula$random) > 0) {
    random <- purrr::map(parsed_formula$random, re)
    for (i in seq_along(random)) {
      random[[i]] <- construct_re(random[[i]], data)
      data <- random[[i]]$data
      random[[i]]$data <- NULL
    }
    random <- purrr::transpose(random)

    random_terms <- unlist(random$terms)
    # Check that the user hasn't specified the same fixed and random effect
    if (any(random_terms %in% parsed_formula$fixed)) {
      cli::cli_abort(
        "Random effect terms must not be included in the fixed effects formula",
        call. = FALSE
      )
    }
    random_metadata <- data.table::rbindlist(
      random$effects,
      use.names = TRUE, fill = TRUE
    )
  } else {
    random_terms <- NULL
    random_metadata <- NULL
  }

  # Make fixed design matrix using all fixed effects from all components
  # this should include new variables added by the random effects
  # need to make sure all random effects don't have contrasts
  terms <- c(parsed_formula$fixed, random_terms, rw_terms)
  expanded_formula <- as.formula(paste0("~ ", paste(terms, collapse = " + ")))
  fixed <- enw_design(
    formula = expanded_formula,
    no_contrasts = random_terms,
    data = data,
    sparse = sparse
  )

  # Joint sparse deduplication: when an ARIMA term is supplied
  # alongside a sparse design, deduplicate by the joint (covariate
  # row × ARIMA time × ARIMA group) granularity rather than by
  # covariate row alone. This lets downstream consumers that loop over
  # fdesign rows (for example a per-row PMF call) benefit from
  # coarse-time ARIMA without paying per-snapshot cost.
  # Both ARIMA and GP terms gather a per-observation latent value from a
  # (time x group) matrix using a column-major `flat_idx`. Under a sparse
  # design the fdesign rows are deduplicated, so the latent gather has to
  # be keyed at the joint (covariate row x time x group) granularity for
  # every latent term that is present. Build a single joint key over all
  # present terms' time/group columns so the deduplicated `fixed$index`
  # stays aligned for ARIMA and GP simultaneously, then remap each term's
  # `time_idx`/`group_idx` onto the deduplicated rows.
  if (sparse && (length(arima_specs) > 0 || length(gp_specs) > 0)) {
    joint <- data.table::data.table(cov = fixed$index)
    key_cols <- "cov"
    if (length(arima_specs) > 0) {
      joint[, "at" := arima_specs[[1]]$time_idx]
      joint[, "ag" := arima_specs[[1]]$group_idx]
      key_cols <- c(key_cols, "at", "ag")
    }
    if (length(gp_specs) > 0) {
      joint[, "gt" := gp_specs[[1]]$time_idx]
      joint[, "gg" := gp_specs[[1]]$group_idx]
      key_cols <- c(key_cols, "gt", "gg")
    }
    joint[, "uniq" := .GRP, by = key_cols]
    new_index <- joint[["uniq"]]
    uniq <- unique(joint, by = key_cols)
    data.table::setorderv(uniq, "uniq")
    fixed$design <- fixed$design[uniq[["cov"]], , drop = FALSE]
    fixed$index <- new_index
    if (length(arima_specs) > 0) {
      arima_specs[[1]]$time_idx <- uniq[["at"]]
      arima_specs[[1]]$group_idx <- uniq[["ag"]]
    }
    if (length(gp_specs) > 0) {
      gp_specs[[1]]$time_idx <- uniq[["gt"]]
      gp_specs[[1]]$group_idx <- uniq[["gg"]]
    }
  }
  # Extract fixed effects metadata
  metadata <- enw_effects_metadata(fixed$design)

  # Combine with random effects and random walk effects
  if (!is.null(random_metadata)) {
    metadata <- metadata[!random_metadata, on = "effects"]
    metadata <- rbind(metadata, random_metadata, use.names = TRUE, fill = TRUE)
  }

  if (!is.null(rw_metadata)) {
    metadata <- metadata[!rw_metadata, on = "effects"]
    metadata <- rbind(metadata, rw_metadata, use.names = TRUE, fill = TRUE)
  }

  metadata <- cbind(
    metadata[, "effects"],
    data.table::setnafill(metadata[, -"effects"], fill = 0)
  )

  # Make the random effects design matrix
  if (ncol(metadata) == 2) {
    random <- enw_design(~1, metadata, sparse = FALSE)
  } else {
    random_formula <- as.formula(
      paste0(
        "~ 0 + ",
        paste(
          paste0("`", colnames(metadata)[-1], "`"),
          collapse = " + "
        )
      )
    )
    random <- enw_design(random_formula, metadata, sparse = FALSE)
  }

  out <- list(
    formula = as_string_formula(formula),
    parsed_formula = parsed_formula,
    expanded_formula = as_string_formula(expanded_formula),
    fixed = fixed,
    random = random,
    arima = arima_specs,
    gp = gp_specs
  )
  class(out) <- c("enw_formula", class(out))
  out
}
