test_that("enw_metadata_delay produces the expected features", {
  delays <- enw_metadata_delay(20, 4)
  vars <- c("delay", "delay_cat", "delay_week", "delay_head", "delay_tail")
  expect_data_table(delays)
  expect_identical(
    colnames(delays), vars
  )
  expect_identical(delays$delay, 0:19)
  expect_identical(
    unique(as.character(delays$delay_cat)),
    c("[0,5)", "[5,10)", "[10,15)", "[15,20)")
  )
  expect_identical(
    delays$delay_week,
    c(rep(0L, 7), rep(1L, 7), rep(2L, 6))
  )
  expect_identical(
    delays$delay_head,
    c(rep(TRUE, 5), rep(FALSE, 15))
  )
  expect_identical(
    delays$delay_tail,
    c(rep(FALSE, 15), rep(TRUE, 5))
  )

  delays <- enw_metadata_delay(19, 3)
  expect_data_table(delays)
  expect_identical(
    colnames(delays), vars
  )
  expect_identical(delays$delay, 0:18)
  expect_identical(
    unique(as.character(delays$delay_cat)),
    c("[0,7)", "[7,1e+01)", "[1e+01,2e+01)")
  )
  expect_identical(
    delays$delay_week,
    c(rep(0L, 7), rep(1L, 7), rep(2L, 5))
  )
  expect_identical(
    delays$delay_tail,
    c(rep(FALSE, 14), rep(TRUE, 5))
  )
})

test_that("enw_delay_metadata throws deprecation warning", {
  lifecycle::expect_deprecated(
    enw_delay_metadata(20, 4),
    regexp = "was deprecated in epinowcast 0.2.3"
  )
})
