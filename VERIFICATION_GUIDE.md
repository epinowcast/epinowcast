# How to Verify PR #528 Fixes

## Quick Verification

Run this command to test both fixes:

```bash
Rscript verify_fixes.R
```

This will:
1. Load the package with fixes applied
2. Run the Germany weekly reporting example
3. Verify the model initializes and samples successfully

**Expected outcome**: Model completes without "Gradient is not finite" error

**Time**: ~5-10 minutes to complete sampling

---

## What Was Changed

### Core Fixes

**R/model-modules.R** (lines 289-334)
- Fix 1: Array conversion using manual loop (lines 296-302)
- Fix 2: Precompute selected indices for aggregation (lines 304-328)

**inst/stan/functions/expected_obs.stan** (lines 102-165)
- Updated function signature with new parameters
- New stable aggregation using `log_sum_exp()` with precomputed indices

**inst/stan/epinowcast.stan**
- Lines 119-121: Data declarations for precomputed indices
- Lines 418-443: Updated likelihood calls with new parameters
- Lines 465-470: Updated generated quantities

**inst/stan/functions/expected_obs_from.stan**
- Updated function signatures and calls to pass precomputed indices through

**inst/stan/functions/delay_lpmf.stan**
- Updated likelihood function signatures and calls

---

## View Changes

### See all modified files:
```bash
git diff main --name-only
```

### See specific changes:
```bash
# Array conversion fix
git diff main R/model-modules.R | grep -A20 "Fill array manually"

# Precomputed indices creation
git diff main R/model-modules.R | grep -A30 "Precompute selected"

# Gradient stability fix
git diff main inst/stan/functions/expected_obs.stan | grep -A30 "log_sum_exp"
```

---

## Understanding the Fixes

**Fix 1 - Array Conversion** (R/model-modules.R:296-302)
- Problem: `array(unlist())` scrambled matrix structures
- Solution: Manual loop preserving each matrix correctly

**Fix 2 - Gradient Stability** (Multiple Stan files)
- Problem: `log(matrix * exp(vector))` created non-finite gradients
- Solution: Precompute indices in R, use Stan's `log_sum_exp()` for numerical stability

---

## Detailed Summary

Read **PR528_COMPLETE_SUMMARY.md** for full technical details including:
- Investigation process
- Root cause analysis
- Mathematical correctness proof
- Performance impact assessment
- Complete file listing with line numbers

---

## Debug Mode

To see detailed debug output (useful for development):

The Stan files still have debug printing enabled. Look for:
```
=== AGGREGATION l=7 ===
Matrix non-zero rows:1  ← Should always be 1
Before agg: prob_sum=1  ← Should sum to ~1
After agg: n_inf=6      ← Correct for weekly reporting
```

These print statements should be removed before merging but are useful for verification.

---

## Before Merging

1. Remove debug `print()` statements from Stan files
2. Run full test suite: `devtools::test()`
3. Run package check: `devtools::check()`
4. Update NEWS.md with fix description
5. Consider adding unit tests for array conversion
