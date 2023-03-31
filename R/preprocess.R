#' @title Extract metadata from raw data
#'
#' @description Extract metadata from raw data, either
#' by reference or by report date. For the target date chosen
#' (reference or report), `confirm`, `max_confirm``, and `cum_prop_reported`
#' are dropped and the first observation for each group and date is retained.
#'
#' @param obs A `data.frame` or `data.table` with columns: `reference_date`
#' and/or `report_date`; at least one must be provided, `.group`, a grouping
#' column and a `date`, a [Date] column.
#'
#' @param target_date A character string, either "reference_date" or
#' "report_date". The column corresponding to this string will be used
#' as the target date for metadata extraction.
#'
#' @return A data.table with columns:
#' * `date`, a [Date] column
#' * `.group`, a grouping column
#'
#' and the first observation for each group and date.
#' The data.table is sorted by `.group` and `date`.
#'
#' @family preprocess
#' @importFrom data.table setkeyv setnames
#' @export
#' @examples
#' obs <- data.frame(
#'  reference_date = as.Date("2021-01-01"),
#'  report_date = as.Date("2022-01-01"), x = 1:10
#' )
#' enw_metadata(obs, target_date = "reference_date")
enw_metadata <- function(obs, target_date = c(
                           "reference_date", "report_date"
                         )) {
  choices <- eval(formals()$target_date)
  target_date <- match.arg(target_date)
  date_to_drop <- setdiff(choices, target_date)

  metaobs <- data.table::setnames(
    coerce_dt(obs, required_cols = target_date, group = TRUE),
    target_date, "date"
  )

  suppressWarnings(
    metaobs[
      ,
      c(date_to_drop, "confirm", "max_confirm", "cum_prop_reported") := NULL
    ]
  )
  metaobs <- metaobs[, .SD[1, ], by = c("date", ".group")]
  data.table::setkeyv(metaobs, c(".group", "date"))
  return(metaobs[])
}

#' @title Add common metadata variables
#'
#' @description If not already present, annotates time series data with metadata
#' commonly used in models: day of week, and days, weeks, and months since start
#' of time series.
#'
#' @param metaobs Raw data, coercible via [data.table::as.data.table()].
#' Coerced object must have [Dates] column corresponding to `datecol` name.
#'
#' @param holidays a (potentially empty) vector of dates (or input
#' coercible to such; see [coerce_date()]). The `day_of_week` column will be
#' set to `holidays_to` for these dates.
#'
#' @param holidays_to A character string to assign to holidays, when `holidays`
#' argument non-empty. Replaces the `day_of_week` column value
#'
#' @param datecol The column in `metaobs` corresponding to pertinent dates.
#'
#' @details Effects models often need to include covariates for time-based
#' features, such as day of the week (e.g. to reflect different care-seeking
#' and/or reporting behaviour).
#'
#' This function is called from within [enw_preprocess_data()] to systematically
#' annotate `metaobs` with these commonly used metadata, if not already present.
#'
#' However, it can also be used directly on other data.
#'
#' @return A copy of the `metaobs` input, with additional columns:
#'  * `day_of_week`, a factor of values as output from [weekdays()] and
#'  possibly as `holiday_to` if distinct from weekdays values
#'  * `day`, numeric, 0 based from start of time series
#'  * `week`, numeric, 0 based from start of time series
#'  * `month`, numeric, 0 based from start of time series
#'
#' @family preprocess
#' @importFrom purrr compose
#' @export
#' @examples
#'
#' # make some example date
#' nat_germany_hosp <- subset(
#'   germany_covid19_hosp,
#'   location == "DE" & age_group == "80+"
#' )[1:40]
#'
#' basemeta <- enw_add_metaobs_features(
#'   nat_germany_hosp,
#'   datecol = "report_date"
#' )
#' basemeta
#'
#' # with holidays - n.b.: holidays not found are silently ignored
#' holidaymeta <- enw_add_metaobs_features(
#'   nat_germany_hosp,
#'   datecol = "report_date",
#'   holidays = c(
#'     "2021-04-04", "2021-04-05",
#'     "2021-05-01", "2021-05-13",
#'     "2021-05-24"
#'   ),
#'   holidays_to = "Holiday"
#' )
#' holidaymeta
#' subset(holidaymeta, day_of_week == "Holiday")
enw_add_metaobs_features <- function(metaobs,
                                     holidays = NULL,
                                     holidays_to = "Sunday",
                                     datecol = "date") {
  # localize and check metaobs input
  metaobs <- coerce_dt(metaobs, required_cols = datecol)
  if (!is.Date(metaobs[[datecol]])) {
    stop(sprintf("metaobs column '%s' is not a Date.", datecol))
  }

  # this may also error, so coercing first
  holidays <- coerce_date(holidays)

  # warn about columns that may be overwritten
  tarcols <- c("day_of_week", "day", "week", "month")
  if (any(tarcols %in% colnames(metaobs))) {
    warning(sprintf(
      "Pre-existing columns in `metaobs` will be overwritten: {%s}.",
      intersect(tarcols, colnames(metaobs))
    ))
  }
  # sort by current sorting and datacol
  data.table::setkeyv(metaobs, union(data.table::key(metaobs), datecol))

  # function to transform numbers to be referenced from 0
  zerobase <- function(x) {
    return(x - min(x))
  }
  # function to transform by weeks
  to0week <- function(x) {
    return(x %/% 7L)
  }
  # function to count months from series start
  toevermonths <- function(d) {
    m <- data.table::month(d)
    y <- zerobase(data.table::year(d))
    return(m + 12 * y)
  }

  # functions to extract date indices; defined as
  # series of transformations applied (right to left)
  # then purrr::compose'd
  funs <- lapply(list(
    day_of_week = list(
      factor,
      function(d) {
        data.table::fifelse(
          d %in% holidays,
          yes = holidays_to, no = weekdays(d)
        )
      }
    ),
    day = list(zerobase, as.numeric),
    week = list(to0week, zerobase, as.numeric),
    month = list(zerobase, toevermonths)
  ), function(fns) {
    purrr::compose(!!!fns)
  })

  # current implementation: this is always true. if we later
  # determine that e.g. we want to optionally overwrite columns
  # then this logic will become useful
  if (length(tarcols)) {
    # pick out transforms associated with those columns
    xforms <- funs[tarcols]

    # add tarcol features
    metaobs[, c(tarcols) := lapply(xforms, do.call, .(get(datecol)))]
  }

  return(metaobs[])
}

#' @title Extend a time series with additional dates
#'
#' @description Extend a time series with additional dates. This is useful
#' when extending the report dates of a time series to include future dates
#' for nowcasting purposes or to include additional dates for backcasting
#' when using a renewal process as the expectation model.
#'
#' @param metaobs A `data.frame` with a `date` column.
#'
#' @param days Number of days to add to the time series. Defaults to 20.
#'
#' @param direction Should new dates be added at the beginning or end of
#' the data. Default is "end" with "start" also available.
#'
#' @return A data.table with the same columns as `metaobs` but with
#' additional rows for each date in the range of `date` to `date + days`
#' (or `date - days` if `direction = "start"`). An additional variable
#' observed is added with a value of FALSE for all new dates and TRUE
#' for all existing dates.
#'
#' @family preprocess
#' @export
#' @importFrom data.table data.table rbindlist setkeyv
#' @importFrom purrr map
#' @examples
#' metaobs <- data.frame(date = as.Date("2021-01-01") + 0:4)
#' enw_extend_date(metaobs, days = 2)
#' enw_extend_date(metaobs, days = 2, direction = "start")
enw_extend_date <- function(metaobs, days = 20, direction = c("end", "start")) {
  direction <- match.arg(direction)

  new_days <- 1:days
  if (direction %in% "start") {
    new_days <- -new_days
    filt_fn <- min
  } else {
    filt_fn <- max
  }
  metaobs <- coerce_dt(metaobs, group = TRUE)
  exts <- metaobs[, .SD[date == filt_fn(date)], by = .group]
  exts <- split(exts, by = ".group")
  exts <- purrr::map(
    exts,
    ~ data.table::data.table(
      extend_date = .$date + new_days,
      .
    )
  )
  exts <- data.table::rbindlist(exts)
  exts[, date := extend_date][, extend_date := NULL]

  exts <- rbind(
    metaobs[, observed := TRUE],
    exts[, observed := FALSE]
  )
  data.table::setkeyv(exts, c(".group", "date"))
  return(exts[])
}

#' @title Assign a group to each row of a data.table
#'
#' @description Assign a group to each row of a data.table. If `by` is
#' specified, then each unique combination of the columns in `by` will
#' be assigned a unique group. If `by` is not specified, then all rows
#' will be assigned to the same group.
#'
#' @param obs A `data.table` or `data.frame` without a `.group` column.
#'
#' @param by A character vector of column names to group by. Defaults to
#' an empty vector.
#'
#' @param copy A logical; make a copy (default) of `obs` or modify it in
#' place?
#'
#' @return A `data.table` with a `.group` column added ordered by `.group`
#' and the existing key of `obs`.
#'
#' @family preprocess
#' @export
#' @examples
#' obs <- data.frame(x = 1:3, y = 1:3)
#' enw_assign_group(obs)
#' enw_assign_group(obs, by = "x")
enw_assign_group <- function(obs, by = NULL, copy = TRUE) {
  obs <- coerce_dt( # must have by (if present), cannot initially have .group
    obs, required_cols = by, forbidden_cols = ".group",
    group = (length(by) == 0), # ... but should add .group, if by is empty
    copy = copy
  )
  if (length(by) != 0) {       # if by is not empty, add more complex .group
    obs[, .group := .GRP, by = by]
  }
  # update or set key to include .group
  data.table::setkeyv(obs, union(".group", data.table::key(obs)))
  return(obs[])
}

#' @title Add a delay variable
#'
#' @description Add a delay variable based on the numeric difference
#' between the `report_date` and `reference_date` columns.
#'
#' @return A data.table with a `delay` column added.
#'
#' @inheritParams enw_add_incidence
#' @family preprocess
#' @export
#' @examples
#' obs <- data.frame(report_date = as.Date("2021-01-01") + -2:0)
#' obs$reference_date <- as.Date("2021-01-01")
#' enw_add_delay(obs)
enw_add_delay <- function(obs, copy = TRUE) {
  obs <- coerce_dt(obs, dates = TRUE, copy = copy)
  obs[, delay := as.numeric(report_date - reference_date)]
  return(obs[])
}

#' @title Add the maximum number of reported cases for each reference_date
#'
#' @description This is a helper function which adds the maximum (in the sense
#' of latest observed) number of reported cases for each reference_date and
#' computes the proportion of already reported cases for each combination of
#' reference_date and report_date.
#'
#' @return A data.table with a `max_confirm` and `cum_prop_reported`
#' columns added. `max_confirm` is the maximum number of cases reported
#' on a given day. `cum_prop_reported` is the proportion of cases
#' reported on a given day relative to the maximum number of cases
#' reported on a given day.
#'
#' @inheritParams enw_add_incidence
#' @inheritParams enw_latest_data
#' @family preprocess
#' @export
#' @examples
#' obs <- data.frame(report_date = as.Date("2021-01-01") + 0:2)
#' obs$reference_date <- as.Date("2021-01-01")
#' obs$confirm <- 1:3
#' enw_add_max_reported(obs)
enw_add_max_reported <- function(obs, copy = TRUE) {
  obs <- coerce_dt(
    obs, required_cols = "confirm", group = TRUE, dates = TRUE, copy = copy
  )
  orig_latest <- enw_latest_data(obs)
  orig_latest <- orig_latest[
    ,
    .(reference_date, .group, max_confirm = confirm)
  ]
  obs <- orig_latest[obs, on = c("reference_date", ".group")]
  obs[is.na(reference_date), max_confirm := confirm]
  obs[, cum_prop_reported := confirm / max_confirm]
  return(obs[])
}

#' Filter by report dates
#'
#' @description This is a helper function which allows users to create
#' truncated data sets at past time points from a given larger data set.
#' This is useful when evaluating nowcast performance against fully
#' observed data. Users may wish to combine this function with
#' [enw_filter_reference_dates()].
#'
#' @param obs A `data.frame` with a `report_date` column.
#'
#' @param latest_date Date, the latest report date to include in the
#' returned dataset.
#'
#' @param remove_days Integer, if \code{latest_date} is not given, the number
#' of report dates to remove, starting from the latest date included.
#'
#' @param obs A `data.frame`; must have `report_date` and `reference_date`
#' columns.
#'
#' @return A data.table  filtered by report date
#' @family preprocess
#' @export
#' @examples
#' # Filter by date
#' enw_filter_report_dates(germany_covid19_hosp, latest_date = "2021-09-01")
#'
#' # Filter by days
#' enw_filter_report_dates(germany_covid19_hosp, remove_days = 10)
enw_filter_report_dates <- function(obs, latest_date, remove_days) {
  stopifnot(
    "exactly one of `remove_days` and `latest_date` must be specified." =
      xor(missing(remove_days), missing(latest_date))
  )
  filt_obs <- coerce_dt(obs, dates = TRUE)
  if (missing(latest_date)) {
    latest_date <- max(filt_obs$report_date) - remove_days
  }
  filt_obs <- filt_obs[report_date <= as.Date(latest_date)]
  return(filt_obs[])
}

#' Filter by reference dates
#'
#' @description This is a helper function which allows users to filter
#' datasets by reference date. This is useful, for example, when evaluating
#' nowcast performance against fully observed data. Users may wish to combine
#' this function with [enw_filter_report_dates()]. Note that by definition it
#' is assumed that a report date for a given reference date must be the equal
#' or greater (i.e a report cannot happen before the event being reported
#' occurs). This means that this function will also filter report dates earlier
#' than the target reference dates.
#'
#' @param earliest_date earliest reference date to include in the data set
#'
#' @param include_days if \code{earilest_date} is not given, the number
#' of reference dates to include, ending with the latest reference
#' date included once report dates have been removed. If specified
#' this is indexed to `latest_date` or `remove_days`.
#'
#' @param latest_date Date, the latest reference date to include in the
#' returned dataset.
#'
#' @param remove_days Integer, if \code{latest_date} is not given, the number
#' of reference dates to remove, starting from the latest date included.
#'
#' @param obs An `data.frame`; must have `report_date` and `reference_date`
#' columns.
#'
#' @return A data.table  filtered by report date
#' @family preprocess
#' @export
#' @examples
#' # Filter by date
#' enw_filter_reference_dates(
#'   germany_covid19_hosp,
#'   earliest_date = "2021-09-01",
#'   latest_date = "2021-10-01"
#' )
#' #
#' # Filter by days
#' enw_filter_reference_dates(
#'   germany_covid19_hosp,
#'   include_days = 10, remove_days = 10
#' )
enw_filter_reference_dates <- function(obs, earliest_date, include_days,
                                       latest_date, remove_days) {
  filt_obs <- coerce_dt(obs, dates = TRUE)
  if (!missing(remove_days)) {
    if (!missing(latest_date)) {
      stop("`remove_days` and `latest_date` can't both be specified.")
    }
    latest_date <- max(filt_obs$reference_date) - remove_days
  }
  if (!missing(remove_days) || !missing(latest_date)) {
    filt_obs <- filt_obs[
      reference_date <= as.Date(latest_date) | is.na(reference_date)
    ]
  }
  if (!missing(include_days)) {
    if (!missing(earliest_date)) {
      stop(
        "`include_days` and `earliest_date` can't both be specified."
      )
    }
    earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days
  }
  if (!missing(include_days) || !missing(earliest_date)) {
    filt_obs <- filt_obs[
      reference_date >= as.Date(earliest_date) | is.na(reference_date)
    ][
      report_date >= as.Date(earliest_date)
    ]
  }
  return(filt_obs[])
}

#' Filter observations to the latest available reported
#'
#' @description Filter observations to be the latest available reported
#' data for each reference date. Note this is not the same as filtering
#' for the maximum report date in all cases as data may only be updated
#' up to some maximum number of days.
#'
#' @return A `data.table` of observations filtered for the latest available data
#' for each reference date.
#'
#' @param obs A `data.frame`; must have `report_date` and `reference_date`
#' columns.
#'
#' @family preprocess
#' @export
#' @examples
#' # Filter for latest reported data
#' enw_latest_data(germany_covid19_hosp)
enw_latest_data <- function(obs) {
  latest_data <- coerce_dt(obs, dates = TRUE)

  latest_data <- latest_data[,
    .SD[report_date == (max(report_date)) | is.na(reference_date)],
    by = "reference_date"
  ]
  latest_data <- latest_data[!is.na(reference_date)]
  return(latest_data[])
}

#' Filter observations to restrict the maximum reporting delay
#'
#' @return A `data.frame` filtered so that dates by report are less than or
#' equal the reference date plus the maximum delay.
#'
#' @inheritParams enw_add_incidence
#' @inheritParams enw_preprocess_data
#' @family preprocess
#' @export
#' @examples
#' obs <- enw_example("preprocessed")$obs[[1]]
#' enw_delay_filter(obs, max_delay = 2)
enw_delay_filter <- function(obs, max_delay) {
  obs <- coerce_dt(obs, required_cols = "reference_date", group = TRUE)
  obs <- obs[,
    .SD[
      report_date <= (reference_date + max_delay - 1) | is.na(reference_date)
    ],
    by = c("reference_date", ".group")
  ]
  empirical_max_delay <- obs[, max(delay, na.rm = TRUE)]
  if (empirical_max_delay < (max_delay - 1)) {
    warning("Observed maximum delay is less than the specified maximum delay.")
  }
  return(obs[])
}

#' Construct the reporting triangle
#'
#' Constructs the reporting triangle with each row representing a reference date
#' and columns being observations by report date
#'
#' @param obs A `data.frame` as produced by [enw_add_incidence()].
#' Must contain the following variables: `reference_date`, `.group`, `delay`.
#'
#' @return A `data.frame` with each row being a reference date, and columns
#' being observations by reporting delay.
#' @family preprocess
#' @export
#' @importFrom data.table dcast setorderv
#' @examples
#' obs <- enw_example("preprocessed")$new_confirm
#' enw_reporting_triangle(obs)
enw_reporting_triangle <- function(obs) {
  obs <- coerce_dt(
    obs, required_cols = c("new_confirm", "reference_date", "delay"),
    group = TRUE
  )
  if (any(obs$new_confirm < 0)) {
    warning(
      "Negative new confirmed cases found. This is not yet supported in
       epinowcast."
    )
  }
  reports <- data.table::dcast(
    obs, .group + reference_date ~ delay,
    value.var = "new_confirm", fill = 0
  )
  data.table::setkeyv(reports, c(".group", "reference_date"))
  return(reports[])
}

#' Recast the reporting triangle from wide to long format
#'
#' @param obs A `data.frame` in the format produced by
#' [enw_reporting_triangle()].
#'
#' @return A long format reporting triangle as a `data.frame` with additional
#' variables `new_confirm` and `delay`.
#' @family preprocess
#' @export
#' @importFrom data.table melt setorderv
#' @examples
#' obs <- enw_example("preprocessed")$new_confirm
#' rt <- enw_reporting_triangle(obs)
#' enw_reporting_triangle_to_long(rt)
enw_reporting_triangle_to_long <- function(obs) {
  obs <- coerce_dt(obs, required_cols = "reference_date", group = TRUE)
  reports_long <- data.table::melt(
    obs,
    id.vars = c("reference_date", ".group"),
    variable.name = "delay", value.name = "new_confirm"
  )
  data.table::setkeyv(reports_long, c(".group", "reference_date", "delay"))
  return(reports_long[])
}

#' Complete missing reference and report dates
#'
#' Ensures that all reference and report dates are present for
#' all groups based on the maximum and minimum dates found in the data.
#' This function may be of use to users when preprocessing their data. In
#' general all features that you may consider using as grouping variables
#' or as covariates need to be included in the `by` variable.
#'
#' @param missing_reference Logical, should entries for cases with missing
#' reference date be completed as well?, Default: TRUE
#'
#' @param completion_beyond_max_report Logical, should entries be completed
#' beyond the maximum date found in the data? Default: FALSE
#'
#' @return A `data.table` with completed entries for all combinations of
#' reference dates, groups and possible report dates.
#'
#' @inheritParams enw_preprocess_data
#' @export
#' @importFrom data.table CJ
#' @family preprocess
#' @examples
#' obs <- data.frame(
#'   report_date = c("2021-10-01", "2021-10-03"), reference_date = "2021-10-01",
#'   confirm = 1
#' )
#' enw_complete_dates(obs)
#'
#' # Allow completion beyond the maximum date found in the data
#' enw_complete_dates(obs, completion_beyond_max_report = TRUE, max_delay = 10)
enw_complete_dates <- function(obs, by = NULL, max_delay,
                               missing_reference = TRUE,
                               completion_beyond_max_report  = FALSE) {
  obs <- coerce_dt(obs, dates = TRUE)
  check_group(obs)

  min_date <- min(obs$reference_date, na.rm = TRUE)
  max_date <- max(obs$report_date, na.rm = TRUE)
  if (missing(max_delay)) {
    max_delay <- as.numeric(max_date - min_date)
  }

  dates <- seq.Date(min_date, max_date, by = 1)
  dates <- as.IDate(dates)

  obs <- enw_assign_group(obs, by = by, copy = FALSE)
  by_with_group_id <- c(".group", by) # nolint: object_usage_linter
  groups <- unique(obs[, ..by_with_group_id])

  completion <- data.table::CJ(
    reference_date = dates,
    .group = groups$.group,
    report_date = 0:max_delay
  )
  completion <- completion[, report_date := reference_date + report_date]
  if (!completion_beyond_max_report) {
    completion <- completion[report_date <= max_date]
  }

  if (missing_reference) {
    completion <- rbind(
      completion,
      data.table::CJ(
        reference_date = as.IDate(NA),
        .group = groups$.group,
        report_date = dates
      )
    )
  }
  # join completion with groups and original obs
  completion <- completion[groups, on = ".group"]
  obs <- obs[completion, on = c(names(groups), "reference_date", "report_date")]
  # impute missing as last available observation or 0
  obs[,
    confirm := nafill(nafill(confirm, "locf"), fill = 0),
    by = c("reference_date", ".group")
  ]
  obs[, .group := NULL]
  data.table::setkeyv(obs, c(by, "reference_date", "report_date"))
  data.table::setcolorder(obs, c(by, "report_date", "reference_date"))
  return(obs[])
}

#' Extract reports with missing reference dates
#'
#' Returns reports with missing reference dates as well as calculating
#' the proportion of reports for a given reference date that were missing.
#'
#' @param obs A `data.frame` as produced by [enw_add_incidence()].
#' Must contain the following variables: `report_date`, `reference_date`,
#' `.group`, and `confirm`, and `new_confirm`.
#'
#' @return A `data.table` of missing counts and proportions by report date and
#' group.
#'
#' @export
#' @family preprocess
#' @examples
#' obs <- data.frame(
#'   report_date = c("2021-10-01", "2021-10-03"), reference_date = "2021-10-01",
#'   confirm = 1
#' )
#' obs <- rbind(
#'   obs,
#'   data.frame(report_date = "2021-10-04", reference_date = NA, confirm = 4)
#' )
#' obs <- enw_complete_dates(obs)
#' obs <- enw_assign_group(obs)
#' obs <- enw_add_incidence(obs)
#' enw_missing_reference(obs)
enw_missing_reference <- function(obs) {
  obs <- coerce_dt(
    obs, required_cols = "new_confirm", group = TRUE, dates = TRUE
  )
  ref_avail <- obs[!is.na(reference_date)]
  ref_avail <- ref_avail[,
    .(.confirm_avail = sum(new_confirm)),
    by = c("report_date", ".group")
  ]

  ref_missing <- obs[is.na(reference_date)]
  cols <- intersect(
    c(
      "delay", "reference_date", "max_confirm", "cum_prop_reported",
      "prop_reported", "new_confirm"
    ), colnames(ref_missing)
  )
  ref_missing[, (cols) := NULL]
  ref_missing <- ref_avail[ref_missing, on = c(".group", "report_date")]
  ref_missing[, prop_missing := confirm / (confirm + .confirm_avail)]
  ref_missing[, .confirm_avail := NULL]
  data.table::setkeyv(ref_missing, c(".group", "report_date"))
  return(ref_missing[])
}

#' Calculate reporting delay metadata
#'
#' Calculate delay metadata based on the supplied maximum delay and independent
#' of other metadata or date indexing. These data are meant to be used in
#' conjunction with metadata on the date of reference. Users can build
#' additional features this  `data.frame`  or regenerate it using this function
#' in the output of `enw_preprocess_data()`.
#'
#' @param breaks Numeric, defaults to 4. The number of breaks to use when
#' constructing a categorised version of numeric delays.
#'
#' @return A  `data.frame`  of delay metadata. This includes:
#'  - `delay`: The numeric delay from reference date to report.
#'  - `delay_cat`: The categorised delay. This may be useful for model building.
#'  - `delay_week`: The numeric week since the delay was reported. This again
#'  may be useful for model building.
#'  - `delay_tail`: A logical variable defining if the delay is in the upper
#'  75% of the potential delays. This may be particularly useful when building
#'  models that assume a parametric distribution in order to increase the weight
#'  of the tail of the reporting distribution in a pragmatic way.
#' @inheritParams enw_preprocess_data
#' @family preprocess
#' @export
#' @examples
#' enw_delay_metadata(20, breaks = 4)
enw_delay_metadata <- function(max_delay = 20, breaks = 4) {
  delays <- data.table::data.table(delay = 0:(max_delay - 1))
  even_delay <- max_delay + max_delay %% 2
  delays <- delays[, `:=`(
    delay = delay,
    delay_cat = cut(
      delay, seq(
        from = 0, to = ceiling(even_delay / breaks) * breaks,
        by = ceiling(even_delay / breaks)
      ),
      dig.lab = 0, right = FALSE
    ),
    delay_week = as.integer(delay / 7),
    delay_tail = delay > quantile(delay, probs = 0.75)
  )]
  return(delays[])
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
#'  and and restricted to the specified maximum delay.
#'
#' @param new_confirm Incidence of notifications by reference and report date.
#' Empirical reporting distributions are also added.
#'
#' @param latest The latest available observations.
#'
#' @param missing_reference A `data.frame` of reported observations that are
#' missing the reference date.
#'
#' @param reporting_triangle Incident observations by report and reference
#'  date in the standard reporting triangle matrix format.
#'
#' @param metareference Metadata reference dates derived from observations.
#'
#' @param metareport Metadata for report dates.
#'
#' @param metadelay Metadata for reporting delays produced using
#'  [enw_delay_metadata()].
#
#' @inheritParams enw_preprocess_data
#' @inherit enw_preprocess_data return
#' @family preprocess
#' @export
#' @examples
#' pobs <- enw_example("preprocessed")
#' enw_construct_data(
#'   obs = pobs$obs[[1]],
#'   new_confirm = pobs$new_confirm[[1]],
#'   latest = pobs$latest[[1]],
#'   missing_reference = pobs$missing_reference[[1]],
#'   reporting_triangle = pobs$reporting_triangle[[1]],
#'   metareport = pobs$metareport[[1]],
#'   metareference = pobs$metareference[[1]],
#'   metadelay = enw_delay_metadata(max_delay = 20),
#'   by = c(),
#'   max_delay = pobs$max_delay[[1]]
#' )
enw_construct_data <- function(obs, new_confirm, latest, missing_reference,
                               reporting_triangle, metareport, metareference,
                               metadelay, by, max_delay) {
  out <- data.table::data.table(
    obs = list(obs),
    new_confirm = list(new_confirm),
    latest = list(latest),
    missing_reference = list(missing_reference),
    reporting_triangle = list(reporting_triangle),
    metareference = list(metareference),
    metareport = list(metareport),
    metadelay = list(metadelay),
    time = nrow(latest[.group == 1]),
    snapshots = nrow(unique(obs[, .(.group, report_date)])),
    by = list(by),
    groups = length(unique(obs$.group)),
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
#' used by visualisation and modelling functions including the
#' observed empirical probability of a report on a given day, the cumulative
#' probability of report, the latest available observations, incidence of
#' observations, and metadata about the date of reference and report (used to
#' construct models). This function wraps other preprocessing functions that may
#' be instead used individually if required. Note that internally reports
#' beyond the user specified delay are dropped for modelling purposes with the
#' `cum_prop_reported` and `max_confirm` variables allowing the user to check
#' the impact this may have (if `cum_prop_reported` is significantly below 1 a
#' longer `max_delay` may be appropriate). Also note that if missing reference
#' or report dates are suspected to occur in your data then these need to be
#' completed with [enw_complete_dates()].
#'
#' @param obs A `data.frame` containing at least the following variables:
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
#' setting so consider what maximum makes sense for your data carefully. Note
#' that this is zero indexed and so includes the reference date and
#' `max_delay - 1` other days.
#'
#' @param ... Other arguments to [enw_add_metaobs_features()],
#'   e.g. `holidays`, which sets commonly used metadata
#'   (e.g. day of week, days since start of time series)
#'
#' @param copy A logical; if `TRUE` (the default) creates a copy; otherwise,
#' modifies `obs` in place.
#'
#' @return A data.table containing processed observations as a series of nested
#' data.frames as well as variables containing metadata. These are:
#'  - `obs`: (observations with the addition of empirical reporting proportions
#'  and and restricted to the specified maximum delay).
#' - `new_confirm`: Incidence of notifications by reference and report date.
#' Empirical reporting distributions are also added.
#' - `latest`: The latest available observations.
#' - `missing_reference`: Observations missing reference dates.
#' - `reporting_triangle`: Incident observations by report and reference date in
#' the standard reporting triangle matrix format.
#' - `metareference`: Metadata reference dates derived from observations.
#' - `metrareport`: Metadata for report dates.
#' - `metadelay`: Metadata for reporting delays produced using
#'  [enw_delay_metadata()].
#' - `time`: Numeric, number of timepoints in the data.
#' - `snapshots`: Numeric, number of available data snapshots to use for
#'  nowcasting.
#' - `groups`: Numeric, Number of groups/strata in the supplied observations
#'  (set using `by`).
#' - `max_delay`: Numeric, the maximum delay in the processed data
#' - `max_date`: The maximum available report date.
#'
#' @family preprocess
#' @inheritParams enw_add_incidence
#' @export
#' @importFrom data.table data.table
#' @examples
#' library(data.table)
#'
#' # Filter example hospitalisation data to be national and over all ages
#' nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
#' nat_germany_hosp <- nat_germany_hosp[age_group %in% "00+"]
#'
#' # Preprocess with default settings
#' pobs <- enw_preprocess_data(nat_germany_hosp)
#' pobs
enw_preprocess_data <- function(obs, by = NULL, max_delay = 20,
                                set_negatives_to_zero = TRUE,
                                ..., copy = TRUE) {
  # coerce obs - at this point, either making a copy or not
  # after, we are modifying the copy/not copy
  obs <- coerce_dt(obs, dates = TRUE, copy = copy)
  check_group(obs)
  data.table::setkeyv(obs, "reference_date")

  obs <- enw_assign_group(obs, by = by, copy = FALSE)
  obs <- enw_add_max_reported(obs, copy = FALSE)
  obs <- enw_add_delay(obs, copy = FALSE)

  obs <- enw_delay_filter(obs, max_delay = max_delay)

  diff_obs <- enw_add_incidence(
    obs,
    set_negatives_to_zero = set_negatives_to_zero,
    by = by
  )

  # filter obs based on diff constraints
  obs <- merge(
    obs, diff_obs[, .(reference_date, report_date, .group)],
    by = c("reference_date", "report_date", ".group")
  )

  # update grouping in case any are now missing
  setnames(obs, ".group", ".old_group")
  obs <- enw_assign_group(obs, by)

  # update diff data groups using updated groups
  diff_obs <- merge(
    diff_obs,
    obs[
      ,
      .(reference_date, report_date, .new_group = .group, .group = .old_group)
    ],
    by = c("reference_date", "report_date", ".group")
  )
  diff_obs[, .group := .new_group][, .new_group := NULL]
  obs[, .old_group := NULL]

  # separate obs with and without missing reference date
  reference_available <- diff_obs[!is.na(reference_date)]
  reference_missing <- enw_missing_reference(diff_obs)

  # calculate reporting matrix on obs with available reference date
  reporting_triangle <- enw_reporting_triangle(reference_available)

  # extract latest data
  latest <- enw_latest_data(reference_available)
  latest[, new_confirm := NULL]

  # extract and extend report date meta data to include unobserved reports
  metareport <- enw_metadata(reference_available, target_date = "report_date")
  metareport <- enw_extend_date(
    metareport,
    days = max_delay - 1, direction = "end"
  )
  metareport <- enw_add_metaobs_features(metareport, ...)

  # extract and add features for reference date
  metareference <- enw_metadata(
    obs[!is.na(reference_date)],
    target_date = "reference_date"
  )
  metareference <- enw_add_metaobs_features(metareference, ...)

  # extract and add features for delays
  metadelay <- enw_delay_metadata(max_delay, breaks = 4)

  out <- enw_construct_data(
    obs = obs,
    new_confirm = reference_available,
    missing_reference = reference_missing,
    latest = latest,
    reporting_triangle = reporting_triangle,
    metareference = metareference,
    metareport = metareport,
    metadelay = metadelay,
    by = by,
    max_delay = max_delay
  )

  return(out[])
}
