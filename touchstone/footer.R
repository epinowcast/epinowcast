# You can modify the PR comment footer here. You can use github markdown e.g.
# emojis like :tada:.
# This file will be parsed and evaluate within the context of
# `benchmark_analyze` and should return the comment text as the last value.
# See `?touchstone::pr_comment`
link <- "https://lorenzwalthert.github.io/touchstone/articles/inference.html"
epinowcast_link <- "https://github.com/epinowcast/epinowcast/tree/main/inst/examples" # nolint
glue::glue(
  "\nThese benchmarks are based on package examples which are available",
  " [here]({epinowcast_link}). Further explanation regarding interpretation",
  " and methodology can be found in the [documentation of `touchstone`]({link})." # nolint
)
