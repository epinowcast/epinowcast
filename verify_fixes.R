#!/usr/bin/env Rscript
# Verification script for PR #528 fixes
# This runs the Germany weekly reporting example to verify both fixes work

cat("\n=== PR #528 Fix Verification ===\n\n")
cat("Loading package with fixes...\n")
devtools::load_all(".")

cat("\nRunning Germany weekly reporting example...\n")
cat("This tests:\n")
cat("  1. Array conversion fix (matrices preserve structure)\n")
cat("  2. Gradient stability fix (precomputed indices + log_sum_exp)\n\n")

cat("Expected outcome: Model should initialize and begin sampling\n")
cat("Previous error: 'Gradient evaluated at the initial value is not finite'\n\n")

# Run the example
source("inst/examples/germany_weekly_reporting_daily_process_model.R")

cat("\n=== VERIFICATION SUCCESSFUL ===\n")
cat("Model initialized and completed sampling\n")
