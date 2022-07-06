#' Format formula data for use with stan
#'
#' @param data A list of stan observation data as produced by
#' [enw_obs_as_data_list()].
#'
#' @param reference_effects A list of fixed and random design matrices
#' defining the date of reference model. Defaults to [enw_manual_formula()]
#' which is an intercept only model.
#'
#' @param report_effects A list of fixed and random design matrices
#' defining the date of reports model. Defaults to [enw_manual_formula()]
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
#' @param distribution Character string indicating the type of distribution to
#' use for reference date effects. The default is to use a lognormal but other
#' options available include the exponential and gamma distributions. If "none"
#' is specfied then no parametric delay distribution is used.
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
enw_opts_as_data_list <- function(distribution = "lognormal", nowcast = TRUE,
                                  pp = FALSE, likelihood = TRUE, debug = FALSE,
                                  output_loglik = FALSE) {
  if (pp) {
    nowcast <- TRUE
  }
  # check distribution type is supported and change to numeric
  distribution <- match.arg(
    distribution, c("none", "exponential", "lognormal", "gamma")
  )
  if (distribution %in% "none") {
    warning(
      "As non-parametric hazards have yet to be implemented a parametric hazard
       is likely required for all real-world use cases"
    )
  }
  distribution <- data.table::fcase(
    distribution %in% "none", 0,
    distribution %in% "exponential", 1,
    distribution %in% "lognormal", 2,
    distribution %in% "gamma", 3
  )

  data <- list(
    dist = distribution,
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
      "profile\\(.+\\)\\s*\\{((?:[^{}]++|\\{(?1)\\})++)\\}", "\\1", s,
      perl = TRUE
    )
  }
  return(s)
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
                                        target_dir = tempdir()) {
  # remove profiling from main .stan file
  code_main_model <- paste(readLines(stan_file, warn = FALSE), collapse = "\n")
  code_main_model_no_profile <- remove_profiling(code_main_model)
  if (!dir.exists(target_dir)) {
    dir.create(target_dir, recursive = TRUE)
  }
  main_model <- cmdstanr::write_stan_file(
    code_main_model_no_profile,
    dir = target_dir,
    basename = basename(stan_file)
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
        dir.create(include_paths_no_profile_fdir, recursive = TRUE)
      }
      cmdstanr::write_stan_file(
        code_include_paths_no_profile,
        dir = include_paths_no_profile_fdir,
        basename = basename(f)
      )
    }
  }
  return(list(model = main_model, include_paths = include_paths_no_profile))
}
