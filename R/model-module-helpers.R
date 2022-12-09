#' Identify report dates with complete (i.e up to the maximum delay) reference
#' dates
#'
#' @param new_confirm `new_confirm` data.frame output from
#' [enw_preprocess_data()].
#'
#' @return A data frame containing a `report_date` variable, and grouping
#' variables specified for report dates that have complete reporting.
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reps_with_complete_refs <- function(new_confirm, max_delay, by = c()) {
  rep_with_complete_ref <- data.table::as.data.table(new_confirm)
  rep_with_complete_ref <- rep_with_complete_ref[,
    .(n = .N),
    by = c(by, "report_date")
  ][n >= max_delay]
  rep_with_complete_ref[, n := NULL]
  return(rep_with_complete_ref[])
}

#' Construct a lookup of references dates by report
#'
#' @param missing_reference `missing_reference` data.frame output from
#' [enw_preprocess_data()].
#'
#' @param reps_with_complete_refs A `data.frame` of report dates with complete
#' (i.e fully reported) reference dates as produced using
#' [enw_reps_with_complete_refs()].
#'
#' @param metareference `metareference` data.frame output from
#' [enw_preprocess_data()].
#'
#' @return A wide data frame with each row being a complete report date and'
#' the columns being the observation index for each reporting delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reference_by_report <- function(missing_reference, reps_with_complete_refs,
                                    metareference, max_delay) {
  # Make a complete data frame of all possible reference and report dates
  miss_lk <- data.table::copy(metareference)[
    ,
    .(reference_date = date, .group)
  ]
  miss_lk[, delay := list(0:(max_delay - 1))]
  miss_lk <- miss_lk[,
    .(delay = unlist(delay)),
    by = c("reference_date", ".group")
  ]
  miss_lk[, report_date := reference_date + delay]
  data.table::setkeyv(miss_lk, c(".group", "reference_date", "report_date"))

  # Assign an index (this should link with the in model index)
  miss_lk[, .id := 1:.N]

  # Link with reports with complete reference dates
  complete_miss_lk <- miss_lk[
    reps_with_complete_refs,
    on = c("report_date", ".group")
  ]
  data.table::setkeyv(
    complete_miss_lk, c(".group", "report_date", "reference_date")
  )

  # Make wide format
  refs_by_report <- data.table::dcast(
    complete_miss_lk[, .(report_date, .id, delay)], report_date ~ delay,
    value.var = ".id"
  )
  return(refs_by_report[])
}
#' Convert latest observed data to a matrix
#'
#' @param latest `latest` data.frame output from [enw_preprocess_data()].
#'
#' @return A matrix with each column being a group and each row a reference date
#' @family modelmodulehelpers
latest_obs_as_matrix <- function(latest) {
  latest_matrix <- data.table::dcast(
    latest, reference_date ~ .group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])
}

#' Construct a convolution matrix
#'
#' This function allows the construction of convoluton matrices which can be
#' be combined with a vector of primary events to produce a vector of secondary
#' events for example in the form of a renewal equation or to simulate
#' reporting delays. Time-varying delays are supported as well as distribution
#' padding (to allow for use in renewal equation like aproaches).
#'
#' @param dist A vector of list of vectors describing the distribution to be
#' convolved as a probability mass function.
#'
#' @param t Integer value indicating the number of time steps to convolve over.
#'
#' @param include_partial Logical, defaults to FALSE. If TRUE, the convolution
#' include partially complete secondary events.
#'
#' @return A matrix with each column indicating a primary event and each row
#' indicating a secondary event.
#' @export
#' @family modelmodulehelpers
#' @importFrom purrr map_dbl
#' @examples
#' # Simple convolution matrix with a static distribution
#' convolution_matrix(c(1, 2, 3), 10)
#' # Include partially reported convolutions
#' convolution_matrix(c(1, 2, 3), 10, include_partial = TRUE)
#' # Use a list of distributions
#' convolution_matrix(rep(list(c(1, 2 3)), 10),10)
#' # Use a time-varying list of distributions
#' convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4,5,6))), 11)
convolution_matrix <- function(dist, t, include_partial = FALSE) {
  if (is.list(dist)) {
    if (length(dist) != t) {
      stop("dist must equal t or be the same for all t (i.e. length 1)")
    }
    ldist <- purrr::map_dbl(dist, length)
    if (!all(ldist == ldist[1])) {
      stop("dist must be the same length for all t")
    }
  }else {
    ldist <- rep(length(dist), t)
    dist <- rep(list(dist), t)
  }
  conv <- matrix(0, nrow = t, ncol = t)
  for (s in 1:t) {
    l <- min(t - s + 1, ldist[s])
    conv[s:(s + l - 1), s] <- head(dist[[s]], l)
  }
  if (!include_partial) {
    if (ldist[1] > 1) {
      conv[1:(ldist[1] - 1), ] <- 0
    }
  }
  return(conv)
}

add_pmfs <- function(pmf, pmf2) {
  lpmf <- length(pmf)
  lpmf2 <- length(pmf2)
  l <- lpmf + lpmf2
  conv <- rep(0, l)
  for (i in 1:lpmf) {
    for (j in 1:(min(l - i + 1, lpmf2))) {
      conv[i + j - 1] <- conv[i + j - 1] + pmf[i] * pmf2[j]
    }
  }
  return(conv)
}

#' Extract sparse matrix elements
#'
#' This helper function allows the extraction of a sparse matrix from a matrix
#' using `rstan::extract_sparse_parsts()` and returns these elements in a named
#' list for use in stan.
#'
#' @param mat A matrix to extract the sparse matrix from.
#' @param prefix A character string to prefix the names of the returned list.
#'
#' @return Return a list that describes the sparse matrix this includes:
#'  - `nw` the number of non-zero elements in the matrix.
#'  - `w` the non-zero elements of the matrix.
#'  - `nv` the number of non-zero row identifiers in the matrix.
#'  - `v` the non-zero row identifiers of the matrix.
#' - `nu` the number of non-zero column identifiers in the matrix.
#' - `u` the non-zero column identifiers of the matrix.
#' @export
#' @family modelmodulehelpers
#' @importFrom rstan extract_sparse_parts
#' @examples
#' mat <- matrix(1:9, nrow = 3)
#' extract_sparse_matrix(mat)
extract_sparse_matrix <- function(mat, prefix = "") {
  sparse_mat <- rstan::extract_sparse_parts(mat)
  sparse_mat <- list(
    nw = length(sparse_mat$w),
    w = sparse_mat$w,
    nv = length(sparse_mat$v),
    v = sparse_mat$v,
    nu = length(sparse_mat$u),
    u = sparse_mat$u
  )
  if (prefix != "") {
    names(sparse_mat) <- paste0(prefix, "_", names(sparse_mat))
  }
  return(sparse_mat)
}
