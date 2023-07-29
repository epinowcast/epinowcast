test_that("enw_metadata_maxdelay produces the expected metadata", {
  obs <- enw_example(type = "preprocessed_observations")$obs[[1]]
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 10),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(10, 20, 10),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 30),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(30, 20, 20),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  )
  expect_equal(
    enw_metadata_maxdelay(obs = obs, max_delay = 20),
    metamaxdelay <- data.table::data.table(
      type = c("specified", "observed", "modelled"),
      delay = c(20, 20, 20),
      description = c(
        "maximum delay specified by the user",
        "maximum delay observed in the data",
        "maximum delay used in model"
      )
    )
  )
})
