test_that(".precompute_matrix_indices computes correct indices", {
  # Matrix with known index pattern
  mat <- matrix(c(
    1, 1, 0,  # Row 1: indices 1, 2
    0, 0, 1,  # Row 2: index 3
    1, 0, 1   # Row 3: indices 1, 3
  ), nrow = 3, byrow = TRUE)

  result <- epinowcast:::.precompute_matrix_indices(mat)

  # Check n_selected
  expect_equal(result$n_selected[1], 2L)  # Row 1: 2 indices
  expect_equal(result$n_selected[2], 1L)  # Row 2: 1 index
  expect_equal(result$n_selected[3], 2L)  # Row 3: 2 indices

  # Check selected_idx
  expect_equal(result$selected_idx[1, 1:2], c(1L, 2L))  # Row 1
  expect_equal(result$selected_idx[2, 1], 3L)           # Row 2
  expect_equal(result$selected_idx[3, 1:2], c(1L, 3L))  # Row 3

  # Unused positions should be 0
  expect_equal(result$selected_idx[1, 3], 0L)
  expect_equal(result$selected_idx[2, 2:3], c(0L, 0L))
})

test_that(".precompute_matrix_indices handles empty rows", {
  mat <- matrix(c(
    1, 1,
    0, 0  # Empty row
  ), nrow = 2, byrow = TRUE)

  result <- epinowcast:::.precompute_matrix_indices(mat)

  # Empty row should have n_selected = 0
  expect_equal(result$n_selected[2], 0L)
  # All positions in empty row should be 0
  expect_equal(result$selected_idx[2, ], c(0L, 0L))
})

test_that(".precompute_matrix_indices handles all-ones row", {
  mat <- matrix(c(1, 1, 1, 1), nrow = 1)

  result <- epinowcast:::.precompute_matrix_indices(mat)

  expect_equal(result$n_selected[1], 4L)
  expect_equal(result$selected_idx[1, ], 1:4)
})

test_that(".precompute_aggregation_lookups preserves matrix structure", {
  # Create simple test structure
  mat1 <- matrix(c(
    1, 1, 0,
    0, 0, 0,
    0, 0, 0
  ), nrow = 3, byrow = TRUE)

  mat2 <- matrix(c(
    0, 0, 0,
    0, 1, 1,
    0, 0, 0
  ), nrow = 3, byrow = TRUE)

  structural <- list(
    list(mat1, mat2)  # 1 group, 2 times
  )

  result <- epinowcast:::.precompute_aggregation_lookups(
    structural,
    n_groups = 1,
    n_times = 2,
    max_delay = 3
  )

  # Check result has correct structure
  expect_true("n_selected" %in% names(result))
  expect_true("selected_idx" %in% names(result))
})

test_that(".precompute_aggregation_lookups computes correct indices", {
  # Matrix with known index pattern
  mat <- matrix(c(
    1, 1, 0,  # Row 1: indices 1, 2
    0, 0, 1,  # Row 2: index 3
    1, 0, 1   # Row 3: indices 1, 3
  ), nrow = 3, byrow = TRUE)

  structural <- list(list(mat))

  result <- epinowcast:::.precompute_aggregation_lookups(
    structural,
    n_groups = 1,
    n_times = 1,
    max_delay = 3
  )

  # Check n_selected
  expect_equal(result$n_selected[1, 1, 1], 2L)  # Row 1: 2 indices
  expect_equal(result$n_selected[1, 1, 2], 1L)  # Row 2: 1 index
  expect_equal(result$n_selected[1, 1, 3], 2L)  # Row 3: 2 indices

  # Check selected_idx
  expect_equal(result$selected_idx[1, 1, 1, 1:2], c(1L, 2L))  # Row 1
  expect_equal(result$selected_idx[1, 1, 2, 1], 3L)           # Row 2
  expect_equal(result$selected_idx[1, 1, 3, 1:2], c(1L, 3L))  # Row 3
})

test_that(".precompute_aggregation_lookups handles multiple groups", {
  mat_g1 <- matrix(c(1, 0, 0, 1), nrow = 2)
  mat_g2 <- matrix(c(0, 1, 1, 0), nrow = 2)

  structural <- list(
    list(mat_g1),  # Group 1
    list(mat_g2)   # Group 2
  )

  result <- epinowcast:::.precompute_aggregation_lookups(
    structural,
    n_groups = 2,
    n_times = 1,
    max_delay = 2
  )

  # Check result structure
  expect_true("n_selected" %in% names(result))
  expect_true("selected_idx" %in% names(result))
  expect_equal(dim(result$n_selected), c(2, 1, 2))
  expect_equal(dim(result$selected_idx), c(2, 1, 2, 2))
})

test_that(".precompute_aggregation_lookups handles empty rows", {
  mat <- matrix(c(
    1, 1,
    0, 0  # Empty row
  ), nrow = 2, byrow = TRUE)

  structural <- list(list(mat))

  result <- epinowcast:::.precompute_aggregation_lookups(
    structural,
    n_groups = 1,
    n_times = 1,
    max_delay = 2
  )

  # Empty row should have n_selected = 0
  expect_equal(result$n_selected[1, 1, 2], 0L)
})

test_that(".precompute_aggregation_lookups matches example from documentation", {
  # Wednesday-only reporting: aggregate all days (1-7) to Wednesday (day 4)
  wednesday_row <- 4
  max_delay <- 7

  mat <- matrix(0, nrow = max_delay, ncol = max_delay)
  mat[wednesday_row, ] <- 1  # Wednesday aggregates all days

  structural <- list(list(mat))

  result <- epinowcast:::.precompute_aggregation_lookups(
    structural,
    n_groups = 1,
    n_times = 1,
    max_delay = max_delay
  )

  # Check Wednesday row has all 7 indices
  expect_equal(result$n_selected[1, 1, wednesday_row], 7L)
  expect_equal(
    result$selected_idx[1, 1, wednesday_row, 1:7],
    1:7
  )

  # Check other rows are empty
  for (row in seq_len(max_delay)) {
    if (row != wednesday_row) {
      expect_equal(result$n_selected[1, 1, row], 0L)
    }
  }
})

test_that(".validate_structural_reporting accepts valid data.table", {
  structural <- data.table::data.table(
    .group = 1,
    date = as.Date("2021-01-01"),
    report_date = as.Date("2021-01-02"),
    report = 1
  )

  expect_invisible(epinowcast:::.validate_structural_reporting(structural))
})

test_that(".validate_structural_reporting accepts and converts data.frame", {
  structural <- data.frame(
    .group = 1,
    date = as.Date("2021-01-01"),
    report_date = as.Date("2021-01-02"),
    report = 1
  )

  result <- epinowcast:::.validate_structural_reporting(structural)
  expect_true(data.table::is.data.table(result))
  expect_equal(nrow(result), 1)
})

test_that(".validate_structural_reporting rejects missing columns", {
  # Missing report column
  structural <- data.table::data.table(
    .group = 1,
    date = as.Date("2021-01-01"),
    report_date = as.Date("2021-01-02")
  )

  expect_error(
    epinowcast:::.validate_structural_reporting(structural),
    "missing required columns"
  )
})

test_that(".validate_structural_reporting rejects invalid report values", {
  structural <- data.table::data.table(
    .group = 1,
    date = as.Date("2021-01-01"),
    report_date = as.Date("2021-01-02"),
    report = 2  # Invalid: not 0 or 1
  )

  expect_error(
    epinowcast:::.validate_structural_reporting(structural),
    "only 0s and 1s"
  )
})

test_that(".validate_structural_reporting rejects NA report values", {
  structural <- data.table::data.table(
    .group = 1,
    date = as.Date("2021-01-01"),
    report_date = as.Date("2021-01-02"),
    report = NA_real_
  )

  expect_error(
    epinowcast:::.validate_structural_reporting(structural),
    "only 0s and 1s"
  )
})

test_that(".structural_reporting_to_matrices creates correct structure", {
  nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
  pobs <- suppressWarnings(
    enw_preprocess_data(nat_germany_hosp, max_delay = 5)
  )

  # Create simple structural pattern from real data
  structural <- enw_dayofweek_structural_reporting(pobs, day_of_week = "Wednesday")

  result <- epinowcast:::.structural_reporting_to_matrices(structural, pobs)

  # Check it's a nested list
  expect_type(result, "list")
  expect_equal(length(result), pobs$groups[[1]])
  expect_equal(length(result[[1]]), pobs$time[[1]])

  # Check matrix structure
  mat <- result[[1]][[1]]
  expect_true(is.matrix(mat))
  expect_equal(dim(mat), c(pobs$max_delay, pobs$max_delay))
})

test_that(".structural_reporting_to_matrices handles custom patterns", {
  nat_germany_hosp <- germany_covid19_hosp[location == "DE"][age_group == "00+"]
  pobs <- suppressWarnings(
    enw_preprocess_data(nat_germany_hosp, max_delay = 5)
  )

  # Create structural with multiple reporting days
  structural <- enw_dayofweek_structural_reporting(
    pobs, day_of_week = c("Monday", "Wednesday", "Friday")
  )

  result <- epinowcast:::.structural_reporting_to_matrices(structural, pobs)

  expect_equal(length(result), pobs$groups[[1]])
  expect_equal(length(result[[1]]), pobs$time[[1]])
})
