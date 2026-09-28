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
  expect_named(
    rep$inits(rep$data, rep$priors)(),
    c(
      "rep_beta", "rep_beta_sd",
      "rep_arima_pacf", "rep_arima_theta", "rep_arima_sigma",
      "rep_gp_rho", "rep_gp_alpha"
    )
  )
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
    "Report date models"
  )
  # Structural reporting also rejected
  expect_error(
    enw_report(
      non_parametric = ~0,
      structural = data.table::data.table(dummy = 1),
      data = pobs_retro
    ),
    "Report date models"
  )
  # ~0 should work (no report model)
  expect_no_error(
    enw_report(non_parametric = ~0, data = pobs_retro)
  )
})

test_that("enw_report uses the report axis length from the metadata", {
  # completion_beyond_max_report extends the report axis past time + max_delay - 1
  obs <- enw_example("observations")
  max_delay <- 20L
  inc <- enw_complete_dates(
    obs,
    max_delay = max_delay,
    max_date = max(obs$report_date) + 14,
    completion_beyond_max_report = TRUE
  )
  pobs_ext <- suppressWarnings(enw_preprocess_data(inc, max_delay = max_delay))

  rep_per_group <- nrow(pobs_ext$metareport[[1]]) / pobs_ext$groups[[1]]
  expect_gt(rep_per_group, pobs_ext$time[[1]] + max_delay - 1)

  expect_no_warning(rep <- enw_report(~0, data = pobs_ext))
  expect_equal(rep$data$rep_t, rep_per_group)
})
