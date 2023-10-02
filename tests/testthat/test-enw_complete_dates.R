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
  exp_obs[,
   .observed := c(FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE)
  ]
  expect_equal(
    enw_complete_dates(obs, by = "location", flag_observation = TRUE),
    exp_obs
  )
})
