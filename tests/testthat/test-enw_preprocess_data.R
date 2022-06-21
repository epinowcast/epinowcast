library(data.table)

# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
nat_germany_hosp <- nat_germany_hosp[age_group %in% "00+"]

cols <- c(
  "obs", "new_confirm", "latest", "reporting_triangle",
  "metareference", "metareport", "time", "snapshots", "groups",
  "max_delay", "max_date"
)
test_that("Preprocessing produces expected output with default settings", {
  pobs <- enw_preprocess_data(nat_germany_hosp)
  expect_data_table(pobs)
  expect_equal(colnames(pobs), cols)
  expect_data_table(pobs$obs[[1]])
  expect_data_table(pobs$new_confirm[[1]])
  expect_data_table(pobs$latest[[1]])
  expect_data_table(pobs$reporting_triangle[[1]])
  expect_data_table(pobs$metareference[[1]])
  expect_data_table(pobs$metareport[[1]])
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 198)
  expect_equal(pobs$groups[[1]], 1)
  expect_equal(pobs$max_delay[[1]], 20)
})

test_that("Preprocessing produces expected output when excluding and using a
  maximum delay of 10", {
  pobs <- enw_preprocess_data(
    nat_germany_hosp,
    max_delay = 10, max_delay_strat = "exclude"
  )
  expect_data_table(pobs)
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 198)
  expect_equal(pobs$groups[[1]], 1)
  expect_equal(pobs$max_delay[[1]], 10)
})

test_that("Preprocessing hanbdles groups as expected", {
  pobs <- enw_preprocess_data(
    germany_covid19_hosp,
    by = c("location", "age_group")
  )
  expect_data_table(pobs)
  expect_equal(colnames(pobs), cols)
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 23562)
  expect_equal(pobs$groups[[1]], 119)
  expect_equal(pobs$max_delay[[1]], 20)
})
