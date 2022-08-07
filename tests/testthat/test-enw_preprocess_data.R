library(data.table)

# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
nat_germany_hosp <- nat_germany_hosp[age_group %in% "00+"]

cols <- c(
  "obs", "new_confirm", "latest", "missing_reference", "reporting_triangle",
  "metareference", "metareport", "metadelay", "time", "snapshots", "by", "groups", "max_delay", "max_date"
)
test_that("Preprocessing produces expected output with default settings", {
  pobs <- enw_preprocess_data(nat_germany_hosp)
  expect_data_table(pobs)
  expect_equal(colnames(pobs), cols)
  expect_data_table(pobs$obs[[1]])
  expect_data_table(pobs$new_confirm[[1]])
  expect_data_table(pobs$latest[[1]])
  expect_data_table(pobs$missing_reference[[1]])
  expect_data_table(pobs$reporting_triangle[[1]])
  expect_data_table(pobs$metareference[[1]])
  expect_data_table(pobs$metareport[[1]])
  expect_data_table(pobs$metadelay[[1]])
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 198)
  expect_equal(pobs$groups[[1]], 1)
  expect_equal(pobs$max_delay[[1]], 20)
})

test_that("Preprocessing produces expected output when excluding and using a
  maximum delay of 10", {
  pobs <- enw_preprocess_data(
    nat_germany_hosp,
    max_delay = 10
  )
  expect_data_table(pobs)
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 198)
  expect_equal(pobs$groups[[1]], 1)
  expect_equal(pobs$max_delay[[1]], 10)
})

test_that("Preprocessing handles groups as expected", {
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

test_that("enw_preprocess_data hasn't changed compared to saved example data", {
  nat_germany_hosp <- enw_filter_report_dates(
    nat_germany_hosp,
    latest_date = "2021-10-01"
  )

  # Make sure observations are complete
  nat_germany_hosp <- enw_complete_dates(
    nat_germany_hosp,
    by = c("location", "age_group")
  )
  # Make a retrospective dataset
  retro_nat_germany <- enw_filter_report_dates(
    nat_germany_hosp,
    remove_days = 40
  )
  retro_nat_germany <- enw_filter_reference_dates(
    retro_nat_germany,
    include_days = 40
  )

  # Preprocess observations
  pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)
  expect_equal(pobs, enw_example("preprocessed"))
})
