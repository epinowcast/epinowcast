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
#' @importFrom rlang abort
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
      rlang::abort(
        paste0(
          "`length(dist)` must equal `t` or be the same for all t ",
          "(i.e. length 1)"
        )
      )
    }
    ldist <- lengths(dist)
    if (!all(ldist == ldist[1])) {
      rlang::abort("dist must be the same length for all t")
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

#' Simulate daily double censored PMF
#'
#' This function simulates the probability mass function of a  daily
#' double-censored process. The process involves two distributions: a primary
#' distribution which represents the censoring process for the primary event
#' and another distribution (which is offset by the primary).
#'
#' @param max Maximum value for the computed CDF. If not specified, the maximum
#' value is the maximum simulated delay.
#' @param fun_primary Primary distribution function (default is \code{runif}).
#' @param fun_dist Distribution function to be added to the primary (default is
#' \code{rlnorm}).
#' @param n Number of simulations (default is 1e6).
#' @param primary_args List of additional arguments to be passed to the primary
#' distribution function.
#' @param dist_args List of additional arguments to be passed to the
#' distribution function.
#' @param ... Additional arguments to be passed to the distribution function.
#' This is an alternative to `dist_args`.
#'
#' @return A numeric vector representing the PMF.
#' @export
#' @family modelmodulehelpers
#' @examples
#' simulate_double_censored_pmf(10, meanlog = 0, sdlog = 1)
simulate_double_censored_pmf <- function(
  max, fun_primary = stats::runif, primary_args = list(),
  fun_dist = stats::rlnorm,
  dist_args = list(...), n = 1e6, ...
) {
  primary <- do.call(fun_primary, c(list(n), primary_args))
  secondary <- primary + do.call(fun_dist, c(list(n), dist_args))
  delay <- floor(secondary) - floor(primary)
  if (missing(max)) {
    max <- base::max(delay)
  }
  cdf <- ecdf(delay)(0:max)
  pmf <- c(cdf[1], diff(cdf))
  return(pmf)
}

#' Add maximum observed delay
#'
#' This function calculates and adds the maximum observed delay for each group
#' and reference date in the provided dataset. It first checks the validity of
#' the observation indicator and then computes the maximum delay. If an
#' observation indicator is provided, it further adjusts the maximum observed
#' delay for unobserved data to be negative 1 (indicating no maximum observed).
#'
#' @inheritParams extract_obs_metadata
#' @return A data.table with the original columns of `new_confirm` and an
#' additional "max_obs_delay" column representing the maximum observed delay
#' for each group and reference date. If an observation indicator is provided,
#' unobserved data will have a "max_obs_delay" value of -1.
#' @family modelmodulehelpers
add_max_observed_delay <- function(new_confirm, observation_indicator = NULL) {
  check_observation_indicator(new_confirm, observation_indicator)
  new_confirm <- new_confirm[,
    max_obs_delay := max(delay),
    by = c("reference_date", ".group", observation_indicator)
  ]
  if (!is.null(observation_indicator)) {
    new_confirm[!get(observation_indicator), max_obs_delay := -1]
    new_confirm <- new_confirm[,
      max_obs_delay := max(max_obs_delay), by = c("reference_date", ".group")
    ]
  }
  return(new_confirm[])
}

#' Extract observation metadata
#'
#' This function extracts metadata from the provided dataset to be used in the
#' observation model.
#'
#' @param new_confirm A data.table containing the columns: "reference_date",
#' "delay", ".group", "new_confirm", and "max_obs_delay".
#' As produced by [enw_preprocess_data()] in the `new_confirm` output with the
#' addition of the "max_obs_delay" column as produced by
#' [add_max_observed_delay()].
#'
#' @param observation_indicator A character string specifying the column name
#' in `new_confirm` that indicates whether an observation is observed or not.
#' This column should be a logical vector. If NULL (default), all observations
#' are considered observed.
#'
#' @return A list containing:
#'   \itemize{
#'     \item \code{st}: time index of each snapshot (snapshot time).
#'     \item \code{ts}: snapshot index by time and group.
#'     \item \code{sl}: number of reported observations per snapshot (snapshot
#'     length).
#'     \item \code{csl}: cumulative version of sl.
#'     \item \code{lsl}: number of consecutive reported observations per
#'     snapshot accounting for missing data.
#'     \item \code{clsl}: cumulative version of lsl.
#'     \item \code{nsl}: number of observed observations per snapshot (snapshot
#'     length).
#'     \item \code{cnsl}: cumulative version of nsl.
#'     \item \code{sg}: group index of each snapshot (snapshot group).
#'   }
#' @family modelmodulehelpers
extract_obs_metadata <- function(new_confirm,  observation_indicator = NULL) {
  check_observation_indicator(new_confirm, observation_indicator)
  # format vector of snapshot lengths
  snap_length <- new_confirm
  snap_length <- snap_length[, .SD[delay == max(delay)],
    by = c("reference_date", ".group")
  ]
  snap_length <- snap_length$delay + 1

  # format the vector of snapshot lengths accounting for missing data
  if (!is.null(observation_indicator)) {
    # Get the maximum consecutive length of observed data
    l_snap_length <- new_confirm[,
     .(s = unique(max_obs_delay) + 1), by = c("reference_date", ".group")
    ]$s
    # Get the number of observed data points per snapshot
    nc_snap_length <- new_confirm[,
      .(s = sum(get(observation_indicator))), by = .(reference_date, .group)
    ]$s
  } else {
    l_snap_length <- snap_length
    nc_snap_length <- snap_length
  }

  # snap lookup
  snap_lookup <- unique(new_confirm[, .(reference_date, .group)])
  snap_lookup[, s := seq_len(.N)]
  snap_lookup <- data.table::dcast(
    snap_lookup, reference_date ~ .group,
    value.var = "s"
  )
  snap_lookup <- as.matrix(snap_lookup[, -1])

  # snap time
  snap_time <- unique(new_confirm[, .(reference_date, .group)])
  snap_time[, t := seq_len(.N), by = ".group"]
  snap_time <- snap_time$t

  # Format indexing and observed data
  out <- list(
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    csl = cumsum(snap_length),
    lsl = l_snap_length,
    clsl = cumsum(l_snap_length),
    nsl = nc_snap_length,
    cnsl = cumsum(nc_snap_length),
    sg = unique(new_confirm[, .(reference_date, .group)])$.group
  )
  return(out)
}
