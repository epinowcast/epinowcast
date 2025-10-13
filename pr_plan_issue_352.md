# Feature Implementation Plan: Fix include_days Off-by-One Error (#352)

**Reference**: See `issue_analysis_352.md` for detailed issue analysis

## Overview

Fix the off-by-one error in `enw_filter_reference_dates()` where `include_days = 10` incorrectly returns 11 dates instead of 10. This is a breaking change that requires updates to the core function, tests, snapshots, and NEWS documentation.

**Key Objectives:**
- Correct the calculation on line 466 of R/preprocess.R
- Update all affected tests with corrected date expectations
- Add comprehensive edge case tests
- Regenerate snapshot files
- Document breaking change in NEWS.md
- Ensure all tests and checks pass

**Success Criteria:**
- `include_days = 10` returns exactly 10 dates
- `include_days = 1` returns only the most recent date
- `include_days = 0` returns no data
- All tests pass with no warnings
- R CMD check passes cleanly

## Phase 1: Analysis and Verification

- [ ] Verify current behaviour in R console → Agent: statistical-implementation-specialist
  - Test with actual data to confirm off-by-one error
  - Document exact output before changes

- [ ] Review all affected test files → Agent: test-debug-fixer
  - Identify all date expectations that need updating
  - List snapshot files requiring regeneration

## Phase 2: Core Implementation

### Code Changes with Examples

- [ ] Fix the calculation in R/preprocess.R (line 466) → Agent: statistical-implementation-specialist

**File:** `/Users/lshsa2/code/epinowcast/R/preprocess.R`

**Before (line 466):**
```r
earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days
```

**After (line 466):**
```r
earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days + 1
```

**Context (lines 462-470):**
```r
  if (!is.null(include_days)) {
    if (!is.numeric(include_days) || include_days < 0) {
      stop("include_days must be a non-negative numeric value")
    }
    earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days + 1  # FIXED
    filt_obs <- filt_obs[reference_date >= earliest_date]
  }
```

## Phase 3: Test Updates

### Update Existing Tests

- [ ] Update test-enw_filter_reference_dates.R → Agent: test-debug-fixer

**File:** `/Users/lshsa2/code/epinowcast/tests/testthat/test-enw_filter_reference_dates.R`

**Test 1: Basic filtering test (lines 14-21)**

**Before:**
```r
test_that("enw_filter_reference_dates filters correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 10
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  expect_identical(
    min(filtered$reference_date),
    as.IDate("2021-10-10")  # Old expectation: 11 days
  )
})
```

**After:**
```r
test_that("enw_filter_reference_dates filters correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 10
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  expect_identical(
    min(filtered$reference_date),
    as.IDate("2021-10-11")  # Corrected: exactly 10 days (2021-10-11 to 2021-10-20)
  )
})
```

**Additional check to add:**
```r
  # Verify exact count of dates
  n_dates <- length(unique(filtered$reference_date))
  expect_identical(n_dates, include_days)
```

### Add Edge Case Tests

- [ ] Add comprehensive edge case tests → Agent: test-debug-fixer

**File:** `/Users/lshsa2/code/epinowcast/tests/testthat/test-enw_filter_reference_dates.R`

**Add after existing tests:**

```r
test_that("enw_filter_reference_dates handles include_days = 0 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 0
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  # Should return empty data.table
  expect_identical(nrow(filtered), 0L)
  expect_s3_class(filtered, "data.table")
})

test_that("enw_filter_reference_dates handles include_days = 1 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 1
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  # Should return only the most recent date
  n_dates <- length(unique(filtered$reference_date))
  expect_identical(n_dates, 1L)
  expect_identical(min(filtered$reference_date), as.IDate("2021-10-20"))
  expect_identical(max(filtered$reference_date), as.IDate("2021-10-20"))
})

test_that("enw_filter_reference_dates handles include_days = 2 correctly", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 2
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  # Should return exactly 2 days
  n_dates <- length(unique(filtered$reference_date))
  expect_identical(n_dates, 2L)
  expect_identical(min(filtered$reference_date), as.IDate("2021-10-19"))
  expect_identical(max(filtered$reference_date), as.IDate("2021-10-20"))
})

test_that("enw_filter_reference_dates returns correct count for various include_days", {
  latest_date <- as.IDate("2021-10-20")

  test_cases <- c(5, 10, 15, 20)

  for (days in test_cases) {
    filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, days)
    n_dates <- length(unique(filtered$reference_date))
    expect_identical(
      n_dates,
      days,
      label = sprintf("include_days = %d should return exactly %d dates", days, days)
    )
  }
})
```

### Verify Data Structure Consistency

- [ ] Add test to verify no unintended changes to data structure → Agent: test-debug-fixer

```r
test_that("enw_filter_reference_dates preserves data structure after fix", {
  latest_date <- as.IDate("2021-10-20")
  include_days <- 10
  filtered <- enw_filter_reference_dates(nat_germany_hosp, latest_date, include_days)

  # Check all expected columns present
  expected_cols <- c("reference_date", "report_date", "confirm", "age_group", "location")
  expect_true(all(expected_cols %in% names(filtered)))

  # Check data.table class preserved
  expect_s3_class(filtered, "data.table")

  # Check no NA reference dates in filtered result
  expect_false(any(is.na(filtered$reference_date)))
})
```

## Phase 4: Documentation Updates

- [ ] Update function documentation if needed → Agent: documentation-updater

**File:** `/Users/lshsa2/code/epinowcast/R/preprocess.R`

**Check documentation around line 430-445 for `enw_filter_reference_dates()`:**

Verify the `@param include_days` documentation clearly states:
```r
#' @param include_days Numeric. The number of reference dates to include
#'   (counting backwards from the latest date). For example, `include_days = 10`
#'   will return exactly 10 reference dates. If `NULL` (default), all dates
#'   are included.
```

**Add to `@details` section if exists, or create one:**
```r
#' @details
#' The `include_days` parameter filters to include exactly the specified number
#' of most recent reference dates. For example, if the latest reference date is
#' 2021-10-20 and `include_days = 10`, the filtered data will contain reference
#' dates from 2021-10-11 to 2021-10-20 (10 days inclusive).
```

- [ ] Run devtools::document() → Agent: documentation-updater

```r
devtools::document()
```

## Phase 5: NEWS.md Update

- [ ] Add breaking change entry to NEWS.md → Agent: documentation-updater

**File:** `/Users/lshsa2/code/epinowcast/NEWS.md`

**Add under the development version section (after version 0.3.0.1000 header):**

```markdown
# epinowcast 0.3.0.1000

## Breaking changes

* Fixed off-by-one error in `enw_filter_reference_dates()` where `include_days = n`
  incorrectly returned `n + 1` dates instead of exactly `n` dates. Now
  `include_days = 10` returns exactly 10 reference dates, not 11. This brings
  the function behaviour in line with its documentation and user expectations.
  Users relying on the previous (incorrect) behaviour will need to adjust their
  `include_days` arguments by subtracting 1 to maintain the same date range.
  See issue #352 for details.

## Bug fixes

(If there's a separate section, optionally add a reference here too)

## Documentation

## Package

(Existing sections...)
```

## Phase 6: Snapshot Regeneration

- [ ] Regenerate snapshot tests → Agent: test-debug-fixer

**Files affected:**
- `/Users/lshsa2/code/epinowcast/tests/testthat/_snaps/enw_filter_reference_dates.md`
- Any other snapshot files that depend on this function

**Process:**
1. Delete existing snapshot file(s):
   ```bash
   rm /Users/lshsa2/code/epinowcast/tests/testthat/_snaps/enw_filter_reference_dates.md
   ```

2. Run tests to regenerate snapshots:
   ```r
   testthat::test_file("/Users/lshsa2/code/epinowcast/tests/testthat/test-enw_filter_reference_dates.R")
   ```

3. Review regenerated snapshot files for correctness

## Phase 7: Validation and Testing

- [ ] Run focused tests → Agent: test-debug-fixer

```r
# Test the specific file
testthat::test_file("/Users/lshsa2/code/epinowcast/tests/testthat/test-enw_filter_reference_dates.R")

# Run all preprocessing tests
testthat::test_local(filter = "preprocess")
```

- [ ] Run full test suite → Agent: test-debug-fixer

```r
devtools::test()
```

- [ ] Check for unexpected failures in related functions → Agent: test-debug-fixer

**Functions to verify:**
- `enw_filter_report_dates()` (should be unaffected)
- `enw_preprocess_data()` (may call `enw_filter_reference_dates()`)
- Any vignette examples using `include_days`

- [ ] Run R CMD check → Agent: code-linting-specialist

```r
devtools::check()
```

## Phase 8: Interactive Verification

- [ ] Manual verification in R console → Agent: statistical-implementation-specialist

**Test script to run:**
```r
library(epinowcast)
library(data.table)

# Load test data
data("nat_germany_hosp")

# Test case 1: include_days = 10
latest_date <- as.IDate("2021-10-20")
filtered_10 <- enw_filter_reference_dates(nat_germany_hosp, latest_date, 10)
cat("Test 1: include_days = 10\n")
cat("  Expected min date: 2021-10-11\n")
cat("  Actual min date:  ", as.character(min(filtered_10$reference_date)), "\n")
cat("  Expected max date: 2021-10-20\n")
cat("  Actual max date:  ", as.character(max(filtered_10$reference_date)), "\n")
cat("  Expected n dates:  10\n")
cat("  Actual n dates:   ", length(unique(filtered_10$reference_date)), "\n\n")

# Test case 2: include_days = 1
filtered_1 <- enw_filter_reference_dates(nat_germany_hosp, latest_date, 1)
cat("Test 2: include_days = 1\n")
cat("  Expected n dates: 1\n")
cat("  Actual n dates:  ", length(unique(filtered_1$reference_date)), "\n")
cat("  Only date:       ", as.character(unique(filtered_1$reference_date)), "\n\n")

# Test case 3: include_days = 0
filtered_0 <- enw_filter_reference_dates(nat_germany_hosp, latest_date, 0)
cat("Test 3: include_days = 0\n")
cat("  Expected n rows: 0\n")
cat("  Actual n rows:  ", nrow(filtered_0), "\n\n")

# Test case 4: include_days = 2
filtered_2 <- enw_filter_reference_dates(nat_germany_hosp, latest_date, 2)
cat("Test 4: include_days = 2\n")
cat("  Expected dates: 2021-10-19, 2021-10-20\n")
cat("  Actual dates:  ", paste(sort(unique(filtered_2$reference_date)), collapse = ", "), "\n")
```

## Phase 9: Code Review and Quality Assurance

- [ ] Lint the modified code → Agent: code-linting-specialist

```r
lintr::lint("/Users/lshsa2/code/epinowcast/R/preprocess.R")
```

- [ ] Style check → Agent: code-linting-specialist

```r
styler::style_file("/Users/lshsa2/code/epinowcast/R/preprocess.R")
```

- [ ] Final code review → Agent: code-review-expert
  - Verify the mathematical correctness of the fix
  - Ensure no unintended side effects
  - Check that error messages and validation remain appropriate
  - Review test coverage for completeness

## Phase 10: Final Integration

- [ ] Verify worktree setup → Agent: statistical-implementation-specialist
  - Ensure working in appropriate worktree or branch
  - Confirm not on main branch

- [ ] Stage and commit changes → Agent: statistical-implementation-specialist

```bash
cd /Users/lshsa2/code/epinowcast
git add R/preprocess.R
git add tests/testthat/test-enw_filter_reference_dates.R
git add tests/testthat/_snaps/enw_filter_reference_dates.md
git add man/  # Documentation files
git add NEWS.md
git commit -m "Fix: Correct off-by-one error in enw_filter_reference_dates() (#352)

- Fixed calculation to return exactly include_days dates, not include_days + 1
- Updated all affected tests with corrected date expectations
- Added edge case tests for include_days = 0, 1, and 2
- Regenerated snapshot tests
- Added breaking change entry to NEWS.md

Breaking change: include_days = 10 now returns 10 dates instead of 11.
Users may need to adjust their include_days arguments."
```

- [ ] Run pre-commit hooks manually (if not automatic) → Agent: code-linting-specialist

```bash
pre-commit run --all-files
```

## Phase 11: Documentation and Communication

- [ ] Verify all documentation is up to date → Agent: documentation-updater
  - Function help pages (`?enw_filter_reference_dates`)
  - NEWS.md entry is clear and actionable
  - No placeholder references remain

- [ ] Check examples still work → Agent: statistical-implementation-specialist

```r
# Run examples from documentation
example(enw_filter_reference_dates)
```

## Risk Assessment and Considerations

### Potential Issues and Mitigation

**Issue 1: Tests in other files may depend on the old behaviour**
- **Mitigation**: Run full test suite and grep for uses of `enw_filter_reference_dates()` in tests
- **Search command**:
  ```bash
  grep -r "enw_filter_reference_dates" /Users/lshsa2/code/epinowcast/tests/
  grep -r "include_days" /Users/lshsa2/code/epinowcast/tests/
  ```

**Issue 2: Vignettes or examples might break**
- **Mitigation**: According to issue analysis, vignettes already expect corrected behaviour. Verify by running:
  ```r
  # Build vignettes to check for errors
  devtools::build_vignettes()
  ```

**Issue 3: `include_days = 0` edge case might cause unexpected errors downstream**
- **Mitigation**: Test specifically checks this returns empty data.table. Add validation in function if needed:
  ```r
  if (include_days == 0) {
    return(filt_obs[0])  # Return empty data.table with correct structure
  }
  ```

**Issue 4: Benchmark tests might need updating**
- **Mitigation**: Check touchstone benchmark files after running full tests:
  ```bash
  grep -r "include_days" /Users/lshsa2/code/epinowcast/touchstone/
  ```
- If benchmarks fail, update expectations in touchstone scripts

**Issue 5: Date arithmetic might behave unexpectedly with IDate class**
- **Mitigation**: Verified in issue analysis that `IDate - numeric` works correctly. Tests explicitly check with `expect_identical()` for exact matching.

### Dependencies and Constraints

- **No external dependencies affected**: This is an internal calculation change
- **Breaking change requires clear communication**: NEWS.md entry must be prominent
- **Snapshot tests are deterministic**: Regeneration is straightforward
- **Must use absolute paths**: All file paths in commands use absolute paths per agent requirements

### Testing Strategy Summary

1. **Unit tests**: Verify exact date ranges for various `include_days` values
2. **Edge cases**: Test boundary conditions (0, 1, 2 days)
3. **Integration tests**: Ensure downstream functions still work
4. **Manual verification**: Interactive console testing before committing
5. **Full suite**: Run complete test suite to catch unexpected interactions

### Rollback Procedure

If issues arise after implementation:

1. **Immediate rollback**:
   ```bash
   git revert HEAD
   ```

2. **Investigate specific failures**:
   - Run individual test files to isolate issues
   - Check if vignettes or examples are affected
   - Review any user-reported issues from PR #353

3. **Alternative fix if needed**:
   - Consider adding a new parameter to control behaviour (not recommended due to API bloat)
   - Add deprecation warning before breaking change (not needed for bug fix)

## Implementation Notes

- **Execution order matters**: Fix code → update tests → regenerate snapshots → run checks
- **One task in progress at a time**: Follow the checklist sequentially for clarity
- **Use absolute paths**: All file operations use `/Users/lshsa2/code/epinowcast/` prefix
- **Document everything**: Each change should be clear and justified
- **This is a bug fix, not a feature**: No deprecation cycle needed, just clear breaking change notice

## Success Validation Checklist

Final verification before considering complete:

- [ ] Line 466 contains `- include_days + 1`
- [ ] Test expects min date of `2021-10-11` for `include_days = 10`
- [ ] Edge case tests added and passing
- [ ] `devtools::test()` returns 0 failures
- [ ] `devtools::check()` returns 0 errors, 0 warnings
- [ ] NEWS.md contains breaking change entry
- [ ] Documentation updated with `devtools::document()`
- [ ] Manual console verification confirms correct behaviour
- [ ] All snapshot files regenerated successfully
- [ ] Pre-commit hooks pass
- [ ] Working on correct branch (not main)

---

**This plan is ready for implementation. Proceed sequentially through each phase.**
