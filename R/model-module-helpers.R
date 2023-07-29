#' Identify report dates with complete (i.e up to the maximum delay) reference
#' dates
#'
#' @param new_confirm `new_confirm` `data.frame` output from
#' [enw_preprocess_data()].
#'
#' @return A `data.frame` containing a `report_date` variable, and grouping
#' variables specified for report dates that have complete reporting.
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reps_with_complete_refs <- function(
  new_confirm, max_delay, by = NULL, copy = TRUE
) {
  rep_with_complete_ref <- coerce_dt(
    new_confirm, select = c(by, "report_date"), copy = copy
  )
  rep_with_complete_ref <- rep_with_complete_ref[,
    .(n = .N),
    by = c(by, "report_date")
  ][n >= max_delay]
  rep_with_complete_ref[, n := NULL]
  return(rep_with_complete_ref[])
}

#' Construct a lookup of references dates by report
#'
#' @param missing_reference `missing_reference` `data.frame` output from
#' [enw_preprocess_data()].
#'
#' @param reps_with_complete_refs A `data.frame` of report dates with complete
#' (i.e fully reported) reference dates as produced using
#' [enw_reps_with_complete_refs()].
#'
#' @param metareference `metareference` `data.frame` output from
#' [enw_preprocess_data()].
#'
#' @return A wide `data.frame` with each row being a complete report date and'
#' the columns being the observation index for each reporting delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reference_by_report <- function(missing_reference, reps_with_complete_refs,
                                    metareference, max_delay) {
  # Make a complete data.table of all possible reference and report dates
  miss_lk <- coerce_dt(
    metareference, select = "date", group = TRUE
  )
  data.table::setnames(miss_lk, "date", "reference_date")

  miss_lk <- miss_lk[,
    .(delay = 0:(max_delay - 1)),
    by = c("reference_date", ".group")
  ]
  miss_lk[, report_date := reference_date + delay]
  data.table::setkeyv(miss_lk, c(".group", "reference_date", "report_date"))

  # Assign an index (this should link with the in model index)
  miss_lk[, .id := seq_len(.N)]

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
#' @param latest `latest` `data.frame` output from [enw_preprocess_data()].
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
#' This function allows the construction of convolution matrices which can be
#' be combined with a vector of primary events to produce a vector of secondary
#' events for example in the form of a renewal equation or to simulate
#' reporting delays. Time-varying delays are supported as well as distribution
#' padding (to allow for use in renewal equation like approaches).
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
#' @importFrom utils head
#' @examples
#' # Simple convolution matrix with a static distribution
#' convolution_matrix(c(1, 2, 3), 10)
#' # Include partially reported convolutions
#' convolution_matrix(c(1, 2, 3), 10, include_partial = TRUE)
#' # Use a list of distributions
#' convolution_matrix(rep(list(c(1, 2, 3)), 10), 10)
#' # Use a time-varying list of distributions
#' convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4, 5, 6))), 11)
convolution_matrix <- function(dist, t, include_partial = FALSE) {
  if (is.list(dist)) {
    if (length(dist) != t) {
      stop("dist must equal t or be the same for all t (i.e. length 1)")
    }
    ldist <- lengths(dist)
    if (!all(ldist == ldist[1])) {
      stop("dist must be the same length for all t")
    }
  } else {
    ldist <- rep(length(dist), t)
    dist <- rep(list(dist), t)
  }
  conv <- matrix(0, nrow = t, ncol = t)
  for (s in 1:t) {
    l <- min(t - s + 1, ldist[s])
    conv[s:(s + l - 1), s] <- head(dist[[s]], l)
  }
  if (!include_partial && ldist[1] > 1) {
    conv[1:(ldist[1] - 1), ] <- 0
  }
  return(conv)
}

#' Add probability mass functions
#'
#' This function allows the addition of probability mass functions (PMFs) to
#' produce a new PMF. This is useful for example in the context of reporting
#' delays where the PMF of the sum of two Poisson distributions is the
#' convolution of the PMFs.
#'
#' @param pmfs A list of vectors describing the probability mass functions to
#'
#' @return A vector describing the probability mass function of the sum of the
#'
#' @export
#' @importFrom stats ecdf
#' @importFrom purrr map_dbl
#' @family modelmodulehelpers
#' @examples
#' # Sample and analytical PMFs for two Poisson distributions
#' x <- rpois(10000, 5)
#' xpmf <- dpois(0:20, 5)
#' y <- rpois(10000, 7)
#' ypmf <- dpois(0:20, 7)
#' # Add sampled Poisson distributions up to get combined distribution
#' z <- x + y
#' # Analytical convolution of PMFs
#' conv_pmf <- add_pmfs(list(xpmf, ypmf))
#' conv_cdf <- cumsum(conv_pmf)
#' # Empirical convolution of PMFs
#' cdf <- ecdf(z)(0:42)
#' # Compare sampled and analytical CDFs
#' plot(conv_cdf)
#' lines(cdf, col = "black")
add_pmfs <- function(pmfs) {
  d <- length(pmfs)
  if (d == 1) {
    return(pmfs[[1]])
  }
  if (!is.list(pmfs)) {
    return(pmfs)
  }
  # P(Z = z) = sum_over_x(P(X = x) * P(Y = z - x)) # nolint
  return(
    Reduce(x = pmfs, f = function(conv, pmf) {
      lc <- length(conv)
      wd <- seq_len(lc) - 1
      proc <- numeric(lc + length(pmf))
      for (j in seq_along(pmf)) {
        proc[j + wd] <- proc[j + wd] + pmf[j] * conv
      }
      return(proc)
    })
  )
}

#' Extract sparse matrix elements
#'
#' This helper function allows the extraction of a sparse matrix from a matrix
#' using `rstan::extract_sparse_parts()` and returns these elements in a named
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
  sparse_mat <- suppressMessages(rstan::extract_sparse_parts(mat))
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
