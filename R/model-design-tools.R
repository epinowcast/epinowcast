#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param x PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family utils
is.Date <- function(x) {
  # nolint
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


#' FUNCTION_TITLE
#'
#' FUNCTION_DESCRIPTION
#'
#' @param formula DESCRIPTION.
#' @param data DESCRIPTION.
#' @param sparse DESCRIPTION.
#' @param ... DESCRIPTION.
#' @keywords internal
#' @noRd
#' @return RETURN_DESCRIPTION
mod_matrix <- function(formula, data, sparse = TRUE, ...) {
  design <- model.matrix(formula, data, ...)
  if (sparse) {
    sparse_design <- unique(design)
    index <- match(data.frame(t(design)), data.frame(t(sparse_design)))
  } else {
    sparse_design <- design
    index <- seq_len(nrow(design))
  }
  return(list(
    formula = as_string_formula(formula),
    design = sparse_design,
    index = index
  ))
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
  # drop missing factor levels
  data <- droplevels(data)

  # make model.matrix helper

  if (length(no_contrasts) == 1 && is.logical(no_contrasts)) {
    if (!no_contrasts) {
      design <- mod_matrix(formula, data, sparse = sparse, ...)
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
    design <- mod_matrix(formula, data, sparse = sparse, ...)
    return(design)
  } else {
    # make list of contrast args
    contrast_args <- purrr::map(
      no_contrasts, ~ stats::contrasts(data[[.]], contrast = FALSE)
    )
    names(contrast_args) <- no_contrasts

    # model matrix with contrast options
    design <- mod_matrix(
      formula, data,
      sparse = sparse, contrasts.arg = contrast_args, ...
    )
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
  if (!any(grepl(cfeature, colnames(metaobs)))) {
    if (is.null(metaobs[[feature]])) {
      stop(
        "Requested variable ", feature,
        " is not present in the supplied data frame."
      )
    }
    metaobs[, (cfeature) := as.factor(get(feature))]
    metaobs <- cbind(
      metaobs, model.matrix(as.formula(paste0("~ 0 + ", cfeature)), metaobs)
    )
    metaobs[, (cfeature) := NULL]
    min_avail <- min(metaobs[, get(feature)])
    metaobs[, (paste0(cfeature, as.character(min_avail))) := NULL]
    cfeatures <- grep(cfeature, colnames(metaobs), value = TRUE)
    metaobs[,
      (cfeatures) := purrr::map(.SD, ~ ifelse(cumsum(.) > 0, 1, 0)),
      .SDcols = cfeatures, by = ".group"
    ]
  }
  return(metaobs[])
}
