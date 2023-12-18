# Use meta data for references dates from the Germany COVID-19
# hospitalisation data.
obs <- enw_filter_report_dates(
  germany_covid19_hosp[location == "DE"][
    age_group %in% c("00+", "05-14", "15-34")
  ],
  remove_days = 10
)
obs <- enw_filter_reference_dates(obs, include_days = 14)
pobs <- enw_preprocess_data(
  obs,
  by = c("age_group", "location"), max_delay = 14
)
data <- pobs$metareference[[1]]
data <- data[age_group %in% c("00+", "15-34")]
data <- data[day_of_week %in% c("Monday", "Tuesday")]

test_that("enw_formula can return a basic fixed effects formula", {
  expect_snapshot(enw_formula(~ 1 + age_group, data))
})

test_that("enw_formula can return a basic random effects formula", {
  expect_snapshot(
    enw_formula(~ 1 + (1 | age_group), data)
  )
})

test_that(
  "enw_formula can return a random effects formula with an internal interaction",
  {
    expect_snapshot(
      enw_formula(~ 1 + (1 + month | day_of_week:age_group), data)
    )
  }
)

test_that("enw_formula can return a random effects formula with an internal interaction with only one contrast by falling back to no interaction", {
  expect_snapshot(
    suppressMessages(enw_formula(
      ~ 1 + (1 + month | day_of_week:age_group),
      data[age_group == "00+"]
    ))
  )
})

test_that("enw_formula cannot return a random effects formula with multiple internal interaction", {
  expect_error(
    enw_formula(~ 1 + (1 + month | day_of_week:age_group:location), data)
  )
})

test_that("enw_formula can return a model with a random effect and a random walk", {
  expect_snapshot(enw_formula(~ 1 + (1 | age_group) + rw(week), data))
})

test_that("enw_formula can return a model with a random effect and a random walk by group", {
  expect_snapshot(
    enw_formula(~ 1 + (1 | age_group) + rw(week, age_group), data)
  )
})

test_that("enw_formula can return a model with a fixed effect, random effect and a random walk", {
  expect_snapshot(
    enw_formula(~ 1 + day_of_week + (1 | age_group) + rw(week), data)
  )
})

test_that("enw_formula can handle random effects that are not factors", {
  test_data <- data.table::data.table(d = 0:(14 - 1))
  test_data <- test_data[, d_week := as.integer(d / 7)]
  expect_snapshot(enw_formula(~ 1 + (1 | d_week), test_data))
})

test_that("enw_formula can handle formulas that do not have sparse fixed effects", {
  expect_snapshot(enw_formula(~1, data[1:5, ], sparse = FALSE))
})

test_that("enw_formula can handle complex combined formulas", {
  expect_snapshot(
    enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), mtcars)
  )
})

test_that("enw_formula fails when incorrect random walks are defined", {
  expect_error(
    enw_formula(~ 1 + rw(day), data = mtcars),
    regexp = "The time variable day is not numeric but must be to be"
  )
})

test_that("enw_formula fails when non-numeric random walks are defined", {
  expect_error(
    enw_formula(~ 1 + rw(age_group), data = data),
    regexp = "The time variable age_group is not numeric"
  )
})

test_that("enw_formula supports random effects and random walks for the same variable", {
  expect_snapshot(
    enw_formula(~ 1 + (1 | week) + rw(week), data)
  )
})


test_that("enw_formula does not allow the same fixed and random effect", {
  expect_error(
    enw_formula(~ 1 + age_group + (1 | age_group), data),
    regexp = "Random effect terms must not be included in the fixed effects"
  )
})
