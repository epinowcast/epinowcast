test_that("plot.epinowcast passes to lower level functions as expected", {
  fit <- enw_example("nowcast")
  obs <- enw_example("obs")
  expect_error(plot(fit, type = "not_a_type"))
  vdiffr::expect_doppelganger(
    "plot.epinowcast default nowcast", plot(fit, type = "nowcast")
  )
  suppressWarnings(suppressMessages(
    vdiffr::expect_doppelganger(
      "plot.epinowcast posterior predictions",
      plot(fit, type = "posterior_prediction") +
        ggplot2::facet_wrap(ggplot2::vars(reference_date), scales = "free")
    )
  ))
})
