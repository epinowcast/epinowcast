test_that(".expectation_delay_spec normalises a fixed PMF", {
  spec <- epinowcast:::.expectation_delay_spec(c(0.2, 0.5, 0.3), "delay")
  expect_identical(spec$n, 3L)
  expect_identical(spec$dist, 0L)
  expect_equal(spec$scale, 1)
  expect_equal(spec$lrev, log(rev(c(0.2, 0.5, 0.3))))
})

test_that(".expectation_delay_spec accepts a list of PMFs", {
  spec <- epinowcast:::.expectation_delay_spec(
    list(c(0.4, 0.6), c(0.5, 0.5)), "delay"
  )
  expect_identical(spec$n, 2L)
  expect_identical(spec$dist, 0L)
})

test_that(".expectation_delay_spec passes through an uncertain spec", {
  unc <- enw_uncertain(distribution = "gamma", max = 5)
  spec <- epinowcast:::.expectation_delay_spec(unc, "delay")
  expect_identical(spec$n, 5L)
  expect_identical(spec$dist, unc$dist_id)
})

test_that(".expectation_delay_spec rejects malformed fixed PMFs", {
  expect_error(
    epinowcast:::.expectation_delay_spec(numeric(0), "delay"),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(c(0.5, -0.5), "delay"),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(c(0.5, NA), "delay"),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(c(0.5, Inf), "delay"),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(c(0, 0), "delay"),
    "delay"
  )
})

test_that(".expectation_delay_spec rejects malformed PMF lists", {
  expect_error(
    epinowcast:::.expectation_delay_spec(list(), "delay"),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(
      list(c(0.5, 0.5), c(0, 0)), "delay"
    ),
    "delay"
  )
  expect_error(
    epinowcast:::.expectation_delay_spec(
      list(c(0.5, 0.5), c(0.5, -0.5)), "delay"
    ),
    "delay"
  )
})
