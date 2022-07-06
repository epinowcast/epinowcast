#' @rawNamespace import(data.table, except = transpose)
#' @import cmdstanr
#' @import ggplot2
#' @importFrom stats median rnorm
NULL

#' Read in a stan function file as a character string
#'
#' @inheritParams expose_stan_fns
#' @return A character string in the of stan functions.
#' @family utils
#' @importFrom purrr map_chr
stan_fns_as_string <- function(files, target_dir) {
  functions <- paste0(
    "\n functions{ \n",
      paste(purrr::map_chr(
        files,
        ~ paste(readLines(file.path(target_dir, .)), collapse = "\n")
      ),
      collapse = "\n"
      ),
    "\n }"
  )
  return(functions)
}

#' Convert Cmdstan to Rstan
#'
#' @param functions A character string of stan functions as produced using
#' [stan_fns_as_string()].
#'
#' @return A character string of stan functions converted for use in `rstan`.
#' @family utils
convert_cmdstan_to_rstan <- function(functions) {
  # replace bars in CDF with commas
  functions <- gsub("_cdf\\(([^ ]+) *\\|([^)]+)\\)", "_cdf(\\1,\\2)", functions)
  # replace lupmf with lpmf
  functions <- gsub("_lupmf", "_lpmf", functions)
  # replace array syntax
  #   case 1: array[] real x -> real[] x
  functions <- gsub(
    "array\\[(,?)\\] (.*) ([a-z_]+)", "\\2[\\1] \\3", functions
  )
  #   case 2: array[n] real x -> real x[n]
  functions <- gsub(
    "array\\[([^]]*)\\]\\s+([a-z_]+)\\s+([a-z_]+)", "\\2 \\3[\\1]", functions
  )
  #   case 3: array[nl, np] matrix[n, l] x -> matrix[n, l] x[nl, np]
  functions <- gsub(
    "array\\[([^]]*)\\]\\s+([a-z_]+)\\[([^]]*)\\]\\s+([a-z_]+)",
    "\\2[\\3] \\4[\\1]", functions
  )
  # remove profiling code
  functions <- remove_profiling(functions)
  return(functions)
}

#' Expose stan functions in R
#'
#' @description This function builds on top of
#' [rstan::expose_stan_functions()] in order to facilitate exposing package
#' functions in R for internal use, testing, and exploration. Crucially
#' it performs a conversion between the package `cmdstan` stan code
#' and `rstan` compatible stan code. It is not generally recommended that users
#' make use of this function apart from when exploring package functionality.
#'
#' @param files A character vector of file names
#'
#' @param target_dir A character string giving the directory in which
#' files can be found.
#'
#' @param ... Arguments to pass to [rstan::expose_stan_functions()]
#'
#' @return NULL (invisibly)
#' @family utils
#' @importFrom rstan expose_stan_functions stanc
expose_stan_fns <- function(files, target_dir, ...) {
  # Make functions into a string
  functions <- stan_fns_as_string(files, target_dir)
  # Convert from cmdstan -> rstan to allow for in R uses
  functions <- convert_cmdstan_to_rstan(functions)
  # expose stan codef
  rstan::expose_stan_functions(rstan::stanc(model_code = functions), ...)
  return(invisible(NULL))
}

#' Load a package example
#'
#' Loads examples of nowcasts produce using example scripts. Used to streamline
#' examples, in package tests and to enable users to explore package
#' functionality without needing to install `cmdstanr`.
#'
#' @param type A character string indicating the example to load.
#' Supported options are "nowcast, "preprocessed_observations", "observations",
#' and "script" which are the output of epinowcast()], [enw_preprocess_data()],
#' and [enw_latest_data()] applied to the [germany_covid19_hosp] package
#' dataset), and the script used to generate these examples respectively.
#'
#' @return A `data.table` of summarised output
#'
#' @family data
#' @export
#' @examples
#' # Load the nowcast
#' enw_example(type = "nowcast")
#'
#' # Load the preprocessed observations
#' enw_example(type = "preprocessed_observations")
#'
#' # Load the latest observations
#' enw_example(type = "observations")
#'
#' # Load the script used to generate these examples
#' # Optionally source this script to regenerate the example
#' readLines(enw_example(type = "script"))
enw_example <- function(type = "nowcast") {
  type <- match.arg(
    type,
    choices = c(
      "nowcast", "preprocessed_observations", "observations", "script"
    )
  )

  if (type %in% c("nowcast", "preprocessed_observations", "observations")) {
    file <- system.file("extdata", paste0(type, ".rds"), package = "epinowcast")
  } else if (type %in% "script") {
    file <- system.file("scripts", "germany_example.R", package = "epinowcast")
  }

  if (type %in% "script") {
    out <- file
  } else {
    out <- readRDS(file)
  }
  return(out)
}

utils::globalVariables(
  c(
    ".", ".draw", "max_treedepth", "no_at_max_treedepth",
    "per_at_max_treedepth", "q20", "q5", "q80", "q95", "quantile",
    "sd", "..by", "cmf", "day_of_week", "delay", "new_confirm",
    "observed", "old_group", "reference_date", "report_date",
    "reported_cases", "s", "time", "extend_date", "effects",
    "confirm", "effects", "fixed", "group", "logmean", "logsd",
    "new_group", "observed", "latest_confirm", "mad", "variable",
    "fit", "patterns", ".draws", "prop_reported", "max_confirm",
    "run_time", "cum_prop_reported"
  )
)
