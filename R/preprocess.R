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

  # make holidays be sundays
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
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table copy
enw_add_delay <- function(obs) {
  obs <- data.table::as.data.table(obs)
  obs[, report_date := as.IDate(report_date)]
  obs[, reference_date := as.IDate(reference_date)]
  obs[, delay := as.numeric(report_date - reference_date)]
  return(obs = obs[])
}

#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param obs PARAM_DESCRIPTION
#'
#' @return OUTPUT_DESCRIPTION
#'
#' @family preprocess
#' @export
#' @importFrom data.table copy
enw_add_max_reported <- function(obs) {
  obs <- data.table::copy(obs)
  orig_latest <- enw_latest_data(obs)
  orig_latest <- orig_latest[
    ,
    .(reference_date, group, max_confirm = confirm)
  ]
  obs <- obs[orig_latest, on = c("reference_date", "group")]
  obs[, cum_prop_reported := confirm / max_confirm]
  return(obs[])
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

#' Filter observations to the latest available
#'
#' @param obs A data frame containing at least the following variables:
#' `reference date` (index date of interest), and `report_date` (report date for
#' observations).
#'
#' @param ref_window Numeric vector of length 2. Can optionally be used to
#' restrict the reference date to a window referenced to the maximum available
#' reference date.
#'
#' @return A filtered data frame with the same variables as `obs`.
#' @family preprocess
#' @export
#' @importFrom data.table copy as.IDate
#' @examples
#' # Filter for latest available data
#' enw_latest_data(germany_covid19_hosp)
#'
#' # Restrict to a window of 40 days ignoring the most recent 10 days
#' enw_latest_data(germany_covid19_hosp, c(50, 10))
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

#' Calculate incidence of new reports from cumulative reports
#'
#' @param obs A data frame containing at least the following variables:
#' `reference date` (index date of interest), `report_date` (report date for
#' observations), `confirm` (cumulative observations by reference and report
#' date), and `group` (as added by [enw_assign_group()]).
#'
#' @param set_negatives_to_zero Logical, defaults to TRUE. Should negative
#' counts (for calculated incidence of observations) be set to zero. Currently
#' downstream modelling does not support negative counts and so setting must be
#' TRUE if intending to use [epinowcast()].
#'
#' @return The input data frame with a new variable `new_confirm`. If
#' `max_confirm` was present in the data frame then the proportion
#' reported on each day (`prop_reported`) is also added.
#' @family preprocess
#' @export
#' @importFrom data.table copy shift
#' @examples
#' # Default reconstruct incidence
#' dt <- enw_assign_group(
#'   germany_covid19_hosp[location == "DE"],
#'   by = "age_group"
#' )
#' enw_new_reports(dt)
#'
#' # Make use of maximum reported to calculate empirical daily reporting
#' dt <- enw_add_max_reported(dt)
#' enw_new_reports(dt)
enw_new_reports <- function(obs, set_negatives_to_zero = TRUE) {
  reports <- data.table::copy(obs)
  reports <- reports[order(reference_date)]
  reports[, new_confirm := confirm - data.table::shift(confirm, fill = 0),
    by = c("reference_date", "group")
  ]
  reports <- reports[, .SD[reference_date >= min(report_date)],
    by = c("group")
  ]
  reports <- reports[, delay := 0:(.N - 1), by = c("reference_date", "group")]

  if (!is.null(reports$max_confirm)) {
    reports[, prop_reported := new_confirm / max_confirm]
  }

  if (set_negatives_to_zero) {
    reports <- reports[new_confirm < 0, new_confirm := 0]
  }
  return(reports[])
}

#' Filter observations to retrict the maximum reporting delay
#'
#' @return A data frame filtered so that dates by report are less than or equal
#' the reference date plus the maximum delay.
#'
#' @inheritParams enw_new_reports
#' @inheritParams enw_preprocess_data
#' @family preprocess
#' @export
#' @importFrom data.table copy
#' @examples
#' obs <- enw_example("preprocessed")$obs[[1]]
#' enw_filter_obs(obs, max_delay = 2)
enw_filter_obs <- function(obs, max_delay) {
  obs <- data.table::copy(obs)
  obs <- obs[, .SD[report_date <= (reference_date + max_delay - 1)],
    by = c("reference_date", "group")
  ]
  return(obs[])
}

#' Construct the reporting triangle
#'
#' Constructs the reporting triangle with each row representing a reference date
#' and columns being observations by report date
#'
#' @param obs A data frame as produced by [enw_new_reports()]. Must contain the
#' following variables: `reference_date`, `group`, `delay`.
#'
#' @return A data frame with each row being a reference date, and columns being
#' observations by reporting delay.
#' @family preprocess
#' @export
#' @importFrom data.table as.data.table dcast setorderv
#' @examples
#' obs <- enw_example("preprocessed")$new_confirm
#' enw_reporting_triangle(obs)
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

#' Recast the reporting triangle from wide to long format
#'
#' @param obs A dataframe in the format produced by [enw_reporting_triangle()].
#'
#' @return A long format reporting triangle as a data frame with additional
#' variables `new_confirm` and `delay`.
#' @family preprocess
#' @export
#' @importFrom data.table melt setorderv
#' @examples
#' obs <- enw_example("preprocessed")$new_confirm
#' rt <- enw_reporting_triangle(obs)
#' enw_reporting_triangle_to_long(rt)
enw_reporting_triangle_to_long <- function(obs) {
  reports_long <- data.table::melt(
    obs,
    id.vars = c("reference_date", "group"),
    variable.name = "delay", value.name = "new_confirm"
  )
  data.table::setorderv(reports_long, c("reference_date", "group"))
  return(reports_long[])
}

#' Construct preprocessed data
#'
#' This function is used internally by [enw_preprocess_data()] to combine
#' various pieces of processed observed data into a single object. It
#' is exposed to the user in order to allow for modular data preprocessing
#' though this is not currently recommended. See documentation and code 
#' of [enw_preprocess_data()] for more on the expected inputs.
#'
#' @param obs Observations with the addition of empirical reporting proportions
#'  and and restricted to the specified maximum delay).
#' 
#' @param new_confirm`: Incidence of notifications by reference and report date.
#' Empirical reporting distributions are also added.
#' 
#' @param latest`: The latest available observations.
#' 
#' @param reporting_triangle`: Incident observations by report and reference
#'  date in the standard reporting triangle matrix format.
#' 
#' @param metareference`: Metadata reference dates derived from observations.
#' 
#' @param metrareport`: Metadata for report dates.
#
#' @inheritParams enw_preprocess_data
#' @inherit enw_preprocess_data return
#' @export
#' @examples
#' pobs <- enw_example("preprocessed")
#' enw_construct_data(
#'  obs = pobs$obs[[1]],
#'  new_confirm = pobs$new_confirm[[1]],
#'  latest = pobs$latest[[1]],
#'  reporting_triangle = pobs$reporting_triangle[[1]],
#'  metareport = pobs$metareport[[1]],
#'  metareference = pobs$metareference[[1]],
#'  max_delay = pobs$max_delay[[1]]
#' )
enw_construct_data <- function(obs, new_confirm, latest, reporting_triangle,
                               metareport, metareference, max_delay) {
    out <- data.table::data.table(
      obs = list(obs),
      new_confirm = list(new_confirm),
      latest = list(latest),
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


#' Preprocess observations
#'
#' This function preprocesses raw observations under the
#' assumption they are reported as cumulative counts by a reference and
#' report date and is used to assign groups. It also constructs data objects
#' used by downstreaming visualisation and modelling functions including the
#' observed empirical probability of a report on a given day, the cumulative
#' probability of report, the latest available observations, incidence of
#' observations, and metadata about the date of reference and report (used to
#' construct models). This function wraps other preprocessing functions that may
#' be instead used individually if required.
#'
#' @param obs A data frame containing at least the following variables:
#' `reference date` (index date of interest), `report_date` (report date for
#' observations), `confirm` (cumulative observations by reference and report
#' date).
#'
#' @param by A character vector describing the stratification of
#' observations. This defaults to no grouping. This should be used
#' when modelling multiple time series in order to identify them for
#' downstream modelling
#'
#' @param max_delay Numeric defaults to 20. The maximum number of days to
#' include in the delay distribution. Computation scales non-linearly with this
#' setting so consider what maximum makes sense for your data carefully.
#'
#' @param max_delay_strat Character string indicating how to handle
#' reported cases beyond the specified maximum delay. Options include:
#' excluding ("exclude") and adding to the maximum delay ("add_to_max_delay").
#' Adding to the maximum delay is the default. Compare `confirm`, `max_confirm`,
#' `prop_reported` columns to understand the impact of this assumption.
#'
#' @param holidays A vector of dates indicating when holidays occur used by
#' [enw_add_metaobs_features()] to treate holidays as sundays within the
#' `day_of_week` variable it creates internally.
#'
#' @return A data.table containing processed observations as a series of nested
#' data frames as well as variables containing metadata. These are:
#'  - `obs`: (observations with the addition of empirical reporting proportions
#'  and and restricted to the specified maximum delay).
#' - `new_confirm`: Incidence of notifications by reference and report date.
#' Empirical reporting distributions are also added.
#' - `latest`: The latest available observations.
#' - `reporting_triangle`: Incident observations by report and reference date in
#' the standard reporting triangle matrix format.
#' - `metareference`: Metadata reference dates derived from observations.
#' - `metrareport`: Metadata for report dates.
#' - `time`: Numeric, number of timepoints in the data.
#' - `snapshots`: Numeric, nnumber of available data snapshots to use for
#'  nowcasting.
#' - `groups`: Numeric, Number of groups/strata in the supplied observations
#'  (set using `by`).
#' - `max_delay`: Numeric, the maximum delay in the processed data
#' - `max_date`: The maximum available report date.
#'
#' @family preprocess
#' @inheritParams enw_new_reports
#' @export
#' @importFrom data.table as.data.table data.table
#' @examples
#' library(data.table)
#'
#' # Filter example hospitalisation data to be natioanl and over all ages
#' nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
#' nat_germany_hosp <- nat_germany_hosp[age_group %in% "00+"]
#'
#' # Preprocess with default settings
#' pobs <- enw_preprocess_data(nat_germany_hosp)
#' pobs
#'
#' # Preprocess using exclusion beyond the maximum delay and a max delay of 10
#' pobs_exclude <- enw_preprocess_data(
#'   nat_germany_hosp,
#'   max_delay = 10, max_delay_strat = "exclude"
#' )
#' pobs_exclude
#'
#' # Preprocess all data
#' pobs_all <- enw_preprocess_data(
#'   germany_covid19_hosp,
#'   by = c("location", "age_group")
#' )
#' pobs_all
enw_preprocess_data <- function(obs, by = c(), max_delay = 20,
                                max_delay_strat = "add_to_max_delay",
                                holidays = c(), set_negatives_to_zero = TRUE) {
  max_delay_strat <- match.arg(
    max_delay_strat, choices = c("exclude", "add_to_max_delay")
  )
  obs <- data.table::as.data.table(obs)
  obs <- obs[order(reference_date)]

  obs <- enw_assign_group(obs, by = by)
  obs <- enw_add_max_reported(obs)
  obs <- enw_add_delay(obs)

  if (max_delay_strat %in% "add_to_max_delay") {
    obs[
      report_date == (reference_date + max_delay - 1),
      confirm := max_confirm,
      by = "group"
    ]
  }

  obs <- enw_filter_obs(obs, max_delay = max_delay)

  diff_obs <- enw_new_reports(
    obs, set_negatives_to_zero = set_negatives_to_zero
  )

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

  reporting_triangle <- enw_reporting_triangle(diff_obs)

  latest <- enw_latest_data(obs)

  # extract and extend report date meta data to include unobserved reports
  metareport <- enw_metadata(obs, target_date = "report_date")
  metareport <- enw_extend_date(metareport, max_delay = max_delay)
  metareport <- enw_add_metaobs_features(metareport, holidays = holidays)

  # extract and add features for reference date
  metareference <- enw_metadata(obs, target_date = "reference_date")
  metareference <- enw_add_metaobs_features(metareference, holidays = holidays)

  out <- enw_construct_data(
    obs = obs,
    new_confirm = new_confirm,
    latest = latest,
    reporting_triangle = reporting_triangle,
    metareference = metareference,
    metareport = metareport,
    max_delay = max_delay
  )

  return(out[])
}
