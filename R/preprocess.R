enw_metadata <- function(obs, target_date = "reference_date") {
  choices <- c("reference_date", "report_date")
  target_date <- match.arg(target_date, choices)
  date_to_drop <- setdiff(choices, target_date)
  metaobs <- data.table::as.data.table(obs)
  metaobs[, c(date_to_drop, "confirm") := NULL]
  metaobs <- unique(metaobs)
  setnames(metaobs, target_date, "date")
  return(metaobs[])
}

enw_extend_date <- function(metaobs, max_delay = 20) {
  exts <- data.table::copy(metaobs)
  exts <- exts[, .SD[date == max(date)], by = group]
  exts <- split(exts, by = "group")
  exts <- purrr::map(
    exts,
    ~ data.table::data.table(
      extend_date = .$date + 1:(max_delay - 1),
      .
    )
  )
  exts <- data.table::rbindlist(exts)
  exts[, date := extend_date][, extend_date := NULL]
  exts[, observed := FALSE]

  exts <- rbind(
    data.table::copy(metaobs)[, observed := TRUE],
    exts[, observed := FALSE]
  )
  data.table::setorderv(exts, c("group", "date"))
  return(exts[])
}

enw_assign_group <- function(obs, by = c()) {
  obs <- data.table::as.data.table(obs)
  if (length(by) == 0) {
    obs <- obs[, group := 1]
  } else {
    groups_index <- data.table::copy(obs)
    groups_index <- unique(groups_index[, ..by])
    groups_index[, group := 1:.N]
    obs <- merge(obs, groups_index, by = by, all.x = TRUE)
  }
  return(obs = obs[])
}

enw_latest_data <- function(obs) {
  latest_data <- data.table::copy(obs)[,
    .SD[report_date == max(report_date)],
    by = c("reference_date", "group")
  ]
  latest_data[, report_date := NULL]
  return(latest_data[])
}

enw_new_reports <- function(obs) {
  reports <- data.table::copy(obs)
  reports <- reports[order(reference_date)]
  reports[, new_confirm := confirm - data.table::shift(confirm, fill = 0),
    by = c("reference_date", "group")
  ]
  reports <- reports[, .SD[reference_date >= min(report_date)],
    by = c("group")
  ]
  reports <- reports[, delay := 0:(.N - 1), by = c("reference_date", "group")]
  return(reports[])
}

enw_reporting_triangle <- function(obs) {
  obs <- data.table::as.data.table(obs)
  if (any(obs$new_confirm < 0)) {
    stop("Negative new confirmed cases found. This is not yet supported.")
  }
  reports <- data.table::dcast(
    obs, group + reference_date ~ delay,
    value.var = "new_confirm", fill = 0
  )
  data.table::setorderv(reports, c("reference_date", "group"))
  return(reports[])
}

enw_reporting_triangle_to_long <- function(obs) {
  reports_long <- data.table::melt(
    obs,
    id.vars = c("reference_date", "group"),
    variable.name = "delay", value.name = "new_confirm"
  )
  data.table::setorderv(reports_long, c("reference_date", "group"))
  return(reports_long[])
}

enw_preprocess_data <- function(obs, by = c(), max_delay = 20,
                                min_report_date, set_negatives_to_zero = TRUE) {
  obs <- data.table::as.data.table(obs)
  obs <- obs[order(reference_date)]

  if (!missing(min_report_date)) {
    obs <- obs[report_date >= min_report_date]
  }

  # assign groups
  obs <- enw_assign_group(obs, by = by)

  # filter by maximum report date
  obs <- obs[, .SD[report_date <= (reference_date + max_delay - 1)],
    by = c("reference_date", "group")
  ]

  # difference reports and filter for max delay an report date
  diff_obs <- enw_new_reports(obs)

  if (set_negatives_to_zero) {
    diff_obs <- diff_obs[new_confirm < 0, new_confirm := 0]
  }

  # filter obs based on diff constraints
  obs <- merge(obs, diff_obs[, .(reference_date, report_date, group)],
    by = c("reference_date", "report_date", "group")
  )

  # update grouping in case any are now missing
  setnames(obs, "group", "old_group")
  obs <- enw_assign_group(obs, by)

  # update diff data groups using updated groups
  diff_obs <- merge(
    diff_obs,
    obs[, .(reference_date, report_date, new_group = group, group = old_group)],
    by = c("reference_date", "report_date", "group")
  )
  diff_obs[, group := new_group][, new_group := NULL]
  obs[, old_group := NULL]

  # calculate reporting matrix
  reporting_triangle <- enw_reporting_triangle(diff_obs)

  # extract latest data
  latest <- enw_latest_data(obs)

  # extract and extend report date meta data to include unobserved reports
  metareport <- enw_metadata(obs, target_date = "report_date")
  metareport <- enw_extend_date(metareport, max_delay = max_delay)

  out <- data.table::data.table(
    obs = list(obs),
    new_confirm = list(diff_obs),
    latest = list(latest),
    reporting_triangle = list(reporting_triangle),
    metareference = list(enw_metadata(obs)),
    metareport = list(metareport),
    time = nrow(latest[group == 1]),
    snapshots = nrow(unique(obs[, .(group, report_date)])),
    groups = length(unique(obs$group)),
    max_delay = max_delay,
    max_date = max(obs$report_date)
  )
  return(out[])
}
