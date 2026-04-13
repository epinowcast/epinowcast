# Simulated preprocess object for testing
make_test_pobs_quant <- function(
  delays = 0:4, new_confirms = c(10, 5, 3, 1, 1),
  n_dates = 3, max_delay = 4
) {
  dates <- as.IDate(
    seq.Date(as.Date("2021-01-01"), by = 1, length.out = n_dates)
  )
  nc <- data.table::CJ(
    reference_date = dates, delay = delays
  )
  nc[, `:=`(
    .group = 1L,
    new_confirm = rep(new_confirms, n_dates),
    report_date = reference_date + delay
  )]
  nc[, confirm := cumsum(new_confirm), by = reference_date]
  nc[, max_confirm := max(confirm), by = reference_date]
  nc[, cum_prop_reported := confirm / max_confirm]
  nc[, prop_reported := new_confirm / max_confirm]
  data.table::setkey(nc, reference_date, report_date)

  pobs <- list(
    new_confirm = list(nc),
    by = list(character(0)),
    max_delay = max_delay
  )
  class(pobs) <- c("enw_preprocess_data", class(pobs))
  pobs
}

test_that("enw_delay_quantiles returns correct columns", {
  pobs <- make_test_pobs_quant()
  eq <- enw_delay_quantiles(pobs)
  expect_s3_class(eq, "data.table")
  expect_true(all(
    c("reference_date", ".group", "0.1", "0.5", "0.9") %in%
      names(eq)
  ))
})

test_that("enw_delay_quantiles respects custom quantiles", {
  pobs <- make_test_pobs_quant()
  eq <- enw_delay_quantiles(pobs, quantiles = c(0.25, 0.75))
  expect_true(all(c("0.25", "0.75") %in% names(eq)))
  expect_false("0.5" %in% names(eq))
})

test_that("enw_delay_quantiles are monotonically ordered", {
  pobs <- make_test_pobs_quant()
  eq <- enw_delay_quantiles(pobs, quantiles = c(0.1, 0.5, 0.9))
  expect_true(all(eq$`0.1` <= eq$`0.5`))
  expect_true(all(eq$`0.5` <= eq$`0.9`))
})

test_that("enw_delay_quantiles median is correct for known data", {
  # All notifications at delay 0
  pobs <- make_test_pobs_quant(
    delays = 0:2, new_confirms = c(10, 0, 0)
  )
  eq <- enw_delay_quantiles(pobs, quantiles = c(0.5))
  expect_true(all(eq$`0.5` == 0))

  # All notifications at delay 2
  pobs2 <- make_test_pobs_quant(
    delays = 0:2, new_confirms = c(0, 0, 10)
  )
  eq2 <- enw_delay_quantiles(pobs2, quantiles = c(0.5))
  expect_true(all(eq2$`0.5` == 2))
})

test_that("enw_delay_quantiles handles all-zero new_confirm", {
  pobs <- make_test_pobs_quant(
    new_confirms = c(0, 0, 0, 0, 0)
  )
  eq <- enw_delay_quantiles(pobs)
  # All-zero dates are filtered out

  expect_equal(nrow(eq), 0)
})

test_that("enw_delay_quantiles handles negative new_confirm", {
  pobs <- make_test_pobs_quant(
    delays = 0:4, new_confirms = c(10, -2, 3, 1, 1)
  )
  # Should not error — negatives are clamped to 0
  eq <- enw_delay_quantiles(pobs)
  expect_s3_class(eq, "data.table")
  expect_true(nrow(eq) > 0)
})

test_that("enw_delay_quantiles within delay range", {
  pobs <- make_test_pobs_quant()
  eq <- enw_delay_quantiles(pobs, quantiles = c(0.1, 0.5, 0.9))
  expect_true(all(eq$`0.1` >= 0))
  expect_true(all(eq$`0.9` <= 4))
})
