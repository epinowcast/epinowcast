test_that("enw_delay_categories computes correct proportions", {
  pobs <- make_test_pobs()
  nc <- enw_delay_categories(pobs, c(0, 2, 5))

  # Two groups: [0,2) and [2,5)
  expect_equal(
    levels(nc$delay_group), c("[0,2)", "[2,5)")
  )

  # Check one reference date
  one_date <- nc[reference_date == as.IDate("2021-01-01")]
  # [0,2): new_confirm = 10+5 = 15
  # [2,5): new_confirm = 3+1+1 = 5
  # total = 20
  expect_equal(one_date$new_confirm, c(15, 5))
  expect_equal(
    one_date$prop_reported, c(15 / 20, 5 / 20)
  )
  # cum_prop: [0,2) confirm = 15, [2,5) confirm = 20
  expect_equal(
    one_date$cum_prop_reported, c(15 / 20, 20 / 20)
  )
})

test_that("enw_delay_categories filters zero max_confirm", {
  pobs <- make_test_pobs(
    new_confirms = c(0, 0, 0, 0, 0)
  )
  nc <- enw_delay_categories(pobs, c(0, 2, 5))
  expect_equal(nrow(nc), 0)
})

test_that("enw_delay_categories drops out-of-range delays", {
  pobs <- make_test_pobs(delays = 0:4)
  # Thresholds only cover [0,3) — delays 3-4 are outside

  nc <- enw_delay_categories(pobs, c(0, 3))
  expect_true(all(nc$delay_group == "[0,3)"))
})

test_that("enw_delay_categories handles single-day threshold", {
  pobs <- make_test_pobs()
  nc <- enw_delay_categories(pobs, c(0, 1, 2, 3, 4, 5))
  expect_equal(
    levels(nc$delay_group),
    c("[0,1)", "[1,2)", "[2,3)", "[3,4)", "[4,5)")
  )
})

test_that("enw_delay_categories results sum to total", {
  pobs <- make_test_pobs()
  nc <- enw_delay_categories(pobs, c(0, 2, 5))
  totals <- nc[,
    .(total = sum(new_confirm)),
    by = reference_date
  ]
  # Each date has 10+5+3+1+1 = 20 total notifications
  expect_true(all(totals$total == 20))
})
