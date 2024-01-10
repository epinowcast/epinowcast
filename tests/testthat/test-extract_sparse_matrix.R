test_that("extract_sparse_matrix() can extract a sparse matrix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat)
  expect_identical(sparse_mat$nw, 9L)
  expect_identical(sparse_mat$w, c(1, 4, 7, 2, 5, 8, 3, 6, 9))
  expect_identical(sparse_mat$nv, 9L)
  expect_identical(sparse_mat$v, c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$nu, 4L)
  expect_identical(sparse_mat$u, c(1L, 4L, 7L, 10L))
})

test_that("extract_sparse_matrix() can extract a sparse matrix with a prefix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat, "prefix")
  expect_identical(sparse_mat$prefix_nw, 9L)
  expect_identical(sparse_mat$prefix_w, c(1, 4, 7, 2, 5, 8, 3, 6, 9))
  expect_identical(sparse_mat$prefix_nv, 9L)
  expect_identical(sparse_mat$prefix_v, c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$prefix_nu, 4L)
  expect_identical(sparse_mat$prefix_u, c(1L, 4L, 7L, 10L))
})

test_that("extract_sparse_matrix() handles matrices with zeros correctly", {
  mat <- matrix(1:9, nrow = 3)
  mat[2, 2] <- 0
  mat[3, 1] <- 0

  sparse_mat <- extract_sparse_matrix(mat)

  expect_identical(sparse_mat$nw, 7L)
  expect_identical(sparse_mat$w, c(1, 4, 7, 2, 8, 6, 9))
  expect_identical(sparse_mat$nv, 7L)
  expect_identical(sparse_mat$v, c(1L, 2L, 3L, 1L, 3L, 2L, 3L))

  expect_identical(sparse_mat$nu, 4L)
  expect_identical(sparse_mat$u, c(1L, 4L, 6L, 8L))
})
