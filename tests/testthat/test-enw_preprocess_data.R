# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- germany_covid19_hosp[location == "DE"]
nat_germany_hosp <- nat_germany_hosp[age_group == "00+"]
cols <- c(
  "obs", "new_confirm", "latest", "missing_reference", "reporting_triangle",
  "metareference", "metareport", "metadelay", "max_delay", "time", "snapshots",
  "by", "groups", "max_date", "timestep"
)
test_that(
  "enw_preprocess_data() produces expected output with default settings",
  {
    pobs <- enw_preprocess_data(nat_germany_hosp, max_delay = 20)
    expect_data_table(pobs)
    expect_identical(colnames(pobs), cols)
    expect_data_table(pobs$obs[[1]])
    expect_data_table(pobs$new_confirm[[1]])
    expect_data_table(pobs$latest[[1]])
    expect_data_table(pobs$missing_reference[[1]])
    expect_data_table(pobs$reporting_triangle[[1]])
    expect_data_table(pobs$metareference[[1]])
    expect_data_table(pobs$metareport[[1]])
    expect_data_table(pobs$metadelay[[1]])
    expect_identical(pobs$time[[1]], 198L)
    expect_identical(pobs$snapshots[[1]], 198L)
    expect_identical(pobs$groups[[1]], 1L)
    expect_identical(pobs$max_delay, 20)
    expect_identical(pobs$timestep[[1]], "day")
  }
)

test_that("enw_preprocess_data() produces expected output when excluding and
          using a maximum delay of 10", {
  expect_warning(
    # nolint next: implicit_assignment_linter.
    pobs <- enw_preprocess_data(
      nat_germany_hosp,
      max_delay = 10
    ),
    regexp = "Consider using a larger maximum delay"
  )
  expect_data_table(pobs)
  expect_identical(pobs$time[[1]], 198L)
  expect_identical(pobs$snapshots[[1]], 198L)
  expect_identical(pobs$groups[[1]], 1L)
  expect_identical(pobs$max_delay, 10)
  expect_identical(pobs$timestep[[1]], "day")
})

test_that("enw_preprocess_data() produces expected output when not setting
           max_delay", {
  expect_message(
    # nolint next: implicit_assignment_linter.
    pobs <- enw_preprocess_data(nat_germany_hosp),
    regexp = "the maximum observed delay"
  )
  expect_data_table(pobs)
  expect_identical(pobs$max_delay, 82)
})

test_that("enw_preprocess_data() handles groups as expected", {
  pobs <- enw_preprocess_data(
    germany_covid19_hosp,
    max_delay = 20,
    by = c("location", "age_group")
  )
  expect_data_table(pobs)
  expect_identical(colnames(pobs), cols)
  expect_identical(pobs$time[[1]], 198L)
  expect_identical(pobs$snapshots[[1]], 23562L)
  expect_identical(pobs$groups[[1]], 119L)
  expect_identical(pobs$max_delay, 20)
  expect_identical(pobs$timestep[[1]], "day")

})

test_that(
  "enw_preprocess_data() can handle a non-default timestep as expected", {
    weekly_nat_germany_hosp <- enw_aggregate_cumulative(
      nat_germany_hosp, timestep = "week"
    )

    weekly_nat_germany_hosp <- enw_filter_reference_dates(
      weekly_nat_germany_hosp, earliest_date = "2021-05-10"
    )

    weekly_pobs <- enw_preprocess_data(
      weekly_nat_germany_hosp,
      max_delay = 5, timestep = "week"
    )
    expect_data_table(weekly_pobs)
    expect_identical(colnames(weekly_pobs), cols)
    expect_identical(weekly_pobs$time[[1]], 24L)
    expect_identical(weekly_pobs$snapshots[[1]], 24L)
    expect_identical(weekly_pobs$groups[[1]], 1L)
    expect_identical(weekly_pobs$max_delay[[1]], 5)
    expect_identical(weekly_pobs$timestep[[1]], "week")
    expect_identical(
      unique(weekly_pobs$obs[[1]]$reference_date)[1:2],
      as.IDate(c("2021-05-10", "2021-05-17"))
    )
    expect_identical(
      unique(weekly_pobs$obs[[1]]$report_date)[1:2],
      as.IDate(c("2021-05-10", "2021-05-17"))
    )
    expect_setequal(
      weekly_pobs$metareport[[1]]$delay, 0:4
    )
    expect_identical(
      weekly_pobs$metareport[[1]]$date[20:21],
      as.IDate(c("2021-09-20", "2021-09-27"))
    )
    expect_identical(
      weekly_pobs$metadelay[[1]]$delay, 0:4
    )
  }
)

test_that("enw_preprocess_data() throws error when using months", {
  expect_error(
    enw_preprocess_data(
      nat_germany_hosp,
      max_delay = 20,
      timestep = "month"
    ),
    regexp = "Calendar months are not currently supported"
  )
}
)

test_that(
  "enw_preprocess_data() hasn't changed compared to saved example data",
  {
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
    expect_identical(pobs, enw_example("preprocessed"))
  }
)

test_that("enw_preprocess_data passes arguments to enw_add_metaobs_features", {
  holidays <- c(
    "2021-04-04", "2021-04-05",
    "2021-05-01", "2021-05-13",
    "2021-05-24"
  )
  pobs <- enw_preprocess_data(
    nat_germany_hosp, max_delay = 20, holidays = holidays
    )
  expect_identical(
    as.character(
      pobs$metareference[[1]][date %in% as.Date(holidays), unique(day_of_week)]
    ),
    "Sunday"
  )
  expect_identical(
    as.character(
      pobs$metareport[[1]][date %in% as.Date(holidays), unique(day_of_week)]
    ),
    "Sunday"
  )
  expect_identical(
    as.character(enw_preprocess_data(
      nat_germany_hosp,
      max_delay = 20,
      holidays = holidays,
      holidays_to = "Holiday"
    )$metareport[[1]][date %in% as.Date(holidays), unique(day_of_week)]),
    "Holiday"
  )
  expect_error(
    enw_preprocess_data(nat_germany_hosp, max_delay = 20, holidays = junk)
  )
})

test_that(
  "enw_preprocess_data() fails as expected with incorrect max_delay input",
  {
    expect_error(
      suppressWarnings(
        enw_preprocess_data(nat_germany_hosp, max_delay = "junk")
      )
    )
    expect_error(
      enw_preprocess_data(nat_germany_hosp, max_delay = 0)
    )
  }
)

test_that(
  "enw_preprocess_data fails as expected when input data is not aggregated by
  the specified by variables",
  {
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
  }
)
