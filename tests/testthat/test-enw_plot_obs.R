test_that("enw_plot_obs can plot observed data as expected", {
  nowcast <- enw_example("nowcast")
  obs <- enw_example("obs")
  vdiffr::expect_doppelganger(
    "enw_plot_obs default", enw_plot_obs(obs, x = reference_date)
  )
  vdiffr::expect_doppelganger(
    "enw_plot_obs default with log scale",
    enw_plot_obs(obs, x = reference_date, log = TRUE)
  )
  vdiffr::expect_doppelganger(
    "enw_plot_obs default with latest obs",
    enw_plot_obs(nowcast$latest[[1]], x = reference_date, latest_obs = obs)
  )
})