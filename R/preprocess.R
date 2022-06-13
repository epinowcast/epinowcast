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
  metaobs <- metaobs[, .SD[1, ], by = c("date", "group")]
  return(metaobs[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param metaobs PARAM_DESCRIPTION
#' @param holidays PARAM_DESCRIPTION
#' @param holidays_to A character string to assign to holidays when present.
#' Replaces the day of the week and defaults to Sunday.
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table
enw_add_metaobs_features <- function(metaobs, holidays = c(),
                                     holidays_to = "Sunday") {
  # add days of week
  metaobs <- data.table::copy(metaobs)
  metaobs[, day_of_week := weekdays(date)]

  # make holidays be Sundays
  if (length(holidays) != 0) {
    metaobs[get(holidays) == TRUE, day_of_week := holidays_to]
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
  if ("group" %in% names(obs)) {
    stop("Dataset cannot have a column called 'group'.")
  }
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
#' @importFrom data.table copy as.IDate
enw_retrospective_data <- function(obs, rep_date, rep_days, ref_date,
                                   ref_days) {
  retro_data <- data.table::copy(obs)
  retro_data[, report_date := as.IDate(report_date)]
  retro_data[, reference_date := as.IDate(reference_date)]
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
#' @importFrom data.table copy as.IDate
enw_latest_data <- function(obs, ref_window) {
  latest_data <- data.table::copy(obs)
  latest_data[, report_date := as.IDate(report_date)]
  latest_data[, reference_date := as.IDate(reference_date)]

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
  reports <- reports[, .SD[reference_date >= min(report_date) | is.na(reference_date)],
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
#' @param ref_holidays DESCRIPTION
#'
#' @param rep_holidays DESCRIPTION
#'
#' @param min_report_date PARAM_DESCRIPTION
#'
#' @param set_negatives_to_zero PARAM_DESCRIPTION, Default: TRUE
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table data.table
enw_preprocess_data <- function(obs, by = c(), max_delay = 20,
                                rep_holidays = c(), ref_holidays = c(),
                                min_report_date, set_negatives_to_zero = TRUE) {
  obs <- data.table::as.data.table(obs)
  obs <- obs[order(reference_date)]

  if (!missing(min_report_date)) {
    obs <- obs[report_date >= min_report_date]
  }

  # assign groups
  obs <- enw_assign_group(obs, by = by)
  
  # complete missing report dates
  comp <- rbind(
    obs[!is.na(reference_date)][rep(1:.N,each=max_delay), .(report_date = reference_date + 0:(.N - 1)), by = c("reference_date", "group")],
    CJ(reference_date = as.Date(NA), group = unique(obs[,group]), report_date = obs[,seq.Date(pmin(min(report_date,na.rm=T),min(reference_date,na.rm=T)),
                                                                                              pmin(max(report_date,na.rm=T),max(reference_date,na.rm=T)),by=1)])
  )
  grouping_factors <- obs[, lapply(.SD, min, na.rm = TRUE), .SDcols = by, by = "group"]
  comp <- comp[grouping_factors, on = "group"]
  obs <- obs[comp, on = c("reference_date", "group", "report_date", by)]
  obs[, confirm:=nafill(nafill(confirm, "locf"), fill = 0), by = c("reference_date", "group")]
  
  # filter by maximum report date
  obs <- obs[, .SD[report_date <= (reference_date + max_delay - 1) | is.na(reference_date)],
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
  
  # separate obs with and without missing reference date
  reporting_available <- diff_obs[!is.na(reference_date)]
  reporting_missing <- diff_obs[is.na(reference_date)]

  # calculate reporting matrix on obs with available reference date
  reporting_triangle <- enw_reporting_triangle(reporting_available)

  # extract latest data
  # Note: currently, only the obs with available reference date are used
  # This should to be extended to missing reference dates to avoid bias
  latest <- enw_latest_data(reporting_available)

  # extract and extend report date meta data to include unobserved reports
  metareport <- enw_metadata(reporting_available, target_date = "report_date")
  metareport <- enw_extend_date(metareport, max_delay = max_delay)
  metareport <- enw_add_metaobs_features(metareport, holidays = rep_holidays)

  # extract and add features for reference date
  metareference <- enw_metadata(reporting_available, target_date = "reference_date")
  metareference <- enw_add_metaobs_features(
    metareference,
    holidays = ref_holidays
  )

  out <- data.table::data.table(
    obs = list(obs),
    new_confirm = list(reporting_available),
    new_confirm_missing = list(reporting_missing),
    latest = list(latest),
    diff = list(reporting_available),
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
