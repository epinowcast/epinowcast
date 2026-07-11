# Gaussian process latent terms: maths, priors, and usage

## Introduction

This vignette covers the maths behind `epinowcast`’s Gaussian process
latent terms, how to use them in any module’s formula, and how to set
their priors. It explains the Hilbert-space spectral approximation, the
available kernels, and the regularisation choices, with the trade-offs
made explicit. For worked usage and a comparison to
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`arima()`](https://package.epinowcast.org/reference/arima.md), and
lme4-style random effects, see the [latent processes
vignette](https://package.epinowcast.org/articles/latent-processes.md).
For the full model definition see the [model
vignette](https://package.epinowcast.org/articles/model.md).

The implementation was ported from
[`EpiNow2`](https://github.com/epiforecasts/EpiNow2)
(`epiforecasts/EpiNow2`, MIT licensed), where the same Hilbert-space
approximate Gaussian process is used as the default latent process for
the reproduction number. The Stan functions in
`inst/stan/functions/gaussian_process.stan` carry an attribution comment
to that effect. The maths below follows the `EpiNow2` implementation
notes and the underlying method of Riutort-Mayol et
al.^(\[[1](#ref-approxGP)\]).

## What a Gaussian process term does

A `gp(time, by, kernel, basis_prop)` term in a formula declares a smooth
latent function of time that is added to the relevant linear predictor
at every observation. Writing the linear predictor of a module as
\\\eta_i\\ for observation \\i\\ at time \\t_i\\ and group \\g_i\\:

\\\eta_i = X_i \beta + Z_i b + f\_{g_i}(t_i),\\

where \\X_i \beta\\ are the fixed effects, \\Z_i b\\ the random effects
(including any [`rw()`](https://package.epinowcast.org/reference/rw.md)
contributions, which are handled through the design matrix), and
\\f\_{g_i}(t_i)\\ is the value of the Gaussian process for group \\g_i\\
at time \\t_i\\. The process evolves over the time axis declared in
`gp(...)`; each observation just looks up the value at its own (time,
group) index.

The one-dimensional Gaussian processes used here have a zero mean
function and a stationary covariance kernel \\k\\,

\\f \sim \mathrm{GP}(0,\\ k(\Delta t)), \qquad k(t, t') = k(\|t - t'\|)
= k(\Delta t),\\

so the prior correlation between two time points depends only on their
separation \\\Delta t\\. Where the
[`arima()`](https://package.epinowcast.org/reference/arima.md) term
builds memory step by step from a recursion, the Gaussian process places
a smooth prior over the whole trajectory at once, with a *length scale*
\\\rho\\ that controls how quickly the function can change and a
*magnitude* \\\alpha\\ that controls how far it can depart from zero.

## Using Gaussian process terms in a formula

Add a term to any module’s formula with
[`gp()`](https://package.epinowcast.org/reference/gp.md):

- `gp(time)` — a Gaussian process over `time` with the default Matérn
  3/2 kernel.
- `gp(time, by)` — an independent realisation per level of `by`, sharing
  the length scale and magnitude.
- `gp(time, d = 1)` — an integrated (non-stationary) process (see
  [Differencing order](#differencing)).
- `gp(time, kernel = "se")` — a different kernel (see
  [Kernels](#kernels)).
- `gp(time, basis_prop = 0.3)` — more basis functions, trading speed for
  approximation accuracy.

`time` is the column the process evolves over, and the optional `by`
gives each group its own realisation under shared hyperparameters. The
[latent processes
vignette](https://package.epinowcast.org/articles/latent-processes.md)
works through [`gp()`](https://package.epinowcast.org/reference/gp.md)
on the growth rate and compares it to
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`arima()`](https://package.epinowcast.org/reference/arima.md), and
lme4-style random effects; the [Priors](#priors) section below covers
tuning their regularisation.

## The kernel and Hilbert-space decomposition

A Gaussian process with a dense covariance matrix costs \\O(T^3)\\ to
evaluate, which is prohibitive inside a sampler. We instead use the
Hilbert-space reduced-rank (spectral) approximation of Riutort-Mayol et
al.^(\[[1](#ref-approxGP)\]), which represents the process as a finite
weighted sum of fixed basis functions,

\\f(t) \approx \sum\_{j=1}^{m} \left( S_k(\sqrt{\lambda_j})
\right)^{\frac{1}{2}} \phi_j(t)\\ \beta_j,\\

with \\m\\ the number of basis functions. This turns the Gaussian
process into a linear model in \\m\\ standard-normal weights
\\\beta_j\\, so the cost is \\O(T m)\\ rather than \\O(T^3)\\.

The number of basis functions is set as a proportion \\b\\ of the number
of time points \\t\_\mathrm{GP}\\ to which the process is applied,
rounded up^(\[[1](#ref-approxGP)\]),

\\m = \lceil b\\ t\_\mathrm{GP} \rceil.\\

The eigenvalues of the Laplace operator on the boundary-scaled interval
are

\\\lambda_j = \left( \frac{j \pi}{2 L} \right)^2,\\

with \\L\\ a positive boundary factor, and the eigenfunctions are

\\\phi_j(t) = \frac{1}{\sqrt{L}} \sin\\\left( \sqrt{\lambda_j}\\ (t^\* +
L) \right),\\

with time rescaled linearly to lie in \\\[-1, 1\]\\,

\\t^\* = \frac{t - \tfrac{1}{2} t\_\mathrm{GP}}{\tfrac{1}{2}
t\_\mathrm{GP}}.\\

The weights have a standard-normal prior \\\beta_j \sim \mathcal{N}(0,
1)\\, so the approximation is non-centred: all of the kernel’s structure
enters through the spectral densities \\S_k(\sqrt{\lambda_j})\\, which
scale each basis function by how much power the kernel places at that
frequency.

The basis matrix \\\Phi \in \mathbb{R}^{T \times m}\\ (with entries
\\\phi_j(t)\\) is data-only: it does not depend on \\\rho\\ or
\\\alpha\\, so it is built once on the R side in
[`construct_gp()`](https://package.epinowcast.org/reference/construct_gp.md)
and passed to Stan as data. The spectral densities are
parameter-dependent and rebuilt every gradient evaluation. Putting the
pieces together, the latent process for one group is

``` text
S    <- diagSPD(alpha, rho, L, M)     # length-M (or 2M) spectral density
f    <- PHI * (S .* eta)              # length-T latent, eta ~ Normal(0, 1)
```

The Stan implementation of these steps lives in
`inst/stan/functions/gaussian_process.stan`, which was adapted from
`EpiNow2`.

## Kernels and special cases

The kernel choice enters only through the spectral density \\S_k\\. For
a Matérn kernel of order \\\nu\\,

\\S_k(\omega) = \alpha^2\\ \frac{2 \sqrt{\pi}\\ \Gamma(\nu + 1/2)\\
(2\nu)^{\nu}}{\Gamma(\nu)\\ \rho^{2\nu}} \left( \frac{2\nu}{\rho^2} +
\omega^2 \right)^{-\left(\nu + \frac{1}{2}\right)}.\\

The `kernel` argument selects among the following special cases.

- **Matérn 3/2** (`kernel = "matern32"`, the default), with covariance
  \\k(\Delta t) = \alpha^2 \left( 1 + \sqrt{3}\\\Delta t / \rho \right)
  \exp(-\sqrt{3}\\\Delta t / \rho)\\ and spectral density

  \\S_k(\omega) = \left( \frac{2 \alpha\\
  (\sqrt{3}/\rho)^{3/2}}{(\sqrt{3}/\rho)^2 + \omega^2} \right)^2.\\

- **Matérn 5/2** (`kernel = "matern52"`), with

  \\S_k(\omega) = \alpha^2\\ \frac{16\\ (\sqrt{5}/\rho)^5}{3 \left(
  (\sqrt{5}/\rho)^2 + \omega^2 \right)^3}.\\

- **Ornstein-Uhlenbeck** (`kernel = "ou"`), the Matérn 1/2 kernel, with
  \\k(\Delta t) = \alpha^2 \exp(-\Delta t / \rho)\\ and

  \\S_k(\omega) = \alpha^2\\ \frac{2}{\rho\\ (1/\rho^2 + \omega^2)}.\\

- **Squared exponential** (`kernel = "se"`), with \\k(\Delta t) =
  \alpha^2 \exp\\\left( -\tfrac{1}{2}\\ \Delta t^2 / \rho^2 \right)\\
  and

  \\S_k(\omega) = \alpha^2 \sqrt{2\pi}\\ \rho\\ \exp\\\left(
  -\tfrac{1}{2}\\ \rho^2 \omega^2 \right).\\

- **Periodic** (`kernel = "periodic"`), which repeats on a fixed cycle
  rather than decaying with separation. It uses a fundamental-frequency
  basis (cosine/sine pairs) rather than the boundary-scaled basis above,
  so `boundary_scale` has no effect for this kernel.

The smoother kernels (squared exponential, higher Matérn order) place
less power at high frequencies, so their spectral densities decay faster
and the approximation needs fewer basis functions for a given accuracy.

## Group structure: dependent vs independent

When `by` is supplied each group has its own column of standard-normal
spectral weights \\\eta\_{\cdot, g}\\, but the length scale \\\rho\\ and
magnitude \\\alpha\\ are shared across groups. The basis matrix \\\Phi\\
is built once and applied to each group’s weight column in turn, so
every group’s realisation is an independent draw from a Gaussian process
with common hyperparameters. The length scale \\\rho\\ and magnitude
\\\alpha\\ are shared across groups, and
[`gp()`](https://package.epinowcast.org/reference/gp.md) does not take a
`type` argument.

The latent process produces \\f \in \mathbb{R}^{T \times G}\\, but
observations live in a flat vector. Each observation carries its own
time and group index, so the contribution to the linear predictor is a
single matrix lookup per observation — negligible next to building the
spectral densities. On modules with a sparse design (the parametric and
non-parametric reference, the report-time hazards, and the
missing-reference proportion) the lookup index is built from the same
joint (covariate row \\\times\\ time \\\times\\ group) deduplication
used for [`arima()`](https://package.epinowcast.org/reference/arima.md),
so the gather stays aligned with the deduplicated design rows.

## Differencing order

The `d` argument integrates the realisation \\d\\ times before it enters
the predictor, matching the `d` of
[`arima()`](https://package.epinowcast.org/articles/arima.md). It
controls whether the Gaussian process models the *level* of the latent
quantity or its *change*.

- **`d = 0`** (the default) is a stationary process: \\f\\ is the
  realisation described above, fluctuating around zero with no preferred
  direction. On the growth rate this corresponds to EpiNow2’s
  `gp_on = "R0"`, where the process models stationary deviations from a
  fixed reproduction number.

- **`d = 1`** integrates the process once, so it is the *increments* of
  the trajectory that are smooth rather than the trajectory itself. The
  result drifts like a random walk but with correlated, smoothly varying
  steps, which is often the more natural prior for an epidemic trend.
  This matches EpiNow2’s default `gp_on = "R_t-1"`, where the Gaussian
  process is placed on the first difference of the log reproduction
  number.

- **`d \ge 2`** integrates further, generalising beyond EpiNow2 to
  smoother non-stationary trends (for example \\d = 2\\ models curvature
  with a smoothly varying slope).

Concretely, for \\d \ge 1\\ the spectral approximation generates the
\\T - d\\ free values \\\tilde f\\, which are placed in positions
\\(d+1), \dots, T\\ of a length-\\T\\ vector whose first \\d\\ entries
are zero, and the vector is then cumulatively summed \\d\\ times:

\\f = \underbrace{C \cdots C}\_{d}\\ \begin{pmatrix} \mathbf{0}\_d \\
\tilde f \end{pmatrix}, \qquad C \text{ the cumulative-sum operator}.\\

Because the leading \\d\\ entries start at zero they remain zero through
every integration pass, so \\f_1 = \dots = f_d = 0\\. This anchoring is
the identifiability fix: it leaves the free level (for \\d = 1\\) and
additionally the free slope (for \\d \ge 2\\) to the module’s fixed
effects rather than the Gaussian process, which would otherwise be
confounded with the intercept. This is the same convention EpiNow2 uses
for its non-stationary reproduction-number process
(`gp[2:(gp_n + 1)] = noise; gp = cumulative_sum(gp)`), generalised to
arbitrary \\d\\.

Differencing is meaningful for the latent expectation modules (the
growth rate `expr` and the latent-to-obs proportion `expl`), where a
drifting non-stationary trend is the usual model. It is permitted on the
logit-hazard modules (`refnp`, `rep`, `miss`) for API consistency with
[`arima()`](https://package.epinowcast.org/reference/arima.md), but
integrating a logit hazard is unusual and rarely the intended model.

## Priors

The default priors follow `EpiNow2`^(\[[1](#ref-approxGP)\]). The length
scale \\\rho\\ and magnitude \\\alpha\\ can both be overridden through
the standard `priors` argument of the relevant module; the spectral
weights are fixed.

- \\\eta_j \sim \mathcal{N}(0, 1)\\ — fixed by the non-centred
  parameterisation; not user-tunable.
- \\\alpha \sim \mathcal{N}\_+(\mu\_\alpha, \sigma\_\alpha)\\
  (half-normal) — controls how far the process can deviate from zero.
  Set through the `<prefix>_gp_alpha` prior.
- \\\rho \sim \mathrm{LogNormal}(\mu\_\rho, \sigma\_\rho)\\ — controls
  how quickly the process can change. Set through the `<prefix>_gp_rho`
  prior.

Here `<prefix>` is the module the term sits on (`expr` for the growth
rate, `refp` for the parametric reference mean, and so on; see [Where
you can use it](#where)). The `EpiNow2` defaults were chosen on the
scale of the log reproduction number; on a given module’s scale (for
example a logit hazard) they may need tightening or loosening. For
example, to put a tighter length scale on the growth-rate process:

Code

``` r

library(epinowcast)
rho_prior <- data.frame(variable = "expr_gp_rho", mean = log(3), sd = 0.25)
# epinowcast(..., priors = rho_prior)
```

The magnitude prior on \\\alpha\\ is the most consequential in practice;
tighten it if the latent process is competing with the rest of the
linear predictor for variance. The length-scale prior on \\\rho\\ is the
lever for how wiggly the function is allowed to be: a smaller \\\rho\\
permits faster changes, a larger \\\rho\\ forces a smoother trajectory.

## Where you can use it

[`gp()`](https://package.epinowcast.org/reference/gp.md) works on every
module that takes a formula, each with its own prior prefix:

- [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)
  — the growth rate (`expr`) and the latent-to-obs proportion (`expl`).
- [`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)
  — the parametric mean (`refp`) and the non-parametric logit hazards
  (`refnp`).
- [`enw_report()`](https://package.epinowcast.org/reference/enw_report.md)
  — report-date logit hazards (`rep`).
- [`enw_missing()`](https://package.epinowcast.org/reference/enw_missing.md)
  — the missing-reference proportion (`miss`).

Putting a [`gp()`](https://package.epinowcast.org/reference/gp.md) term
on the reference delay mean, for instance, models a reporting delay that
drifts smoothly over time, while a
[`gp()`](https://package.epinowcast.org/reference/gp.md) on the growth
rate models the epidemic trend itself.

## Limitations

- One Gaussian process term per formula. The R side aborts if multiple
  are supplied.
- Grouped series share the length scale and magnitude across groups, and
  [`gp()`](https://package.epinowcast.org/reference/gp.md) does not take
  a `type` argument.
- The approximation accuracy is controlled by `basis_prop`; too few
  basis functions oversmooth short-length-scale structure, while too
  many slow the fit. The `EpiNow2` default of \\b = 0.2\\ is a
  reasonable starting point but may need raising for processes with fast
  variation.
- When the parametric reference standard deviation is modelled
  (`model_refp > 1`), it shares the Gaussian process basis, length
  scale, and spectral weights of the mean but carries an independent
  magnitude (`refp_gp_sd_alpha`). The two latent processes are therefore
  perfectly correlated up to that magnitude rather than driven by
  separate weights.

## References

1\.

Riutort-Mayol, G., Bürkner, P.-C., Andersen, M. R., Solin, A., &
Vehtari, A. (2023). Practical hilbert space approximate bayesian
gaussian processes for probabilistic programming. *Statistics and
Computing*, *33*(1), 17. <https://doi.org/10.1007/s11222-022-10167-2>
