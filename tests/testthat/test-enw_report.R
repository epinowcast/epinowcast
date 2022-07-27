# Use example data
pobs <- enw_example("preprocessed")

test_that("enw_report supports non-parametric models", {
  expect_snapshot({
    rep <- enw_report(~ 1 + day_of_week, data = pobs)
    rep$inits <- NULL
    rep
  })
  rep <- enw_report(
    ~ 1 + day_of_week,
    data = pobs
  )
  expect_named(rep$init(rep$data, rep$priors)(), c("rep_beta", "rep_beta_sd"))
  expect_equal(
    enw_report(~0, data = pobs)$formula$non_parametric, "~1"
  )
  expect_equal(enw_report(~0, data = pobs)$data$model_rep, 0)
})

test_that("enw_report does not support structural models", {
  expect_error(
    enw_report(structural = ~ 1 + day_of_week, data = pobs)
  )
})
