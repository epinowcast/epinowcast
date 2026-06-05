#' Identify report dates with complete (i.e up to the maximum delay) reference
#' dates
#'
#' @param new_confirm `new_confirm` `data.frame` output from
#' [enw_preprocess_data()].
#'
#' @return A `data.frame` containing a `report_date` variable, and grouping
#' variables specified for report dates that have complete reporting.
#'
#' @inheritParams enw_filter_delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reps_with_complete_refs <- function(
  new_confirm, max_delay, by = NULL, copy = TRUE
) {
  rep_with_complete_ref <- coerce_dt(
    new_confirm,
    select = c(by, "report_date"), copy = copy
  )
  rep_with_complete_ref <- rep_with_complete_ref[,
    .(n = .N),
    by = c(by, "report_date")
  ][n >= max_delay]
  rep_with_complete_ref[, n := NULL]
  rep_with_complete_ref[]
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
#'
#' @inheritParams enw_filter_delay
#' @inheritParams enw_preprocess_data
#' @family modelmodulehelpers
enw_reference_by_report <- function(missing_reference, reps_with_complete_refs,
                                    metareference, max_delay) {
  # Make a complete data.table of all possible reference and report dates
  miss_lk <- coerce_dt(
    metareference,
    select = "date", group = TRUE
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
  refs_by_report[]
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
#' @importFrom cli cli_abort
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
      cli::cli_abort(
        "`length(dist)` must equal `t` or be the same for all t (i.e. length 1)"
      )
    }
    ldist <- lengths(dist)
    if (!all(ldist == ldist[1])) {
      cli::cli_abort("dist must be the same length for all t")
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
  conv
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
  Reduce(x = pmfs, f = function(conv, pmf) {
    lc <- length(conv)
    wd <- seq_len(lc) - 1
    proc <- numeric(lc + length(pmf))
    for (j in seq_along(pmf)) {
      proc[j + wd] <- proc[j + wd] + pmf[j] * conv
    }
    proc
  })
}

#' Extract sparse matrix elements
#'
#' This helper function allows the extraction of a sparse matrix from a matrix
#' using a similar approach to that implemented in
#' [rstan::extract_sparse_parts()] and returns these elements in a named
#' list for use in stan. This function is used in the construction of the
#' expectation model (see [enw_expectation()]).
#'
#' @param mat A matrix to extract the sparse matrix from.
#' @param prefix A character string to prefix the names of the returned list.
#'
#' @return A list representing the sparse matrix, containing:
#'  - `nw`: Count of non-zero elements in `mat`.
#'  - `w`: Vector of non-zero elements in `mat`. Equivalent to the numeric
#'     values from `mat` excluding zeros.
#'  - `nv`: Length of v.
#'  - `v`: Vector of row indices corresponding to each non-zero element in `w`.
#'     Indicates the row location in `mat` for each non-zero value.
#'  - `nu`: Length of u.
#'  - `u`: Vector indicating the starting indices in `w` for non-zero elements
#'     of each row in `mat`. Helps identify the partition of `w` into different
#'     rows of `mat`.
#' @export
#' @family modelmodulehelpers
#' @seealso [enw_expectation()]
#' @examples
#' mat <- matrix(1:12, nrow = 4)
#' mat[2, 2] <- 0
#' mat[3, 1] <- 0
#' extract_sparse_matrix(mat)
extract_sparse_matrix <- function(mat, prefix = "") {
  lifecycle::deprecate_soft("0.5.0", "extract_sparse_matrix()")
  if (length(mat) == 0) {
    sparse_mat <- list(
      nw = 0,
      w = numeric(0),
      nv = 0,
      v = numeric(0),
      nu = 0,
      u = numeric(0)
    )
  } else {
    # Identifying non-zero elements
    mat <- t(mat)
    non_zero_indices <- which(mat != 0, arr.ind = TRUE)
    w <- mat[non_zero_indices] # Non-zero elements of the matrix

    # Extracting column non-zero elements
    v <- non_zero_indices[, 1]
    u_original <- non_zero_indices[, 2] # Column indices (used to compute u)

    # Compute the 'u' vector in CSR format
    u <- rep(0, nrow(mat) + 1)
    u[1] <- 1 # index starts from 1, so we adjust accordingly
    for (i in seq_along(u_original)) {
      u[u_original[i] + 1] <- i + 1
    }

    # Ensure that all elements in u are at least as large as the previous one
    for (i in 2:length(u)) {
      u[i] <- max(u[i], u[i - 1])
    }

    sparse_mat <- list(
      nw = length(w),
      w = w,
      nv = length(v),
      v = v,
      nu = length(u),
      u = as.integer(u)
    )
  }

  if (prefix != "") {
    names(sparse_mat) <- paste0(prefix, "_", names(sparse_mat))
  }

  sparse_mat
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
      max_obs_delay := max(max_obs_delay),
      by = c("reference_date", ".group")
    ]
  }
  new_confirm[]
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
extract_obs_metadata <- function(new_confirm, observation_indicator = NULL) {
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
      .(s = unique(max_obs_delay) + 1),
      by = c("reference_date", ".group")
    ]$s
    # Get the number of observed data points per snapshot
    nc_snap_length <- new_confirm[,
      .(s = sum(get(observation_indicator))),
      by = .(reference_date, .group)
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
  out
}

#' Create structural reporting metadata grid
#'
#' Creates a base metadata grid for structural reporting patterns by
#' generating all combinations of reference dates, delays, and report dates.
#' This grid serves as the foundation for defining custom reporting patterns.
#'
#' @param pobs A preprocessed observation list from
#' [enw_preprocess_data()].
#'
#' @return A `data.table` with columns:
#' * `.group`: Group identifier
#' * `date`: Reference date
#' * `report_date`: Report date (reference date + delay)
#'
#' @family modelmodulehelpers
#' @export
#' @examples
#' \dontrun{
#' pobs <- enw_preprocess_data(obs, max_delay = 30)
#' metadata <- enw_structural_reporting_metadata(pobs)
#'
#' # Add custom reporting pattern (e.g., only report on first day of month)
#' metadata[, report := as.integer(format(report_date, "%d") == "01")]
#' }
enw_structural_reporting_metadata <- function(pobs) {
  metadata <- data.table::copy(pobs$metareference[[1]])
  metadata[, key := 1]
  metadata <- metadata[, .(key, .group, date)]

  delay_data <- data.table::copy(pobs$metadelay[[1]])
  delay_data[, key := 1]

  metadata <- metadata[delay_data, on = "key", allow.cartesian = TRUE]
  metadata <- metadata[, .(.group, date, report_date = date + delay)]
  data.table::setorder(metadata, .group, date, report_date)

  metadata[]
}

#' Create day-of-week structural reporting pattern
#'
#' Creates a structural reporting pattern for cases where reporting only
#' occurs on specific days of the week (e.g., Wednesday-only reporting).
#' This is a convenience function that builds on
#' [enw_structural_reporting_metadata()].
#'
#' @inheritParams enw_structural_reporting_metadata
#' @param day_of_week Character vector of weekday names when reporting
#' occurs (e.g., `"Wednesday"` or `c("Monday", "Wednesday")`).
#'
#' @return A `data.table` with columns:
#' * `.group`: Group identifier
#' * `date`: Reference date
#' * `report_date`: Report date
#' * `report`: Binary indicator (1 = reporting occurs, 0 = no reporting)
#'
#' @family modelmodulehelpers
#' @export
#' @examples
#' \dontrun{
#' pobs <- enw_preprocess_data(obs, max_delay = 30)
#'
#' # Wednesday-only reporting
#' enw_dayofweek_structural_reporting(
#'   pobs,
#'   day_of_week = "Wednesday"
#' )
#'
#' # Multiple reporting days
#' enw_dayofweek_structural_reporting(
#'   pobs,
#'   day_of_week = c("Monday", "Wednesday", "Friday")
#' )
#' }
enw_dayofweek_structural_reporting <- function(pobs, day_of_week) {
  metadata <- enw_structural_reporting_metadata(pobs)
  metadata[, day_of_week_col := weekdays(report_date)]
  metadata[, report := as.integer(day_of_week_col %in% day_of_week)]
  metadata[, day_of_week_col := NULL]

  metadata[, .(.group, date, report_date, report)]
}

# Build conditional ARIMA initial values for a module's prefix.
#
# Pulls the `<prefix>_arima_*` size and presence fields from `data`
# (as shipped by `enw_formula_as_data_list()`) and the
# `<prefix>_arima_sigma_p` (and optionally `<prefix>_arima_sd_sigma_p`)
# rows from the prior list. Returns a named list of initial values
# for any ARIMA parameters that are non-empty given the data; returns
# an empty list when no ARIMA term is present for this prefix.
#
# Used by `enw_expectation()`, `enw_reference()`, `enw_report()`, and
# `enw_missing()` to keep their `inits` functions short and to keep
# the per-module ARIMA boilerplate in one place.
# Standard description for an ARIMA partial-autocorrelation prior.
#
# The AR coefficients are parameterised through partial autocorrelations
# constrained to (-1, 1), which are Uniform by default. Supplying a
# positive standard deviation switches to a Normal(mean, sd) prior
# truncated to (-1, 1), shared across the AR order and any groups.
.arima_pacf_prior_description <- function(context) {
  paste0(
    "Partial autocorrelations of the ARIMA latent residual on the ",
    context, "; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) ",
    "truncated to (-1, 1)"
  )
}

#' @importFrom stats runif
.arima_inits <- function(data, priors, prefix, with_sd_sigma = FALSE) {
  z_nm <- paste0(prefix, "_arima_z")
  pacf_nm <- paste0(prefix, "_arima_pacf")
  theta_nm <- paste0(prefix, "_arima_theta")
  sigma_nm <- paste0(prefix, "_arima_sigma")
  sd_sigma_nm <- paste0(prefix, "_arima_sd_sigma")

  # Declare every vector-valued ARIMA parameter the module exposes with
  # an empty default, then fill in real inits below when the term is
  # present. This mirrors how the other module parameters are
  # initialised (the `numeric(0)` defaults in the module `inits`
  # functions) and stops cmdstanr warning about missing inits for them.
  #
  # `arima_z` is a matrix and is handled separately: an empty 0x0 matrix
  # cannot be represented in cmdstanr's JSON (it serialises to `[]`,
  # which Stan reads as dims (0) not (0, 0) and rejects at
  # initialisation), so it is only supplied when genuinely sized.
  init <- list()
  init[[pacf_nm]] <- numeric(0)
  init[[theta_nm]] <- numeric(0)
  init[[sigma_nm]] <- numeric(0)
  if (with_sd_sigma) {
    init[[sd_sigma_nm]] <- numeric(0)
  }

  pT <- data[[paste0(prefix, "_arima_T")]]
  pG <- data[[paste0(prefix, "_arima_G")]]
  pp <- data[[paste0(prefix, "_arima_p")]]
  pq <- data[[paste0(prefix, "_arima_q")]]
  ppresent <- data[[paste0(prefix, "_arima_present")]]
  if (isTRUE(pT > 0 && pG > 0)) {
    init[[z_nm]] <- matrix(rnorm(pT * pG, 0, 0.01), pT, pG)
  }
  if (isTRUE(pp > 0)) {
    init[[pacf_nm]] <- array(runif(pp, -0.1, 0.1))
  }
  if (isTRUE(pq > 0)) {
    init[[theta_nm]] <- array(rnorm(pq, 0, 0.01))
  }
  if (isTRUE(ppresent > 0)) {
    sp <- priors[[paste0(prefix, "_arima_sigma_p")]]
    init[[sigma_nm]] <- array(abs(rnorm(1, sp[1], sp[2] / 10)))
    # The sd-scale parameter is only sized 1 when the parametric sd is
    # modelled (`model_refp > 1`); otherwise it stays the empty default.
    if (with_sd_sigma && isTRUE(data$model_refp > 1)) {
      sd_p <- priors[[paste0(prefix, "_arima_sd_sigma_p")]]
      init[[sd_sigma_nm]] <- array(abs(rnorm(1, sd_p[1], sd_p[2] / 10)))
    }
  }
  init
}

# Standard descriptions for the Gaussian process hyperprior data. The
# length scale (rho) is modelled on the log scale (a log-normal prior)
# and the magnitude (alpha) with a half-normal, mirroring the EpiNow2
# GP defaults.
.gp_rho_prior_description <- function(context) {
  paste0(
    "Length scale of the Gaussian process on the ", context,
    "; log-normal prior on the (positive) length scale"
  )
}

.gp_alpha_prior_description <- function(context) {
  paste0(
    "Magnitude (marginal standard deviation) of the Gaussian process on ",
    "the ", context, "; half-normal prior"
  )
}

# Build conditional Gaussian process initial values for a module's
# prefix. Mirrors `.arima_inits()`: declares empty defaults for the
# spectral coefficients (`<prefix>_gp_eta`), length scale
# (`<prefix>_gp_rho`) and magnitude (`<prefix>_gp_alpha`), then fills
# them when the term is present and genuinely sized. When `with_sd_alpha`
# is `TRUE` (the parametric reference, which shares a GP between the mean
# and sd) the second magnitude `<prefix>_gp_sd_alpha` is also declared
# and filled when `model_refp > 1`, mirroring the ARIMA `sd_sigma`.
#' @importFrom stats rlnorm
.gp_inits <- function(data, priors, prefix, with_sd_alpha = FALSE) {
  eta_nm <- paste0(prefix, "_gp_eta")
  rho_nm <- paste0(prefix, "_gp_rho")
  alpha_nm <- paste0(prefix, "_gp_alpha")
  sd_alpha_nm <- paste0(prefix, "_gp_sd_alpha")

  # rho/alpha are length-1 arrays sized 0 when the term is absent, so an
  # empty default is safe. `gp_eta` is a matrix; like `arima_z` an empty
  # 0x0 matrix cannot round-trip through cmdstanr's JSON, so it is only
  # supplied when genuinely sized.
  init <- list()
  init[[rho_nm]] <- numeric(0)
  init[[alpha_nm]] <- numeric(0)
  if (with_sd_alpha) {
    init[[sd_alpha_nm]] <- numeric(0)
  }

  present <- data[[paste0(prefix, "_gp_present")]]
  if (!isTRUE(present > 0)) {
    return(init)
  }
  # Periodic kernels use 2M spectral coefficients (cos/sin pairs), the
  # others M. gp_type == 1 is the periodic kernel.
  m <- data[[paste0(prefix, "_gp_M")]]
  g <- data[[paste0(prefix, "_gp_G")]]
  n_eta <- if (isTRUE(data[[paste0(prefix, "_gp_type")]] == 1L)) 2L * m else m
  if (isTRUE(n_eta > 0 && g > 0)) {
    init[[eta_nm]] <- matrix(rnorm(n_eta * g, 0, 0.01), n_eta, g)
  }

  rho_p <- priors[[paste0(prefix, "_gp_rho_p")]]
  init[[rho_nm]] <- array(rlnorm(1, rho_p[1], rho_p[2] / 10))
  alpha_p <- priors[[paste0(prefix, "_gp_alpha_p")]]
  init[[alpha_nm]] <- array(abs(rnorm(1, alpha_p[1], alpha_p[2] / 10 + 1e-3)))
  if (with_sd_alpha && isTRUE(data$model_refp > 1)) {
    sd_alpha_p <- priors[[paste0(prefix, "_gp_sd_alpha_p")]]
    init[[sd_alpha_nm]] <- array(abs(
      rnorm(1, sd_alpha_p[1], sd_alpha_p[2] / 10 + 1e-3)
    ))
  }
  init
}
