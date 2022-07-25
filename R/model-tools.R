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
#'  - `prefix_fdesign`: The fixed effects design matrix
#'  - `prefix_fnrow`: The number of rows of the fixed design matrix
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
#'
#' # A missing formula produces the default list
#' enw_formula_as_data_list(prefix = "missing")
enw_formula_as_data_list <- function(formula, prefix,
                                     drop_intercept = FALSE) {
  paste_lab <- function(string, lab = prefix) {
    paste0(lab, "_", string)
  }
  if (!missing(formula)) {
    if (!("enw_formula" %in% class(formula))) {
      stop(
        "formula must be an object of class enw_formula as produced using
        enw_formula"
      )
    }
    data <- list()
    data[[paste_lab("fdesign")]] <- formula$fixed$design
    data[[paste_lab("fnrow")]] <- nrow(formula$fixed$design)
    data[[paste_lab("findex")]] <- formula$fixed$index
    data[[paste_lab("fnindex")]] <- length(formula$fixed$index)
    data[[paste_lab("fncol")]] <-
      ncol(formula$fixed$design) - as.numeric(drop_intercept)
    data[[paste_lab("rdesign")]] <- formula$random$design
    data[[paste_lab("rncol")]] <- ncol(formula$random$design) - 1
  } else {
    data <- list()
    data[[paste_lab("fdesign")]] <- numeric(0)
    data[[paste_lab("fnrow")]] <- 0
    data[[paste_lab("findex")]] <- numeric(0)
    data[[paste_lab("fnindex")]] <- 0
    data[[paste_lab("fncol")]] <- 0
    data[[paste_lab("rdesign")]] <- numeric(0)
    data[[paste_lab("rncol")]] <- 0
  }
  return(data)
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
  priors <- data.table::as.data.table(priors)
  priors[, variable := paste0(variable, "_p")]
  priors <- priors[, .(variable, mean, sd)]
  priors <- split(priors, by = "variable", keep.by = FALSE)
  priors <- purrr::map(priors, ~ as.vector(t(.)))
  return(priors)
}

#' Replace default priors with user specified priors
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
#' replace the default priors. Note that currently vectorised prior names
#' (i.e those of the form `variable[n]` will be treated as `variable`).
#'
#' @return A data.table of prior definitions (variable, mean and sd).
#' @family modeltools
#' @export
#' @importFrom data.table as.data.table
#' @examples
#' priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
#' custom_priors <- data.frame(variable = "x[1]", mean = 10, sd = 2)
#' enw_replace_priors(priors, custom_priors)
enw_replace_priors <- function(priors, custom_priors) {
  custom_priors <- data.table::as.data.table(custom_priors)[
    ,
    .(variable, mean, sd)
  ]
  custom_priors <- custom_priors[
    ,
    variable := gsub("\\[([^]]*)\\]", "", variable)
  ]
  variables <- custom_priors$variable
  priors <- data.table::as.data.table(priors)[!(variable %in% variables)]
  priors <- rbind(priors, custom_priors, fill = TRUE)
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

#' Fit a CmdStan model using NUTS
#'
#' @param data A list of data as produced by model modules (for example
#' [enw_expectation()], [enw_obs()], etc.) and as required for use the
#' `model` being used.
#'
#' @param model A `cmdstanr` model object as loaded by [enw_model()] or as
#' supplied by the user.
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
#' @importFrom cmdstanr cmdstan_model
#' @importFrom posterior rhat
enw_sample <- function(data, model = epinowcast::enw_model(),
                       diagnostics = TRUE, ...) {
  fit <- model$sample(data = data, ...)

  out <- data.table(
    fit = list(fit),
    data = list(data),
    fit_args = list(list(...))
  )

  if (diagnostics) {
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
  return(out[])
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
#' @param threads Logical, defaults to `FALSE`. Should the model compile with
#' support for multi-thread support in chain. Note that this requires the use of
#' the `threads_per_chain` argument when model fitting using [enw_sample()],
#' and [epinowcast()].
#'
#' @param verbose Logical, defaults to `TRUE`. Should verbose
#' messages be shown.
#'
#' @param profile Logical, defaults to `FALSE`. Should the model be profiled?
#' For more on profiling see the [`cmdstanr` documentation](https://mc-stan.org/cmdstanr/articles/profiling.html). # nolint
#'
#' @param stanc_options A list of options to pass to the `stanc_options` of
#' [cmdstanr::cmdstan_model()]. By default nothing is passed but potentially
#' users may wish to pass optimisation flags for example.See the documentation
#' for [cmdstanr::cmdstan_model()] for further details.
#'
#' @param ... Additional arguments passed to [cmdstanr::cmdstan_model()].
#'
#' @return A `cmdstanr` model.
#'
#' @family modeltools
#' @export
#' @importFrom cmdstanr cmdstan_model
#' @examplesIf interactive()
#' mod <- enw_model()
enw_model <- function(model, include, compile = TRUE,
                      threads = FALSE, profile = FALSE,
                      stanc_options = list(), verbose = TRUE, ...) {
  if (missing(model)) {
    model <- "stan/epinowcast.stan"
    model <- system.file(model, package = "epinowcast")
  }
  if (missing(include)) {
    include <- system.file("stan", package = "epinowcast")
  }

  if (!profile) {
    stan_no_profile <- write_stan_files_no_profile(model, include)
    model <- stan_no_profile$model
    include <- stan_no_profile$include_paths
  }

  if (compile) {
    if (verbose) {
      model <- cmdstanr::cmdstan_model(model,
        include_paths = include,
        stanc_options = stanc_options,
        cpp_options = list(
          stan_threads = threads
        ),
        ...
      )
    } else {
      suppressMessages(
        model <- cmdstanr::cmdstan_model(model,
          include_paths = include,
          stanc_options = stanc_options,
          cpp_options = list(
            stan_threads = threads
          ), ...
        )
      )
    }
  }
  return(model)
}
