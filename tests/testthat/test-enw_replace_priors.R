test_that("enw_replace_priors can replace a default prior with a custom
           prior", {
  priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
  custom_priors <- data.frame(variable = "x", mean = 10, sd = 2)
  exp_priors <- data.table::data.table(
    variable = c("y", "x"), mean = c(2, 10), sd = c(2, 2)
  )
  expect_equal(enw_replace_priors(priors, custom_priors), exp_priors)
})

test_that("enw_replace_priors can replace a default prior with a custom
           prior when it is vectorised", {
  priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
  custom_priors <- data.frame(variable = "x[1]", mean = 10, sd = 2)
  exp_priors <- data.table::data.table(
    variable = c("y", "x"), mean = c(2, 10), sd = c(2, 2)
  )
  expect_equal(enw_replace_priors(priors, custom_priors), exp_priors)
})
