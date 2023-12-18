test_that("check_modules_compatible works as expected", {
  modules <- as.list(rep(1, 6))
  modules[[4]] <- list(data = list(model_miss = FALSE))
  modules[[6]] <- list(data = list(likelihood_aggregation = FALSE))
  expect_equal(check_modules_compatible(modules), NULL)
  modules[[4]] <- list(data = list(model_miss = TRUE))
  modules[[6]] <- list(data = list(likelihood_aggregation = FALSE))
  expect_warning(check_modules_compatible(modules))
})
