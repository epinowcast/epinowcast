test_that("enw_add_cumulative_membership adds features as expected", {
  metaobs <- data.frame(week = 1:3)
  metaobs <- enw_add_cumulative_membership(metaobs, "week")
  expect_identical(
    metaobs,
    data.table::data.table(
      week = 1:3,
      .group = 1,
      cweek2 = c(0, 1, 1),
      cweek3 = c(0, 0, 1)
    )
  )
})

test_that(
  "enw_add_cumulative_membership adds features as expected when a .group
   variable is present",
  {
    metaobs <- data.frame(week = 1:3, .group = c(1, 1, 2))
    metaobs <- enw_add_cumulative_membership(metaobs, "week")
  expect_identical(
      metaobs,
      data.table::data.table(
        week = 1:3,
        .group = c(1, 1, 2),
        cweek2 = c(0, 1, 0),
        cweek3 = c(0, 0, 1)
      )
    )
  }
)

test_that("enw_add_cumulative_membership fails as expected", {
  metaobs <- data.table::data.table(week = 1:3)
  expect_error(
    enw_add_cumulative_membership(metaobs, "day"),
    regexp = "The following columns are required: day"
  )
  expect_error(
    enw_add_cumulative_membership(metaobs[, week := as.factor(week)], "week"),
    "Requested variable week is not numeric. Cumulative membership effects"
  )
})
