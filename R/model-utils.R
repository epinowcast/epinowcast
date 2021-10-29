is.Date <- function(x) { # nolint
  inherits(x, "Date")
}

enw_dates_to_factors <- function(data) {
  data <- data.table::as.data.table(data)
  cols <- colnames(data)[sapply(data, is.Date)]
  data <- data[, lapply(.SD, factor), .SDcols = cols]
  return(data[])
}

enw_design <- function(formula, data, no_contrasts = FALSE, sparse = TRUE,
                       ...) {
  # make data.table and copy
  data <- data.table::as.data.table(data)

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
    return(list(design = sparse_design, index = index))
  }

  # design matrix using default contrasts
  if (length(no_contrasts) == 1 && !no_contrasts) {
    design <- mod_matrix(formula, data, ...)
    return(design)
  } else {
    if (length(no_contrasts) == 1 && no_contrasts) {
      no_contrasts <- colnames(data)[
        sapply(data, function(x) is.factor(x) | is.character(x))
      ]
    }
    # what is in the formula
    in_form <- rownames(attr(stats::terms(formula, data = data), "factors"))

    # drop contrasts not in the formula
    no_contrasts <- no_contrasts[no_contrasts %in% in_form]

    if (length(no_contrasts) == 0) {
      design <- mod_matrix(formula, data, ...)
      return(design)
    } else {
      # check everything is  a factor that should be
      data[, lapply(.SD, as.factor), .SDcols = no_contrasts]

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
}

enw_effects_metadata <- function(design) {
  dt <- data.table::data.table(effects = colnames(design), fixed = 1)
  dt <- dt[!effects %in% "(Intercept)"]
  return(dt[])
}

enw_add_pooling_effect <- function(effects, string, var_name = "sd") {
  effects[, (var_name) := ifelse(grepl(string, effects), 1, 0)]
  effects[grepl(string, effects), fixed := 0]
  return(effects[])
}

enw_add_day_of_week <- function(metaobs, holidays = c()) {

}

enw_add_week <- function(metaobs) {

}

enw_cumulative_week_membership <- function(metaobs) {

}

enw_cumulative_day_membership <- function(metaobs) {

}
