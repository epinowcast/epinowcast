test_that("check_design_matrix_sparsity is silent for small matrices", {
  small_matrix <- matrix(1, nrow = 5, ncol = 5)
  expect_silent(
    check_design_matrix_sparsity(small_matrix, min_matrix_size = 30)
  )
})

test_that("check_design_matrix_sparsity is silent for non-sparse matrices", {
  non_sparse_matrix <- matrix(runif(200), nrow = 10, ncol = 20)
  expect_silent(check_design_matrix_sparsity(non_sparse_matrix))
})

test_that("check_design_matrix_sparsity gives message for sparse matrices", {
  sparse_matrix <- matrix(0, nrow = 10, ncol = 20)
  sparse_matrix[sample.int(200, 10)] <- 1
  expect_message(check_design_matrix_sparsity(sparse_matrix),
                 "The checked design matrix is sparse")
})

test_that("check_design_matrix_sparsity respects custom name and threshold", {
  custom_matrix <- matrix(c(rep(0, 95), rep(1, 5)), nrow = 10)
  expect_message(check_design_matrix_sparsity(custom_matrix,
                                              sparsity_threshold = 0.8,
                                              name = "custom"),
                 "The custom design matrix is sparse")
})

test_that("check_design_matrix_sparsity handles all-zero matrices", {
  all_zero_matrix <- matrix(0, nrow = 10, ncol = 10)
  expect_message(check_design_matrix_sparsity(all_zero_matrix),
                 "The checked design matrix is sparse")
})

test_that("check_design_matrix_sparsity is silent for non-zero matrices", {
  no_zero_matrix <- matrix(1, nrow = 10, ncol = 10)
  expect_silent(check_design_matrix_sparsity(no_zero_matrix))
})
