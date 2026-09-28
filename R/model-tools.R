#' Format formula data for use with stan
#'
#' @param formula The output of [enw_formula()].
#'
#' @param prefix A character string indicating variable
#' label to use as a prefix.
#'
#' @param drop_intercept Logical, defaults to `FALSE`. Should the
#' intercept be included as a fixed effect or excluded. This is used internally
#' in model modules where an intercept must be present/absent.
#'
#' @return A list defining the model formula. This includes:
#'  - `prefix_fintercept:` Is an intercept present for the fixed effects design
#'     matrix.
#'  - `prefix_fdesign`: The fixed effects design matrix
#'  - `prefix_fnrow`: The number of rows of the fixed design matrix
#'  - `prefix_findex`: The index linking design matrix rows to  observations
#'  - `prefix_fnindex`: The length of the index
#'  - `prefix_fncol`: The number of columns (i.e effects) in the fixed effect
#'  design matrix (minus 1 if an intercept is present).
#'  - `prefix_rdesign`: The random effects design matrix
#'  - `prefix_rncol`: The number of columns (i.e random effects) in the random
#'  effect design matrix (minus 1 as the intercept is dropped).
#'  - `prefix_arima_present`: `1` if the formula contains an [arima()] term,
#'  `0` otherwise.
#'  - `prefix_arima_T`, `prefix_arima_G`: ARIMA series length and group count.
#'  - `prefix_arima_p`, `prefix_arima_d`, `prefix_arima_q`: ARIMA orders.
#'  - `prefix_arima_flat_idx`: per-observation column-major index into a
#'  `(T x G)` ARIMA residual matrix, used by Stan to gather residuals
#'  with `to_vector(eps)[flat_idx]`.
#'  - `prefix_arima_n_obs`: length of the lookup vectors.
#' @family modeltools
#' @importFrom cli cli_abort
#' @export
#' @examples
#' f <- enw_formula(~ 1 + (1 | cyl), mtcars)
#' enw_formula_as_data_list(f, "mtcars")
#'
#' # A missing formula produces the default list
#' enw_formula_as_data_list(prefix = "missing")
enw_formula_as_data_list <- function(formula, prefix, drop_intercept = FALSE) {
  data <- list(
    fintercept = 0,
    fnrow = 0,
    findex = numeric(0),
    fnindex = 0,
    fncol = 0,
    rncol = 0,
    fdesign = numeric(0),
    fdesign_means = numeric(0),
    rdesign = numeric(0),
    arima_present = 0L,
    arima_T = 0L,
    arima_G = 0L,
    arima_p = 0L,
    arima_d = 0L,
    arima_q = 0L,
    arima_n_obs = 0L,
    arima_flat_idx = integer(0),
    gp_present = 0L,
    gp_T = 0L,
    gp_G = 0L,
    gp_M = 0L,
    gp_type = 0L,
    gp_nu = 0,
    gp_d = 0L,
    gp_L = 0,
    gp_n_obs = 0L,
    gp_PHI = matrix(numeric(0), 0, 0),
    gp_flat_idx = integer(0)
  )
  if (!missing(formula)) {
    if (!inherits(formula, "enw_formula")) {
      cli::cli_abort(
        paste0(
          "formula must be an object of class enw_formula as produced using ",
          "`enw_formula()`"
        )
      )
    }
    fintercept <- as.numeric(any(grepl(
      "(Intercept)", colnames(formula$fixed$design),
      fixed = TRUE
    )))
    data$fintercept <- fintercept
    data$fnrow <- nrow(formula$fixed$design)
    data$findex <- formula$fixed$index
    data$fnindex <- length(formula$fixed$index)
    data$fncol <- ncol(formula$fixed$design) - fintercept
    data$rncol <- ncol(formula$random$design) - 1

    # Store dense matrices
    data$fdesign <- formula$fixed$design
    if (fintercept) {
      data$fdesign <- data$fdesign[, -1, drop = FALSE]
    }
    # Observation-weighted column means of the (non-intercept) fixed
    # design, used to centre the design in Stan so the intercept
    # decorrelates from the slopes (brms-style). Weighted by how often
    # each design row is used via the observation index. The choice of
    # means leaves the posterior unchanged (it only shifts the level
    # between the intercept and the slopes); these means are the ones
    # that best decorrelate the two.
    full_design <- formula$fixed$design[formula$fixed$index, , drop = FALSE]
    data$fdesign_means <- as.numeric(colMeans(full_design))
    if (fintercept) {
      data$fdesign_means <- data$fdesign_means[-1]
    }
    data$rdesign <- formula$random$design

    if (length(formula$arima) > 1L) {
      cli::cli_abort(
        "Only one `arima()` term per formula is currently supported."
      )
    }
    if (length(formula$arima) == 1L) {
      a <- formula$arima[[1]]
      data$arima_present <- 1L
      data$arima_T <- a$T
      data$arima_G <- a$G
      data$arima_p <- a$p
      data$arima_d <- a$d
      data$arima_q <- a$q
      data$arima_n_obs <- length(a$time_idx)
      # Pre-flatten (time, group) into a single column-major index
      # over a (T x G) matrix so the Stan side can do a single
      # vectorised gather (`to_vector(eps)[flat_idx]`) instead of a
      # per-observation lookup loop.
      data$arima_flat_idx <- as.integer(
        (a$group_idx - 1L) * a$T + a$time_idx
      )
    }

    if (length(formula$gp) > 1L) {
      cli::cli_abort(
        "Only one `gp()` term per formula is currently supported."
      )
    }
    if (length(formula$gp) == 1L) {
      g <- formula$gp[[1]]
      data$gp_present <- 1L
      data$gp_T <- g$T
      data$gp_G <- g$G
      data$gp_M <- g$M
      data$gp_type <- g$gp_type
      data$gp_nu <- g$nu
      data$gp_d <- g$d
      data$gp_L <- g$boundary_scale
      data$gp_n_obs <- length(g$time_idx)
      data$gp_PHI <- g$PHI
      # Column-major (T x G) flatten, identical to the ARIMA scheme, so
      # the Stan side can gather the per-observation GP contribution
      # with `to_vector(gp_eps)[flat_idx]`.
      data$gp_flat_idx <- as.integer(
        (g$group_idx - 1L) * g$T + g$time_idx
      )
    }
  }
  names(data) <- sprintf("%s_%s", prefix, names(data))
  data
}

#' Build a module prior table
#'
#' Internal constructor for the `data.table` of priors returned in the
#' `$priors` element of each model module (see [enw_reference()],
#' [enw_report()], [enw_expectation()], [enw_missing()], and [enw_obs()]).
#' Each prior is a `<dist_spec>` object from the `distspec` package (for
#' example [distspec::Normal()] or [distspec::LogNormal()]) holding the
#' location and scale that the Stan model applies.
#'
#' @param variable Character vector of prior variable names (without the
#' `_p` suffix used in the Stan model).
#'
#' @param description Character vector describing each prior.
#'
#' @param distribution Character vector naming the prior family the Stan
#' model applies to each variable. One of `"Normal"`,
#' `"Zero truncated normal"`, `"Log normal"`, or `"Uniform"`.
#'
#' @param prior A list of `<dist_spec>` objects with the same length as
#' `variable`, giving the parameters of each prior. Use `NULL` for a flat
#' prior (only supported for `"Uniform"` entries).
#'
#' @param dimension Optional integer vector giving the index of each entry
#' of a vectorised prior. Defaults to `NULL` (no `dimension` column).
#'
#' @return A `data.table` with columns `variable`, `dimension` (when
#' supplied), `description`, `distribution`, `prior`, `mean`, and `sd`.
#' `mean` and `sd` are derived from `prior` (the location and scale the
#' Stan model applies, e.g. `meanlog`/`sdlog` for a `"Log normal"` prior;
#' see [.enw_prior_params()]) and kept for backwards compatibility with
#' code that reads the numeric prior location and scale directly.
#' @keywords internal
#' @importFrom cli cli_abort
.enw_prior_table <- function(variable, description, distribution, prior,
                             dimension = NULL) {
  n <- length(variable)
  if (length(description) != n || length(distribution) != n ||
        length(prior) != n) {
    cli::cli_abort(
      paste0(
        "{.arg description}, {.arg distribution}, and {.arg prior} must ",
        "have the same length as {.arg variable} ({n})"
      )
    )
  }
  out <- data.table::data.table(variable = variable)
  if (!is.null(dimension)) {
    data.table::set(out, j = "dimension", value = dimension)
  }
  data.table::set(out, j = "description", value = description)
  data.table::set(out, j = "distribution", value = distribution)
  data.table::set(out, j = "prior", value = list(unname(prior)))
  purrr::pwalk(
    list(out$prior, out$distribution, out$variable), .enw_check_prior
  )
  params <- purrr::map(out$prior, .enw_prior_params)
  data.table::set(out, j = "mean", value = vapply(params, `[`, numeric(1), 1))
  data.table::set(out, j = "sd", value = vapply(params, `[`, numeric(1), 2))
  out[]
}

#' Prior families supported for each model prior distribution
#'
#' The default `distribution` of a prior (see [.enw_prior_table()])
#' identifies the support of the parameter it is placed on: `"Normal"`
#' priors are on unbounded parameters, `"Zero truncated normal"` and
#' `"Log normal"` priors on positive parameters, and `"Uniform"` priors on
#' the ARIMA partial autocorrelations in (-1, 1). The prior family passed
#' to the Stan model must be supported on that parameter.
#'
#' @param distribution A character string naming the default prior family
#' the Stan model applies (see [.enw_prior_table()]), or `NA`.
#'
#' @return A character vector of the `<dist_spec>` distribution types (as
#' returned by [distspec::get_distribution()]) that can be used to specify
#' the prior.
#' @keywords internal
.enw_prior_families <- function(distribution) {
  positive <- c("normal", "lognormal", "gamma", "exp")
  if (isTRUE(distribution == "Normal")) {
    "normal"
  } else if (isTRUE(distribution %in% c("Zero truncated normal", "Log normal"))) {
    positive
  } else if (isTRUE(distribution == "Uniform")) {
    c("normal", "fixed")
  } else {
    # An unknown distribution (e.g. a prior table without a `distribution`
    # column) accepts any supported family.
    c(positive, "fixed")
  }
}

#' Distribution id of a prior for the Stan model
#'
#' @param prior A `<dist_spec>` with fixed parameters, or `NULL` for a flat
#' prior.
#'
#' @return An integer: `0` for a flat prior (`NULL` or a fixed value, which
#' leaves the parameter bounds as the only constraint), `1` for a normal,
#' `2` for a log-normal, `3` for a gamma, and `4` for an exponential prior.
#' @keywords internal
.enw_prior_dist_id <- function(prior) {
  if (is.null(prior)) {
    return(0L)
  }
  ids <- c(fixed = 0L, normal = 1L, lognormal = 2L, gamma = 3L, exp = 4L)
  family <- distspec::get_distribution(prior)
  if (!family %in% names(ids)) {
    cli::cli_abort(
      paste0(
        "Priors must be specified using {.fn distspec::Normal}, ",
        "{.fn distspec::LogNormal}, {.fn distspec::Gamma}, ",
        "{.fn distspec::Exponential}, or {.fn distspec::Fixed}, not a ",
        "{.val {family}} distribution"
      )
    )
  }
  ids[[family]]
}

#' Extract the location and scale a prior passes to Stan
#'
#' @param prior A `<dist_spec>` with fixed parameters, or `NULL` for a flat
#' prior.
#'
#' @return A numeric vector of length two giving the location and scale used
#' by the Stan model: the `mean` and `sd` of a normal prior, the `meanlog`
#' and `sdlog` of a log-normal prior, the `shape` and `rate` of a gamma
#' prior, the `rate` and `0` of an exponential prior, the value and `0` for
#' a fixed value, and `0` and `0` for a flat prior.
#' @keywords internal
.enw_prior_params <- function(prior) {
  if (is.null(prior)) {
    return(c(0, 0))
  }
  .enw_prior_dist_id(prior)
  params <- distspec::get_parameters(prior)
  switch(distspec::get_distribution(prior),
    normal = c(params$mean, params$sd),
    lognormal = c(params$meanlog, params$sdlog),
    gamma = c(params$shape, params$rate),
    exp = c(params$rate, 0),
    fixed = c(params$value, 0)
  )
}

#' Mean and standard deviation of a prior for initial values
#'
#' @inheritParams .enw_prior_dist_id
#'
#' @return A numeric vector of length two giving the mean and standard
#' deviation of the prior on the natural scale (`0` and `0` for a flat
#' prior), used to draw initial values near the centre of the prior.
#' @keywords internal
.enw_prior_moments <- function(prior) {
  if (is.null(prior)) {
    return(c(0, 0))
  }
  c(mean(prior), distspec::sd(prior))
}

#' Check that a prior can be used by the Stan model
#'
#' @param prior A `<dist_spec>` or `NULL`.
#'
#' @param distribution A character string naming the prior family the Stan
#' model applies to `variable` (see [.enw_prior_table()]), or `NA` if
#' unknown.
#'
#' @param variable A character string naming the prior variable (used in
#' error messages).
#'
#' @return `NULL` invisibly. Called for its side effect of raising an
#' informative error when `prior` is not usable.
#' @keywords internal
#' @importFrom cli cli_abort
.enw_check_prior <- function(prior, distribution = NA_character_,
                             variable = "prior") {
  if (is.null(distribution) || length(distribution) != 1) {
    distribution <- NA_character_
  }
  if (is.null(prior)) {
    if (!identical(distribution, "Uniform")) {
      cli::cli_abort(
        paste0(
          "The prior for {.var {variable}} must be a {.cls dist_spec} ",
          "(e.g. {.code distspec::Normal(mean = 0, sd = 1)}); a flat ",
          "({.code NULL}) prior is only supported where the model uses a ",
          "Uniform prior"
        )
      )
    }
    return(invisible(NULL))
  }
  if (!inherits(prior, "dist_spec")) {
    cli::cli_abort(
      paste0(
        "The prior for {.var {variable}} must be a {.cls dist_spec} from ",
        "the {.pkg distspec} package (e.g. ",
        "{.code distspec::Normal(mean = 0, sd = 1)}), not an object of ",
        "class {.cls {class(prior)}}"
      )
    )
  }
  if (distspec::ndist(prior) != 1) {
    cli::cli_abort(
      paste0(
        "The prior for {.var {variable}} must be a single distribution, ",
        "not a sum of distributions"
      )
    )
  }
  if (distspec::has_uncertainty(prior)) {
    cli::cli_abort(
      paste0(
        "The prior for {.var {variable}} must have fixed (numeric) ",
        "parameters; parameters that are themselves uncertain are not ",
        "supported"
      )
    )
  }
  families <- .enw_prior_families(distribution)
  family <- distspec::get_distribution(prior)
  if (!family %in% families) {
    constructors <- c(
      normal = "distspec::Normal()", lognormal = "distspec::LogNormal()",
      gamma = "distspec::Gamma()", exp = "distspec::Exponential()",
      fixed = "distspec::Fixed()"
    )
    allowed <- constructors[families] # nolint: object_usage_linter
    cli::cli_abort(
      paste0(
        "The prior for {.var {variable}} must be a {.or {.code {allowed}}} ",
        "distribution as the model applies a {distribution} prior, not a ",
        "{.val {family}} distribution"
      )
    )
  }
  params <- .enw_prior_params(prior)
  if (length(params) != 2 || !all(is.finite(params))) {
    cli::cli_abort(
      "The prior for {.var {variable}} must have finite scalar parameters"
    )
  }
  # The scale (sd, sdlog or rate) must be positive, as must the shape of a
  # gamma and the rate of an exponential; a fixed value has no scale.
  positive <- switch(family,
    normal = params[2], lognormal = params[2], gamma = params,
    exp = params[1], numeric(0)
  )
  if (any(positive <= 0)) {
    cli::cli_abort(
      "The prior for {.var {variable}} must have positive parameters"
    )
  }
  invisible(NULL)
}

#' Construct a prior from a location and scale
#'
#' Used to convert priors given as a mean and standard deviation (for
#' example from `summary(nowcast, type = "fit")`) into a `<dist_spec>`.
#' The values are used as the location and scale of the prior on the scale
#' the Stan model applies it, so for a `"Log normal"` prior they are the
#' `meanlog` and `sdlog`.
#'
#' @param location Numeric, the location (mean) of the prior.
#'
#' @param scale Numeric, the scale (standard deviation) of the prior.
#'
#' @inheritParams .enw_check_prior
#' @return A `<dist_spec>`.
#' @keywords internal
.enw_prior_from_location_scale <- function(location, scale,
                                           distribution = NA_character_) {
  location <- as.numeric(location)
  scale <- as.numeric(scale)
  if (identical(distribution, "Log normal")) {
    distspec::LogNormal(meanlog = location, sdlog = scale)
  } else {
    distspec::Normal(mean = location, sd = scale)
  }
}

#' Coerce prior specifications to a prior table
#'
#' Converts the supported ways of specifying priors into a `data.table`
#' with a `variable` column and a `prior` list column of `<dist_spec>`
#' objects. See [enw_replace_priors()] for the supported formats.
#'
#' @param x A named list of `<dist_spec>` objects, a `data.frame` with a
#' `variable` column and a `prior` list column, or a `data.frame` with
#' `variable`, `mean`, and `sd` columns.
#'
#' @param template An optional prior table (with `variable` and
#' `distribution` columns) used to look up the prior family for entries of
#' `x` given as a mean and standard deviation.
#'
#' @param arg A character string naming the argument being coerced (used in
#' error messages).
#'
#' @return A `data.table` with a `variable` column and a `prior` list
#' column. Other columns of a `data.frame` input are retained.
#' @keywords internal
#' @importFrom cli cli_abort
#' @importFrom purrr map pmap
.enw_as_prior_table <- function(x, template = NULL, arg = "priors") {
  if (inherits(x, "dist_spec")) {
    cli::cli_abort(
      paste0(
        "{.arg {arg}} must be a named list of {.cls dist_spec} objects ",
        "(e.g. {.code list(refp_mean_int = distspec::Normal(1, 1))}), ",
        "not a single {.cls dist_spec}"
      )
    )
  }
  if (is.list(x) && !is.data.frame(x)) {
    nms <- names(x)
    if (length(x) > 0 && (is.null(nms) || !all(nzchar(nms, keepNA = FALSE)))) {
      cli::cli_abort(
        paste0(
          "{.arg {arg}} must be a named list of {.cls dist_spec} objects ",
          "with a prior variable name for each element"
        )
      )
    }
    out <- data.table::data.table(variable = as.character(nms))
    data.table::set(out, j = "prior", value = list(unname(x)))
    return(out[])
  }
  if (!is.data.frame(x)) {
    cli::cli_abort(
      paste0(
        "{.arg {arg}} must be a named list of {.cls dist_spec} objects or ",
        "a {.cls data.frame} with a {.var variable} column and either a ",
        "{.var prior} column or {.var mean} and {.var sd} columns"
      )
    )
  }
  if ("prior" %in% colnames(x)) {
    out <- coerce_dt(x, required_cols = c("variable", "prior"))
    if (!is.list(out$prior)) {
      cli::cli_abort(
        "The {.var prior} column of {.arg {arg}} must be a list column"
      )
    }
    return(out[])
  }
  if (!all(c("mean", "sd") %in% colnames(x))) {
    cli::cli_abort(
      paste0(
        "{.arg {arg}} must have a {.var prior} column of {.cls dist_spec} ",
        "objects or {.var mean} and {.var sd} columns"
      )
    )
  }
  out <- coerce_dt(x, required_cols = c("variable", "mean", "sd"))
  base <- .enw_prior_base_name(out$variable)
  if (!is.null(template) && "distribution" %in% colnames(template)) {
    distribution <- template$distribution[match(base, template$variable)]
  } else if ("distribution" %in% colnames(out)) {
    distribution <- out$distribution
  } else {
    distribution <- rep(NA_character_, nrow(out))
  }
  prior <- purrr::pmap(
    list(out$mean, out$sd, distribution), .enw_prior_from_location_scale
  )
  out[, c("mean", "sd") := NULL]
  data.table::set(out, j = "prior", value = list(prior))
  out[]
}

# Strip a trailing `[n]` index from prior variable names, so that
# `variable[n]` matches the prior variable `variable`.
.enw_prior_base_name <- function(x) {
  gsub("\\[.*\\]$", "", x)
}

#' Find the rows of a prior table matched by a prior variable name
#'
#' @param priors A prior table with a `variable` column and optionally a
#' `dimension` column.
#'
#' @param name A character string naming the prior to match. An index of the
#' form `variable[n]` matches the entry with `dimension == n` when
#' `variable` is vectorised and is otherwise ignored.
#'
#' @param strict Logical, defaults to `TRUE`. If `TRUE`, an error is raised
#' when `name` does not match any prior variable. If `FALSE`, no rows are
#' matched instead.
#'
#' @return A logical vector indicating the matched rows of `priors`.
#' @keywords internal
#' @importFrom cli cli_abort
.enw_match_prior_rows <- function(priors, name, strict = TRUE) {
  base <- .enw_prior_base_name(name)
  rows <- priors$variable == base
  if (!any(rows)) {
    if (!strict) {
      return(rows)
    }
    cli::cli_abort(
      paste0(
        "{.var {name}} is not a prior variable in {.arg priors}. Available ",
        "prior variables are: {.val {unique(priors$variable)}}"
      )
    )
  }
  index <- suppressWarnings(
    as.integer(sub("^[^[]+[[]([0-9]+)[]]$", "\\1", name))
  )
  if (!is.na(index) && "dimension" %in% colnames(priors) &&
        !all(is.na(priors$dimension[rows]))) {
    rows <- rows & !is.na(priors$dimension) & priors$dimension == index
    if (!any(rows)) {
      cli::cli_abort(
        "{.var {base}} has no entry with dimension {index}"
      )
    }
  }
  rows
}

#' Convert priors to a list for Stan
#'
#' Converts priors specified as `<dist_spec>` objects into the list
#' format used by the Stan model. Each prior becomes a `2 x n` array with
#' the location in the first row and the scale in the second (with `n > 1`
#' for vectorised priors) together with an integer distribution id, and
#' `_p` (or `_p_dist`) is added to each variable name so that priors can be
#' distinguished from the corresponding parameters.
#'
#' @param priors Priors in any of the formats supported by
#' [enw_replace_priors()]: the `$priors` table of a model module, a named
#' list of `<dist_spec>` objects, a `data.frame` with `variable` and `prior`
#' list columns, or a `data.frame` with `variable`, `mean`, and `sd`
#' columns.
#'
#' @return A named list with, for each prior variable, a `<variable>_p`
#' entry giving the prior as a `2 x n` array of its location and scale
#' (the `mean` and `sd` of a normal prior, the `meanlog` and `sdlog` of a
#' log-normal prior, the `shape` and `rate` of a gamma prior, and the `rate`
#' of an exponential prior) and a `<variable>_p_dist` entry giving the
#' integer distribution id used by the Stan model (`0` flat, `1` normal,
#' `2` log-normal, `3` gamma, `4` exponential). The entries of a vectorised
#' prior must share a distribution family.
#' @family modeltools
#' @importFrom purrr map map_int
#' @export
#' @examples
#' priors <- list(
#'   x = distspec::Normal(mean = 1, sd = 2),
#'   y = distspec::LogNormal(meanlog = 0, sdlog = 0.5)
#' )
#' enw_priors_as_data_list(priors)
#'
#' # From the default priors of a model module
#' enw_priors_as_data_list(enw_obs(data = enw_example("preprocessed"))$priors)
enw_priors_as_data_list <- function(priors) {
  priors <- .enw_as_prior_table(priors)
  variable <- factor(priors$variable, levels = unique(priors$variable))
  params <- split(purrr::map(priors$prior, .enw_prior_params), variable)
  dist <- split(purrr::map_int(priors$prior, .enw_prior_dist_id), variable)
  mixed <- names(dist)[purrr::map_int(dist, ~ length(unique(.))) > 1]
  if (length(mixed) > 0) {
    cli::cli_abort(
      paste0(
        "The entries of a vectorised prior must share a distribution ",
        "family, but {.var {mixed}} mixes families"
      )
    )
  }
  out <- purrr::map(params, ~ as.array(matrix(unlist(.), nrow = 2)))
  names(out) <- paste0(names(out), "_p")
  dist <- purrr::map(dist, 1L)
  names(dist) <- paste0(names(dist), "_p_dist")
  c(out, dist)[
    as.vector(rbind(names(out), names(dist)))
  ]
}

#' Convert priors to a list of means and standard deviations
#'
#' Internal companion to [enw_priors_as_data_list()] used by the model
#' modules' initial value functions. Each prior becomes a `2 x n` array
#' with the prior mean in the first row and standard deviation in the
#' second, on the natural scale of the parameter, so that initial values
#' can be drawn near the centre of any supported prior family.
#'
#' @inheritParams enw_priors_as_data_list
#'
#' @return A named list with each `<variable>_p` entry a `2 x n` array of
#' prior means and standard deviations.
#' @keywords internal
.enw_priors_as_init_list <- function(priors) {
  priors <- .enw_as_prior_table(priors)
  variable <- factor(priors$variable, levels = unique(priors$variable))
  moments <- split(purrr::map(priors$prior, .enw_prior_moments), variable)
  out <- purrr::map(moments, ~ as.array(matrix(unlist(.), nrow = 2)))
  names(out) <- paste0(names(out), "_p")
  out
}

#' Replace default priors with user specified priors
#'
#' Replaces default model priors with user specified ones.
#' Priors are specified using the `<dist_spec>` objects of the `distspec`
#' package (for example [distspec::Normal()] and [distspec::LogNormal()]),
#' as in `EpiNow2`.
#' A common use is extracting the posterior from a previous
#' [epinowcast()] run (using `summary(nowcast, type = "fit")`)
#' and using it as a prior for subsequent fits.
#'
#' Default priors can be obtained from each model module's
#' `$priors` element, e.g. `enw_reference(data = pobs)$priors`.
#' See the `priors` argument of [epinowcast()] for a list of
#' available prior variable names by module.
#'
#' @details
#' Each default prior has a `distribution` describing the default prior
#' family, which also identifies the support of the parameter it is placed
#' on.
#' The prior family is passed to the Stan model, so a replacement can use
#' any family supported on that parameter: [distspec::Normal()] for
#' `"Normal"` priors (on unbounded parameters such as intercepts);
#' [distspec::Normal()] (truncated at zero by the parameter bounds),
#' [distspec::LogNormal()], [distspec::Gamma()], or
#' [distspec::Exponential()] for `"Zero truncated normal"` and
#' `"Log normal"` priors (on positive parameters such as standard
#' deviations and length scales); and [distspec::Normal()] (truncated to
#' (-1, 1)) for `"Uniform"` priors on the ARIMA partial autocorrelations,
#' where `NULL` or a standard deviation of zero restores the flat default.
#' Parameters must be fixed numbers rather than distributions.
#'
#' Priors given as a mean and standard deviation (for example from
#' `summary(nowcast, type = "fit")`) are converted to the family of the
#' default they replace.
#' The values are used as the location and scale on the scale the model
#' applies the prior, so for a `"Log normal"` prior they are the `meanlog`
#' and `sdlog`.
#' Use [distspec::LogNormal()] with `mean` and `sd` to specify a log-normal
#' prior by its natural-scale mean and standard deviation.
#'
#' @param priors The default priors to update, usually the `data.frame`
#' with a `variable` column and a `prior` list column of `<dist_spec>`
#' objects returned by the `$priors` element of [enw_reference()] and
#' other model module functions. The same formats as `custom_priors` are
#' accepted.
#'
#' @param custom_priors The replacement priors as a named list of
#' `<dist_spec>` objects (e.g.
#' `list(refp_mean_int = distspec::Normal(mean = 1, sd = 0.5))`), a
#' `data.frame` with `variable` and `prior` columns, or a `data.frame` with
#' `variable`, `mean`, and `sd` columns.
#' Entries replace the matching rows of `priors` by the `variable` column.
#' Vectorised prior names of the form `variable[n]` replace the entry with
#' `dimension == n` when `variable` is vectorised (i.e. has a `dimension`
#' index) and otherwise match `variable` after stripping the index.
#' Every element of a named list must name a prior variable in `priors`
#' (an error is raised otherwise), whereas rows of a `data.frame` that do
#' not match a prior variable (such as the non-prior parameters in a
#' posterior summary) are ignored.
#'
#' @return A `data.table` of prior definitions with the same columns and
#' rows as `priors` and the matched entries of the `prior` column replaced.
#' @family modeltools
#' @importFrom purrr map
#' @export
#' @examples
#' # Update priors from a named list of distributions
#' priors <- enw_obs(data = enw_example("preprocessed"))$priors
#' enw_replace_priors(
#'   priors, list(sqrt_phi = distspec::Normal(mean = 0, sd = 1))
#' )
#'
#' # Update priors from a previous model fit
#' default_priors <- enw_reference(
#'   distribution = "lognormal",
#'   data = enw_example("preprocessed"),
#' )$priors
#' print(default_priors)
#'
#' fit_priors <- summary(
#'   enw_example("nowcast"),
#'   type = "fit",
#'   variables = c("refp_mean_int", "refp_sd_int", "sqrt_phi")
#' )
#' fit_priors
#'
#' enw_replace_priors(default_priors, fit_priors)
enw_replace_priors <- function(priors, custom_priors) {
  priors <- .enw_as_prior_table(priors, arg = "priors")
  custom <- .enw_as_prior_table(
    custom_priors,
    template = priors, arg = "custom_priors"
  )
  strict <- !is.data.frame(custom_priors)
  new_prior <- priors$prior
  for (i in seq_len(nrow(custom))) {
    variable <- custom$variable[i]
    rows <- .enw_match_prior_rows(priors, variable, strict = strict)
    if (!any(rows)) {
      next
    }
    distribution <- NA_character_
    if ("distribution" %in% colnames(priors)) {
      distribution <- priors$distribution[rows][1]
    }
    prior <- custom$prior[[i]]
    .enw_check_prior(prior, distribution, variable)
    new_prior[rows] <- rep(list(prior), sum(rows))
  }
  data.table::set(priors, j = "prior", value = list(new_prior))
  # Keep the derived `mean`/`sd` columns (see `.enw_prior_table()`) in sync
  # with any replaced priors, when the input table has them.
  if (all(c("mean", "sd") %in% colnames(priors))) {
    params <- purrr::map(new_prior, .enw_prior_params)
    data.table::set(
      priors, j = "mean", value = vapply(params, `[`, numeric(1), 1)
    )
    data.table::set(
      priors, j = "sd", value = vapply(params, `[`, numeric(1), 2)
    )
  }
  priors[]
}

#' Remove profiling statements from a character vector representing stan code
#'
#' @param s Character vector representing stan code
#'
#' @return A `character` vector of the stan code without profiling statements
#' @family modeltools
remove_profiling <- function(s) {
  while (grepl("profile\\(.+\\)\\s*\\{", s, perl = TRUE)) {
    s <- gsub(
      "profile\\(.+\\)\\s*\\{((?:[^{}]++|\\{(?1)\\})++)\\}", "\\1", s,
      perl = TRUE
    )
  }
  s
}

#' Write copies of the .stan files of a Stan model and its #include files
#' with all profiling statements removed.
#'
#' @param stan_file The path to a .stan file containing a Stan program.
#'
#' @param include_paths Paths to directories where Stan should look for files
#' specified in #include directives in the Stan program.
#'
#' @param target_dir The path to a directory in which the manipulated .stan
#' files without profiling statements should be stored. To avoid overriding of
#' the original .stan files, this should be different from the directory of the
#' original model and the `include_paths`.
#'
#' @return A `list` containing the path to the .stan file without profiling
#' statements and the include_paths for the included .stan files without
#' profiling statements
#'
#' @family modeltools
write_stan_files_no_profile <- function(stan_file, include_paths = NULL,
                                        target_dir = epinowcast::enw_get_cache()
                                        ) {
  check_cmdstanr()
  # remove profiling from main .stan file
  code_main_model <- paste(readLines(stan_file, warn = FALSE), collapse = "\n")
  code_main_model_no_profile <- remove_profiling(code_main_model)
  if (!dir.exists(target_dir)) {
    dir.create(target_dir, recursive = TRUE)
  }
  main_model <- cmdstanr::write_stan_file(
    code_main_model_no_profile,
    dir = target_dir,
    basename = basename(stan_file),
    force_overwrite = FALSE
  )

  # remove profiling from included .stan files
  include_paths_no_profile <- rep(NA, length(include_paths))
  for (i in length(include_paths)) {
    include_paths_no_profile[i] <- file.path(
      target_dir, paste0("include_", i), basename(include_paths[i])
    )
    include_files <- list.files(
      include_paths[i],
      pattern = "*.stan", recursive = TRUE
    )
    for (f in include_files) {
      include_paths_no_profile_fdir <- file.path(
        include_paths_no_profile[i], dirname(f)
      )
      code_include <- paste(
        readLines(file.path(include_paths[i], f), warn = FALSE),
        collapse = "\n"
      )
      code_include_paths_no_profile <- remove_profiling(code_include)
      if (!dir.exists(include_paths_no_profile_fdir)) {
        dir_create_with_parents(include_paths_no_profile_fdir)
      }
      cmdstanr::write_stan_file(
        code_include_paths_no_profile,
        dir = include_paths_no_profile_fdir,
        basename = basename(f),
        force_overwrite = FALSE
      )
    }
  }
  list(model = main_model, include_paths = include_paths_no_profile)
}

#' Fit a CmdStan model using NUTS
#'
#' @param data A list of data as produced by model modules (for example
#' [enw_expectation()], [enw_obs()], etc.) and as required for use the
#' `model` being used.
#'
#' @param model A `cmdstanr` model object as loaded by [enw_model()] or as
#' supplied by the user.
#'
#' @param init A list of initial values or a function to generate initial
#' values. If not provided, the model will attempt to generate initial values
#'
#' @param init_method The method to use for initializing the model. Defaults to
#' "prior" which samples initial values from the prior. "pathfinder", which uses
#' the pathfinder algorithm ([enw_pathfinder()]) to initialize the model.
#'
#' @param init_method_args A list of additional arguments to pass to the
#' initialization method.
#'
#' @param diagnostics Logical, defaults to `TRUE`. Should fitting diagnostics
#' be returned as a `data.frame`.
#'
#' @param ... Additional parameters passed to the `sample` method of `cmdstanr`.
#'
#' @return A `data.frame` containing the `cmdstanr` fit, the input data, the
#' fitting arguments, and optionally summary diagnostics.
#'
#' @family modeltools
#' @export
#' @importFrom posterior rhat
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#'
#' nowcast <- epinowcast(pobs,
#'   expectation = enw_expectation(~1, data = pobs),
#'   fit = enw_fit_opts(enw_sample, pp = TRUE),
#'   obs = enw_obs(family = "poisson", data = pobs),
#' )
#'
#' summary(nowcast)
#'
#' # Use pathfinder initialization
#' nowcast_pathfinder <- epinowcast(pobs,
#'   expectation = enw_expectation(~1, data = pobs),
#'   fit = enw_fit_opts(enw_sample, pp = TRUE, init_method = "pathfinder"),
#'   obs = enw_obs(family = "poisson", data = pobs),
#' )
#'
#' summary(nowcast_pathfinder)
enw_sample <- function(data, model = epinowcast::enw_model(),
                       init = NULL, init_method = c("prior", "pathfinder"),
                       init_method_args = list(), diagnostics = TRUE, ...) {
  init_method <- rlang::arg_match(init_method)

  updated_inits <- update_inits(
    data, model, init, init_method, init_method_args, ...
  )

  cli::cli_alert_info("Fitting the model using NUTS")
  fit <- model$sample(data = data, init = updated_inits$init, ...)

  out <- data.table(
    fit = list(fit),
    data = list(data),
    fit_args = list(list(...)),
    init_method_output = list(updated_inits$method_output)
  )

  if (diagnostics) {
    fit <- out$fit[[1]]
    diag <- fit$sampler_diagnostics(format = "df")
    diagnostics <- data.table(
      samples = nrow(diag),
      max_rhat = round(max(
        fit$summary(
          variables = NULL, posterior::rhat,
          .args = list(na.rm = TRUE)
        )$`posterior::rhat`,
        na.rm = TRUE
      ), 2),
      divergent_transitions = sum(diag$divergent__),
      per_divergent_transitions = sum(diag$divergent__) / nrow(diag),
      max_treedepth = max(diag$treedepth__)
    )
    diagnostics[, no_at_max_treedepth := sum(diag$treedepth__ == max_treedepth)]
    diagnostics[, per_at_max_treedepth := no_at_max_treedepth / nrow(diag)]
    out <- cbind(out, diagnostics)

    timing <- round(fit$time()$total, 1)
    out[, run_time := timing]
  }
  out[]
}

#' Update initial values for model fitting
#'
#' This function updates the initial values for model fitting based on the
#' specified initialization method.
#'
#' @inheritParams enw_sample
#' @param ... Additional arguments passed to initialization methods.
#'
#' @return A list containing updated initial values and method-specific output.
#' @keywords internal
update_inits <- function(data, model, init,
                         init_method = c("prior", "pathfinder"),
                         init_method_args = list(), ...) {
  rlang::arg_match(init_method)
  dot_args <- list(...)

  if (init_method == "pathfinder") {
    init_method_args$threads_per_chain <- dot_args$threads_per_chain
    cli::cli_alert_info("Using pathfinder initialization.")
    pf <- do.call(
      enw_pathfinder,
      c(list(data = data, model = model, init = init), init_method_args)
    )
    updated_init <- pf$fit[[1]]
    method_output <- pf
  } else if (init_method == "prior") {
    cli::cli_alert_info("Using prior initialization.")
    updated_init <- init
    method_output <- NULL
  }

  list(init = updated_init, method_output = method_output)
}

#' Fit a CmdStan model using the pathfinder algorithm
#'
#' For more information on the pathfinder algorithm see the
#' [CmdStan documentation](https://mc-stan.org/cmdstanr/reference/model-method-pathfinder.html). # nolint
#'
#' Note that the `threads_per_chain` argument is renamed to `num_threads` to
#' match the `CmdStanModel$pathfinder()` method.
#'
#' This fitting method is faster but more approximate than the NUTS sampler
#' used in [enw_sample()] and as such is recommended for use in exploratory
#' analysis and model development.
#'
#' @inheritParams enw_sample
#' @param ... Additional parameters to be passed to `CmdStanModel$pathfinder()`.
#'
#' @return A data.table containing the fit, data, and fit_args.
#' If diagnostics is TRUE, it also includes the run_time column with the timing
#' information.
#'
#' @export
#' @family modeltools
#' @importFrom cli cli_abort
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#'
#' nowcast <- epinowcast(pobs,
#'   expectation = enw_expectation(~1, data = pobs),
#'   fit = enw_fit_opts(enw_pathfinder, pp = TRUE),
#'   obs = enw_obs(family = "poisson", data = pobs),
#' )
#'
#' summary(nowcast)
enw_pathfinder <- function(data, model = epinowcast::enw_model(),
                           diagnostics = TRUE, init = NULL, ...) {
  if (is.null(model[["pathfinder"]])) {
    cli::cli_abort(
      "`pathfinder` algorithm unavailable. Requires CmdStan >=2.34."
    )
  }
  dot_args <- list(...)
  dot_args$num_threads <- dot_args$threads_per_chain
  dot_args$threads_per_chain <- NULL
  dot_args$init <- init
  fit <- do.call(model$pathfinder, c(list(data), dot_args))

  out <- data.table(
    fit = list(fit),
    data = list(data),
    fit_args = list(list(...))
  )

  if (diagnostics) {
    timing <- round(fit$time()$total, 1)
    out[, run_time := timing]
  }
  out[]
}

#' Load and compile the nowcasting model
#'
#' @param model A character string indicating the path to the model.
#' If not supplied the package default model is used.
#'
#' @param include A character string specifying the path to any stan
#' files to include in the model. If missing the package default is used.
#'
#' @param compile Logical, defaults to `TRUE`. Should the model
#' be loaded and compiled using [cmdstanr::cmdstan_model()].
#'
#' @param threads Logical, defaults to `TRUE`. Should the model compile with
#' support for multi-thread support in chain. Note that setting this will
#' produce a warning that `threads_to_chain` is set and ignored. Changing this
#' to `FALSE` is not expected to yield any performance benefits even when
#' not using multithreading and thus not recommended.
#'
#' @param verbose Logical, defaults to `TRUE`. Should verbose
#' messages be shown.
#'
#' @param profile Logical, defaults to `FALSE`. Should the model be profiled?
#' For more on profiling see the [`cmdstanr` documentation](https://mc-stan.org/cmdstanr/articles/profiling.html). # nolint
#'
#' @param stanc_options A list of options to pass to the `stanc_options` of
#' [cmdstanr::cmdstan_model()]. By default nothing is passed but potentially
#' users may wish to pass optimisation flags for example. See the documentation
#' for [cmdstanr::cmdstan_model()] for further details.
#'
#' @param cpp_options A list of options to pass to the `cpp_options` of
#' [cmdstanr::cmdstan_model()]. By default nothing is passed but potentially
#' users may wish to pass optimisation flags for example. See the documentation
#' for [cmdstanr::cmdstan_model()] for further details. Note that the `threads`
#' argument replaces `stan_threads`.
#'
#' @param ... Additional arguments passed to [cmdstanr::cmdstan_model()].
#'
#' @return A `cmdstanr` model.
#'
#' @family modeltools
#' @importFrom cli cli_alert_info
#' @export
#' @inheritParams write_stan_files_no_profile
#' @examplesIf interactive()
#' mod <- enw_model()
enw_model <- function(model = system.file(
                        "stan", "epinowcast.stan",
                        package = "epinowcast"
                      ),
                      include = system.file("stan", package = "epinowcast"),
                      compile = TRUE, threads = TRUE, profile = FALSE,
                      target_dir = epinowcast::enw_get_cache(),
                      stanc_options = list(),
                      cpp_options = list(), verbose = TRUE, ...) {
  check_cmdstanr()
  if (verbose) {
    cli::cli_alert_info("Using model {model}.")
    cli::cli_alert_info("Include is {toString(include)}.")
  }

  if (!profile) {
    stan_no_profile <- write_stan_files_no_profile(
      model, include,
      target_dir = target_dir
    )
    model <- stan_no_profile$model
    include <- stan_no_profile$include_paths
  }

  if (compile) {
    monitor <- suppressMessages
    if (verbose) {
      monitor <- function(x) {
        x
      }
    }
    cpp_options$stan_threads <- threads
    model <- monitor(cmdstanr::cmdstan_model(
      model,
      include_paths = include,
      stanc_options = stanc_options,
      cpp_options = cpp_options,
      ...
    ))
  }
  model
}

#' Expose `epinowcast` stan functions in R
#'
#' @description This function facilitates the exposure of Stan functions from
#' the [epinowcast]() package in R. It utilizes the
#' \link[cmdstanr]{expose_functions} method of [cmdstanr::CmdStanModel] for
#' this purpose. This function is useful for
#' developers and contributors to the [epinowcast] package, as well as for
#' users interested in exploring and prototyping with model functionalities.
#'
#' @param files A character vector specifying the names of Stan files to be
#' exposed. These must be in the `include` directory. Defaults to all Stan
#' files in the `include` directory. Note that the following files contain
#' overloaded functions and cannot be exposed: "delay_lpmf.stan",
#' "allocate_observed_obs.stan", "obs_lpmf.stan", and "effects_priors_lp.stan".
#'
#' @param include A character string specifying the directory containing Stan
#' files. Defaults to the 'stan/functions' directory of the [epinowcast()]
#' package.
#'
#' @param global A logical value indicating whether to expose the functions
#' globally. Defaults to `TRUE`. Passed to the \link[cmdstanr]{expose_functions}
#' method of \link[cmdstanr]{CmdStanModel}.
#'
#' @param ... Additional arguments passed to [enw_model]().
#'
#' @inheritParams enw_model
#' @return An object of class `CmdStanModel` with functions from the model
#' exposed for use in R.
#'
#' @family modeltools
#' @importFrom cli cli_abort cli_warn
#' @export
#' @examplesIf interactive()
#' # Compile functions in stan/functions/hazard.stan
#' stan_functions <- enw_stan_to_r("hazard.stan")
#' # These functions can now be used in R
#' stan_functions$functions$prob_to_hazard(c(0.5, 0.1, 0.1))
#' # or exposed globally and used directly
#' prob_to_hazard(c(0.5, 0.1, 0.1))
enw_stan_to_r <- function(
  files = list.files(include, pattern = "\\.stan$"),
  include = system.file("stan", "functions", package = "epinowcast"),
  global = TRUE,
  verbose = TRUE,
  ...
) {
  check_cmdstanr()
  overloaded_fns <- c(
    "delay_lpmf.stan", "allocate_observed_obs.stan", "obs_lpmf.stan",
    "prior_lpdf.stan", "effects_priors_lp.stan",
    # regression.stan calls the overloaded effect_priors_lp() so it
    # cannot be standalone-compiled when that file is excluded.
    "regression.stan"
  )
  if (any(files %in% overloaded_fns)) {
    cli::cli_warn(c(
      "The following functions are overloaded and cannot be exposed: ",
      toString(overloaded_fns)
    ))
    files <- files[!files %in% overloaded_fns]
  }
  if (length(files) == 0 || is.null(files)) {
    cli::cli_abort(paste0(
      "No non-overloaded files specified. Please specify files to expose ",
      "using the `files` argument."
    ))
  }
  include_files <- list.files(include)
  if (!all(files %in% include_files)) {
    cli::cli_abort(c(
      paste0(
        "The following files are not in the include directory: ",
        toString(files[!files %in% include_files])
      ),
      "The following files are in the include directory: ",
      toString(include_files)
    ))
  }
  functions <- stan_fns_as_string(files, include)
  function_file <- cmdstanr::write_stan_file(functions)
  mod <- enw_model(
    model = function_file,
    include = include,
    verbose = verbose,
    compile_standalone = TRUE,
    ...
  )
  if (isTRUE(global)) {
    mod$expose_functions(global = TRUE)
  }
  mod
}

#' Set caching location for Stan models
#'
#' This function allows the user to set a cache location for Stan models
#' rather than a temporary directory. This can reduce the need for model
#' compilation on every new model run across sessions or within a session.
#' For R version 4.0.0 and above, it's recommended to use the persistent cache
#' as shown in the example.
#'
#' @param path A valid filepath representing the desired cache location. If
#' the directory does not exist it will be created.
#'
#' @param type A character string specifying the cache type. It can be one of
#' "session", "persistent", or "all". Default is "session".
#' "session" sets the cache for the current session, "persistent" writes the
#' cache location to the user's `.Renviron` file,  and "all" does both.
#'
#' @return The string of the filepath set.
#'
#' @family modeltools
#' @importFrom cli cli_abort cli_alert_success cli_alert_warning
#' @importFrom rlang arg_match
#' @export
#' @examplesIf interactive()
#' # Set to local directory
#' my_enw_cache <- enw_set_cache(file.path(tempdir(), "test"))
#' enw_get_cache()
#' \dontrun{
#' # Use the package cache in R >= 4.0
#' if (R.version.string >= "4.0.0") {
#'   enw_set_cache(
#'     tools::R_user_dir(package = "epinowcast", "cache"),
#'     type = "all"
#'   )
#' }
#' }
enw_set_cache <- function(path, type = c("session", "persistent", "all")) {
  type <- rlang::arg_match(type, multiple = TRUE)

  if (!is.character(path)) {
    cli::cli_abort("`path` must be a valid file path.")
  }

  candidate_path <- normalizePath(path, winslash = "\\", mustWork = FALSE)

  create_cache_dir(candidate_path)

  if (any(type %in% c("persistent", "all"))) {
    unset_cache_from_environ(alert_on_not_set = FALSE)
    env_contents_active <- get_renviron_contents()

    enw_environment <- paste0("enw_cache_location=\"", candidate_path, "\"\n")

    new_env_contents <- append(
      env_contents_active[["env_contents"]],
      enw_environment
    )

    writeLines(
      new_env_contents,
      con = env_contents_active[["env_path"]], sep = "\n"
    )

    cli::cli_alert_success(
      "Added `{enw_environment}` to `.Renviron` at {env_contents_active[['env_path']]}" # nolint line_length
    )
  }

  if (any(type %in% c("session", "all"))) {
    prior_cache <- Sys.getenv("enw_cache_location", unset = "", names = NA)
    if (!check_environment_unset(prior_cache)) {
      cli::cli_alert_warning(
        "Environment variable `enw_cache_location` exists and will be overwritten" # nolint line_length
      )
    }
    cli::cli_alert_success(
      "Set `enw_cache_location` to {candidate_path}"
    )
    Sys.setenv(enw_cache_location = candidate_path)
  }

  invisible(candidate_path)
}

#' Unset Stan cache location
#'
#' Optionally removes the `enw_cache_location` environment variable from
#' the user .Renviron file and/or removes it from the local
#' environment. If you unset the local cache and want to switch
#' back to using the persistent cache, you can reload the
#' `.Renviron` file using `readRenviron("~/.Renviron")`.
#'
#' @param type A character string specifying the type of cache to unset.
#' It can be one of "session", "persistent", or "all". Default is "session".
#' "session" unsets the cache for the current session, "persistent" removes the
#' cache location from the user's `.Renviron` file,and "all" does all options.
#'
#' @return The prior cache location, if it existed otherwise `NULL`.
#'
#' @importFrom cli cli_alert_success cli_alert_danger
#' @importFrom rlang arg_match
#' @family modeltools
#' @export
#' @examplesIf interactive()
#' enw_unset_cache()
enw_unset_cache <- function(type = c("session", "persistent", "all")) {
  type <- rlang::arg_match(type, multiple = TRUE)

  prior_location <- NULL

  if (any(type %in% c("session", "all"))) {
    prior_location <- Sys.getenv("enw_cache_location")
    if (prior_location != "") {
      Sys.unsetenv("enw_cache_location")
      cli::cli_alert_success(
        "Removed `enw_cache_location = {prior_location}` from the local environment." # nolint line_length
      )
      if (any(type == "session")) {
        environ <- get_renviron_contents()
        cache_in_environ <- check_renviron_for_cache(environ)
        if (any(cache_in_environ)) {
          cli::cli_alert_info(
            "To revert to the persistent cache, run `readRenviron('~/.Renviron')`" # nolint line_length
          )
        }
      }
    } else {
      cli::cli_alert_danger(
        "`enw_cache_location` not set in the local environment. Nothing to unset." # nolint line_length
      )
    }
  }

  if (any(type %in% c("persistent", "all"))) {
    unset_cache_from_environ()
  }

  invisible(prior_location)
}

#' Retrieve Stan cache location
#'
#' Retrieves the user set cache location for Stan models. This
#' path can be set through the `enw_cache_location` function call.
#' If no environmental variable is available the output from
#' [tempdir()] will be returned.
#'
#' @return A string representing the file path for the cache location
#' @importFrom cli cli_inform
#' @family modeltools
#' @export
enw_get_cache <- function() {
  cache_location <- Sys.getenv("enw_cache_location")

  cli::cli_inform(cache_location_message())

  if (check_environment_unset(cache_location)) {
    cache_location <- tempdir()
  }

  create_cache_dir(cache_location)

  cache_location
}
