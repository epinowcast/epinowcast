test_that("enw_missing_reference works as expected given correct input data", {
  obs <- data.frame(
    .group = rep(1, 13),
    location = rep("DE", 13),
    report_date = c(
      "2021-10-01", "2021-10-02", "2021-10-03", "2021-10-02", "2021-10-03", "2021-10-04", "2021-10-03", "2021-10-04", "2021-10-04", "2021-10-01",
      "2021-10-02", "2021-10-03", "2021-10-04"
    ),
    reference_date = c(
      rep("2021-10-01", 3), rep("2021-10-02", 3), rep("2021-10-03", 2),
      "2021-10-04", rep(NA, 4)
    ),
    confirm = c(rep(1, 3), rep(0, 9), 4),
    new_confirm = c(1, rep(0, 11), 4)
  )
  exp_obs <- data.table::data.table(
    report_date = as.IDate(
      seq.Date(as.Date("2021-10-01"), as.Date("2021-10-04"), by = "day")
    ),
    .group = 1, location = "DE",
    confirm = c(rep(0, 3), 4), prop_missing = c(0, NaN, NaN, 1)
  )
  data.table::setkeyv(exp_obs, c(".group", "report_date"))
  expect_equal(enw_missing_reference(obs), exp_obs)
})

test_that("enw_missing_reference works as expected when no missingness is
           present", {
  obs <- data.frame(
    .group = rep(1, 9),
    location = rep("DE", 9),
    report_date = c(
      "2021-10-01", "2021-10-02", "2021-10-03", "2021-10-02", "2021-10-03", "2021-10-04", "2021-10-03", "2021-10-04", "2021-10-04"
    ),
    reference_date = c(
      rep("2021-10-01", 3), rep("2021-10-02", 3), rep("2021-10-03", 2),
      "2021-10-04"
    ),
    confirm = c(rep(1, 3), rep(0, 6)),
    new_confirm = c(1, rep(0, 8))
  )
  expect_equal(nrow(enw_missing_reference(obs)), 0)
})
