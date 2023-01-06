pobs <- enw_example("prepro")
obs <- pobs$new_confirm[[1]]
missing_reference <- pobs$missing_reference[[1]]
metareference <- pobs$metareference[[1]]

test_that("enw_reference_by_report can make a look-up with no delay", {
  complete_1 <- enw_reps_with_complete_refs(obs, max_delay = 1, by = ".group")
  ref_by_rep <- enw_reference_by_report(
    missing_reference, complete_1, metareference, 1
  )
  expect_equal(ref_by_rep[, report_date], complete_1[, report_date])
  expect_equal(ref_by_rep[, `0`], 1:41)
})

test_that("enw_reference_by_report can make a look-up with 1 delay", {
  complete_2 <- enw_reps_with_complete_refs(obs, max_delay = 2, by = ".group")
  ref_by_rep <- enw_reference_by_report(
    missing_reference, complete_2, metareference, 2
  )
  expect_equal(ref_by_rep[, report_date], complete_2[, report_date])
  expect_equal(as.numeric(ref_by_rep[1, -1]), c(3, 2))
  expect_equal(as.numeric(ref_by_rep[33, -1]), c(67, 66))
})

test_that("enw_reference_by_report can make a look-up with 5 delays", {
  complete_5 <- enw_reps_with_complete_refs(obs, max_delay = 5, by = ".group")
  ref_by_rep <- enw_reference_by_report(
    missing_reference, complete_5, metareference, 5
  )
  # We should see indexing on the diagonal as this represents by reference date
  expect_equal(ref_by_rep[, report_date], complete_5[, report_date])
  expect_equal(as.numeric(ref_by_rep[1, -1]), c(21, 17, 13, 9, 5))
  expect_equal(as.numeric(ref_by_rep[33, -1]), c(181, 177, 173, 169, 165))
})
