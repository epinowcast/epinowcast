# test data
obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][
    age_group %in% c("00+", "05-14", "15-34")
  ],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 14)
pobs <- suppressWarnings(enw_preprocess_data(
  obs,
  by = c("age_group", "location"), max_delay = 14
))
data <- pobs$metareference[[1]]
data <- data[age_group == "00+"]
data <- data[day_of_week %in% c("Monday", "Tuesday")]

test_that("enw_manual_formula can return a basic fixed effects formula", {
  expect_snapshot(enw_manual_formula(data, fixed = "day_of_week"))
})

test_that("enw_manual_formula can return a basic random effects formula", {
  expect_snapshot(enw_manual_formula(data, random = "day_of_week"))
})

test_that(
  "enw_manual_formula can return a basic custom random effects formula",
  {
    expect_snapshot(enw_manual_formula(data, custom_random = "day_of"))
  }
)
