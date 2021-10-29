enw_default_design <- function(design, rows) {
  if (is.null(design[[1]])) {
    design[[1]] <- matrix(1, nrow = rows, ncol = 1)
    neffs <- 0
  } else {
    neffs <- ncol(design)
  }
  if (is.null(design_sd)) {
    design_sd <- matrix(1, nrow = neffs, ncol = 1)
    neff_sds <- 0
  } else {
    neff_sds <- ncol(design_sd) - 1
  }
  stopifnot(
    "Number of design matrix columns must equal design_sd rows" = neffs == nrow(design_sd) # nolint
  )
}

enw_stan_data <- function(pobs,
                          reference_effects = enw_intercept_model(
                            pobs$metareference[[1]]
                          ),
                          report_effects = enw_intercept_model(
                            pobs$metareport[[1]]
                          ),
                          dist = "lognormal",
                          likelihood = TRUE, debug = FALSE,
                          nowcast = TRUE, pp = FALSE) {
  if (pp) {
    nowcast <- TRUE
  }
  # check dist type is supported and change to numeric
  dist <- match.arg(dist, c("lognormal", "gamma"))
  dist <- data.table::fcase(
    dist %in% "lognormal", 0,
    dist %in% "gamma", 1
  )
  # format latest matrix
  latest_matrix <- pobs$latest[[1]]
  latest_matrix <- data.table::dcast(
    latest_matrix, reference_date ~ group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])

  # format vector of snapshot lengths
  snap_length <- pobs$new_confirm[[1]]
  snap_length <- snap_length[, .SD[delay == max(delay)],
    by = c("reference_date", "group")
  ]
  snap_length <- snap_length$delay + 1

  # snap lookup
  snap_lookup <- unique(pobs$new_confirm[[1]][, .(reference_date, group)])
  snap_lookup[, s := 1:.N]
  snap_lookup <- data.table::dcast(
    snap_lookup, reference_date ~ group,
    value.var = "s"
  )
  snap_lookup <- as.matrix(snap_lookup[, -1])

  # snap time
  snap_time <- unique(pobs$new_confirm[[1]][, .(reference_date, group)])
  snap_time[, t := 1:.N, by = "group"]
  snap_time <- snap_time$t

  # Format indexing and observed data
  # See stan code for docs on what all of these are
  data <- list(
    t = pobs$time[[1]],
    s = pobs$snapshots[[1]],
    g = pobs$groups[[1]],
    st = snap_time,
    ts = snap_lookup,
    sl = snap_length,
    sg = unique(pobs$new_confirm[[1]][, .(reference_date, group)])$group,
    dmax = pobs$max_delay[[1]],
    obs = as.matrix(pobs$reporting_triangle[[1]][, -c(1:2)]),
    latest_obs = latest_matrix
  )

  # Add reference date data
  data <- c(data, list(
    npmfs = nrow(reference_effects$fixed$design),
    dpmfs = reference_effects$fixed$index,
    neffs = ncol(reference_effects$fixed$design) - 1,
    d_fixed = reference_effects$fixed$design,
    neff_sds = ncol(reference_effects$random$design) - 1,
    d_random = reference_effects$random$design
  ))

  # map report date effects to groups and days
  report_date_eff_ind <- matrix(
    report_effects$fixed$index,
    ncol = data$g, nrow = data$t + data$dmax - 1
  )

  # Add report date data
  data <- c(data, list(
    rd = data$t + data$dmax - 1,
    urds = nrow(report_effects$fixed$design),
    rdlurd = report_date_eff_ind,
    nrd_effs = ncol(report_effects$fixed$design) - 1,
    rd_fixed = report_effects$fixed$design,
    nrd_eff_sds = ncol(report_effects$random$design) - 1,
    rd_random = report_effects$random$design
  ))

  # Add model options
  data <- c(data, list(
    dist = dist,
    debug = as.numeric(debug),
    likelihood = as.numeric(likelihood),
    pp = as.numeric(pp),
    cast = as.numeric(nowcast)
  ))
  return(data)
}

enw_inits <- function(data) {
  init_fn <- function() {
    init <- list(
      logmean_int = rnorm(1, 1, 0.1),
      logsd_int = abs(rnorm(1, 0.5, 0.1)),
      eobs_lsd = array(abs(rnorm(data$g, 0, 0.1))),
      sqrt_phi = abs(rnorm(1, 0, 0.1))
    )
    init$logmean <- rep(init$logmean_int, data$npmfs)
    init$logsd <- rep(init$logsd_int, data$npmfs)
    init$phi <- 1 / sqrt(init$sqrt_phi)
    # initialise reference date effects
    if (data$neffs > 0) {
      init$logmean_eff <- rnorm(data$neffs, 0, 0.01)
      init$logsd_eff <- rnorm(data$neffs, 0, 0.01)
    }
    if (data$neffs > 0) {
      init$logmean_eff <- rnorm(data$neffs, 0, 0.01)
      init$logsd_eff <- rnorm(data$neffs, 0, 0.01)
    }
    # initialise report date effects
    if (data$nrd_effs > 0) {
      init$rd_eff <- rnorm(data$nrd_effs, 0, 0.01)
    }
    return(init)
  }
  return(init_fn)
}
