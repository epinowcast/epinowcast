  // Declare tuples for sparse matrix components
  int expr_nonzero = num_nonzero(expr_fdesign);
  tuple(vector[expr_nonzero], array[expr_nonzero] int, array[expr_fnindex + 1] int) expr_sparse;
  int expl_nonzero = num_nonzero(expl_fdesign);
  tuple(vector[expl_nonzero], array[expl_nonzero] int, array[expl_fnindex + 1] int) expl_sparse;
  int expl_lrd_nonzero = num_nonzero(expl_lrd);
  tuple(vector[expl_lrd_nonzero], array[expl_lrd_nonzero] int, array[expr_ft + 1] int) expl_lrd_sparse;
  int refp_nonzero = num_nonzero(refp_fdesign);
  tuple(vector[refp_nonzero], array[refp_nonzero] int, array[refp_fnrow + 1] int) refp_sparse;
  int rep_nonzero = num_nonzero(rep_fdesign);
  tuple(vector[rep_nonzero], array[rep_nonzero] int, array[rep_fnrow + 1] int) rep_sparse;
  int refnp_nonzero = num_nonzero(refnp_fdesign);
  tuple(vector[refnp_nonzero], array[refnp_nonzero] int, array[refnp_fnindex + 1] int) refnp_sparse;
  int miss_nonzero = num_nonzero(miss_fdesign);
  tuple(vector[miss_nonzero], array[miss_nonzero] int, array[miss_fnindex + 1] int) miss_sparse;

  // ---- Latent case submodule ----
  // We already know that the latent case submodule is sparse
  if (expl_lrd_nonzero > 0) {
    expl_lrd_sparse = csr_extract(expl_lrd);
  }

  if (sparse_design) {
    // Create sparse matrix components by module using csr_extract
    // ---- Expectation model ----
    if (expr_nonzero > 0) {
      expr_sparse = csr_extract(expr_fdesign);
    }
    if (expl_nonzero > 0) {
      expl_sparse = csr_extract(expl_fdesign);
    }
    // ---- Reference model ----
    if (refp_nonzero > 0) {
      refp_sparse = csr_extract(refp_fdesign);
    }
    if (refnp_nonzero > 0) {
      refnp_sparse = csr_extract(refnp_fdesign);
    }
    // ---- Reporting time model ----
    if (rep_nonzero > 0) {
      rep_sparse = csr_extract(rep_fdesign);
    }
    // ---- Missing reference date model ----
    if (miss_nonzero > 0) {
      miss_sparse = csr_extract(miss_fdesign);
    }
  }
  