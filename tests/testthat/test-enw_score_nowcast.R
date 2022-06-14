if (requireNamespace("scoringutils")) {
  test_that("Can score nowcasts", {
    skip_on_cran()
    nowcast <- enw_example("nowcast")
    summarised_nowcast <- summary(nowcast)
    obs <- enw_example("observations")

    expect_data_table(
      suppressWarnings(suppressMessages(
        enw_score_nowcast(summarised_nowcast, obs))
      )
    )
    expect_data_table(
      suppressWarnings(suppressMessages(
        enw_score_nowcast(
          summarised_nowcast, obs, log = TRUE
      )))
    )
    expect_data_table(
      suppressWarnings(suppressMessages(enw_score_nowcast(
        summarised_nowcast, obs,
        check = TRUE
      )))
    )
  })
}
