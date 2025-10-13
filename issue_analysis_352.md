# Issue Analysis: #352 - Change interpretation of include_days in enw_filter_reference_dates

## Summary

Issue #352 identifies an unintuitive behaviour in the `enw_filter_reference_dates()` function where the `include_days` parameter returns `include_days + 1` reference dates instead of exactly `include_days` reference dates.
This is a bug in the parameter interpretation that leads to off-by-one errors in user expectations.
For example, when a user specifies `include_days = 10`, they expect to get exactly 10 reference dates, but currently get 11.

## Key Discussion Points

- **Current behaviour**: `include_days = 10` returns 11 reference dates (from day -10 to day 0, inclusive)
- **Expected behaviour**: `include_days = 10` should return exactly 10 reference dates (from day -9 to day 0, inclusive)
- **Special cases**:
  - `include_days = 1` should return only the most recent reference date
  - `include_days = 0` should return no data
- **Breaking change acknowledged**: This will require updates to tests, examples, vignettes, and the README
- **Deprecation strategy proposed**: Add a warning using `rlang` that shows every 8 hours, and add a news item flagging the breaking change

## Stakeholders

- **@adrian-lison (Adrian Lison)**: Issue reporter, created PR #353 to address this
- **@seabbs (Sam Abbott)**: Repository maintainer, agreed with the fix and provided implementation guidance

## Status and Timeline

- **Created**: 2023-10-27
- **Status**: Open (neither issue nor PR #353 is merged)
- **Labels**: `bug`, `high-priority`
- **Key events**:
  - 2023-10-27: Issue opened and PR #353 created
  - 2023-10-31: Labelled as bug and high-priority
  - 2023-11-17: Sam asked if help needed to unstick
  - 2024-08-27: Sam offered to create PR into PR #353 to help close it out
- **Blockers**: PR #353 is marked as "stuck" and incomplete (missing checklist items for news, version bump, tests)

## Related Code Areas

### Primary Function

**File**: `R/preprocess.R`

**Function**: `enw_filter_reference_dates()` (lines 446-476)

**Current implementation** (line 466):
```r
earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days
```

**Problem**: This calculation results in `include_days + 1` dates being included because both the `earliest_date` and the `max` date are inclusive.

**Required change**: Should be:
```r
earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days + 1
```

This would give:
- `include_days = 10` → earliest_date = max - 9, returning 10 days total
- `include_days = 1` → earliest_date = max - 0, returning 1 day (most recent only)
- `include_days = 0` → earliest_date = max + 1, returning 0 days (no data)

### Affected Files and Areas

**Tests** (need updates):
- `tests/testthat/test-enw_filter_reference_dates.R`
  - Lines 14-21: Test expects 11 dates with `include_days = 10` (from 2021-10-10 to 2021-10-20)
  - Lines 52-63: Test with missing reference dates expects same behaviour
  - Line 90: Snapshot test needs updating

**Snapshot files** (need regeneration):
- `tests/testthat/_snaps/enw_filter_reference_dates.md`

**Vignettes** (need updates):
- `vignettes/epinowcast.Rmd`
  - Line 54: `include_days = 40`
  - Line 83: `include_days = 40`

**Examples** (need updates):
- `inst/examples/germany_simple.R`
  - Line 30: `include_days = 40`
  - Line 36: `include_days = 20`
- Similar updates needed in other example files (germany_dow.R, germany_latent_renewal.R, etc.)

**Touchstone benchmarks** (need updates):
- `touchstone/*.R` files using `include_days`

**Helper functions** (likely need updates):
- `tests/testthat/helper-functions.R`

## Test Requirements

1. **Update existing tests**:
   - Change expected values in `test-enw_filter_reference_dates.R` to expect `include_days` dates instead of `include_days + 1`
   - Example: `include_days = 10` should expect min date of 2021-10-11 instead of 2021-10-10

2. **Add edge case tests**:
   - Test `include_days = 0` returns empty dataset
   - Test `include_days = 1` returns exactly 1 reference date (the most recent)
   - Test `include_days = 2` returns exactly 2 reference dates

3. **Regenerate snapshots**:
   - Run `testthat::snapshot_accept()` after making changes

4. **Integration tests**:
   - Verify that changing `include_days` doesn't break downstream functions that use filtered data
   - Test with `enw_preprocess_data()` workflow

## Related Issues and PRs

- **PR #353**: "Issue 352: Change interpretation of include_days in filter_reference_dates"
  - Status: Open, marked as "stuck"
  - Missing items from checklist:
    - Unit tests need updating
    - News item needs adding
    - Package version needs incrementing
    - CI checks need addressing
  - Contains initial implementation but needs completion

## Additional Context

### Implementation Details from PR Discussion

From @seabbs's comment on PR #353:
- Need to change all examples
- Need to change the README
- Need to change the vignettes
- Need to change all function examples
- Need to add a deprecation warning/flag
- Need to add a news item for bug/breaking change
- Need to check any other `include_days` option for parity

### Current Behavior Example

Based on test execution:
```r
# With include_days = 10 on data with max reference date of 2021-10-20
# Current: returns dates from 2021-10-10 to 2021-10-20 (11 dates)
# Expected: should return dates from 2021-10-11 to 2021-10-20 (10 dates)

# With include_days = 1
# Current: returns 2 dates (2021-10-19 and 2021-10-20)
# Expected: should return 1 date (2021-10-20 only)
```

### Impact Assessment

**Breaking change**: Yes, this will affect all existing code using `include_days`

**Severity**: High priority (as labelled) because:
1. It affects user expectations and can lead to subtle bugs
2. Users may have built workflows assuming the current (incorrect) behaviour
3. Off-by-one errors in time series analysis can have significant downstream effects

**Migration path**:
1. Add deprecation warning that triggers when `include_days` is used
2. Document the change prominently in NEWS.md
3. Provide clear examples of how to update existing code
4. Consider adding a temporary parameter like `legacy_include_days` for backwards compatibility (though this may be overkill)

## Acceptance Criteria

For this issue to be resolved:

1. **Code change**: Update line 466 in `R/preprocess.R` to:
   ```r
   earliest_date <- max(filt_obs$reference_date, na.rm = TRUE) - include_days + 1
   ```

2. **Documentation updates**:
   - Update function documentation to clarify the new behaviour
   - Add `@section Breaking changes:` note to the roxygen documentation

3. **Test updates**:
   - Update all test expectations to match new behaviour
   - Add edge case tests for `include_days = 0`, `include_days = 1`
   - Regenerate snapshots

4. **Example updates**:
   - Update all files in `inst/examples/` that use `include_days`
   - Adjust the values if needed (e.g., `include_days = 40` might become `include_days = 41` to maintain same effective window)

5. **Vignette updates**:
   - Update vignettes to use new interpretation
   - Add explanatory text if needed

6. **Package documentation**:
   - Add NEWS.md entry under "Breaking changes"
   - Increment package version (likely minor or patch version)
   - Update DESCRIPTION

7. **Warning system**:
   - Consider adding a lifecycle warning (using `lifecycle` package) that informs users of the change
   - Could use `lifecycle::deprecate_warn()` with appropriate `when` version

8. **Validation**:
   - All tests pass
   - R CMD check passes
   - Benchmarks run without errors

## Full Issue Content

### Original Issue Body

The current implementation of `include_days` in `enw_filter_reference_dates` is not really intuitive to me, because it actually returns `include_days+1` reference dates.

If I supply `include_days=10`, I expect to get exactly 10 reference dates back.
If I supply `include_days=1`, I expect to get only the most recent reference date back.
If I supply `include_days=0`, I expect to get no data back.

I think we should change this, knowing that it can be a breaking change for some running productive pipelines, and a lot of tests need to be updated.

### Comments and Discussion

**@seabbs (2023-10-31)**:
Yes, good catch I agree.
I think as long as we provide a warning (potentially using `rlang` so it only shows up every 8 hours) and flag in the news that will be okay.

**PR #353 Discussion**:
- @adrian-lison noted "Probably more updates of tests etc needed."
- @seabbs provided comprehensive checklist of what needs updating (examples, README, vignettes, function examples, deprecation warning, news item, check other include_days options)
- Multiple check-ins from @seabbs offering to help unstick the PR

### Labels and Metadata

- **Labels**: bug, high-priority
- **Assignees**: None
- **Milestone**: None
- **Project**: None

## Recommended Actions

1. **Immediate**: Review PR #353 to see what's already been done
2. **Complete the fix**: Either:
   - Update PR #353 with remaining changes, or
   - Create a new PR based on current main
3. **Systematic approach**:
   - Make the code change to `enw_filter_reference_dates()`
   - Run tests to identify all failures
   - Update tests systematically
   - Update examples and vignettes
   - Add NEWS entry
   - Add deprecation lifecycle badge/warning if appropriate
4. **Testing strategy**:
   - Create a script that tests both old and new behaviour side-by-side
   - Verify that the fix resolves the issue for all edge cases
5. **Documentation**:
   - Ensure the function documentation clearly explains the new behaviour
   - Add examples showing `include_days = 1`, `include_days = 10`, etc.
