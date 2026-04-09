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
  expect_named(rep$inits(rep$data, rep$priors)(), c("rep_beta", "rep_beta_sd"))
  expect_identical(
    enw_report(~0, data = pobs)$formula$non_parametric, "~1"
  )
  expect_identical(enw_report(~0, data = pobs)$data$model_rep, 0)
})

test_that("enw_report errors on report model with max_delay = 1", {
  obs <- data.table::data.table(
    reference_date = as.Date("2021-01-01") + 0:9,
    report_date = as.Date("2021-01-01") + 0:9,
    confirm = rpois(10, 50)
  )
  pobs_retro <- enw_preprocess_data(obs, max_delay = 1)

  expect_error(
    enw_report(non_parametric = ~ 1 + day_of_week, data = pobs_retro),
    "Report date models cannot be used"
  )
  # ~0 should work (no report model)
  expect_no_error(
    enw_report(non_parametric = ~0, data = pobs_retro)
  )
})
