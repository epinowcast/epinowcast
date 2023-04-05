test_that("enw_metadata_delay produces the expected features", {
  delays <- enw_metadata_delay(20, 4)
  vars <- c("delay", "delay_cat", "delay_week", "delay_tail")
  expect_data_table(delays)
  expect_equal(
    colnames(delays), vars
  )
  expect_equal(delays$delay, 0:19)
  expect_equal(
    unique(as.character(delays$delay_cat)),
    c("[0,5)", "[5,10)", "[10,15)", "[15,20)")
  )
  expect_equal(
    delays$delay_week,
    c(rep(0, 7), rep(1, 7), rep(2, 6))
  )
  expect_equal(
    delays$delay_tail,
    c(rep(FALSE, 15), rep(TRUE, 5))
  )

  delays <- enw_metadata_delay(19, 3)
  expect_data_table(delays)
  expect_equal(
    colnames(delays), vars
  )
  expect_equal(delays$delay, 0:18)
  expect_equal(
    unique(as.character(delays$delay_cat)),
    c("[0,7)", "[7,1e+01)", "[1e+01,2e+01)")
  )
  expect_equal(
    delays$delay_week,
    c(rep(0, 7), rep(1, 7), rep(2, 5))
  )
  expect_equal(
    delays$delay_tail,
    c(rep(FALSE, 14), rep(TRUE, 5))
  )
})
