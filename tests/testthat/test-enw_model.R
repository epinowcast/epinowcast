test_that("enw_model can compile the default model", {
  skip_on_cran()
  enw_model()
})

test_that("enw_model can compile the multi-threaded model", {
  skip_on_cran()
  enw_model(threads = TRUE)
})
