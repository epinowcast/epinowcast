#' @rawNamespace import(data.table, except = transpose)
#' @import cmdstanr
#' @import ggplot2
#' @importFrom stats median rnorm
NULL

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param files PARAM_DESCRIPTION
#' @param target_dir PARAM_DESCRIPTION
#' @param ... PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family utils
#' @export
#' @importFrom purrr map_chr
#' @importFrom rstan expose_stan_functions stanc
expose_stan_fns <- function(files, target_dir, ...) {
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
    "obseverd", "old_group", "reference_date", "report_date",
    "reported_cases", "s", "time", "extend_date", "effects",
    "confirm", "effects", "fixed", "group", "logmean", "logsd",
    "new_group", "observed", "latest_confirm", "mad", "variable",
    "fit", "patterns", ".draws"
  )
)
