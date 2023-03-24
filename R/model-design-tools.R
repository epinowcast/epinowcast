#' @title Check a vector is a Date
#' @description Checks that a vector is a date
#' @param x A vector
#' @return A logical
#' @family utils
is.Date <- function(x) {
  # nolint
  inherits(x, "Date")
}

#' @title Convert all Dates to Factors
#' @description Converts all Date columns to factors
#' in a `data.frame`.
#' @param data A `data.frame`.
#' @return A `data.frame` with all Date variables converted to factors.
#' @family modeldesign
#' @export
#' @importFrom data.table as.data.table
#' @examples
#' data <- data.frame(date = as.Date("2019-01-01") + 0:2, x = 1:3)
#' enw_dates_to_factors(data)
enw_dates_to_factors <- function(data) {
  data <- data.table::as.data.table(data)
  cols <- colnames(data)[sapply(data, is.Date)]
  data <- data[, lapply(.SD, factor), .SDcols = cols]
  return(data[])
}

#' Construct a design matrix from a formula
#'
#' This function is a wrapper around `model.matrix` that can 
#' optionally return a sparse design matrix defined as the unique
#' number of rows in the design matrix and an index vector that
#' allows the full design matrix to be reconstructed. This is useful
#' for models that have many repeated rows in the design matrix and that
#' are computationally expensive to fit.
#'
#' @param formula An R formula.
#' @param data A data frame containing the variables in the formula.
#' @param sparse Logical, if TRUE return a sparse design matrix. Defaults to
#' TRUE.
#' @param ... Additional arguments passed to `model.matrix`.
#' @keywords internal
#' @noRd
#' @return A list containing the formula, the design matrix, and the index.
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

#' A helper function to construct a design matrix from a formula
#' 
#' @description This function is a wrapper around `model.matrix` that can
#' optionally return a sparse design matrix defined as the unique
#' number of rows in the design matrix and an index vector that
#' allows the full design matrix to be reconstructed. This is useful
#' for models that have many repeated rows in the design matrix and that
#' are computationally expensive to fit. This function also allows
#' for the specification of contrasts for categorical variables.
#'
#' @param formula An R formula.
#'
#' @param data A data frame containing the variables in the formula.
#'
#' @param no_contrasts A vector of variable names that should not be
#' converted to contrasts. If `no_contrasts = FALSE` then all categorical
#' variables will use contrasts. If `no_contrasts = TRUE` then
#' no categorical variables will use contrasts.
#'
#' @param sparse Logical, if TRUE return a sparse design matrix. Defaults to
#' TRUE.
#'
#' @param ... Additional arguments passed to `model.matrix`.
#'
#' @return A list containing the formula, the design matrix, and the index.
#' @family modeldesign
#' @export
#' @importFrom data.table as.data.table
#' @importFrom stats terms contrasts model.matrix
#' @importFrom purrr map
#' data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
#' enw_design(a ~ b + c, data)
#' enw_design(a ~ b + c, data, no_contrasts = TRUE)
#' enw_design(a ~ b + c, data, no_contrasts = c("b"))
#' enw_design(a ~ c, data, sparse = TRUE)
#' enw_design(a ~ c, data, sparse = FALSE)
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
