test_that("enw_linelist_to_incidence can return incidence", {
  linelist <- data.frame(
    onset_date = as.Date(c("2021-01-02", "2021-01-03", "2021-01-02")),
    test_date = as.Date(c("2021-01-03", "2021-01-05", "2021-01-04"))
  )
  linelist_right_names <- data.frame(
    reference_date = as.Date(c("2021-01-02", "2021-01-03", "2021-01-02")),
    report_date = as.Date(c("2021-01-03", "2021-01-05", "2021-01-04")), 
    age = c(20, 20, 40)
  )
  expect_snapshot(
    enw_linelist_to_incidence(
      linelist, reference_date = "onset_date", report_date = "test_date"
    )
  )
  expect_snapshot(
    enw_linelist_to_incidence(
      linelist_right_names, max_delay = 2
    )
  )
  expect_snapshot(
    enw_linelist_to_incidence(
      linelist_right_names, max_delay = 6
    )
  )
  expect_snapshot(
    enw_linelist_to_incidence(
      linelist_right_names, by = "age"
    )
  )
})