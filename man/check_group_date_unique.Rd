% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check.R
\name{check_group_date_unique}
\alias{check_group_date_unique}
\title{Check observations for uniqueness of grouping variables with respect
to \code{reference_date} and \code{report_date}}
\usage{
check_group_date_unique(obs)
}
\arguments{
\item{obs}{An object that will be \code{coerce_dt}d in place, that contains
\code{.group}, \code{reference_date}, and \code{report_date} columns.}
}
\description{
This function checks that the input data is stratified by
\code{reference_date}, \code{report_date}, and \code{.group.} It does this by counting the
number of observations for each combination of these variables, and
throwing a warning if any combination has more than one observation.
}
\seealso{
Functions used for checking inputs
\code{\link{check_calendar_timestep}()},
\code{\link{check_design_matrix_sparsity}()},
\code{\link{check_group}()},
\code{\link{check_max_delay}()},
\code{\link{check_module}()},
\code{\link{check_modules_compatible}()},
\code{\link{check_numeric_timestep}()},
\code{\link{check_observation_indicator}()},
\code{\link{check_quantiles}()},
\code{\link{check_timestep}()},
\code{\link{check_timestep_by_date}()},
\code{\link{check_timestep_by_group}()}
}
\concept{check}
