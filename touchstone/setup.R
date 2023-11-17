# Run preprocessing script
source("touchstone/preprocessing.R")

# Compile the model for use outside of the benchmark
model <- enw_model(threads = TRUE, target_dir = "touchstone")
