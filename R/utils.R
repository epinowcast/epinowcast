#' Expose stan functions
#'
#' @importFrom rstan expose_stan_functions
#' @importFrom purrr map_chr
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

inv_logit <- function(x) {
  il <- 1 / (1 + exp(-x))
  return(il)
}

logit <- function(p) {
  l <- log(p / (1 - p))
  return(l)
}
