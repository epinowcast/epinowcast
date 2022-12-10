mat <- matrix(1:9, nrow = 3)
extract_sparse_matrix(mat)

test_that("extract_sparse_matrix can extract a sparse matrix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat)
  expect_equal(sparse_mat$nw, 9)
  expect_equal(sparse_mat$w, c(1, 4, 7, 2, 5, 8, 3, 6, 9))
  expect_equal(sparse_mat$nv, 9)
  expect_equal(sparse_mat$v, c(1, 2, 3, 1, 2, 3, 1, 2, 3))
  expect_equal(sparse_mat$nu, 4)
  expect_equal(sparse_mat$u, c(1 , 4, 7, 10))
})

test_that("extract_sparse_matrix can extract a sparse matrix with a prefix", {
  mat <- matrix(1:9, nrow = 3)
  sparse_mat <- extract_sparse_matrix(mat, "prefix")
  expect_equal(sparse_mat$prefix_nw, 9)
  expect_equal(sparse_mat$prefix_w, c(1, 4, 7, 2, 5, 8, 3, 6, 9))
  expect_equal(sparse_mat$prefix_nv, 9)
  expect_equal(sparse_mat$prefix_v, c(1, 2, 3, 1, 2, 3, 1, 2, 3))
  expect_equal(sparse_mat$prefix_nu, 4)
  expect_equal(sparse_mat$prefix_u, c(1 , 4, 7, 10))
})