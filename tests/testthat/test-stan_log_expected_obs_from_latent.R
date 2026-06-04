skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

test_that("Stan convolution_matrix() matches the R convolution_matrix()", {
  # The Stan convolution_matrix() function is the reference the in-model
  # uncertain latent reporting delay path is built around; it must reproduce
  # the R convolution_matrix() used by the fixed-PMF path so both feed the
  # same sparse matrix-vector convolution. This de-risks the orientation and
  # indexing.
  rd_n <- 4L
  ft <- 12L
  pmf <- c(0.1, 0.4, 0.3, 0.2)

  stan_mat <- convolution_matrix(pmf, rd_n, ft)
  r_mat <- epinowcast::convolution_matrix(pmf, ft, include_partial = FALSE)

  expect_equal(stan_mat, r_mat, tolerance = 1e-12)
})

test_that(
  "fixed and uncertain latent delay paths agree (degenerate prior)",
  {
    # The uncertain path rebuilds the convolution-matrix CSR weights from the
    # sampled PMF via a value-stable pattern-to-PMF index map, reusing the
    # precomputed integer sparsity pattern, and feeds the SAME
    # log_expected_obs_from_latent() as the fixed path. When the PMF is the
    # same, the two paths must give identical output. This proves the unified
    # path reproduces the fixed-PMF result and that the index map is correct.
    rd_n <- 3L
    t <- 8L
    ft <- t + rd_n - 1L
    pmf <- c(0.2, 0.5, 0.3)
    latent <- log(seq_len(ft) * 10)
    prop <- rep(0, t)

    # Fixed path: R-built convolution matrix, extracted to CSR.
    r_mat <- epinowcast::convolution_matrix(pmf, ft, include_partial = FALSE)
    r_sparse <- suppressWarnings(extract_sparse_matrix(r_mat))
    fixed_out <- log_expected_obs_from_latent(
      list(latent), rd_n, r_sparse$w, r_sparse$v, r_sparse$u, t, 1L, prop
    )[[1]]

    # Uncertain path: rebuild the CSR weights from the PMF using the index map
    # (the in-model mechanism), reusing the fixed pattern's v / u.
    w_idx <- epinowcast:::.conv_pmf_index_map(rd_n, ft)
    uncertain_w <- pmf[w_idx]
    uncertain_out <- log_expected_obs_from_latent(
      list(latent), rd_n, uncertain_w, r_sparse$v, r_sparse$u, t, 1L, prop
    )[[1]]

    expect_equal(uncertain_w, r_sparse$w, tolerance = 1e-12)
    expect_equal(uncertain_out, fixed_out, tolerance = 1e-10)

    # And both match a manual convolution.
    natural <- exp(latent)
    expected <- vapply(seq_len(t), function(s) {
      sum(natural[s:(s + rd_n - 1)] * rev(pmf))
    }, numeric(1))
    expect_equal(exp(fixed_out), expected, tolerance = 1e-8)
  }
)
