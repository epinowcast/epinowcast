#' Format formula data for use with stan
#'
#' @param formula The output of [enw_formula()].
#'
#' @param prefix A character string indicating variable
#' label to use as a prefix.
#'
#' @return A list defining the model formula. This includes:
#'  - `prefix_fdesign`: The fixed effects design matrix
#'  - `prefix_frows`: The number of rows of the fixed design matrix
#'  - `prefix_findex`: The index linking design matrix rows to  observations
#'  - `prefix_fnindex`: The length of the index
#'  - `prefix_fncol`: The number of columns (i.e effects) in the fixed effect
#'  design matrix (minus 1 if `drop_intercept = TRUE`).
#'  - `prefix_rdesign`: The random effects design matrix
#'  - `prefix_rncol`: The number of columns (i.e random effects) in the random
#'  effect design matrix (minus 1 as the intercept is dropped).
#' @family modeltools
#' @export
#' @examples
#' f <- enw_formula(~ 1 + (1 | cyl), mtcars)
#' enw_formula_as_data_list(f, "mtcars")
enw_formula_as_data_list <- function(formula, prefix,
                                     drop_intercept = FALSE) {
  if (!("enw_formula" %in% class(formula))) {
    stop(
      "formula must be an object of class enw_formula as produced using
       enw_formula"
        )
  }
  paste_lab <- function(string, lab = prefix) {
    paste0(lab, "_", string)
  }
  data <- list()
  data[[paste_lab("fdesign")]] <- formula$fixed$design
  data[[paste_lab("frows")]] <- nrow(formula$fixed$design)
  data[[paste_lab("findex")]] <- formula$fixed$index
  data[[paste_lab("fnindex")]] <- length(formula$fixed$index)
  data[[paste_lab("fncol")]] <-
      ncol(formula$random$design) - as.numeric(drop_intercept)
  data[[paste_lab("rdesign")]] <- formula$random$design
  data[[paste_lab("rncol")]] <- ncol(formula$random$design) - 1
  return(data)
}

#' Format model fitting options for use with stan
#'
#' @param sampler A function that creates an object that be used to extract
#' posterior samples from the specfied model. By default this is [enw_sample()]
#' which makes use of [cmdstanr::sample()].
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
#' @param ... Additional arguments to pass to the fitting function being used
#' by [epinowcast()]. By default this will be [enw_sample()] and so `cmdstanr`
#' options should be used.
#'
#' @return A list as required by stan.
#' @importFrom data.table fcase
#' @family modeltools
#' @export
#' @examples
#' # Default options along with settings to pass to enw_sample
#' enw_fit_opts(iter_sampling = 1000, iter_warmup = 1000)
enw_fit_opts <- function(sampler = epinowcast::enw_sample,
                         nowcast = TRUE, pp = FALSE, likelihood = TRUE,
                         debug = FALSE, output_loglik = FALSE, ...) {
  if (pp) {
    nowcast <- TRUE
  }
  out <- list(sampler = sampler)

  out$data_as_list <- list(
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast),
    ologlik = as.numeric(output_loglik)
  )
  out$args <- list(...)
  return(out)
}

#' Convert prior data.frame to list
#'
#' Converts priors defined in a `data.frame` into a list
#' format for use by stan. In addition it adds "_p" to all
#' variable names in order too allow them to be distinguished from
#' their standard usage within modelling code.
#'
#' @return A named list with each entry specifying a prior as a length
#' two vector (specifying the mean and standard deviation of the prior).
#' @family modeltools
#' @inheritParams enw_replace_priors
#' @importFrom data.table copy
#' @importFrom purrr map
#' @export
#' @examples
#' priors <- data.frame(variable = "x", mean = 1, sd = 2)
#' enw_priors_as_data_list(priors)
enw_priors_as_data_list <- function(priors) {
  priors <- data.table::copy(priors)
  priors[, variable := paste0(variable, "_p")]
  priors <- priors[, .(variable, mean, sd)]
  priors <- split(priors, by = "variable", keep.by = FALSE)
  priors <- purrr::map(priors, ~ as.vector(t(.)))
  return(priors)
}

#' Replace default priors with user specfied priors
#'
#' This function is used internally by [epinowcast]() to replace
#' default model priors with users specified ones (restricted to
#' normal priors with specified mean and standard deviations). A common
#' use would be extracting the posterior from a previous [epinowcast()]
#' run (using `summary(nowcast, type = fit)`) and using this a prior.
#'
#' @param priors A data.frame with the following variables:
#'  `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions.
#'
#' @param custom_priors A data.frame with the following variables:
#'  `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions. Priors in this data.frame
#' replace the default priors.
#'
#' @return A data.table of prior definitions (variable, mean and sd).
#' @family modeltools
#' @export
#' @importFrom data.table as.data.table
#' @examples
#' priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
#' custom_priors <- data.frame(variable = "x", mean = 10, sd = 2)
#' enw_replace_priors(priors, custom_priors)
enw_replace_priors <- function(priors, custom_priors) {
  variables <- custom_priors$variable
  priors <- data.table::as.data.table(priors)[!(variable %in% variables)]
  custom_priors <- data.table::as.data.table(custom_priors)[,
   .(variable, mean, sd)
  ]
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
