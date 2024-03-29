% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{unset_cache_from_environ}
\alias{unset_cache_from_environ}
\title{Remove Cache Location Setting from \code{.Renviron}}
\usage{
unset_cache_from_environ(alert_on_not_set = TRUE)
}
\arguments{
\item{alter_on_not_set}{A logical value indicating whether to display a
warning message if the \code{enw_cache_location} setting is not found in the
\code{.Renviron} file. Defaults to \code{TRUE}.}
}
\value{
Invisible NULL. The function is used for its side effect of modifying
the \code{.Renviron} file.
}
\description{
This function searches for and removes the \code{enw_cache_location} setting from
the \code{.Renviron} file located in the user's project or home directory.
It utilizes the \url{get_renviron_contents} function to access and
modify the contents of the \code{.Renviron} file. If the \code{enw_cache_location}
setting is found and successfully removed, a success message is displayed.
If the setting is not found, a warning message is displayed.
}
\seealso{
\code{\link[=get_renviron_contents]{get_renviron_contents()}}
}
\keyword{internal}
