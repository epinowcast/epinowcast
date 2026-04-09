test_that("enw_retrospective converts delayed data to max_delay = 1", {
  pobs <- enw_example("preprocessed")
  retro <- enw_retrospective(pobs)

  expect_true(inherits(retro, "enw_preprocess_data"))
  expect_equal(retro$max_delay, 1)
  expect_identical(retro$time, pobs$time)
  expect_identical(retro$groups, pobs$groups)

  # Reporting triangle should have a single delay column
  rt <- retro$reporting_triangle[[1]]
  delay_cols <- setdiff(names(rt), c(".group", "reference_date"))
  expect_identical(delay_cols, "0")

  # All report dates should equal reference dates
  obs <- retro$obs[[1]]
  expect_true(all(obs$report_date == obs$reference_date))
})

test_that("enw_retrospective respects max_delay parameter", {
  pobs <- enw_example("preprocessed")
  retro <- enw_retrospective(pobs, max_delay = 5)

  expect_equal(retro$max_delay, 1)
  # Time may be fewer if early reference dates lack a delay-5 obs
  expect_true(retro$time <= pobs$time)
})

test_that("enw_retrospective preserves grouping", {
  obs <- germany_covid19_hosp[location == "DE"]
  pobs <- enw_preprocess_data(obs, by = "age_group", max_delay = 10)
  retro <- enw_retrospective(pobs)

  expect_equal(retro$max_delay, 1)
  expect_identical(retro$groups, pobs$groups)
})
