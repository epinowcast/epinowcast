pobs <- enw_example("preprocessed_observations")
thresh <- c(0, 2, 5, 10, 21)

test_that("enw_delay_categories returns expected structure", {
  nc <- enw_delay_categories(pobs, thresh)
  expect_s3_class(nc, "data.table")
  expect_true(all(
    c(
      "reference_date", ".group", "delay_group",
      "new_confirm", "prop_reported", "cum_prop_reported"
    ) %in% names(nc)
  ))
  expect_true(all(nc$cum_prop_reported >= 0))
  expect_true(all(nc$cum_prop_reported <= 1))
})

test_that("enw_delay_quantiles returns expected structure", {
  eq <- enw_delay_quantiles(pobs)
  expect_s3_class(eq, "data.table")
  expect_true(all(
    c("reference_date", ".group", "0.1", "0.5", "0.9") %in%
      names(eq)
  ))
})

test_that("enw_delay_quantiles respects custom quantiles", {
  eq <- enw_delay_quantiles(pobs, quantiles = c(0.25, 0.75))
  expect_true(all(
    c("0.25", "0.75") %in% names(eq)
  ))
})

test_that("plot.enw_preprocess_data rejects invalid type", {
  expect_error(plot(pobs, type = "not_a_type"))
})

test_that("plot.enw_preprocess_data obs type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot obs",
    plot(pobs, type = "obs")
  )
})

test_that("plot.enw_preprocess_data delay_cumulative type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot delay_cumulative",
    plot(pobs, type = "delay_cumulative", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data delay_fraction type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot delay_fraction",
    plot(pobs, type = "delay_fraction", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data delay_quantiles type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot delay_quantiles",
    plot(pobs, type = "delay_quantiles")
  )
})

test_that("plot.enw_preprocess_data delay_counts type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot delay_counts",
    plot(pobs, type = "delay_counts", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data auto-generates thresholds", {
  p <- plot(pobs, type = "delay_cumulative")
  expect_s3_class(p, "ggplot")
})
