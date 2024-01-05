# Run preprocessing script
source("touchstone/preprocessing.R")

# Compile the model for use outside of the benchmark
model <- enw_model(target_dir = "touchstone")
