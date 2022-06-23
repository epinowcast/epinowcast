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
#'
#' @param group Defines the grouping parameter used for the random walk.
#' If not specified no grouping is used.
#'
#' @param type Character string, defaults to "independent". How should the
#' standard deviation of grouped random walks be estimated. Currently this can
#' be set to be independent by group or dependent across groups.
#'
#' @return A list to be parsed internally.
rw <- function(time, group, type = "independent") {
  type <- match.arg(type, choices = c("independent", "dependent"))
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
  out <- list(time = time, group = group, type = type)
  class(out) <- c("enw_rw_term")
  return(out)
}

construct_rw <- function(rw, data) {
  if (!(class(rw) %in% "enw_rw_term")) {
    stop("rw must be a random walk term as constructed by rw")
  }
  data <- data.table::copy(data)
  # add new cumulative features to use for the random walk
  data <- enw_add_cumulative_membership(
    data,
    feature = rw$time
  )
  ctime  <- paste0("c", rw$time)
  terms <- grep(ctime, colnames(data), value = TRUE)
  fdata <- data.table::copy(data)
  fdata <- fdata[, c(terms, rw$group), with = FALSE]
  if (!is.null(rw$group)) {
    terms <- paste0(rw$group, ":", terms)
  }
  # make a fixed effects design matrix
  fixed <- enw_manual_formula(
    fdata, fixed = terms, no_contrasts = TRUE
  )$fixed$design
  # extract effects metadata
  effects <- enw_effects_metadata(fixed)
  # implement random walk structure effects
  if (is.null(rw$group) || rw$type %in% "dependent") {
    effects <- enw_add_pooling_effect(effects, ctime, rw$time)
  }else {
    for (i in  unique(fdata[[rw$group]])) {
    ngroup <- paste0(rw$group, i)
    effects <- enw_add_pooling_effect(
      effects, c(ctime, paste0(rw$group, i)), paste0(ngroup, ":", rw$time),
        finder_fn = function(effect, pattern) {
          grepl(pattern[1], effect) & startsWith(effect, pattern[2])
      })
    }
  }
  return(list(data = data, terms = terms, effects = effects))
}


#' Defines random effect terms using the lme4 syntax
#'
#' @param formula A formula in the format used by [lme4] to define random
#' effects
#'
#' @return A list to be parsed internally.
re <- function(formula) {
  terms <- strsplit(as_string_formula(formula), " \\| ")[[1]]
  fixed <- terms[1]
  random <- terms[2]
  out <- list(fixed = terms[1], random = terms[2])
  class(out) <- c("enw_re_term")
  return(out)
}

construct_re <- function(re, data) {
  if (!(class(re) %in% "enw_re_term")) {
    stop("re must be a random effect term as constructed by re")
  }
  data <- data.table::as.data.table(data)

  # extract random and fixed effects
  fixed <- strsplit(re$fixed, " \\+ ")[[1]]
  random <- strsplit(re$random, " \\+ ")[[1]]

  # combine into fixed effects terms
  terms <- c()
  for (i in random) {
    terms <- c(terms, paste0(fixed, ":", i))
  }
  terms <- gsub("1:", "", terms)

  # make a fixed effects design matrix
  fixed <- enw_manual_formula(
    data, fixed = terms, no_contrasts = TRUE
  )$fixed$design
  # extract effects metadata
  effects <- enw_effects_metadata(fixed)
  # implement random effects structure
  for (i in  terms) {
    loc_terms <- strsplit(i, ":")[[1]]
      if (length(loc_terms) == 1) {
        effects <- enw_add_pooling_effect(effects, i, i)
      }else {
        effects <- enw_add_pooling_effect(
          effects, rev(loc_terms), i,
            finder_fn = function(effect, pattern) {
              grepl(pattern[1], effect) & startsWith(effect, pattern[2])
          })
      }
   }
  return(list(terms = terms, effects = effects))
}

enw_formula <- function(formula, data) {
  # Parse formula
  parsed_formula <- parse_formula(formula)

  # Get random effects for all specified random effects
  random_effects <- purrr::map(parsed_formula$random, re)
  random_effects <- purrr::map(random_effects, construct_re, data = data)
  random_effects <- purrr::transpose(random_effects)

  random_effect_terms <- unlist(random_effects$terms)
  random_effect_metadata <- data.table::rbindlist(
    random_effects$effects, use.names = TRUE, fill = TRUE
  )

  # Get random walk effects by iteratively looping through (as variables are
  # created)
  if (length(parsed_formula$rw) > 0) {
    rw_effects <- purrr::map(parsed_formula$rw, rw)
    for (i in seq_along(rw_effects)) {
      rw_effects[i] <- contruct_rw(rw_effects[i], data)
      data <- rw_effects[i]$data
    }
  }

  # Make fixed design matrix using all fixed effects from all components 
  # this should include new variables added by the random effects
  # Make the random effects design matrix
  # Output: formula, fixed effects formula, fixed effects design,
  # random effects formul, random effects dataframe, random effects design
}
