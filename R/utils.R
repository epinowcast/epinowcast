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

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param x PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family utils
#' @examples
#' inv_logit(c(-10, 1, 0, 100))
#' @export
inv_logit <- function(x) {
  il <- 1 / (1 + exp(-x))
  return(il)
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param p PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family utils
#' @examples
#' logit(c(0.01, 0.1, 0.5, 0.9, 1))
#' @export
logit <- function(p) {
  l <- log(p / (1 - p))
  return(l)
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
