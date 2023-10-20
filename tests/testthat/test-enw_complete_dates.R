test_that("enw_complete_dates() works as expected with well behaved data", {
  obs <- data.frame(
    report_date = c("2021-10-01", "2021-10-03"), reference_date = "2021-10-01",
    confirm = 1
  )
  exp_obs <- data.table::data.table(
    report_date = as.IDate(
      c(
        "2021-10-01", "2021-10-02", "2021-10-03", "2021-10-02", "2021-10-03",
        "2021-10-03", "2021-10-01", "2021-10-02", "2021-10-03"
      )
    ),
    reference_date = as.IDate(
      c(rep("2021-10-01", 3), rep("2021-10-02", 2), "2021-10-03", rep(NA, 3))
    ),
    confirm = c(rep(1, 3), rep(0, 6))
  )
  data.table::setkeyv(exp_obs, c("reference_date", "report_date"))
  expect_equal(enw_complete_dates(obs), exp_obs)
  expect_equal(
    enw_complete_dates(obs, missing_reference = FALSE),
    exp_obs[!is.na(reference_date)]
  )
  expect_snapshot(
    enw_complete_dates(obs, completion_beyond_max_report = TRUE, max_delay = 5)
  )
  expect_equal(
    enw_complete_dates(obs, completion_beyond_max_report = FALSE, max_delay = 5),
    exp_obs
  )
  obs$location <- "DE"
  data.table::setkeyv(
    exp_obs[, location := "DE"], c("location", "reference_date", "report_date")
  )
  data.table::setcolorder(exp_obs, "location")
  expect_equal(
    enw_complete_dates(obs, by = "location"), exp_obs
  )
})

test_that("enw_complete_dates() handles min_date and max_date correctly", {
  obs <- data.frame(
    report_date = c("2021-10-01", "2021-10-03"),
    reference_date = "2021-10-01",
    confirm = 1
  )
  # Test when defaults are provided explicitly
  expect_equal(
    enw_complete_dates(
      obs, min_date = as.Date("2021-10-01"), max_date = as.Date("2021-10-03")
    ), 
    enw_complete_dates(obs)
  )

  # Test when min_date is before the minimum reference_date in obs
  complete_dates <- enw_complete_dates(
    obs, min_date = as.IDate("2021-09-30"), missing_reference = FALSE
  )
  expect_equal(min(complete_dates$report_date), as.IDate("2021-09-30"))
  expect_equal(min(complete_dates$reference_date), as.IDate("2021-09-30"))
  expect_equal(max(complete_dates$report_date), as.IDate("2021-10-03"))
  expect_equal(max(complete_dates$reference_date), as.IDate("2021-10-03"))

  # Test when max_date is after the maximum report_date in obs
  complete_dates <- enw_complete_dates(
    obs, max_date = as.IDate("2021-10-04"), missing_reference = FALSE
  )
  expect_equal(min(complete_dates$report_date), as.IDate("2021-10-01"))
  expect_equal(min(complete_dates$reference_date), as.IDate("2021-10-01"))
  expect_equal(max(complete_dates$report_date), as.IDate("2021-10-04"))
  expect_equal(max(complete_dates$reference_date), as.IDate("2021-10-04"))
})
