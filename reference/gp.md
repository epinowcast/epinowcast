# Adds an approximate Gaussian process to the model.

A call to `gp()` can be used in the `formula` argument of model
construction functions in the `epinowcast` package such as
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md).
It declares a Hilbert-space reduced-rank (spectral) approximate Gaussian
process indexed by `time` (and optionally a grouping variable `by`)
whose value at each observation is added to the linear predictor. As
with [`arima()`](https://package.epinowcast.org/reference/arima.md),
arguments are not evaluated; they are passed by name for use in model
construction.

Like [`arima()`](https://package.epinowcast.org/reference/arima.md) and
[`rw()`](https://package.epinowcast.org/reference/rw.md), a `gp()` term
works on every module that takes a formula, each with its own prior
prefix:

- [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)
  — the growth rate (`expr`) and the latent-to-obs proportion (`expl`).

- [`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)
  — the parametric delay mean (`refp`) and the non-parametric logit
  hazards (`refnp`).

- [`enw_report()`](https://package.epinowcast.org/reference/enw_report.md)
  — report-date logit hazards (`rep`).

- [`enw_missing()`](https://package.epinowcast.org/reference/enw_missing.md)
  — the missing-reference proportion (`miss`).

At most one `gp()` term is currently supported per formula (the
multiple-term example shown for
[`gp_terms()`](https://package.epinowcast.org/reference/gp_terms.md)
only illustrates term detection, not a supported model). The default
`alpha` (magnitude) and length-scale priors are inherited from `EpiNow2`
and are set on `EpiNow2`'s scale; on a given module's scale (for example
the log growth rate or a logit hazard) they may need tuning with
[`enw_replace_priors()`](https://package.epinowcast.org/reference/enw_replace_priors.md).

## Usage

``` r
gp(
  time,
  by,
  d = 0,
  kernel = c("matern32", "matern52", "ou", "se", "periodic"),
  basis_prop = 0.2,
  boundary_scale = 1.5
)
```

## Arguments

- time:

  Defines the time index of the Gaussian process. Must be numeric.

- by:

  Optional grouping variable. If supplied, an independent Gaussian
  process is fitted for each level of `by` (sharing the length scale and
  magnitude hyperparameters). Currently limited to a single variable.

- d:

  Non-negative integer, defaults to `0`. Order of differencing, matching
  the `d` of
  [`arima()`](https://package.epinowcast.org/reference/arima.md): the
  per-group realisation is integrated (cumulative-summed) `d` times
  before it is added to the predictor. `d = 0` gives stationary
  deviations (the default, equivalent to EpiNow2's `gp_on = "R0"`).
  `d = 1` integrates once, giving a smoothly drifting, random-walk-like
  trajectory (equivalent to EpiNow2's default `gp_on = "R_t-1"`). For
  `d >= 1` the first `d` values of the realisation are anchored to zero,
  so the free level (and, for `d >= 2`, slope) is carried by the
  module's fixed effects rather than the GP. Differencing is intended
  for the latent expectation modules (the growth rate `expr` and
  latent-to-obs proportion `expl`); integrating a logit-hazard term
  (`refnp`, `rep`, `miss`) is unusual but permitted for API consistency
  with [`arima()`](https://package.epinowcast.org/reference/arima.md).

- kernel:

  Character string selecting the covariance kernel. One of `"matern32"`
  (the default, a Matern 3/2 kernel), `"matern52"` (Matern 5/2), `"ou"`
  (Ornstein-Uhlenbeck, equivalent to Matern 1/2), `"se"` (squared
  exponential), or `"periodic"`.

- basis_prop:

  Numeric in `(0, 1]`. Proportion of time points to use as basis
  functions, controlling the accuracy-speed trade-off of the
  reduced-rank approximation. Defaults to `0.2` (the `EpiNow2` default).
  The number of basis functions is `ceiling(basis_prop * T)`.

- boundary_scale:

  Numeric, defaults to `1.5`. Boundary factor `L` of the Hilbert-space
  approximation; the process is approximated on the interval scaled by
  this factor. This has no effect when `kernel = "periodic"`, which uses
  a fundamental-frequency basis rather than the boundary-scaled basis.

## Value

A list of class `enw_gp_term` describing the Gaussian process term,
interpretable by
[`construct_gp()`](https://package.epinowcast.org/reference/construct_gp.md).

## Reference

The Stan implementation of the approximate Gaussian process is adapted
from `EpiNow2` (https://github.com/epiforecasts/EpiNow2, MIT licensed).
The Hilbert-space approximation follows Riutort-Mayol et al. (2023),
doi:10.1007/s11222-022-10167-2.

## See also

Functions used to help convert formulas into model designs
[`ar()`](https://package.epinowcast.org/reference/ar.md),
[`arima()`](https://package.epinowcast.org/reference/arima.md),
[`arima_terms()`](https://package.epinowcast.org/reference/arima_terms.md),
[`arma()`](https://package.epinowcast.org/reference/arma.md),
[`as_string_formula()`](https://package.epinowcast.org/reference/as_string_formula.md),
[`construct_arima()`](https://package.epinowcast.org/reference/construct_arima.md),
[`construct_gp()`](https://package.epinowcast.org/reference/construct_gp.md),
[`construct_re()`](https://package.epinowcast.org/reference/construct_re.md),
[`construct_rw()`](https://package.epinowcast.org/reference/construct_rw.md),
[`enw_formula()`](https://package.epinowcast.org/reference/enw_formula.md),
[`enw_manual_formula()`](https://package.epinowcast.org/reference/enw_manual_formula.md),
[`gp_terms()`](https://package.epinowcast.org/reference/gp_terms.md),
[`ma()`](https://package.epinowcast.org/reference/ma.md),
[`parse_formula()`](https://package.epinowcast.org/reference/parse_formula.md),
[`re()`](https://package.epinowcast.org/reference/re.md),
[`remove_arima_terms()`](https://package.epinowcast.org/reference/remove_arima_terms.md),
[`remove_gp_terms()`](https://package.epinowcast.org/reference/remove_gp_terms.md),
[`remove_rw_terms()`](https://package.epinowcast.org/reference/remove_rw_terms.md),
[`rw()`](https://package.epinowcast.org/reference/rw.md),
[`rw_terms()`](https://package.epinowcast.org/reference/rw_terms.md),
[`split_formula_to_terms()`](https://package.epinowcast.org/reference/split_formula_to_terms.md)

## Examples

``` r
gp(time)
#> $time
#> [1] "time"
#> 
#> $by
#> NULL
#> 
#> $kernel
#> [1] "matern32"
#> 
#> $gp_type
#> [1] 2
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 0
#> 
#> $basis_prop
#> [1] 0.2
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> attr(,"class")
#> [1] "enw_gp_term"
gp(time, location)
#> $time
#> [1] "time"
#> 
#> $by
#> [1] "location"
#> 
#> $kernel
#> [1] "matern32"
#> 
#> $gp_type
#> [1] 2
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 0
#> 
#> $basis_prop
#> [1] 0.2
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> attr(,"class")
#> [1] "enw_gp_term"
gp(time, kernel = "se", basis_prop = 0.3)
#> $time
#> [1] "time"
#> 
#> $by
#> NULL
#> 
#> $kernel
#> [1] "se"
#> 
#> $gp_type
#> [1] 0
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 0
#> 
#> $basis_prop
#> [1] 0.3
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> attr(,"class")
#> [1] "enw_gp_term"
gp(time, d = 1)
#> $time
#> [1] "time"
#> 
#> $by
#> NULL
#> 
#> $kernel
#> [1] "matern32"
#> 
#> $gp_type
#> [1] 2
#> 
#> $nu
#> [1] 1.5
#> 
#> $d
#> [1] 1
#> 
#> $basis_prop
#> [1] 0.2
#> 
#> $boundary_scale
#> [1] 1.5
#> 
#> attr(,"class")
#> [1] "enw_gp_term"
```
