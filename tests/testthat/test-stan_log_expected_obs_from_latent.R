skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")
skip_on_local()

test_that(
  "fixed and uncertain latent delay paths agree (degenerate prior)",
  {
    # The uncertain latent reporting delay path rebuilds the convolution-matrix
    # CSR weights from the sampled PMF via a value-stable pattern-to-PMF index
    # map (.conv_pmf_index_map()), reusing the precomputed integer sparsity
    # pattern, and feeds the SAME log_expected_obs_from_latent() as the fixed
    # path. When the PMF is the same, the two paths must give identical output.
    # This proves the unified path reproduces the fixed-PMF result and that the
    # index map and convolution orientation/indexing are correct.
    rd_n <- 3L
    t <- 8L
    ft <- t + rd_n - 1L
    pmf <- c(0.2, 0.5, 0.3)
    latent <- log(seq_len(ft) * 10)
    prop <- rep(0, t)

    # Fixed path: R-built convolution matrix, extracted to CSR.
    r_mat <- convolution_matrix(pmf, ft, include_partial = FALSE)
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

    # The index-map weights match the fixed-path CSR weights exactly.
    expect_equal(uncertain_w, r_sparse$w, tolerance = 1e-12)
    # And the full convolution output is identical between the two paths.
    expect_equal(uncertain_out, fixed_out, tolerance = 1e-10)

    # Both match a manual convolution.
    natural <- exp(latent)
    expected <- vapply(seq_len(t), function(s) {
      sum(natural[s:(s + rd_n - 1)] * rev(pmf))
    }, numeric(1))
    expect_equal(exp(fixed_out), expected, tolerance = 1e-8)
  }
)

test_that(
  "index map is stable when the PMF tail underflows to zero",
  {
    # The pattern-to-PMF index map keeps the nonzero count constant even when
    # the sampled PMF tail underflows to exactly zero (which would otherwise
    # change the nonzero count of a re-extracted matrix and break the reuse of
    # the precomputed integer sparsity pattern).
    rd_n <- 5L
    ft <- 14L
    pmf <- c(0.4, 0.35, 0.25, 0, 0)

    w_idx <- epinowcast:::.conv_pmf_index_map(rd_n, ft)
    pattern <- convolution_matrix(
      rep(1 / rd_n, rd_n), ft,
      include_partial = FALSE
    )
    # Index-map length matches the (value-independent) pattern nonzero count,
    # so the count is stable regardless of zeros in the PMF.
    expect_length(w_idx, sum(pattern != 0))
    expect_true(all(w_idx >= 1L & w_idx <= rd_n))

    # Building weights from the tail-zero PMF and placing them at the pattern's
    # nonzero positions reproduces the dense convolution matrix exactly
    # (including the structural zeros from the underflowed tail).
    w <- pmf[w_idx]
    rebuilt <- matrix(0, ft, ft)
    pattern_t <- t(pattern)
    rebuilt_t <- t(rebuilt)
    rebuilt_t[pattern_t != 0] <- w
    rebuilt <- t(rebuilt_t)
    expect_equal(
      rebuilt, convolution_matrix(pmf, ft, include_partial = FALSE),
      tolerance = 1e-12
    )
  }
)
