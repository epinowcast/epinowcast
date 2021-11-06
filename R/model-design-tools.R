#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param x PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family utils
is.Date <- function(x) { # nolint
  inherits(x, "Date")
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param data PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family modeldesign
#' @export
#' @importFrom data.table as.data.table
enw_dates_to_factors <- function(data) {
  data <- data.table::as.data.table(data)
  cols <- colnames(data)[sapply(data, is.Date)]
  data <- data[, lapply(.SD, factor), .SDcols = cols]
  return(data[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param formula PARAM_DESCRIPTION
#'
#' @param data PARAM_DESCRIPTION
#'
#' @param no_contrasts PARAM_DESCRIPTION, Default: FALSE
#'
#' @param sparse PARAM_DESCRIPTION, Default: TRUE
#'
#' @param ... PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#' @family modeldesign
#' @export
#' @importFrom data.table as.data.table
#' @importFrom stats terms contrasts model.matrix
#' @importFrom purrr map
enw_design <- function(formula, data, no_contrasts = FALSE, sparse = TRUE,
                       ...) {
  # make data.table and copy
  data <- data.table::as.data.table(data)

  # make all character variables factors
  chars <- colnames(data)[sapply(data, function(x) is.character(x))]
  data <- suppressWarnings(
    data[, (chars) := lapply(.SD, as.factor), .SDcols = chars]
  )

  # make model.matrix helper
  mod_matrix <- function(formula, data, ...) {
    design <- model.matrix(formula, data, ...)
    if (sparse) {
      sparse_design <- unique(design)
      index <- match(data.frame(t(design)), data.frame(t(sparse_design)))
    } else {
      sparse_design <- design
      index <- seq_len(nrow(design))
    }
    return(list(formula = formula, design = sparse_design, index = index))
  }

  if (length(no_contrasts) == 1 && is.logical(no_contrasts)) {
    if (!no_contrasts) {
      design <- mod_matrix(formula, data, ...)
      return(design)
    } else {
      no_contrasts <- colnames(data)[
        sapply(data, function(x) is.factor(x) | is.character(x))
      ]
    }
  }

  # what is in the formula
  in_form <- rownames(attr(stats::terms(formula, data = data), "factors"))

  # drop contrasts not in the formula
  no_contrasts <- no_contrasts[no_contrasts %in% in_form]

  if (length(no_contrasts) == 0) {
    design <- mod_matrix(formula, data, ...)
    return(design)
  } else {
    # make list of contrast args
    contrast_args <- purrr::map(
      no_contrasts, ~ stats::contrasts(data[[.]], contrast = FALSE)
    )
    names(contrast_args) <- no_contrasts

    # model matrix with contrast options
    design <- mod_matrix(formula, data, contrasts.arg = contrast_args, ...)
    return(design)
  }
}

#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param design PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @family modeldesign
#' @export
#' @importFrom data.table data.table
enw_effects_metadata <- function(design) {
  dt <- data.table::data.table(effects = colnames(design), fixed = 1)
  dt <- dt[!effects %in% "(Intercept)"]
  return(dt[])
}

#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param effects PARAM_DESCRIPTION
#'
#' @param string PARAM_DESCRIPTION
#'
#' @param var_name PARAM_DESCRIPTION, Default: 'sd'
#'
#' @param finder_fn PARAM_DESCRIPTION, Default: startsWith
#' @return OUTPUT_DESCRIPTION
#'
#' @family modeldesign
#' @export
enw_add_pooling_effect <- function(effects, string, var_name = "sd",
                                   finder_fn = startsWith) {
  effects[, (var_name) := ifelse(finder_fn(effects, string), 1, 0)]
  effects[finder_fn(effects, string), fixed := 0]
  return(effects[])
}

#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param metaobs PARAM_DESCRIPTION
#'
#' @param feature PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#' @family modeldesign
#' @export
enw_add_cumulative_membership <- function(metaobs, feature) {
  metaobs <- data.table::as.data.table(metaobs)
  cfeature <- paste0("c", feature)
  metaobs[, (cfeature) := as.factor(get(feature))]
  metaobs <- cbind(
    metaobs, model.matrix(as.formula(paste0("~ 0 + ", cfeature)), metaobs)
  )
  metaobs[, (cfeature) := NULL]
  metaobs[, (paste0(cfeature, "0")) := NULL]
  cfeatures <- grep(cfeature, colnames(metaobs), value = TRUE)
  metaobs[,
    (cfeatures) := purrr::map(.SD, ~ ifelse(cumsum(.) > 0, 1, 0)),
    .SDcols = cfeatures, by = "group"
  ]
  return(metaobs[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param metaobs PARAM_DESCRIPTION
#'
#' @param fixed PARAM_DESCRIPTION. Default: c()
#'
#' @param random PARAM_DESCRIPTION. Default: c()
#'
#' @param custom_random PARAM_DESCRIPTION. Default: c()
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @family modeldesign
#' @importFrom data.table copy
#' @importFrom stats as.formula
#' @export
enw_formula <- function(metaobs, fixed = c(), random = c(),
                        custom_random = c()) {
  metaobs <- data.table::copy(metaobs)
  form <- c("1")
  no_contrasts <- FALSE

  cr_in_dt <- purrr::map(
    custom_random, ~ colnames(metaobs)[startsWith(colnames(metaobs), .)]
  )
  cr_in_dt <- unlist(cr_in_dt)

  form <- c(form, fixed, random, cr_in_dt)
  if (length(random) > 0) {
    no_contrasts <- c(random)
  }
  form <- as.formula(paste0("~ ", paste(form, collapse = " + ")))

  # build effects design matrix (with  no contrasts)
  fixed <- enw_design(form, metaobs,
    no_contrasts = no_contrasts,
    sparse = TRUE
  )

  # get effects
  effects <- enw_effects_metadata(fixed$design)

  random <- c(random, custom_random)

  if (length(random) == 0) {
    random <- enw_design(~1, effects, sparse = FALSE)
  } else {
    for (i in random) {
      effects <- enw_add_pooling_effect(effects, i, var_name = i)
    }
    rand_form <- c("0", "fixed", random)
    rand_form <- as.formula(paste0("~ ", paste(rand_form, collapse = " + ")))
    random <- enw_design(rand_form, effects, sparse = FALSE)
  }
  return(list(fixed = fixed, random = random))
}
