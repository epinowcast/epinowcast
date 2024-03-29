% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model-module-helpers.R
\name{latest_obs_as_matrix}
\alias{latest_obs_as_matrix}
\title{Convert latest observed data to a matrix}
\usage{
latest_obs_as_matrix(latest)
}
\arguments{
\item{latest}{\code{latest} \code{data.frame} output from \code{\link[=enw_preprocess_data]{enw_preprocess_data()}}.}
}
\value{
A matrix with each column being a group and each row a reference date
}
\description{
Convert latest observed data to a matrix
}
\seealso{
Helper functions for model modules
\code{\link{add_max_observed_delay}()},
\code{\link{add_pmfs}()},
\code{\link{convolution_matrix}()},
\code{\link{enw_reference_by_report}()},
\code{\link{enw_reps_with_complete_refs}()},
\code{\link{extract_obs_metadata}()},
\code{\link{extract_sparse_matrix}()},
\code{\link{simulate_double_censored_pmf}()}
}
\concept{modelmodulehelpers}
