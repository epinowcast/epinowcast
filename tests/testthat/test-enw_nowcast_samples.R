test_that("enw_nowcast_samples can extract nowcast samples as expected", {
  fit <- enw_example("nowcast")
  expect_snapshot(
    round_numerics(
      enw_nowcast_samples(
        fit$fit[[1]], fit$latest[[1]],
        max_delay = fit$max_delay
      )[1:10]
    )
  )
})

test_that(paste(
  "enw_nowcast_samples can extract nowcast samples as expected",
  "when a delay larger than modelled is specified"
), {
  fit <- enw_example("nowcast")
  expect_snapshot(
    round_numerics(
      enw_nowcast_samples(
        fit$fit[[1]], fit$latest[[1]], max_delay = 22
      )[c(1:10, 1001:1010, 2001:2010)]
    )
  )
})
