#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @param target_date PARAM_DESCRIPTION, Default: 'reference_date'
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table
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

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param metaobs PARAM_DESCRIPTION
#' @param holidays_to A character string to assign to holidays when present.
#' Replaces the day of the week and defaults to Sunday.
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table
enw_add_metaobs_features <- function(metaobs, holidays_to = "Sunday") {
  # add days of week
  metaobs <- data.table::copy(metaobs)
  metaobs[, day_of_week := weekdays(date)]

  # make holidays be sundays
  if (!is.null(metaobs$holiday)) {
    metaobs[holidays == TRUE, day_of_week := holidays_to]
  }

  # make day of week a factor
  metaobs[, day_of_week := factor(day_of_week)]

  # add week feature
  metaobs[, week := lubridate::week(date)]
  metaobs[, week := week - min(week)]

  # add month feature
  metaobs[, month := lubridate::month(date)]
  metaobs[, month := month - min(month)]

  return(metaobs[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param metaobs PARAM_DESCRIPTION
#' @param max_delay PARAM_DESCRIPTION, Default: 20
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table copy data.table rbindlist setorderv
#' @importFrom purrr map
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

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @param by PARAM_DESCRIPTION, Default: c()
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table copy
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

#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param obs PARAM_DESCRIPTION
#'
#' @param rep_date PARAM_DESCRIPTION
#'
#' @param rep_days PARAM_DESCRIPTION
#'
#' @param ref_date PARAM_DESCRIPTION
#'
#' @param ref_days PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table copy
enw_retrospective_data <- function(obs, rep_date, rep_days, ref_date,
                                   ref_days) {
  retro_data <- data.table::copy(obs)
  if (!missing(rep_days)) {
    rep_date <- max(retro_data$report_date) - rep_days
  }
  retro_data <- retro_data[report_date <= rep_date]

  if (!missing(ref_days)) {
    ref_date <- max(retro_data$reference_date) - ref_days
  }
  retro_data <- retro_data[reference_date >= ref_date]
  return(retro_data[])
}

#' @title FUNCTION_TITLE
#'
#' @description FUNCTION_DESCRIPTION
#'
#' @param obs PARAM_DESCRIPTION
#'
#' @param ref_window PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table copy
enw_latest_data <- function(obs, ref_window) {
  latest_data <- data.table::copy(obs)

  latest_data <- latest_data[,
    .SD[report_date == (max(report_date))],
    by = c("reference_date")
  ]

  latest_data[, report_date := NULL]
  if (!missing(ref_window)) {
    latest_data <-
      latest_data[reference_date >= (max(reference_date) - ref_window[1])]
    if (length(ref_window) == 2) {
      latest_data <-
        latest_data[reference_date <= (max(reference_date) - ref_window[2])]
    }
  }
  return(latest_data[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @family preprocess
#' @export
#' @importFrom data.table copy shift
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

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table dcast setorderv
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

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table melt setorderv
enw_reporting_triangle_to_long <- function(obs) {
  reports_long <- data.table::melt(
    obs,
    id.vars = c("reference_date", "group"),
    variable.name = "delay", value.name = "new_confirm"
  )
  data.table::setorderv(reports_long, c("reference_date", "group"))
  return(reports_long[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#'
#' @param by PARAM_DESCRIPTION, Default: c()
#'
#' @param max_delay PARAM_DESCRIPTION, Default: 20
#'
#' @param min_report_date PARAM_DESCRIPTION
#'
#' @param set_negatives_to_zero PARAM_DESCRIPTION, Default: TRUE
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @inheritParams enw_add_metaobs_features
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table data.table
enw_preprocess_data <- function(obs, by = c(), max_delay = 20, holidays = c(),
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
  metareport <- enw_add_metaobs_features(metareport, holidays = holidays)

  # extract and add features for reference date
  metareference <- enw_metadata(obs, target_date = "reference_date")
  metareference <- enw_add_metaobs_features(metareference, holidays = holidays)

  out <- data.table::data.table(
    obs = list(obs),
    new_confirm = list(diff_obs),
    latest = list(latest),
    diff = list(diff_obs),
    reporting_triangle = list(reporting_triangle),
    metareference = list(metareference),
    metareport = list(metareport),
    time = nrow(latest[group == 1]),
    snapshots = nrow(unique(obs[, .(group, report_date)])),
    groups = length(unique(obs$group)),
    max_delay = max_delay,
    max_date = max(obs$report_date)
  )
  class(out) <- c("enw_preprocess_data", class(out))
  return(out[])
}
