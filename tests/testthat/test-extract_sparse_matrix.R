test_that("extract_sparse_matrix() can extract a sparse matrix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat)
  expect_identical(sparse_mat$nw, 9L)
  expect_identical(sparse_mat$w, c(1L, 4L, 7L, 2L, 5L, 8L, 3L, 6L, 9L))
  expect_identical(sparse_mat$nv, 9L)
  expect_identical(sparse_mat$v, c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$nu, 4L)
  expect_identical(sparse_mat$u, c(1L, 4L, 7L, 10L))
})

test_that("extract_sparse_matrix() can extract a sparse matrix with a prefix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat, "prefix")
  expect_identical(sparse_mat$prefix_nw, 9L)
  expect_identical(sparse_mat$prefix_w, c(1L, 4L, 7L, 2L, 5L, 8L, 3L, 6L, 9L))
  expect_identical(sparse_mat$prefix_nv, 9L)
  expect_identical(sparse_mat$prefix_v, c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$prefix_nu, 4L)
  expect_identical(sparse_mat$prefix_u, c(1L, 4L, 7L, 10L))
})

test_that("extract_sparse_matrix() handles matrices with zeros correctly", {
  mat <- matrix(1:12, nrow = 4)
  mat[2, 2] <- 0
  mat[3, 1] <- 0
  sparse_mat <- extract_sparse_matrix(mat)
  expect_identical(sparse_mat$nw, 10L)
  expect_identical(sparse_mat$w, c(1, 5, 9, 2, 10, 7, 11, 4, 8, 12))
  expect_identical(sparse_mat$nv, 10L)
  expect_identical(sparse_mat$v, c(1L, 2L, 3L, 1L, 3L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$nu, 5L)
  expect_identical(sparse_mat$u, c(1L, 4L, 6L, 8L, 11L))
})

test_that("extract_sparse_matrix() handles matrices with zeros correctly", {
  mat <- matrix(1:12, nrow = 4)
  mat[1, 1] <- 0
  mat[2, 1] <- 0
  sparse_mat <- extract_sparse_matrix(mat)
  expect_identical(sparse_mat$nw, 10L)
  expect_identical(sparse_mat$w, c(1, 5, 9, 2, 10, 7, 11, 4, 8, 12))
  expect_identical(sparse_mat$nv, 10L)
  expect_identical(sparse_mat$v, c(1L, 2L, 3L, 1L, 3L, 2L, 3L, 1L, 2L, 3L))
  expect_identical(sparse_mat$nu, 5L)
  expect_identical(sparse_mat$u, c(1L, 4L, 6L, 8L, 11L))
})

test_that("extract_sparse_matrix() handles the rstan example as expected", {
  A <- rbind(
    c(19L, 27L,  0L,  0L),
    c(0L,  0L,  0L,  0L),
    c(0L,  0L,  0L, 52L),
    c(81L,  0L, 95L, 33L)
  )
  A[1, 1:4] <- 0
  sparse_A <- extract_sparse_matrix(A)
  expect_identical(sparse_A$nw, 4L)
  expect_identical(sparse_A$w, c(52, 81, 95, 33))
  expect_identical(sparse_A$nv, 4L)
  expect_identical(sparse_A$v, c(4L, 1L, 3L, 4L))
  expect_identical(sparse_A$nu, 5L)
  expect_identical(sparse_A$u, c(1L, 1L, 1L, 2L, 5L))
})