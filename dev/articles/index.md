# Articles

### All vignettes

- [ARIMA latent residuals: maths, priors, and
  usage](https://package.epinowcast.org/dev/articles/arima.md):

  The maths behind the ARIMA(p, d, q) latent residuals in epinowcast,
  how to use them in any module’s formula, and how to set their priors.

- [Estimating reporting delays with the full and delay-only
  models](https://package.epinowcast.org/dev/articles/delay-estimation.md):

  A walk through of estimating a reporting delay distribution, comparing
  the full nowcasting model with the delay-only model that conditions on
  known totals.

- [Discretised
  distributions](https://package.epinowcast.org/dev/articles/distributions.md):

  Distributions and their discretisation in epinowcast

- [Getting Started with Epinowcast:
  Nowcasting](https://package.epinowcast.org/dev/articles/epinowcast.md):

  A quick start example demonstrating use of epinowcast to nowcast
  hospital admissions.

- [Model Features
  Summary](https://package.epinowcast.org/dev/articles/features.md):

  Quick reference to package capabilities

- [Gaussian process latent terms: maths, priors, and
  usage](https://package.epinowcast.org/dev/articles/gaussian-process.md):

  The maths behind the Hilbert-space approximate Gaussian process latent
  terms in epinowcast, how to use them in any module’s formula, and how
  to set their priors.

- [Hierarchical nowcasting of age stratified COVID-19 hospitalisations
  in
  Germany](https://package.epinowcast.org/dev/articles/germany-age-stratified-nowcasting.md):

  A case study exploring hierarchical models of varying complexity to
  jointly nowcast age stratified COVID-19 hospitalisations in Germany.

- [Comparing Inference
  Methods](https://package.epinowcast.org/dev/articles/inference-methods.md):

  A comparison of NUTS sampling, pathfinder approximate inference, and
  pathfinder-initialised NUTS across two model specifications.

- [Latent process and periodic options for the growth-rate
  model](https://package.epinowcast.org/dev/articles/latent-processes.md):

  Random walks, ARIMA(p, d, q) residuals, and periodic effects — the
  time-series structures available in the formula interface for the
  growth rate.

- [Model definition and
  implementation](https://package.epinowcast.org/dev/articles/model.md):

  Model formulation and implementation details

- [Case
  studies](https://package.epinowcast.org/dev/articles/package-use-cases.md):

  A place to document how epinowcast has been used

- [Visualising Preprocessed
  Data](https://package.epinowcast.org/dev/articles/preprocess-visualisation.md):

  Understanding reporting patterns before model fitting.

- [Estimating the effective reproduction number in real-time for a
  single timeseries with reporting
  delays](https://package.epinowcast.org/dev/articles/single-timeseries-rt-estimation.md):

  A walk through of a simple approach to jointly estimating the
  effective reproduction number over time and the delay from a positive
  test to this test being reported.

- [Resources to help with model fitting using
  Stan](https://package.epinowcast.org/dev/articles/stan-help.md):

  How to address issues you may encounter with Stan

- [Temporal aggregation
  guide](https://package.epinowcast.org/dev/articles/temporal-aggregation.md):

  How to fit nowcasts when the data and process timesteps differ,
  including pure weekly, weekly reporting on a daily process, and a
  daily benchmark.
