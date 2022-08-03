#' Convert latest observed data to a matrix
#'
#' @param latest `latest` data.frame output from [enw_preprocess_data()].
#'
#' @return A matrix with each column being a group and each row a reference date
latest_obs_as_matrix <- function(latest) {
  latest_matrix <- data.table::dcast(
    latest, reference_date ~ .group,
    value.var = "confirm"
  )
  latest_matrix <- as.matrix(latest_matrix[, -1])
}
