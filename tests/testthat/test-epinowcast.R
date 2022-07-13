test_sampler <- function(init, data, ...) {
  return(data.table::data.table(init = list(init), data = list(data)))
}