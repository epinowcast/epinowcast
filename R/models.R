enw_intercept_model <- function(metaobs) {

  # build effects design matrix (with  no contrasts)
  fixed <- enw_design(~1, metaobs, sparse = TRUE)

  # extract effects metadata
  effects <- enw_effects_metadata(fixed$design)

  # build design matrix for pooled parameters
  random <- enw_design(~1, effects, sparse = FALSE)

  return(list(fixed = fixed, random = random))
}

enw_day_model <- function(metaobs, rw = FALSE) {

  # turn dates into factors
  metaobs <- enw_dates_to_factors(metaobs)

  # build effects design matrix (with  no contrasts)
  fixed <- enw_design(~date, metaobs, no_contrasts = TRUE)

  # extract effects metadata
  effects <- enw_effects_metadata(fixed$design)

  # construct random effect for date
  effects <- enw_add_pooling_effect(effects, "date")

  # build design matrix for pooled parameters
  random <- enw_design(~ 0 + fixed + sd, effects, sparse = FALSE)

  return(list(fixed = fixed, random = random))
}

enw_day_of_week_model <- function(metaobs, holidays = c()) {
  # add days of week
  metaobs <- data.table::copy(metaobs)
  metaobs[, day_of_week := weekdays(date)]

  # make holidays be sundays
  if (length(holidays) != 0) {
    metaobs[date %in% as.Date(holidays), day_of_week := "Sunday"]
  }

  # make day of week a factor
  metaobs[, day_of_week := factor(day_of_week)]

  # build effects design matrix (with  no contrasts)
  fixed <- enw_design(~day_of_week, metaobs, no_contrasts = TRUE)

  # extract effects metadata
  effects <- enw_effects_metadata(fixed$design)

  # construct random effect for date
  effects <- enw_add_pooling_effect(effects, "day_of_week")

  # build design matrix for pooled parameters
  random <- enw_design(~ 0 + fixed + sd, effects, sparse = FALSE)

  return(list(fixed = fixed, random = random))
}

enw_weekly_model <- function(metaobs, rw = FALSE, day_of_week = FALSE,
                             holidays = c()) {

}
