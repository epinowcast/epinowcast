#' Construct a design matrix from a formula
#'
#' This function is a wrapper around [stats::model.matrix()] that can
#' optionally return a sparse design matrix defined as the unique
#' number of rows in the design matrix and an index vector that
#' allows the full design matrix to be reconstructed. This is useful
#' for models that have many repeated rows in the design matrix and that
#' are computationally expensive to fit.
#'
#' @param formula An R formula.
#' @param data A `data.frame` containing the variables in the formula.
#' @param sparse Logical, if TRUE return a sparse design matrix. Defaults to
#' TRUE.
#' @param ... Additional arguments passed to [stats::model.matrix()].
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
#' @description This function is a wrapper around [stats::model.matrix()] that
#'  can optionally return a sparse design matrix defined as the unique
#' number of rows in the design matrix and an index vector that
#' allows the full design matrix to be reconstructed. This is useful
#' for models that have many repeated rows in the design matrix and that
#' are computationally expensive to fit. This function also allows
#' for the specification of contrasts for categorical variables.
#'
#' @param formula An R formula.
#'
#' @param data A `data.frame` containing the variables in the formula.
#'
#' @param no_contrasts A vector of variable names that should not be
#' converted to contrasts. If `no_contrasts = FALSE` then all categorical
#' variables will use contrasts. If `no_contrasts = TRUE` then
#' no categorical variables will use contrasts.
#'
#' @param sparse Logical, if TRUE return a sparse design matrix. Defaults to
#' TRUE.
#'
#' @param ... Additional arguments passed to [stats::model.matrix()].
#'
#' @return A list containing the formula, the design matrix, and the index.
#' @family modeldesign
#' @export
#' @importFrom stats terms contrasts model.matrix
#' @importFrom purrr map
#' @examples
#' data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
#' enw_design(a ~ b + c, data)
#' enw_design(a ~ b + c, data, no_contrasts = TRUE)
#' enw_design(a ~ b + c, data, no_contrasts = c("b"))
#' enw_design(a ~ c, data, sparse = TRUE)
#' enw_design(a ~ c, data, sparse = FALSE)
enw_design <- function(formula, data, no_contrasts = FALSE, sparse = TRUE,
                       ...) {
  # make data.table and copy
  data <- coerce_dt(data)

  # make all character variables factors
  chars <- colnames(data)[sapply(data, is.character)]
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

#' @title Extracts metadata from a design matrix
#'
#' @description This function extracts metadata from a design matrix
#' and returns a data.table with the following columns:
#' - effects: the name of the effect
#' - fixed: a logical indicating whether the effect is fixed (1) or random (0).
#'
#' It automatically drops the intercept (defined as "(Intercept)").
#'
#' This function is useful for constructing a model design object for random
#' effects when used in combination with `ewn_add_pooling_effect`.
#'
#' @param design A design matrix as returned by [stats::model.matrix()].
#'
#' @return A data.table with the following columns:
#' - effects: the name of the effect
#' - fixed: a logical indicating whether the effect is fixed (1) or random (0)
#'
#' @family modeldesign
#' @export
#' @importFrom data.table data.table
#' @examples
#' data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
#' design <- enw_design(a ~ b + c, data)$design
#' enw_effects_metadata(design)
enw_effects_metadata <- function(design) {
  dt <- data.table::data.table(effects = colnames(design), fixed = 1)
  dt <- dt[!effects %in% "(Intercept)"]
  return(dt[])
}

#' @title Add a pooling effect to model design metadata
#'
#' @description This function adds a pooling effect to the metadata
#' returned by [enw_effects_metadata()]. It does this updating the
#' `fixed` column to 0 for the effects that match the `string` argument and
#' adding a new column `var_name` that is 1 for the effects that match the
#' `string` argument and 0 otherwise.
#'
#' @param effects A `data.table` with the following columns:
#' - effects: the name of the effect
#' - fixed: a logical indicating whether the effect is fixed (1) or random (0).
#'
#' This is the output of [enw_effects_metadata()].
#'
#' @param var_name The name of the new column that will be added to the
#' `effects` data.table. This column will be 1 for the effects that match the
#' string and 0 otherwise. Defaults to 'sd'.
#'
#' @param finder_fn A function that will be used to find the effects that
#' match the string. Defaults to [startsWith()]. This can be any function that
#' takes a `character` as it's first argument (the `effects$effects` column)
#' and then any other other arguments in `...` and returns a logical vector
#' indicating whether the effects were matched.
#'
#' @param ... Additional arguments to `finder_fn`. E.g. for the
#' `finder_fn = startsWith` default, this should be `prefix = "somestring"`.
#'
#' @return A `data.table` with the following columns:
#' - effects: the name of the effect
#' - fixed: a logical indicating whether the effect is fixed (1) or random (0).
#' - Argument supplied to `var_name`: a logical indicating whether the effect
#'  should be pooled (1) or not (0).
#'
#' @family modeldesign
#' @export
#' @examples
#' data <- data.frame(a = 1:3, b = as.character(1:3), c = c(1,1,2))
#' design <- enw_design(a ~ b + c, data)$design
#' effects <- enw_effects_metadata(design)
#' enw_add_pooling_effect(effects, prefix = "b")
enw_add_pooling_effect <- function(effects, var_name = "sd",
                                   finder_fn = startsWith, ...) {
  effects <- data.table::setDT(effects)
  effects[, (var_name) := as.numeric(finder_fn(effects, ...))]
  effects[finder_fn(effects, ...), fixed := 0]
  return(effects[])
}

#' @title Add a cumulative membership effect to a `data.frame`
#'
#' @description This function adds a cumulative membership effect to a data
#' frame. This is useful for specifying models such as random walks (using
#' [rw()]) where these features can be used in the design matrix with the
#' appropriate formula. Supports grouping via the optional `.group` column.
#' Note that cumulative membership is indexed to start with zero (i.e. the
#' first observation is assigned a cumulative membership of zero).
#'
#' @param metaobs A `data.frame` with a column named `feature` that contains
#' a numeric vector of values.
#'
#' @param feature The name of the column in `metaobs` that contains the
#' numeric vector of values.
#'
#' @return A `data.frame` with a new columns `cfeature$` that contain the
#' cumulative membership effect for each value of `feature`. For example if the
#' original `feature` was `week` (with numeric entries `1, 2, 3`) then the new
#' columns will be `cweek1`, `cweek2`, and `cweek3`.
#'
#' @family modeldesign
#' @export
#' @examples
#' metaobs <- data.frame(week = 1:3)
#' enw_add_cumulative_membership(metaobs, "week")
#'
#' metaobs <- data.frame(week = 1:3, .group = c(1,1,2))
#' enw_add_cumulative_membership(metaobs, "week")
enw_add_cumulative_membership <- function(metaobs, feature) {
  metaobs <- coerce_dt(metaobs)
  metaobs <- add_group(metaobs)

  cfeature <- paste0("c", feature)
  if (!any(grepl(cfeature, colnames(metaobs)))) {
    if (is.null(metaobs[[feature]])) {
      stop(
        "Requested variable ", feature,
        " is not present in the supplied data.frame."
      )
    }
    if (!is.numeric(metaobs[[feature]])) {
      stop(
        "Requested variable ", feature,
        " is not numeric. Cumulative membership effects are only defined for ",
        "numeric variables."
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
      (cfeatures) := purrr::map(.SD, ~ as.numeric(cumsum(.) > 0)),
      .SDcols = cfeatures, by = ".group"
    ]
  }
  return(metaobs[])
}
