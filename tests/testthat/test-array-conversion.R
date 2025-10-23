test_that("array(unlist()) scrambles nested matrix structures", {
  # Create a simple nested structure similar to rep_agg_indicators
  # Groups=2, Times=2, Delays=3x3

  # Group 1, Time 1: Identity-like matrix with 1 in row 1
  g1_t1 <- matrix(c(
    1, 1, 0,
    0, 0, 0,
    0, 0, 0
  ), nrow = 3, byrow = TRUE)

  # Group 1, Time 2: Identity-like matrix with 1 in row 2
  g1_t2 <- matrix(c(
    0, 0, 0,
    0, 1, 1,
    0, 0, 0
  ), nrow = 3, byrow = TRUE)

  # Group 2, Time 1: Identity-like matrix with 1 in row 3
  g2_t1 <- matrix(c(
    0, 0, 0,
    0, 0, 0,
    0, 0, 1
  ), nrow = 3, byrow = TRUE)

  # Group 2, Time 2: Identity-like matrix with 1 in row 1
  g2_t2 <- matrix(c(
    1, 0, 0,
    0, 0, 0,
    0, 0, 0
  ), nrow = 3, byrow = TRUE)

  # Create nested list structure
  structural <- list(
    list(g1_t1, g1_t2),  # Group 1
    list(g2_t1, g2_t2)   # Group 2
  )

  # Expected: Each matrix should preserve its structure
  # g1_t1 should be at [1, 1, , ]
  # g1_t2 should be at [1, 2, , ]
  # g2_t1 should be at [2, 1, , ]
  # g2_t2 should be at [2, 2, , ]

  groups <- 2
  times <- 2
  max_delay <- 3

  # BROKEN APPROACH: array(unlist())
  broken_array <- array(
    unlist(structural),
    dim = c(groups, times, max_delay, max_delay)
  )

  # CORRECT APPROACH: Manual loop
  correct_array <- array(
    0,
    dim = c(groups, times, max_delay, max_delay)
  )
  for (g in seq_along(structural)) {
    for (t in seq_along(structural[[g]])) {
      correct_array[g, t, , ] <- structural[[g]][[t]]
    }
  }

  # Test that broken approach differs from correct approach
  expect_false(
    identical(broken_array, correct_array),
    info = "array(unlist()) should produce different result than manual loop"
  )

  # Test correct approach preserves each matrix
  expect_identical(
    correct_array[1, 1, , ],
    g1_t1,
    info = "Group 1, Time 1 matrix should be preserved"
  )

  expect_identical(
    correct_array[1, 2, , ],
    g1_t2,
    info = "Group 1, Time 2 matrix should be preserved"
  )

  expect_identical(
    correct_array[2, 1, , ],
    g2_t1,
    info = "Group 2, Time 1 matrix should be preserved"
  )

  expect_identical(
    correct_array[2, 2, , ],
    g2_t2,
    info = "Group 2, Time 2 matrix should be preserved"
  )

  # Test broken approach does NOT preserve matrices
  expect_false(
    identical(broken_array[1, 1, , ], g1_t1),
    info = "array(unlist()) should NOT preserve Group 1, Time 1 matrix"
  )

  # Show what actually happens with array(unlist())
  # The matrices get scrambled across time points
  cat("\n=== Demonstrating the bug ===\n")
  cat("Expected g1_t1 at [1,1,,] - row 1 should have non-zero values:\n")
  print(g1_t1)
  cat("\nActual result from array(unlist()):\n")
  print(broken_array[1, 1, , ])
  cat("\nCorrect result from manual loop:\n")
  print(correct_array[1, 1, , ])

  # Verify the key property: each matrix should have exactly 1 non-zero row
  count_nonzero_rows <- function(mat) {
    sum(apply(mat, 1, function(row) any(row != 0)))
  }

  # Correct approach: all matrices have 1 non-zero row
  for (g in 1:groups) {
    for (t in 1:times) {
      n_nonzero <- count_nonzero_rows(correct_array[g, t, , ])
      expect_equal(
        n_nonzero, 1,
        info = sprintf("Correct array [%d,%d,,] should have 1 non-zero row", g, t)
      )
    }
  }

  # Broken approach: some matrices will have multiple non-zero rows
  broken_counts <- numeric()
  for (g in 1:groups) {
    for (t in 1:times) {
      broken_counts <- c(
        broken_counts,
        count_nonzero_rows(broken_array[g, t, , ])
      )
    }
  }

  expect_true(
    any(broken_counts != 1),
    info = "array(unlist()) should produce matrices with != 1 non-zero rows"
  )

  cat("\nNon-zero row counts with array(unlist()):", broken_counts, "\n")
  cat("Expected: all 1s\n")
  cat("This demonstrates why the manual loop is necessary.\n")
})

test_that("array conversion preserves matrix structure for real data size", {
  # Test with realistic dimensions from the package
  # This is closer to what actually happens in enw_report()

  groups <- 1
  times <- 10  # 10 time points
  max_delay <- 7  # Weekly data

  # Create matrices where Wednesday (day 4) aggregates days 1-7
  wednesday_row <- 4

  structural <- list()
  for (g in 1:groups) {
    structural[[g]] <- list()
    for (t in 1:times) {
      mat <- matrix(0, nrow = max_delay, ncol = max_delay)
      mat[wednesday_row, ] <- 1  # Wednesday aggregates all days
      structural[[g]][[t]] <- mat
    }
  }

  # Correct approach
  correct_array <- array(
    0,
    dim = c(groups, times, max_delay, max_delay)
  )
  for (g in seq_along(structural)) {
    for (t in seq_along(structural[[g]])) {
      correct_array[g, t, , ] <- structural[[g]][[t]]
    }
  }

  # Verify each matrix has exactly 1 non-zero row at position wednesday_row
  for (t in 1:times) {
    mat <- correct_array[1, t, , ]

    # Check only row wednesday_row is non-zero
    for (row in 1:max_delay) {
      if (row == wednesday_row) {
        expect_true(
          all(mat[row, ] == 1),
          info = sprintf("Time %d: Wednesday row should be all 1s", t)
        )
      } else {
        expect_true(
          all(mat[row, ] == 0),
          info = sprintf("Time %d: Non-Wednesday row %d should be all 0s", t, row)
        )
      }
    }
  }

  # Now test that array(unlist()) would break this
  broken_array <- array(
    unlist(structural),
    dim = c(groups, times, max_delay, max_delay)
  )

  # Count how many matrices have the correct structure
  broken_correct_count <- 0
  for (t in 1:times) {
    mat <- broken_array[1, t, , ]
    is_correct <- all(mat[wednesday_row, ] == 1) &&
                  sum(rowSums(mat) > 0) == 1
    if (is_correct) broken_correct_count <- broken_correct_count + 1
  }

  expect_true(
    broken_correct_count < times,
    info = "array(unlist()) should break structure for some time points"
  )

  cat(sprintf(
    "\nWith array(unlist()): %d/%d matrices preserved correctly\n",
    broken_correct_count, times
  ))
  cat("This demonstrates the scrambling effect.\n")
})
