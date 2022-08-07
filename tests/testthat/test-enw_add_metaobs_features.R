library(data.table)

# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- germany_covid19_hosp[
  (location == "DE") & (age_group %in% "00+")
]

holidays = c(
  "2021-04-04", "2021-04-05",
  "2021-05-01", "2021-05-13",
  "2021-05-24"
)

junk <- c("Garbage Date")

test_that("enw_add_metaobs_features datecol arg validated (exists and is.Date)", {
  expect_error(enw_add_metaobs_features(nat_germany_hosp, datecol = "reference_date"), NA)
  expect_error(enw_add_metaobs_features(nat_germany_hosp, datecol = "report_date"), NA)
  expect_error(enw_add_metaobs_features(nat_germany_hosp))
  expect_error(enw_add_metaobs_features(nat_germany_hosp, datecol = "location"))
})


test_that("enw_add_metaobs_features errors when provided unparseable dates.", {
  expect_error(enw_add_metaobs_features(
    nat_germany_hosp,
    datecol = "reference_date",
    holidays = junk
  ))
  expect_error(enw_add_metaobs_features(
    nat_germany_hosp,
    datecol = "reference_date",
    holidays = c(holidays, junk)
  ))
})

test_that("enw_add_metaobs_features does not set holidays if `c()` or `NULL` provided", {
  mobs <- enw_add_metaobs_features(
    nat_germany_hosp,
    datecol = "reference_date",
    holidays = NULL,
    holidays_to = "Holiday"
  )
  expect_equal(mobs[day_of_week == "Holiday", .N], 0)
  mobs <- enw_add_metaobs_features(
    nat_germany_hosp,
    datecol = "reference_date",
    holidays = c(),
    holidays_to = "Holiday"
  )
  expect_equal(mobs[day_of_week == "Holiday", .N], 0)
})

test_that("enw_preprocess_data passes arguments to enw_add_metaobs_features", {
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
