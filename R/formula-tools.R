#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param x DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @family formulatools
as_string_formula <- function(x) {
  form <- paste(deparse(x), collapse = " ")
  form <- gsub("\\s+", " ", form, perl = FALSE)
  return(form)
}

#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param formula DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @family formulatools
split_formula_to_terms <- function(formula) {
  formula <- as_string_formula(formula)
  formula <- gsub("~", "", formula)
  formula <- strsplit(formula, " \\+ ")[[1]]
  return(formula)
}

#' Remove random walk terms
#'
#' This function was adapted from code written
#' by J Scott (under an MIT license) as part of
#' the `epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).
#'
#' @param x DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @family formulatools
remove_rw_terms <- function(x) {
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

#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param formula DESCRIPTION.
#'
#' @return RETURN_DESCRIPTION
#' @importFrom lme4 nobars findbars
#' @family formulatools
parse_formula <- function(formula) {
  rw <- terms_rw(formula)
  formula <- remove_rw_terms(formula)
  fixed <- lme4::nobars(formula)
  random <- lme4::findbars(formula)

  model_terms <- list(
    fixed = split_formula_to_terms(fixed),
    random = random,
    rw = rw
  )
  return(model_terms)
}

#' Finds random walk terms in a formula object
#'
#' This function was adapted from code written
#' by J Scott (under an MIT license) as part of
#' the `epidemia` package (https://github.com/ImperialCollegeLondon/epidemia/).
#'
#' @param x An object of class "formula"
#'
#' @return The value of attributes. See \code{\link[base]{attr}} for more
#' details.
#' @family formulatools
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
#' @param by Defines the bying parameter used for the random walk.
#' If not specified no bying is used.
#'
#' @param type Character string, defaults to "independent". How should the
#' standard deviation of byed random walks be estimated. Currently this can
#' be set to be independent by by or dependent across bys.
#'
#' @return A list to be parsed internally.
#' @export
#' @family formulatools
rw <- function(time, by, type = "independent") {
  type <- match.arg(type, choices = c("independent", "dependent"))
  if (missing(time)) {
    stop("time must be present")
  } else {
    time <- deparse(substitute(time))
  }

  if (missing(by)) {
    by <- NULL
  } else {
    by <- deparse(substitute(by))
  }
  out <- list(time = time, by = by, type = type)
  class(out) <- c("enw_rw_term")
  return(out)
}

#' Constructs random walk terms
#'
#' @param rw
#'
#' @param data
#'
#' @return RETURN
#' @importFrom data.table copy
#' @family formulatools
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
  fdata <- fdata[, c(terms, rw$by), with = FALSE]
  if (!is.null(rw$by)) {
    terms <- paste0(rw$by, ":", terms)
  }

  # make a fixed effects design matrix
  fixed <- enw_manual_formula(
    fdata, fixed = terms, no_contrasts = TRUE
  )$fixed$design

  # extract effects metadata
  effects <- enw_effects_metadata(fixed)

  # implement random walk structure effects
  if (is.null(rw$by) || rw$type %in% "dependent") {
    effects <- enw_add_pooling_effect(effects, ctime, rw$time)
  }else {
    for (i in  unique(fdata[[rw$by]])) {
    nby <- paste0(rw$by, i)
    effects <- enw_add_pooling_effect(
      effects, c(ctime, paste0(rw$by, i)), paste0(nby, "__", rw$time),
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
#' @export
#' @return A list to be parsed internally.
#' @family formulatools
re <- function(formula) {
  terms <- strsplit(as_string_formula(formula), " \\| ")[[1]]
  fixed <- terms[1]
  random <- terms[2]
  out <- list(fixed = terms[1], random = terms[2])
  class(out) <- c("enw_re_term")
  return(out)
}

#' Constructs random effect terms
#'
#' @param re
#'
#' @param data
#'
#' @return RETURN
#' @family formulatools
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
          effects, rev(loc_terms), paste(loc_terms, collapse = "__"),
            finder_fn = function(effect, pattern) {
              grepl(pattern[1], effect) & startsWith(effect, pattern[2])
          })
      }
   }
  return(list(terms = terms, effects = effects))
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#'
#' @param formula DESCRIPTION
#'
#' @param data DESCRIPTION
#
#' @return A design matrix and metadata
#' @family modeldesign
#' @export
#' @importFrom purrr map transpose
#' @importFrom data.table rbindlist setnafill
enw_formula <- function(formula, data) {
  # Parse formula
  parsed_formula <- parse_formula(formula)

  # Get random effects for all specified random effects
  if (length(parsed_formula$random) > 0) {
    random <- purrr::map(parsed_formula$random, re)
    random <- purrr::map(random, construct_re, data = data)
    random <- purrr::transpose(random)

    random_terms <- unlist(random$terms)
    random_metadata <- data.table::rbindlist(
      random$effects, use.names = TRUE, fill = TRUE
    )
    no_contrasts <- random_terms
  }else {
    no_contrasts <- FALSE
    random_terms <- c()
    random_metadata <- NULL
  }

  # Get random walk effects by iteratively looping through (as variables are
  # created in input data so need to use iteratively)
  if (length(parsed_formula$rw) > 0) {
    rw <- purrr::map(
      parsed_formula$rw,
      ~ eval(parse(text = paste0("epinowcast::", .)))
    )
    for (i in seq_along(rw)) {
      rw[[i]] <- construct_rw(rw[[i]], data)
      data <- rw[[i]]$data
      rw[[i]]$data <- NULL
    }
    rw <- purrr::transpose(rw)
    rw_terms <- unlist(rw$terms)
    rw_metadata <- data.table::rbindlist(
      rw$effects, use.names = TRUE, fill = TRUE
    )
  }else {
    rw_terms <- c()
    rw_metadata <- NULL
  }

  # Make fixed design matrix using all fixed effects from all components
  # this should include new variables added by the random effects
  # need to make sure all random effects don't have contrasts
  terms <- c(parsed_formula$fixed, rw_terms, random_terms)
  expanded_formula <- as.formula(paste0("~ ", paste(terms, collapse = " + ")))
  fixed <- enw_design(
    formula = expanded_formula,
    no_contrasts = random_terms,
    data = data,
    sparse = TRUE
  )
  # Extract fixed effects metadata
  metadata <- enw_effects_metadata(fixed$design)

  # Combine with random effects and random walk effects
  if (!is.null(random_metadata)) {
    metadata <- metadata[!random_metadata, on = "effects"]
    metadata <- rbind(metadata, random_metadata, use.names = TRUE, fill = TRUE)
  }

  if (!is.null(rw_metadata)) {
    metadata <- metadata[!rw_metadata, on = "effects"]
    metadata <- rbind(metadata, rw_metadata, use.names = TRUE, fill = TRUE)
  }

  metadata <- cbind(
    metadata[, "effects"],
    data.table::setnafill(metadata[, -"effects"], fill = 0)
  )

  # Make the random effects design matrix
  if (ncol(metadata) == 2) {
    random <- enw_design(~1, metadata, sparse = FALSE)
  }else {
    random_formula <- as.formula(
      paste0("~ 0  +", paste(colnames(metadata)[-1], collapse = " + "))
    )
    random <- enw_design(random_formula, metadata, sparse = FALSE)
  }

  out <- list(
    formula = formula,
    parsed_formula = parsed_formula,
    expanded_formula = expanded_formula,
    fixed = fixed,
    random = random
  )
  class(out) <- c("enw_formula", class(out))
  return(out)
}
