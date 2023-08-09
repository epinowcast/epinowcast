test_that("enw_metadata_maxdelay produces the expected metadata", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 10),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(10, 20, 10),
      dates_too_short = c(0.136363636, 0, 0.136363636),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  )
  suppressWarnings(expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 30),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(30, 20, 20),
      dates_too_short = c(0, 0, 0),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  ))
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 20),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(20, 20, 20),
      dates_too_short = c(0, 0, 0),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  )
})

test_that(paste(
  "enw_metadata_maxdelay produces warning when user-specified",
  "maximum delay is longer than observed maximum delay"
), {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_warning(
    enw_metadata_maxdelay(obs = obs, max_delay = 30),
    regexp = "epinowcast will only use the maximum observed delay"
  )
})

test_that(paste(
  "enw_metadata_maxdelay produces warning when user-specified",
  "maximum delay is too short"
), {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_warning(
    enw_metadata_maxdelay(obs = obs, max_delay = 5),
    regexp = "covers less than 80% of cases for the majority"
  )
})
