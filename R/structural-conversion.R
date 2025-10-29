#' Precompute indices from aggregation indicator matrix
#'
#' Extracts the column indices where each row of a binary indicator matrix
#' has 1s. This is used for numerically stable aggregation operations in Stan.
#'
#' @param matrix A binary indicator matrix (0s and 1s) where each row
#'   indicates which columns should be aggregated together.
#'
#' @return A list with two components:
#'   - `n_selected`: Integer vector of length `nrow(matrix)` containing the
#'     number of selected (non-zero) indices per row
#'   - `selected_idx`: Integer matrix of dimensions
#'     `[nrow(matrix), ncol(matrix)]` containing the column indices where
#'     each row has 1s, with unused positions filled with 0
#'
#' @details
#' This helper function is primarily used in tests and by
#' `.precompute_aggregation_lookups()` to precompute sparse index lookups for
#' aggregation operations.
#'
#' @keywords internal
.precompute_matrix_indices <- function(matrix) {
  nrows <- nrow(matrix)
  ncols <- ncol(matrix)

  n_selected <- integer(nrows)
  selected_idx <- matrix(0L, nrow = nrows, ncol = ncols)

  for (i in seq_len(nrows)) {
    indices <- which(matrix[i, ] > 0)
    n_sel <- length(indices)
    n_selected[i] <- n_sel
    if (n_sel > 0) {
      selected_idx[i, seq_len(n_sel)] <- indices
    }
  }

  list(
    n_selected = n_selected,
    selected_idx = selected_idx
  )
}


#' Precompute aggregation index lookups for Stan
#'
#' Takes a nested list structure of aggregation indicator matrices and
#' precomputes sparse index lookups for efficient Stan operations.
#'
#' @param structural A nested list structure: list(groups) of list(times) of
#'   matrices (max_delay x max_delay). Each matrix contains 0s and 1s
#'   indicating which delays aggregate to which reporting delays.
#'
#' @param n_groups Integer number of groups.
#'
#' @param n_times Integer number of time points.
#'
#' @param max_delay Integer maximum delay.
#'
#' @return A list with two components:
#'   - `n_selected`: 3D array with dimensions (groups, times, max_delay)
#'     containing the number of selected indices per row
#'   - `selected_idx`: 4D array with dimensions
#'     (groups, times, max_delay, max_delay) containing the column indices
#'     where each row has 1s
#'
#' @details
#' Row i of the precomputed indices only contains column indices j where
#' j <= i, ensuring reports aggregate from current or earlier delays only.
#'
#' @keywords internal
.precompute_aggregation_lookups <- function(structural, n_groups, n_times,
                                            max_delay) {
  # Initialize arrays
  n_selected <- array(
    0L,
    dim = c(n_groups, n_times, max_delay)
  )

  selected_idx <- array(
    0L,
    dim = c(n_groups, n_times, max_delay, max_delay)
  )

  # Fill arrays with precomputed indices
  for (g in seq_along(structural)) {
    # Validate that structural[[g]] exists and is a list
    if (!is.list(structural[[g]])) {
      stop(
        "structural[[", g, "]] must be a list, but got ",
        class(structural[[g]])[1], call. = FALSE
      )
    }
    # Validate that structural[[g]] has correct length
    if (length(structural[[g]]) != n_times) {
      stop(
        "structural[[", g, "]] must have length ", n_times,
        ", but got ", length(structural[[g]]), call. = FALSE
      )
    }

    for (t in seq_along(structural[[g]])) {
      mat <- structural[[g]][[t]]

      # Validate that mat is a matrix
      if (!inherits(mat, "matrix")) {
        stop(
          "structural[[", g, "]][[", t, "]] must be a matrix, but got ",
          class(mat)[1], call. = FALSE
        )
      }

      # Validate that mat has correct dimensions
      mat_dims <- dim(mat)
      if (mat_dims[1] != max_delay || mat_dims[2] != max_delay) {
        stop(
          "structural[[", g, "]][[", t, "]] must have dimensions (",
          max_delay, ", ", max_delay, "), but got (",
          mat_dims[1], ", ", mat_dims[2], ")", call. = FALSE
        )
      }

      # Precompute indices using helper function
      indices_list <- .precompute_matrix_indices(mat)
      n_selected[g, t, ] <- indices_list$n_selected
      selected_idx[g, t, , ] <- indices_list$selected_idx
    }
  }

  list(
    n_selected = n_selected,
    selected_idx = selected_idx
  )
}

#' Validate structural reporting data.table
#'
#' Checks that a structural reporting data.table has the required columns
#' and correct structure for conversion to matrices.
#'
#' @param structural A `data.table` or `data.frame` with columns `.group`,
#'   `date`, `report_date`, and `report`.
#'
#' @return The validated and coerced `data.table` (invisible). Aborts with
#'   error if validation fails.
#'
#' @details
#' The structural reporting matrix ensures reports can only aggregate from
#' the current or earlier delays. For example, a report on delay 5 can
#' aggregate delays 1 through 5, but not delay 6 or later. This function
#' validates that `report_date >= date` to ensure valid delays.
#'
#' @keywords internal
.validate_structural_reporting <- function(structural) {
  # Coerce to data.table and check for required columns
  structural <- coerce_dt(
    structural,
    required_cols = c(".group", "date", "report_date", "report"),
    copy = FALSE,
    msg_required = "`structural` is missing required columns: "
  )

  # Validate report column contains only 0s and 1s
  if (!is.numeric(structural$report) ||
      !all(structural$report %in% c(0, 1))) {
    cli::cli_abort(
      "`report` column must contain only 0s and 1s."
    )
  }

  # Validate report_date >= date. This ensures reports can only aggregate
  # from current or earlier delays (e.g., delay 5 aggregates delays 1-5, not 6+)
  if (any(structural$report_date < structural$date)) {
    cli::cli_abort(
      c(
        "`report_date` must be greater than or equal to `date`.",
        i = "Reports can only aggregate from current or earlier delays."
      )
    )
  }

  invisible(structural)
}

#' Convert structural reporting data.table to nested list of matrices
#'
#' Takes a structural reporting data.table and converts it to the nested
#' list structure required by `.convert_structural_to_arrays()`. This
#' involves creating delay columns and splitting by group and date.
#'
#' @inheritParams .validate_structural_reporting
#' @inheritParams enw_structural_reporting_metadata
#'
#' @return A nested list: list(groups) of list(times) of matrices
#'   (max_delay x max_delay). Each matrix contains 0s and 1s indicating
#'   which delays aggregate to which reporting delays.
#'
#' @keywords internal
.structural_reporting_to_matrices <- function(structural, pobs) {
  structural <- .validate_structural_reporting(structural)

  max_delay <- pobs$max_delay

  # Calculate delay from reference date to report date
  structural <- data.table::copy(structural)
  structural[, delay := as.integer(report_date - date)]

  # Filter to valid delays (0 to max_delay-1)
  structural <- structural[delay >= 0 & delay < max_delay]

  # Compute cumulative reporting per reference date
  data.table::setorder(structural, .group, date, delay)
  structural[, cum_report := cumsum(report) + 1, by = .(.group, date)]
  structural[report == 1, cum_report := cum_report - 1]

  # Create empty delay columns
  for (i in seq_len(max_delay)) {
    structural[, paste0("delay_", i) := 0]
  }

  # Fill delay columns based on cumulative reporting
  structural[, {
    delay_cols <- paste0("delay_", seq_len(max_delay))
    reporting_rows <- which(report == 1)
    if (length(reporting_rows) > 0) {
      for (rep_idx in reporting_rows) {
        cum_rep_val <- cum_report[rep_idx]
        # Set all delays for this reporting row
        values <- as.list(as.integer(cum_report == cum_rep_val))
        set(structural, .I[rep_idx], delay_cols, values)
      }
    }
    NULL
  }, by = .(.group, date)]

  # Split by group and date into matrices
  delay_cols <- paste0("delay_", seq_len(max_delay))
  agg_indicators <- structural[,
    c(".group", "date", delay_cols),
    with = FALSE
  ] |>
    split(by = ".group", drop = TRUE) |>
    purrr::map(\(group_data) {
      group_data |>
        split(by = "date", drop = TRUE) |>
        purrr::map(\(x) as.matrix(x[, -c(".group", "date")]))
    })

  agg_indicators
}
