library(data.table)

# Filter example hospitalisation data to be natioanl and over all ages
nat_germany_hosp <- setkey(germany_covid19_hosp[
  (location == "DE") & (age_group %in% "00+")
], reference_date)

holidays <- c(
  "2021-04-04", "2021-04-05",
  "2021-05-01", "2021-05-13",
  "2021-05-24"
)

junk <- c("Garbage Date")

metadatacols <- c("day_of_week", "day", "week", "month")

test_that("enw_add_metaobs_features datecol arg validated (exists and is.Date)", {
  expect_error(enw_add_metaobs_features(
    nat_germany_hosp, datecol = "reference_date"), NA
  )
  expect_error(enw_add_metaobs_features(nat_germany_hosp))
  expect_error(enw_add_metaobs_features(nat_germany_hosp, datecol = "location"))
})

test_that("enw_add_metaobs_features always adds all columns", {
  expect_equal(
    sort(intersect(
      colnames(enw_add_metaobs_features(
        nat_germany_hosp,
        datecol = "reference_date"
      )),
      metadatacols
    )),
    sort(metadatacols)
  )
})

test_that("enw_add_metaobs_features overwrites columns with a warning", {
  dummy <- as.data.table(nat_germany_hosp)
  dow <- "Placeholder"
  dummy[, day_of_week := dow]
  expect_warning(
    metaobs <- enw_add_metaobs_features(dummy, datecol = "reference_date")
  )
  expect_no_match(
    as.character(metaobs$day_of_week),
    dow
  )
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

test_that("enw_add_metaobs_features count from zero", {
  mobs <- enw_add_metaobs_features(
    nat_germany_hosp,
    datecol = "reference_date",
    holidays = NULL,
    holidays_to = "Holiday"
  )
  expect_equal(mobs[1, c(day, week, month)], c(0, 0, 0))
})

test_that("enw_add_metaobs_features resulting day, week, month always ascending", {
  mobs <- enw_add_metaobs_features(
    rbind(
      copy(nat_germany_hosp)[, reference_date := reference_date - 365],
      nat_germany_hosp
    ),
    datecol = "reference_date",
    holidays = NULL,
    holidays_to = "Holiday"
  )
  expect_equal(mobs[, c(
    all(diff(day) >= 0), all(diff(week) >= 0), all(diff(month) >= 0)
  )], c(TRUE, TRUE, TRUE))
})
