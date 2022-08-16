obs <- enw_example("prepro")$new_confirm[[1]]

test_that("enw_reps_with_complete_refs can identify complete report dates", {
  expect_equal(
    enw_reps_with_complete_refs(obs, max_delay = 1),
    unique(obs[, .(report_date)])
  )
  expect_equal(
    nrow(enw_reps_with_complete_refs(obs, max_delay = 30)), 0
  )
  expect_equal(
    enw_reps_with_complete_refs(obs, max_delay = 10),
    unique(obs[report_date >= as.Date("2021-07-22"), .(report_date)])
  )
  expect_equal(
    enw_reps_with_complete_refs(obs, max_delay = 20),
    unique(obs[report_date >= as.Date("2021-08-01"), .(report_date)])
  )
})

test_that("enw_reps_with_complete_refs fails as expected", {
  expect_error(enw_reps_with_complete_refs(obs))
  expect_error(
    enw_reps_with_complete_refs(
      data.table::copy(obs)[, report_date := NULL],
      max_delay = 1
    )
  )
})
