# A Bayesian Framework for Real-time Infectious Disease Surveillance

## Summary

A modular Bayesian framework for real-time infectious disease
surveillance. Provides tools for nowcasting, reproduction number
estimation, delay estimation, and forecasting from data subject to
reporting delays, right-truncation, missing data, and incomplete
ascertainment. Users can build models suited to their setting using a
flexible formula interface supporting fixed effects, random effects,
random walks, and time-varying parameters, with options including
parametric and non-parametric delay distributions with optional
modifiers (via discrete-time hazard models), renewal processes,
observation models, missing data imputation, and stratified analyses
with partial pooling. By jointly estimating disease dynamics and
reporting patterns, our framework enables earlier and more reliable
detection of trends. While designed with epidemiological applications in
mind, the framework can be applied to any right-truncated time series
count data.

## Important Note on Model Specification

**The default lognormal reporting delay distribution may not suit all
data.** It can fail with multimodal or complex delay patterns. Evaluate
model fit and consider alternatives (e.g., non-parametric hazards) as
needed. See the [package
vignettes](https://package.epinowcast.org/articles) for guidance.

## Installation

Installing the package

You can install the latest released version using the normal `R`
function, though you need to point to `r-universe` instead of CRAN:

``` r
install.packages(
  "epinowcast", repos = "https://epinowcast.r-universe.dev"
)
```

Alternatively, you can use the [`remotes`
package](https://remotes.r-lib.org/) to install the development version
from Github (warning! this version may contain breaking changes and/or
bugs):

``` r
remotes::install_github(
  "epinowcast/epinowcast",
  dependencies = TRUE
)
```

Similarly, you can install historical versions by specifying the release
tag (e.g. this installs
[`0.2.0`](https://github.com/epinowcast/epinowcast/releases/tag/v0.2.0)):

``` r
remotes::install_github(
  "epinowcast/epinowcast",
  dependencies = TRUE, ref = "v0.2.0"
)
```

*Note: You can also use that last approach to install a specific commit
if needed, e.g. if you want to try out a specific unreleased feature,
but not the absolute latest developmental version.*

Installing CmdStan

If you wish to do model fitting and nowcasting, you will need to install
[CmdStan](https://mc-stan.org/users/interfaces/cmdstan), which also
entails having a suitable C++ toolchain setup. We recommend using the
[`cmdstanr` package](https://mc-stan.org/cmdstanr/). The Stan team
provides instructions in the [*Getting started with
`cmdstanr`*](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)
vignette, with other details and support at the [package
site](https://mc-stan.org/cmdstanr/) along with some key instructions
available in the [Stan resources package
vignette](https://package.epinowcast.org/articles/stan-help.html#toolchain),
but the brief version is:

``` r
# if you not yet installed `epinowcast`, or you installed it without `Suggests` dependencies
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
# once `cmdstanr` is installed:
cmdstanr::install_cmdstan()
```

*Note: You can speed up CmdStan installation using the `cores` argument.
If you are installing a particular version of `epinowcast`, you may also
need to install a past version of CmdStan, which you can do with the
`version` argument.*

Alternative: Docker

We also provide a [Docker](https://www.docker.com/get-started/) image
with [`epinowcast` and all dependencies
installed](https://github.com/orgs/epinowcast/packages/container/package/epinowcast).
You can use this image to run `epinowcast` without installing
dependencies.

## Resources

As you use the package, the documentation available via `?enw_` should
be your first stop for troubleshooting. We also provide a range of other
documentation, case studies, and community spaces to ask (and answer!)
questions:

Package Website

The [`epinowcast` website](https://package.epinowcast.org/) includes a
function reference, model outline, and case studies using the package.
The site mainly concerns the release version, but you can also find
documentation for [the latest development
version](https://package.epinowcast.org/dev/).

R Vignettes

We have created [package
vignettes](https://package.epinowcast.org/articles) to help you [get
started
nowcasting](https://package.epinowcast.org/articles/epinowcast.html),
see a [quick reference to package
capabilities](https://package.epinowcast.org/articles/features.html)
(different timesteps, multi-stratification, mixed models, etc.), and
[explore case
studies](https://package.epinowcast.org/articles/germany-age-stratified-nowcasting.html).

Organisation Website

Our [organisation website](https://www.epinowcast.org/) includes links
to other resources, [guest posts](https://www.epinowcast.org/blog.html),
and [seminar schedule](https://www.epinowcast.org/seminars.html) for
both upcoming and past recordings.

Community Forum

Our [community forum](https://community.epinowcast.org/) has areas for
[question and answer](https://community.epinowcast.org/c/interface/15)
and [considering new methods and
tools](https://community.epinowcast.org/c/projects/11), among others. If
you are generally interested in real-time analysis of infectious
disease, you may find this useful even if do not use `epinowcast`.

Package Analysis Scripts

In addition to the vignettes, the package also comes with [example
analyses](https://github.com/epinowcast/epinowcast/tree/main/inst/examples).
These are not as polished as the vignettes, but we typically explore new
features with these and they may help you if you are using a development
version. After installing `epinowcast`, you can find them via:

``` r
list.files(
  system.file("examples", package = "epinowcast"), full.names = TRUE
)
```

## Contributing

We welcome contributions and new contributors! We particularly
appreciate help on [identifying and identified
issues](https://github.com/epinowcast/epinowcast/issues). Please check
and add to the issues, and/or add a [pull
request](https://github.com/epinowcast/epinowcast/pulls) and see our
[contributing
guide](https://github.com/epinowcast/.github/blob/main/CONTRIBUTING.md)
for more information.

If you need a different underlying model for your work: `epinowcast`
lets you pass your own models! If you do try new model parameterisations
that expand the overall flexibility or improve the defaults, please let
us know either here or on the [community
forum](https://community.epinowcast.org/). We always like to hear about
new use-cases, whether or not they are directed at the core `epinowcast`
applications.

### How to make a bug report or feature request

Please briefly describe your problem and what output you expect in an
[issue](https://github.com/epinowcast/epinowcast/issues). If you have a
question, please don’t open an issue. Instead, ask on our [Q and A
page](https://github.com/epinowcast/epinowcast/discussions/categories/q-a).
See our [contributing
guide](https://github.com/epinowcast/.github/blob/main/CONTRIBUTING.md)
for more information.

### Code of Conduct

Please note that the `epinowcast` project is released with a
[Contributor Code of
Conduct](https://github.com/epinowcast/.github/blob/main/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

## Citation

If making use of our methodology or the methodology on which ours is
based, please cite the relevant papers from our [model
outline](https://package.epinowcast.org/articles/model.html). If you use
`epinowcast` in your work, please consider citing it with
`citation("epinowcast")`.

## Contributors

All contributions to this project are gratefully acknowledged using the
[`allcontributors` package](https://github.com/ropensci/allcontributors)
following the [all-contributors](https://allcontributors.org)
specification. Contributions of any kind are welcome!

### Code

[seabbs](https://github.com/epinowcast/epinowcast/commits?author=seabbs),
[adrian-lison](https://github.com/epinowcast/epinowcast/commits?author=adrian-lison),
[sbfnk](https://github.com/epinowcast/epinowcast/commits?author=sbfnk),
[Bisaloo](https://github.com/epinowcast/epinowcast/commits?author=Bisaloo),
[pearsonca](https://github.com/epinowcast/epinowcast/commits?author=pearsonca),
[choi-hannah](https://github.com/epinowcast/epinowcast/commits?author=choi-hannah),
[medewitt](https://github.com/epinowcast/epinowcast/commits?author=medewitt),
[jamesmbaazam](https://github.com/epinowcast/epinowcast/commits?author=jamesmbaazam),
[pitmonticone](https://github.com/epinowcast/epinowcast/commits?author=pitmonticone),
[athowes](https://github.com/epinowcast/epinowcast/commits?author=athowes),
[jessalynnsebastian](https://github.com/epinowcast/epinowcast/commits?author=jessalynnsebastian),
[kathsherratt](https://github.com/epinowcast/epinowcast/commits?author=kathsherratt),
[barbora-sobolova](https://github.com/epinowcast/epinowcast/commits?author=barbora-sobolova),
[kaitejohnson](https://github.com/epinowcast/epinowcast/commits?author=kaitejohnson),
[Lnrivas](https://github.com/epinowcast/epinowcast/commits?author=Lnrivas),
[natemcintosh](https://github.com/epinowcast/epinowcast/commits?author=natemcintosh),
[nikosbosse](https://github.com/epinowcast/epinowcast/commits?author=nikosbosse),
[pratikunterwegs](https://github.com/epinowcast/epinowcast/commits?author=pratikunterwegs)

### Issue Authors

[teojcryan](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Ateojcryan),
[FelixGuenther](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3AFelixGuenther),
[beansrowning](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Abeansrowning),
[jbracher](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Ajbracher),
[zsusswein](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Azsusswein),
[christinesangphet](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Achristinesangphet),
[rumackaaron](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Arumackaaron),
[micahwiesner67](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Amicahwiesner67),
[kylieainslie](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Akylieainslie),
[maria-tang](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+author%3Amaria-tang)

### Issue Contributors

[jhellewell14](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Ajhellewell14),
[Gulfa](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3AGulfa),
[parksw3](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Aparksw3),
[TimTaylor](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3ATimTaylor),
[WardBrian](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3AWardBrian),
[jimrothstein](https://github.com/epinowcast/epinowcast/issues?q=is%3Aissue+commenter%3Ajimrothstein)
