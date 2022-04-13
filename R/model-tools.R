#' Format formula data for use with stan
#'
#' @param data A list of stan observation data as produced by
#' [enw_obs_as_data_list()].
#'
#' @param reference_effects A list of fixed and random design matrices
#' defining the date of reference model. Defaults to [enw_formula()]
#' which is an intercept only model.
#'
#' @param report_effects A list of fixed and random design matrices
#' defining the date of reports model. Defaults to [enw_formula()]
#' which is an intercept only model.
#'
#' @return A list as required by stan.
#' @family modeltools
#' @export
enw_formula_as_data_list <- function(data, reference_effects, report_effects) {
  fdata <- list(
    npmfs = nrow(reference_effects$fixed$design),
    dpmfs = reference_effects$fixed$index,
    neffs = ncol(reference_effects$fixed$design) - 1,
    d_fixed = reference_effects$fixed$design,
    neff_sds = ncol(reference_effects$random$design) - 1,
    d_random = reference_effects$random$design
  )

  # map report date effects to groups and days
  report_date_eff_ind <- matrix(
    report_effects$fixed$index,
    ncol = data$g, nrow = data$t + data$dmax - 1
  )

  # Add report date data
  fdata <- c(fdata, list(
    rd = data$t + data$dmax - 1,
    urds = nrow(report_effects$fixed$design),
    rdlurd = report_date_eff_ind,
    nrd_effs = ncol(report_effects$fixed$design) - 1,
    rd_fixed = report_effects$fixed$design,
    nrd_eff_sds = ncol(report_effects$random$design) - 1,
    rd_random = report_effects$random$design
  ))
  return(fdata)
}

#' Format model options for use with stan
#'
#' @param dist Character string indicating the type of distribution to use for
#' reference date effects. The default is to use a lognormal but other options
#' available include: gamma distributed ("gamma").
#'
#' @param nowcast Logical, defaults to `TRUE`. Should a nowcast be made using
#' posterior predictions of the unobserved future reported notifications.
#'
#' @param pp Logical, defaults to `FALSE`. Should posterior predictions be made
#' for observed data. Useful for evaluating the performance of the model.
#'
#' @param likelihood Logical, defaults to `TRUE`. Should the likelihood be
#' included in the model
#'
#' @param output_loglik Logical, defaults to `FALSE`. Should the
#' log-likelihood be output. Disabling this will speed up fitting
#' if evaluating the model fit is not required.
#'
#' @param debug Logical, defaults to `FALSE`. Should within model debug
#' information be returned.
#'
#' @return A list as required by stan.
#' @importFrom data.table fcase
#' @family modeltools
#' @export
enw_opts_as_data_list <- function(dist = "lognormal", nowcast = TRUE,
                                  pp = FALSE, likelihood = TRUE, debug = FALSE,
                                  output_loglik = FALSE) {
  if (pp) {
    nowcast <- TRUE
  }
  # check dist type is supported and change to numeric
  dist <- match.arg(dist, c("lognormal", "gamma"))
  dist <- data.table::fcase(
    dist %in% "lognormal", 0,
    dist %in% "gamma", 1
  )

  data <- list(
    dist = dist,
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast),
    ologlik = as.numeric(output_loglik)
  )
  return(data)
}

#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param priors DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @family modeltools
#' @importFrom data.table copy
#' @importFrom purrr map
#' @export
#' @examples
#' priors <- enw_priors()
#' enw_priors_as_data_list(priors)
enw_priors_as_data_list <- function(priors) {
  priors <- data.table::copy(priors)
  priors[, variable := paste0(variable, "_p")]
  priors <- priors[, .(variable, mean, sd)]
  priors <- split(priors, by = "variable", keep.by = FALSE)
  priors <- purrr::map(priors, ~ as.vector(t(.)))
  return(priors)
}

#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param nowcast DESCRIPTION
#'
#' @param priors DESCRIPTION.
#'
#' @param variables A character vector of variables both in the
#' posterior and in the default priors.
#'
#' @param scale DESCRIPTION
#'
#' @return RETURN_DESCRIPTION
#' @family modeltools
#' @importFrom data.table setDT
#' @export
enw_posterior_as_prior <- function(nowcast, priors = epinowcast::enw_priors(),
                                   variables = c(), scale = 5) {
  posteriors <- nowcast$fit[[1]]$summary(variables)
  posteriors <- setDT(posteriors)[, sd := sd * scale]
  posteriors <- posteriors[, .(variable, mean, sd)]
  priors <- priors[!(variable %in% variables)]
  priors <- rbind(priors, posteriors, fill = TRUE)
  return(priors[])
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
      "profile\\(.+\\)\\s*\\{((?:[^{}]++|\\{(?1)\\})++)\\}", "\\1", s, perl = TRUE
    )
  }
  return(s)
}