
# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
nat_germany_hosp <- nat_germany_hosp[age_group %in% "00+"]
cols <- c(
  "obs", "new_confirm", "latest", "missing_reference", "reporting_triangle",
  "metareference", "metareport", "metadelay", "time", "snapshots", "by", "groups", "max_delay", "max_date", "timestep"
)
test_that("enw_preprocess_data() produces expected output with default settings", {
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
  expect_equal(pobs$timestep[[1]], "day")
})

test_that("enw_preprocess_data() produces expected output when excluding and using a maximum delay of 10", {
  pobs <- enw_preprocess_data(
    nat_germany_hosp,
    max_delay = 10
  )
  expect_data_table(pobs)
  expect_equal(pobs$time[[1]], 198)
  expect_equal(pobs$snapshots[[1]], 198)
  expect_equal(pobs$groups[[1]], 1)
  expect_equal(pobs$max_delay[[1]], 10)
  expect_equal(pobs$timestep[[1]], "day")
})

test_that("enw_preprocess_data() handles groups as expected", {
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
  expect_equal(pobs$timestep[[1]], "day")
})

test_that("enw_preprocess_data() can handle a non-default timestep as expected", {
  weekly_nat_germany_hosp <- nat_germany_hosp |>
    enw_aggregate_cumulative(timestep = "week")

  weekly_nat_germany_hosp <- weekly_nat_germany_hosp |>
    enw_filter_reference_dates(earliest_date = "2021-05-11")

  weekly_pobs <- enw_preprocess_data(
    weekly_nat_germany_hosp, max_delay = 5, timestep = "week"
  )
  expect_data_table(weekly_pobs)
  expect_equal(colnames(weekly_pobs), cols)
  expect_equal(weekly_pobs$time[[1]], 21)
  expect_equal(weekly_pobs$snapshots[[1]], 21)
  expect_equal(weekly_pobs$groups[[1]], 1)
  expect_equal(weekly_pobs$max_delay[[1]], 5)
  expect_equal(weekly_pobs$timestep[[1]], "week")
  expect_equal(
    unique(weekly_pobs$obs[[1]]$reference_date)[1:2],
    as.IDate(c("2021-05-11", "2021-05-18"))
  )
  expect_equal(
    unique(weekly_pobs$obs[[1]]$report_date)[1:2],
    as.IDate(c("2021-05-11", "2021-05-18"))
  )
  expect_equal(
    unique(weekly_pobs$metareport[[1]]$delay), 0:4
  )
  expect_equal(
    weekly_pobs$metareport[[1]]$date[20:21],
    as.IDate(c("2021-09-21", "2021-09-28"))
  )
  expect_equal(
    weekly_pobs$metadelay[[1]]$delay, 0:4
  )
})

test_that("enw_preprocess_data() hasn't changed compared to saved example data", {
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

test_that("enw_preprocess_data() passes arguments to enw_add_metaobs_features", {
  holidays <- c(
    "2021-04-04", "2021-04-05",
    "2021-05-01", "2021-05-13",
    "2021-05-24"
  )
  pobs <- enw_preprocess_data(nat_germany_hosp, holidays = holidays)
  expect_equal(
    as.character(
      pobs$metareference[[1]][date %in% as.Date(holidays), unique(day_of_week)]
    ),
    "Sunday"
  )
  expect_equal(
    as.character(
      pobs$metareport[[1]][date %in% as.Date(holidays), unique(day_of_week)]
    ),
    "Sunday"
  )
  expect_equal(
    as.character(enw_preprocess_data(
      nat_germany_hosp,
      holidays = holidays,
      holidays_to = "Holiday"
    )$metareport[[1]][date %in% as.Date(holidays), unique(day_of_week)]),
    "Holiday"
  )
  expect_error(
    enw_preprocess_data(nat_germany_hosp, holidays = junk)
  )
})

test_that(
  "enw_preprocess_data() fails as expected with incorrect max_delay input", {
    expect_error(
      suppressWarnings(
        enw_preprocess_data(nat_germany_hosp, max_delay = "junk")
      )
    )
    expect_error(
      enw_preprocess_data(nat_germany_hosp, max_delay = 0)
    )
})

test_that(
  "enw_preprocess_data fails as expected when input data is not aggregated by the specified by variables", {
    expect_error(
      enw_preprocess_data(germany_covid19_hosp),
      "The input data seems to be stratified by more variables"
    )
    expect_error(
      enw_preprocess_data(germany_covid19_hosp, by = "location"),
      "The input data seems to be stratified by more variables"
    )
    expect_error(
      enw_preprocess_data(germany_covid19_hosp, by = "age_group"),
      "The input data seems to be stratified by more variables"
    )
})
