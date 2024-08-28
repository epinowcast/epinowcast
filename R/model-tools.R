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
#'  design matrix (minus 1 if `drop_intercept = TRUE`).
#'  - `prefix_rdesign`: The random effects design matrix
#'  - `prefix_rncol`: The number of columns (i.e random effects) in the random
#'  effect design matrix (minus 1 as the intercept is dropped).
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
    fdesign = numeric(0),
    fintercept = 0,
    fnrow = 0,
    findex = numeric(0),
    fnindex = 0,
    fncol = 0,
    rdesign = numeric(0),
    rncol = 0
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
    fintercept <-  as.numeric(any(grepl(
      "(Intercept)", colnames(formula$fixed$design), fixed = TRUE
    )))
    data$fdesign <- formula$fixed$design
    data$fintercept <- fintercept
    data$fnrow <- nrow(formula$fixed$design)
    data$findex <- formula$fixed$index
    data$fnindex <- length(formula$fixed$index)
    data$fncol <- ncol(formula$fixed$design) -
      min(as.numeric(drop_intercept), fintercept)
    data$rdesign <- formula$random$design
    data$rncol <- ncol(formula$random$design) - 1
  }
  names(data) <- sprintf("%s_%s", prefix, names(data))
  return(data)
}

#' Convert prior `data.frame` to list
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
#' @importFrom purrr map
#' @export
#' @examples
#' priors <- data.frame(variable = "x", mean = 1, sd = 2)
#' enw_priors_as_data_list(priors)
enw_priors_as_data_list <- function(priors) {
  priors <- coerce_dt(priors, select = c("variable", "mean", "sd"))
  priors[, variable := paste0(variable, "_p")]
  priors <- split(priors, by = "variable", keep.by = FALSE)
  priors <- purrr::map(priors, ~ as.array(t(.)))
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
#' @param priors A `data.frame` with the following variables:
#'  `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions.
#'
#' @param custom_priors A `data.frame` with the following variables:
#'  `variable`, `mean`, `sd` describing normal priors. Priors in the
#' appropriate format are returned by [enw_reference()] as well as by
#' other similar model specification functions. Priors in this data.frame
#' replace the default priors. Note that currently vectorised prior names
#' (i.e those of the form `variable[n]` will be treated as `variable`).
#'
#' @return A data.table of prior definitions (variable, mean and sd).
#' @family modeltools
#' @export
#' @examples
#' # Update priors from a data.frame
#' priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
#' custom_priors <- data.frame(variable = "x[1]", mean = 10, sd = 2)
#' enw_replace_priors(priors, custom_priors)
#'
#' # Update priors from a previous model fit
#' default_priors <- enw_reference(
#'  distribution = "lognormal",
#'  data = enw_example("preprocessed"),
#' )$priors
#' print(default_priors)
#'
#' fit_priors <- summary(
#'  enw_example("nowcast"), type = "fit",
#'  variables = c("refp_mean_int", "refp_sd_int", "sqrt_phi")
#' )
#' fit_priors
#'
#' enw_replace_priors(default_priors, fit_priors)
enw_replace_priors <- function(priors, custom_priors) {
  custom_priors <- coerce_dt(
    custom_priors, select = c("variable", "mean", "sd")
  )[
    ,
    .(variable = gsub("\\[([^]]*)\\]", "", variable),
      mean = as.numeric(mean), sd = as.numeric(sd))
  ]
  variables <- custom_priors$variable
  priors <- coerce_dt(
    priors, required_cols = "variable"
  )[!(variable %in% variables)]
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
                                        target_dir = epinowcast::enw_get_cache()
                                        ) {
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
#' @param init A list of initial values or a function to generate initial
#' values. If not provided, the model will attempt to generate initial values
#'
#' @param init_method The method to use for initializing the model. Defaults to
#' "prior" which samples initial values from the prior. "pathfinder", which uses the
#' pathfinder algorithm ([enw_pathfinder()]) to initialize the model.
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
#' @importFrom cmdstanr cmdstan_model
#' @importFrom posterior rhat
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#'
#' nowcast <- epinowcast(pobs,
#'  expectation = enw_expectation(~1, data = pobs),
#'  fit = enw_fit_opts(enw_sample, pp = TRUE),
#'  obs = enw_obs(family = "poisson", data = pobs),
#' )
#'
#' summary(nowcast)
#'
#' # Use pathfinder initialization
#' nowcast_pathfinder <- epinowcast(pobs,
#'  expectation = enw_expectation(~1, data = pobs),
#'  fit = enw_fit_opts(enw_sample, pp = TRUE, init_method = "pathfinder"),
#'  obs = enw_obs(family = "poisson", data = pobs),
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
  return(out[])
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

  return(list(init = updated_init, method_output = method_output))
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
#' @importFrom cmdstanr cmdstan_model
#' @importFrom cli cli_abort
#' @examplesIf interactive()
#' pobs <- enw_example("preprocessed")
#'
#' nowcast <- epinowcast(pobs,
#'  expectation = enw_expectation(~1, data = pobs),
#'  fit = enw_fit_opts(enw_pathfinder, pp = TRUE),
#'  obs = enw_obs(family = "poisson", data = pobs),
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
#' @importFrom cmdstanr cmdstan_model
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
        return(x)
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
  return(model)
}

#' Expose `epinowcast` stan functions in R
#'
#' @description This function facilitates the exposure of Stan functions from
#' the [epinowcast]() package in R. It utilizes the [expose_functions()] method
#' of [cmdstanr::CmdStanModel] or this purpose. This function is useful for
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
#' globally. Defaults to `TRUE`. Passed to the [expose_functions()] method of
#' [cmdstanr::CmdStanModel].
#'
#' @param ... Additional arguments passed to [enw_model]().
#'
#' @inheritParams enw_model
#' @return An object of class `CmdStanModel` with functions from the model
#' exposed for use in R.
#'
#' @family modeltools
#' @importFrom cmdstanr write_stan_file
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
  files = list.files(include),
  include = system.file("stan", "functions", package = "epinowcast"),
  global = TRUE,
  verbose = TRUE,
  ...
) {
  overloaded_fns <- c(
    "delay_lpmf.stan", "allocate_observed_obs.stan", "obs_lpmf.stan",
    "effects_priors_lp.stan"
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
  return(mod)
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
#'  enw_set_cache(
#'    tools::R_user_dir(package = "epinowcast", "cache"), type = "all"
#'  )
#'}
#'
#'}
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

  return(invisible(candidate_path))
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

  return(invisible(prior_location))
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

  return(cache_location)
}
