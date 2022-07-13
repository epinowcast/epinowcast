# Use meta data for references dates from the Germany COVID-19
# hospitalisation data.
obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][
    age_group %in% c("00+", "05-14", "15-34")
  ],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 10)
pobs <- enw_preprocess_data(obs, by = c("age_group", "location"))
data <- pobs$metareference[[1]]

test_that("enw_formula can return a basic fixed effects formula", {
  expect_snapshot(enw_formula(~ 1 + age_group, data))
})

test_that("enw_formula can return a basic random effects formula", {
  expect_snapshot(enw_formula(~ 1 + (1 | age_group), data))
})

test_that("enw_formula can return a model with a random effect and a random
           walk", {
  expect_snapshot(enw_formula(~ 1 + (1 | age_group) + rw(week), data))
})

test_that("enw_formula can return a model with a random effect
           and a random walk by group", {
  expect_snapshot(
    enw_formula(~ 1 + (1 | age_group) + rw(week, age_group), data)
  )
})

test_that("enw_formula can return a model with a fixed effect, random effect
           and a random walk", {
  expect_snapshot(
    enw_formula(~ 1 + day_of_week + (1 | age_group) + rw(week), data)
  )
})

test_that("enw_formula can handle random effects that are not factors", {
  test_data <- data.table::data.table(d = 0:(14 - 1))
  test_data <- test_data[, d_week := as.integer(d / 7)]
  expect_snapshot(enw_formula(~ 1 + (1 | d_week), test_data))
})
