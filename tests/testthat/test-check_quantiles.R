test_that("check_quantiles works as expected", {
  dt <- data.frame(q50 = 1, q95 = 1, q20 = 1, q80 = 1)
  expect_equal(epinowcast:::check_quantiles(dt), NULL)
  expect_equal(epinowcast:::check_quantiles(dt, req_probs = 0.2), NULL)
  expect_error(epinowcast:::check_quantiles(dt, req_probs = 0.35))
  expect_error(epinowcast:::check_quantiles(dt, req_probs =c(0.2, 0.35)))
})