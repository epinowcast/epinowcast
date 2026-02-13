test_that(
  "enw_filter_reference_dates_by_report_start removes early reference dates",
  {
    obs <- data.table::data.table(
      reference_date = data.table::as.IDate(c(
        "2021-10-01", "2021-10-02", "2021-10-03"
      )),
      report_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-02", "2021-10-03"
      ))
    )
    result <- enw_filter_reference_dates_by_report_start(obs)
    expect_identical(nrow(result), 2L)
    expect_true(
      all(result$reference_date >= min(result$report_date))
    )
  }
)

test_that(
  "enw_filter_reference_dates_by_report_start retains NA reference dates",
  {
    obs <- data.table::data.table(
      reference_date = data.table::as.IDate(c(
        NA, "2021-10-02", "2021-10-03"
      )),
      report_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-02", "2021-10-03"
      ))
    )
    result <- enw_filter_reference_dates_by_report_start(obs)
    expect_identical(nrow(result), 3L)
    expect_true(is.na(result$reference_date[1]))
  }
)

test_that(
  "enw_filter_reference_dates_by_report_start works with by argument",
  {
    obs <- data.table::data.table(
      reference_date = data.table::as.IDate(c(
        "2021-10-01", "2021-10-02",
        "2021-10-01", "2021-10-02"
      )),
      report_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-02",
        "2021-10-01", "2021-10-01"
      )),
      group = c("a", "a", "b", "b")
    )
    result <- enw_filter_reference_dates_by_report_start(
      obs, by = "group"
    )
    # Group "a": min report_date = 2021-10-02,
    # so ref 2021-10-01 is dropped
    # Group "b": min report_date = 2021-10-01,
    # so both are kept
    expect_identical(nrow(result), 3L)
    expect_identical(
      sum(result$group == "a"), 1L
    )
    expect_identical(
      sum(result$group == "b"), 2L
    )
  }
)

test_that(
  "enw_filter_reference_dates_by_report_start keeps all rows when valid",
  {
    obs <- data.table::data.table(
      reference_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-03"
      )),
      report_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-03"
      ))
    )
    result <- enw_filter_reference_dates_by_report_start(obs)
    expect_identical(nrow(result), 2L)
  }
)

test_that(
  "enw_filter_reference_dates_by_report_start copies by default",
  {
    obs <- data.table::data.table(
      reference_date = data.table::as.IDate(c(
        "2021-10-01", "2021-10-02"
      )),
      report_date = data.table::as.IDate(c(
        "2021-10-02", "2021-10-02"
      ))
    )
    result <- enw_filter_reference_dates_by_report_start(obs)
    expect_identical(nrow(obs), 2L)
    expect_identical(nrow(result), 1L)
  }
)
