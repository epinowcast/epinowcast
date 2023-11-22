
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Flexible Hierarchical Nowcasting <a href='https://package.epinowcast.org'><img src='man/figures/logo.png' align="right" height="139" /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/epinowcast/epinowcast/workflows/R-CMD-check/badge.svg)](https://github.com/epinowcast/epinowcast/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/epinowcast/epinowcast/branch/main/graph/badge.svg)](https://app.codecov.io/gh/epinowcast/epinowcast)
</br>
[![Universe](https://epinowcast.r-universe.dev/badges/epinowcast)](https://epinowcast.r-universe.dev/epinowcast)
[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/epinowcast/epinowcast/blob/master/LICENSE.md/)
[![GitHub
contributors](https://img.shields.io/github/contributors/epinowcast/epinowcast)](https://github.com/epinowcast/epinowcast/graphs/contributors)
</br>
[![DOI](https://zenodo.org/badge/422611952.svg)](https://zenodo.org/badge/latestdoi/422611952)
<!-- badges: end -->

## Summary

Tools to enable flexible and efficient hierarchical nowcasting of
right-truncated epidemiological time-series using a semi-mechanistic
Bayesian model with support for a range of reporting and generative
processes. Nowcasting, in this context, is gaining situational awareness
using currently available observations and the reporting patterns of
historical observations. This can be useful when tracking the spread of
infectious disease in real-time: without nowcasting, changes in trends
can be obfuscated by partial reporting or their detection may be delayed
due to the use of simpler methods like truncation. While the package has
been designed with epidemiological applications in mind, it could be
applied to any set of right-truncated time-series count data.

## Installation

<details>
<summary>
Installing the package
</summary>

Install the latest released version of the package with:

``` r
install.packages("epinowcast", repos = "https://epinowcast.r-universe.dev")
```

Alternatively, you can use the [`remotes`
package](https://remotes.r-lib.org/) to install the development version
(warning: this version may contain breaking changes and/or bugs) from
GitHub using:

``` r
remotes::install_github("epinowcast/epinowcast", dependencies = TRUE)
```

Similarly, you can install historical releases by adding the release tag
(e.g. this installs
[`0.2.0`](https://github.com/epinowcast/epinowcast/releases/tag/v0.2.0)):

``` r
remotes::install_github(
  "epinowcast/epinowcast", dependencies = TRUE, ref = "v0.2.0"
)
```

*Note: A similar method can be used to install a particular commit of
the package which may be useful for some users who are unable to use a
fixed release but concerned about the stability of their dependencies.*
</details>
<details>
<summary>
Installing CmdStan
</summary>

If you wish to do model fitting and nowcasting, you will need to install
[CmdStan](https://mc-stan.org/users/interfaces/cmdstan). We recommend
using [`cmdstanr`](https://mc-stan.org/cmdstanr/) and the
`cmdstanr::install_cmdstan()` to do so, which needs a suitable C++
toolchain. Instructions are provided in the [*Getting started with
`cmdstanr`*](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
vignette. See the [`cmdstanr`
documentation](https://mc-stan.org/cmdstanr/) for further details and
support.

``` r
cmdstanr::install_cmdstan()
```

*Note: This install process can be sped up using the `cores` argument
and past versions can be installed using the `version` argument (which
may be useful if install historical package releases).*
</details>
<details>
<summary>
Alternative: Docker
</summary>
We also provide a [Docker](https://www.docker.com/get-started/) image
with [`epinowcast` and all dependencies
installed](https://github.com/orgs/epinowcast/packages/container/package/epinowcast).
This image can be used to run `epinowcast` without installing
dependencies locally.
</details>

## Resources

As you use the package, the documentation available via `?enw_` should
be your first stop for troubleshooting. We also provide a range of other
documentation, case studies, and spaces for the community to interact
with each other. Below is a short list of current resources.

- [Package website](https://package.epinowcast.org/): This includes a
  function reference, model outline, and case studies using the package.
  The package site covers the release version, which can be installed
  from our Universe or from the latest GitHub release (see [installation
  instructions](#Installation)). Documentation for the development
  version (corresponding to the `main` branch on GitHub) [is also
  available](https://package.epinowcast.org/dev/).
- [Package Vignettes](https://package.epinowcast.org/articles): These
  provide tutorials and case studies, focused discussions of particular
  aspects, or demonstrate case studies. The [Getting Started with
  Epinowcast:
  Nowcasting](https://package.epinowcast.org/articles/getting-started-part-1)
  is a good place to start.
- [Organisation website](https://www.epinowcast.org/): This includes
  links to our other resources as well as guest posts from community
  members and schedules for any related seminars being run by community
  members.
- [Directory of example
  scripts](https://github.com/epinowcast/epinowcast/tree/main/inst/examples):
  Not as fleshed out as our complete case studies these scripts are used
  during package development and each showcase a subset of package
  functionality. Often newly introduced features will be explored here
  before surfacing in other areas of our documentation.
- [Community forum](https://community.epinowcast.org/): Our community
  forum is where development of methods and tools is discussed, along
  with related research from our members and discussions between users.
  If you are interested in real-time analysis of infectious disease this
  is likely a good place to start regardless of if you end up making use
  of `epinowcast`.

## Contributing

We welcome contributions and new contributors! We particularly
appreciate help on priority problems in the
[issues](https://github.com/epinowcast/epinowcast/issues). Please check
and add to the issues, and/or add a [pull
request](https://github.com/epinowcast/epinowcast/pulls). See our
[contributing
guide](https://github.com/epinowcast/epinowcast/blob/main/CONTRIBUTING.md)
for more information.

If interested in expanding the functionality of the underlying model
note that `epinowcast` allows users to pass in their own models meaning
that alternative parameterisations, for example altering the forecast
model used for inferring expected observations, may be easily tested
within the package infrastructure. Once this testing has been done
alterations that increase the flexibility of the package model and
improves its defaults are very welcome via pull request or other
communication with the package authors. Even if not wanting to add your
updated model to the package please do reach out as we would love to
hear about your use case.

### How to make a bug report or feature request

Please briefly describe your problem and what output you expect in an
[issue](https://github.com/epinowcast/epinowcast/issues). If you have a
question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/epinowcast/epinowcast/discussions/categories/q-a).
See our [contributing
guide](https://github.com/epinowcast/epinowcast/blob/main/CONTRIBUTING.md)
for more information.

### Code of Conduct

Please note that the `epinowcast` project is released with a
[Contributor Code of
Conduct](https://package.epinowcast.org/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.

## Citation

If you use `epinowcast` in your work, please consider citing it using
the following,

``` r
citation("epinowcast")
```

To cite package ‘epinowcast’ in publications use:

Sam Abbott, Lison A, Funk S, Pearson C, Gruson H, Guenther F (NULL).
*epinowcast: Flexible Hierarchical Nowcasting*.
<doi:10.5281/zenodo.5637165> <https://doi.org/10.5281/zenodo.5637165>.

A BibTeX entry for LaTeX users is

@Manual{, title = {epinowcast: Flexible Hierarchical Nowcasting}, author
= {{Sam Abbott} and Adrian Lison and Sebastian Funk and Carl Pearson and
Hugo Gruson and Felix Guenther}, year = {NULL}, doi =
{10.5281/zenodo.5637165}, }

If making use of our methodology or the methodology on which ours is
based, please cite the relevant papers from our [model
outline](https://package.epinowcast.org/articles/model.html).
