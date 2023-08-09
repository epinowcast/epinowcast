test_that("check_max_delay produces the expected warnings", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_warning(
    check_max_delay(obs, max_delay = 5, by = ".group"),
    regexp = "covers less than 80% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, max_delay = 5, by = ".group", warn = FALSE)
  )

  expect_warning(
    check_max_delay(obs, max_delay = 8, cum_coverage = 0.9, by = ".group"),
    regexp = "covers less than 90% of cases for the majority"
  )

  expect_no_warning(
    check_max_delay(obs, 10, by = ".group")
  )
})

test_that("check_max_delay produces the expected output", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]

  expect_equal(
    check_max_delay(obs, max_delay = 10, by = ".group"),
    data.table(
      .group = c(1, "all"), coverage = c(0.8, 0.8),
      below_coverage = c(0.136363636, 0.136363636)
    )
  )

  expect_equal(
    check_max_delay(obs, max_delay = 13, cum_coverage = 0.9, by = ".group"),
    data.table(
      .group = c(1, "all"), coverage = c(0.9, 0.9),
      below_coverage = c(0.409090909, 0.409090909)
    )
  )

  expect_equal(
    check_max_delay(obs, max_delay = 20, by = ".group"),
    data.table(
      .group = c(1, "all"), coverage = c(0.8, 0.8), below_coverage = c(0, 0)
    )
  )

  expect_error(check_max_delay(obs, max_delay = 10, cum_coverage = 80))

  nat_germany_hosp <- epinowcast::germany_covid19_hosp[location == "DE"]
  expect_snapshot(
    check_max_delay(nat_germany_hosp, max_delay = 15, by = "age_group")
  )
})

test_that("check_max_delay does same preprocessing as enw_preprocess_data", {
  nat_germany_hosp <- epinowcast::germany_covid19_hosp[location == "DE"]
  pobs <- suppressWarnings(enw_preprocess_data(
    nat_germany_hosp, max_delay = 999, by = "age_group"
  ))
  expect_equal(
      check_max_delay(nat_germany_hosp, max_delay = 15, "age_group"),
      check_max_delay(pobs$obs, max_delay = 15, by = ".group")
  )
})
