# Compile the Stan model once for all test files that need it. testthat
# edition 3 runs each test file in its own environment, but objects created
# in setup*.R files are shared across files. Gated to not-CRAN CI only (the
# model is compiled and fit there), mirroring the previous file-local
# definition in test-epinowcast.R.
if (not_on_cran() && on_ci()) {
  model <- enw_model()
  options(mc.cores = 2)
}
