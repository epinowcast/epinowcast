test_that("enw_incidence_to_linelist can return a linelist", {
  incidence <- enw_filter_reference_dates_by_report_start(
    germany_covid19_hosp
  )
  incidence <- enw_add_incidence(incidence)
  incidence <- enw_filter_reference_dates(
    incidence[location == "DE"],
    include_days = 10
  )
  expect_snapshot(
    enw_incidence_to_linelist(
      incidence,
      reference_date = "onset_date",
      report_date = "test_date"
    )
  )
  expect_snapshot(
    enw_incidence_to_linelist(incidence)
  )
})
