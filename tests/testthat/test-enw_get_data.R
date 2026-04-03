pobs <- enw_example("preprocessed_observations")

test_that("enw_get_data extracts list columns correctly", {
  obs <- enw_get_data(pobs, "obs")
  expect_data_table(obs)
  expect_identical(obs, pobs$obs[[1]])
})

test_that("enw_get_data extracts all list columns", {
  list_cols <- c(
    "obs", "new_confirm", "latest",
    "missing_reference", "reporting_triangle",
    "metareference", "metareport", "metadelay", "by"
  )
  for (col in list_cols) {
    result <- enw_get_data(pobs, col)
    expect_identical(
      result, pobs[[col]][[1]],
      label = paste("enw_get_data for", col)
    )
  }
})

test_that("enw_get_data extracts scalar columns correctly", {
  expect_identical(
    enw_get_data(pobs, "max_delay"),
    pobs$max_delay
  )
  expect_identical(
    enw_get_data(pobs, "time"),
    pobs$time
  )
  expect_identical(
    enw_get_data(pobs, "snapshots"),
    pobs$snapshots
  )
  expect_identical(
    enw_get_data(pobs, "groups"),
    pobs$groups
  )
})

test_that("enw_get_data errors for invalid names", {
  expect_error(
    enw_get_data(pobs, "nonexistent"),
    "not found"
  )
})

test_that("enw_get_data works with epinowcast objects", {
  nowcast <- enw_example("nowcast")
  obs <- enw_get_data(nowcast, "obs")
  expect_data_table(obs)
  expect_identical(obs, nowcast$obs[[1]])

  expect_identical(
    enw_get_data(nowcast, "max_delay"),
    nowcast$max_delay
  )
})

test_that("enw_get_data extracts epinowcast-specific columns", {
  nowcast <- enw_example("nowcast")
  priors <- enw_get_data(nowcast, "priors")
  expect_true(!is.null(priors))

  fit <- enw_get_data(nowcast, "fit")
  expect_true(!is.null(fit))
})
