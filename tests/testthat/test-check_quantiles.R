test_that("check_quantiles works as expected", {
  dt <- data.frame(q50 = 1, q95 = 1, q20 = 1, q80 = 1)
  expect_identical(epinowcast:::check_quantiles(dt), dt)
  expect_identical(epinowcast:::check_quantiles(dt, req_probs = 0.2), dt)
  expect_error(epinowcast:::check_quantiles(dt, req_probs = 0.35))
  expect_error(epinowcast:::check_quantiles(dt, req_probs = c(0.2, 0.35)))
  expect_error(epinowcast:::check_quantiles(dt, req_probs = 35))
})
