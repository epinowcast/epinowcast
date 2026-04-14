pobs <- enw_example("preprocessed_observations")
thresh <- c(0, 2, 5, 10, 21)

# -- S3 dispatch tests ---------------------------------------

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
    plot(pobs, type = "delay_cumulative",
      delay_group_thresh = thresh
    )
  )
})

test_that("plot.enw_preprocess_data delay_fraction type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot delay_fraction",
    plot(pobs, type = "delay_fraction",
      delay_group_thresh = thresh
    )
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
    plot(pobs, type = "delay_counts",
      delay_group_thresh = thresh
    )
  )
})

test_that("plot.enw_preprocess_data auto-generates thresholds", {
  p <- plot(pobs, type = "delay_cumulative")
  expect_s3_class(p, "ggplot")
})

test_that("plot.enw_preprocess_data custom thresh via S3", {
  custom <- c(0, 5, 21)
  p <- plot(pobs, type = "delay_cumulative",
    delay_group_thresh = custom
  )
  expect_s3_class(p, "ggplot")
})

test_that("plot.enw_preprocess_data facet = FALSE disables facet", {
  # Single-group example: facet arg should still be accepted.
  p <- plot(
    pobs, type = "delay_cumulative",
    delay_group_thresh = thresh, facet = FALSE
  )
  expect_s3_class(p, "ggplot")
})

# -- Direct plot function tests ------------------------------

test_that("enw_plot_delay_cumulative returns ggplot", {
  p <- enw_plot_delay_cumulative(pobs, thresh)
  expect_s3_class(p, "ggplot")
})

test_that("enw_plot_delay_fraction returns ggplot", {
  p <- enw_plot_delay_fraction(pobs, thresh)
  expect_s3_class(p, "ggplot")
})

test_that("enw_plot_delay_quantiles returns ggplot", {
  p <- enw_plot_delay_quantiles(pobs)
  expect_s3_class(p, "ggplot")
})

test_that("enw_plot_delay_quantiles custom quantiles", {
  p <- enw_plot_delay_quantiles(
    pobs, quantiles = c(0.25, 0.5, 0.75)
  )
  expect_s3_class(p, "ggplot")
})

test_that("enw_plot_delay_counts returns ggplot", {
  p <- enw_plot_delay_counts(pobs, thresh)
  expect_s3_class(p, "ggplot")
})
