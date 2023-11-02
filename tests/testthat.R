library(testthat)
library(vdiffr)
library(withr)
library(epinowcast)

test_results <- test_check("epinowcast")

if (any(as.data.frame(test_results)$warning > 0)) {
  stop("tests failed with warnings")
}
