# Summarise the ncp_vs_centred CSV into a markdown comment body for issue #800.
#
# Usage:
#   Rscript experiments/summarise.R > experiments/issue_800_comment.md

suppressPackageStartupMessages({
  library(data.table)
})

WORKTREE <- "/Users/lshsa2/code/epinowcast/epinowcast/.claude/worktrees/agent-adf736ec389b2b7e1"
csv <- file.path(WORKTREE, "experiments", "ncp_vs_centred.csv")
d <- fread(csv)

# Median + range across replicates per (cell, arm).
agg <- d[, .(
  div_median = median(divergent_count, na.rm = TRUE),
  div_min = min(divergent_count, na.rm = TRUE),
  div_max = max(divergent_count, na.rm = TRUE),
  ess_min = round(median(min_ess_bulk, na.rm = TRUE)),
  ess_per_s = round(median(ess_bulk_per_s_slowest, na.rm = TRUE), 2),
  wall_s = round(median(wall_total_s, na.rm = TRUE)),
  rhat = round(max(max_rhat, na.rm = TRUE), 3),
  ebfmi = round(min(ebfmi_min, na.rm = TRUE), 2),
  n_reps = .N
), by = .(cell, arm)]

setorder(agg, cell, arm)
print(agg)
cat("\n--- markdown ---\n")
cat("| cell | arm | div median (range) | min ESS | ESS/s | wall_s | max R-hat | ebfmi |\n")
cat("|---|---|---|---|---|---|---|---|\n")
for (i in seq_len(nrow(agg))) {
  r <- agg[i]
  cat(sprintf("| %s | %s | %s (%s-%s) | %s | %s | %s | %s | %s |\n",
              r$cell, r$arm, r$div_median, r$div_min, r$div_max,
              r$ess_min, r$ess_per_s, r$wall_s, r$rhat, r$ebfmi))
}
