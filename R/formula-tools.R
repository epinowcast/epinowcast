parse_formula <- function(formula) {
  rw <- terms_rw(formula)
  formula <- norws(formula)
  fixed <- lme4::nobars(formula)
  random <- lme4::findbars(formula)

  model_terms <- list(
    fixed = split_formula_to_terms(fixed),
    random = random,
    rw = rw
  )
  return(model_terms)
}

as_string_formula <- function(x) {
  form <- paste(deparse(x), collapse = " ")
  form <- gsub("\\s+", " ", form, perl = FALSE)
  return(form)
}


split_formula_to_terms <- function(formula) {
  formula <- as_string_formula(formula)
  formula <- gsub("~", "", formula)
  formula <- strsplit(formula, " \\+ ")[[1]]
  return(formula)
}

# remove random walk terms
# adapted from code in epidemia written by J Scott
# https://github.com/ImperialCollegeLondon/epidemia/
norws <- function(x) {
  form <- as_string_formula(x)
  form <- gsub("rw\\(.*?\\) \\+ ", "", form)
  form <- gsub("\\+ rw\\(.*?\\)", "", form)
  form <- gsub("rw\\(.*?\\)", "", form)

  form <- tryCatch({
      as.formula(form)
    },
    error = function(cond) {
      as.formula(paste(form, 1))
    }
  )
  return(form)
}

#' Finds random walk terms in a formula object
#'
#' @description Adapted from code in `epidemia` written by J. Scott.
#' @param x An object of class "formula"
#' @return The value of attributes. See \code{\link[base]{attr}} for more
#' details.
terms_rw <- function(x) {
  if (!inherits(x, "formula")) {
    stop("'formula' must be a formula object.")
  }

  # use regex to find random walk terms in formula
  trms <- attr(terms(x), "term.labels")
  match <- grepl("(^(rw)\\([^:]*\\))$", trms)

  # ignore when included in a random effects term
  match <- match & !grepl("\\|", trms)
  return(trms[match])
}

#' Adds random walks with Gaussian steps to the model.
#'
#' A call to `rw()` can be used in the 'formula' argument of model
#' construction functions in the `epinowcast` package. Does not evaluate
#' arguments but instead simply passes information for use in model
#' construction.
#'
#' @param time Defines the random walk time period.
#' @param group Defines the grouping parameter used for the random walk.
#' If not specified no grouping is used.
#' @return A list to be parsed internally.
#' @export
rw <- function(time, group) {
  if (missing(time)) {
    stop("time must be present")
  } else {
    time <- deparse(substitute(time))
  }

  if (missing(group)) {
    group <- NULL
  } else {
    group <- deparse(substitute(group))
  }
  out <- list(time = time, group = group)
  class(out) <- c("rw_term")
  return(out)
}

construct_rw <- function(data, rw) {
  data <- enw_add_cumulative_membership(
    data,
    feature = rw$time

  terms <- grep(paste0("c", rw$time), colnames(data), value = TRUE)
  if (!is.null(rw$group)) {
    terms <- paste0(rw$group, ":", terms)
  }
  # filter data to just columns needed here
  # make a fixed effects design matrix
  # extract effects metadata
  # implement random walk structure effects
  # output updated data, fixed effects, and random effects meta data
  return(list(data = data, terms = terms))
}

construct_re <- function(data, re) {
  # filter data to just columns required here
  # get random effect fixed effects
  # make interactions with group effect
  # set the intercept to the the group effect (i.e 1:group -> group)
  # make a fixed effects design matrix
  # make metadata for this design matrix
  # assign random effect groups based on fixed affects interaction with group
  # output fixed effects and random effects metadata
}

construct_fixed_design(components) {
  # iterate over component design matrices and rbind
  # for each look up in the sparse design matrix inflate lookup based on number
  # of rows in current combined design matrix
  # output combined design matrix and lookup vector
}

construct_random_design(components) {
  # rbind all random effect design matrices
  # output combined design matrix
}