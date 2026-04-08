pobs <- enw_example("preprocessed_observations")
thresh <- c(0, 2, 5, 10, 21)

test_that("enw_cat_new_confirm returns expected structure", {
  nc <- enw_cat_new_confirm(pobs, thresh)
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

test_that("enw_emp_quant_by_reference returns expected structure", {
  eq <- enw_emp_quant_by_reference(pobs)
  expect_s3_class(eq, "data.table")
  expect_true(all(
    c("reference_date", ".group", "0.1", "0.5", "0.9") %in%
      names(eq)
  ))
})

test_that("enw_emp_quant_by_reference respects custom quantiles", {
  eq <- enw_emp_quant_by_reference(pobs, quantiles = c(0.25, 0.75))
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

test_that("plot.enw_preprocess_data emp_rep_cum type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot emp_rep_cum",
    plot(pobs, type = "emp_rep_cum", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data emp_rep_frac type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot emp_rep_frac",
    plot(pobs, type = "emp_rep_frac", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data emp_rep_quant type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot emp_rep_quant",
    plot(pobs, type = "emp_rep_quant")
  )
})

test_that("plot.enw_preprocess_data emp_ts_del type works", {
  vdiffr::expect_doppelganger(
    "preprocess plot emp_ts_del",
    plot(pobs, type = "emp_ts_del", delay_group_thresh = thresh)
  )
})

test_that("plot.enw_preprocess_data auto-generates thresholds", {
  p <- plot(pobs, type = "emp_rep_cum")
  expect_s3_class(p, "ggplot")
})
