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

  // The non-parametric reference design is structurally sparse for the
  // common categorical specifications (e.g. ~1 + (1 | delay), each row has
  // a single nonzero). The associated combine_effects call sits inside the
  // transformed parameters block and is hit on every HMC leapfrog step so
  // its reverse-mode autodiff cost scales with the dense element count
  // (refnp_fnindex * refnp_fncol). Auto-route through the CSR multiply
  // when the design is at least 2x sparser than dense even if the user has
  // not set sparse_design = TRUE; this is a no-op when the design is dense
  // or when the sparse path is in use globally.
  int refnp_fdense_size = refnp_fnindex * refnp_fncol;
  int refnp_use_sparse = (
    refnp_nonzero > 0 &&
    (sparse_design || refnp_nonzero * 2 < refnp_fdense_size)
  ) ? 1 : 0;

  // ---- Latent case submodule ----
  // We already know that the latent case submodule is sparse
  if (expl_lrd_nonzero > 0) {
    expl_lrd_sparse = csr_extract(expl_lrd);
  }
  // ---- Non-parametric reference module ----
  // Always extract the CSR view when we will use the sparse path, so the
  // auto-routed case does not depend on the global flag.
  if (refnp_use_sparse) {
    refnp_sparse = csr_extract(refnp_fdesign);
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
    // refnp_sparse already extracted above when refnp_use_sparse == 1.
    // ---- Reporting time model ----
    if (rep_nonzero > 0) {
      rep_sparse = csr_extract(rep_fdesign);
    }
    // ---- Missing reference date model ----
    if (miss_nonzero > 0) {
      miss_sparse = csr_extract(miss_fdesign);
    }
  }
