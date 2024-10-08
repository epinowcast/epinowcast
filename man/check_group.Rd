% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check.R
\name{check_group}
\alias{check_group}
\title{Check observations for reserved grouping variables}
\usage{
check_group(obs)
}
\arguments{
\item{obs}{An object that will be \code{coerce_dt}d in place, that does not
contain \code{.group}, \code{.old_group}, or \code{.new_group}. These are reserved names.}
}
\value{
The \code{obs} object, which will be modifiable in place.
}
\description{
Check observations for reserved grouping variables
}
\seealso{
Functions used for checking inputs
\code{\link{check_calendar_timestep}()},
\code{\link{check_design_matrix_sparsity}()},
\code{\link{check_group_date_unique}()},
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
