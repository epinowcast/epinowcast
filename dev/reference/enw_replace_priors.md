# Replace default priors with user specified priors

Replaces default model priors with user specified ones (restricted to
normal priors with specified mean and standard deviations). A common use
is extracting the posterior from a previous
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
run (using `summary(nowcast, type = "fit")`) and using it as a prior for
subsequent fits.

## Usage

``` r
enw_replace_priors(priors, custom_priors)
```

## Arguments

- priors:

  A `data.frame` with columns `variable`, `mean`, and `sd` describing
  normal priors. Default priors in the appropriate format are returned
  by the `$priors` element of
  [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md)
  and other model module functions.

- custom_priors:

  A `data.frame` with columns `variable`, `mean`, and `sd` describing
  normal priors to use as replacements. Rows in `custom_priors` replace
  matching rows in `priors` by the `variable` column. Vectorised prior
  names (i.e. those of the form `variable[n]`) are matched after
  stripping the index (treated as `variable`).

## Value

A data.table of prior definitions (variable, mean and sd).

## Details

Default priors can be obtained from each model module's `$priors`
element, e.g. `enw_reference(data = pobs)$priors`. See the `priors`
argument of
[`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
for a list of available prior variable names by module.

## See also

Functions used to help convert models into the format required for stan
[`enw_formula_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_formula_as_data_list.md),
[`enw_get_cache()`](https://package.epinowcast.org/dev/reference/enw_get_cache.md),
[`enw_model()`](https://package.epinowcast.org/dev/reference/enw_model.md),
[`enw_pathfinder()`](https://package.epinowcast.org/dev/reference/enw_pathfinder.md),
[`enw_priors_as_data_list()`](https://package.epinowcast.org/dev/reference/enw_priors_as_data_list.md),
[`enw_sample()`](https://package.epinowcast.org/dev/reference/enw_sample.md),
[`enw_set_cache()`](https://package.epinowcast.org/dev/reference/enw_set_cache.md),
[`enw_stan_to_r()`](https://package.epinowcast.org/dev/reference/enw_stan_to_r.md),
[`enw_unset_cache()`](https://package.epinowcast.org/dev/reference/enw_unset_cache.md),
[`remove_profiling()`](https://package.epinowcast.org/dev/reference/remove_profiling.md),
[`write_stan_files_no_profile()`](https://package.epinowcast.org/dev/reference/write_stan_files_no_profile.md)

## Examples

``` r
# Update priors from a data.frame
priors <- data.frame(variable = c("x", "y"), mean = c(1, 2), sd = c(1, 2))
custom_priors <- data.frame(variable = "x[1]", mean = 10, sd = 2)
enw_replace_priors(priors, custom_priors)
#>    variable  mean    sd
#>      <char> <num> <num>
#> 1:        y     2     2
#> 2:        x    10     2

# Update priors from a previous model fit
default_priors <- enw_reference(
 distribution = "lognormal",
 data = enw_example("preprocessed"),
)$priors
print(default_priors)
#>                variable
#>                  <char>
#>  1:       refp_mean_int
#>  2:         refp_sd_int
#>  3:   refp_mean_beta_sd
#>  4:     refp_sd_beta_sd
#>  5:    refp_arima_sigma
#>  6: refp_arima_sd_sigma
#>  7:     refp_arima_pacf
#>  8:         refp_gp_rho
#>  9:       refp_gp_alpha
#> 10:    refp_gp_sd_alpha
#> 11:           refnp_int
#> 12:       refnp_beta_sd
#> 13:   refnp_arima_sigma
#> 14:    refnp_arima_pacf
#> 15:        refnp_gp_rho
#> 16:      refnp_gp_alpha
#>                                                                                                                                                            description
#>                                                                                                                                                                 <char>
#>  1:                                                                                                             Log mean intercept for parametric reference date delay
#>  2:                                                                                                     Log standard deviation for the parametric reference date delay
#>  3:                                                                                                        Standard deviation of scaled pooled parametric mean effects
#>  4:                                                                                                          Standard deviation of scaled pooled parametric sd effects
#>  5:                                                                                                Scale of the ARIMA latent residual on the parametric reference mean
#>  6:                                                                                                  Scale of the ARIMA latent residual on the parametric reference sd
#>  7:     Partial autocorrelations of the ARIMA latent residual on the parametric reference; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
#>  8:                                                  Length scale of the Gaussian process on the parametric reference; log-normal prior on the (positive) length scale
#>  9:                                                Magnitude (marginal standard deviation) of the Gaussian process on the parametric reference mean; half-normal prior
#> 10:                                                  Magnitude (marginal standard deviation) of the Gaussian process on the parametric reference sd; half-normal prior
#> 11:                                                                                                                  Intercept for non-parametric reference date delay
#> 12:                                                                                                         Standard deviation of scaled pooled non-parametric effects
#> 13:                                                                          Standard deviation of the ARIMA latent residual on non-parametric reference logit hazards
#> 14: Partial autocorrelations of the ARIMA latent residual on the non-parametric reference; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
#> 15:                                              Length scale of the Gaussian process on the non-parametric reference; log-normal prior on the (positive) length scale
#> 16:                                                 Magnitude (marginal standard deviation) of the Gaussian process on the non-parametric reference; half-normal prior
#>              distribution     mean    sd
#>                    <char>    <num> <num>
#>  1:                Normal 1.000000  1.00
#>  2: Zero truncated normal 0.500000  1.00
#>  3: Zero truncated normal 0.000000  1.00
#>  4: Zero truncated normal 0.000000  1.00
#>  5: Zero truncated normal 0.000000  0.20
#>  6: Zero truncated normal 0.000000  0.20
#>  7:               Uniform 0.000000  0.00
#>  8:            Log normal 1.098612  0.50
#>  9: Zero truncated normal 0.000000  0.05
#> 10: Zero truncated normal 0.000000  0.05
#> 11:                Normal 0.000000  1.00
#> 12: Zero truncated normal 0.000000  1.00
#> 13: Zero truncated normal 0.000000  0.20
#> 14:               Uniform 0.000000  0.00
#> 15:            Log normal 1.098612  0.50
#> 16: Zero truncated normal 0.000000  0.05

fit_priors <- summary(
 enw_example("nowcast"), type = "fit",
 variables = c("refp_mean_int", "refp_sd_int", "sqrt_phi")
)
fit_priors
#>            variable      mean    median         sd        mad        q5
#>              <char>     <num>     <num>      <num>      <num>     <num>
#> 1: refp_mean_int[1] 2.3281669 2.2738029 0.54845804 0.53648911 1.5005858
#> 2:   refp_sd_int[1] 3.2157421 3.1984237 0.24959322 0.25213096 2.8399775
#> 3:      sqrt_phi[1] 0.2519801 0.2512342 0.03421619 0.03369525 0.1965987
#>          q20       q80       q95     rhat ess_bulk ess_tail
#>        <num>     <num>     <num>    <num>    <num>    <num>
#> 1: 1.8653912 2.7627578 3.3101674 1.009581 763.6917 595.2214
#> 2: 2.9910514 3.4071274 3.6644596 1.002632 880.4599 582.2866
#> 3: 0.2231656 0.2811834 0.3114561 1.003758 878.3723 709.2373

enw_replace_priors(default_priors, fit_priors)
#>                variable
#>                  <char>
#>  1:   refp_mean_beta_sd
#>  2:     refp_sd_beta_sd
#>  3:    refp_arima_sigma
#>  4: refp_arima_sd_sigma
#>  5:     refp_arima_pacf
#>  6:         refp_gp_rho
#>  7:       refp_gp_alpha
#>  8:    refp_gp_sd_alpha
#>  9:           refnp_int
#> 10:       refnp_beta_sd
#> 11:   refnp_arima_sigma
#> 12:    refnp_arima_pacf
#> 13:        refnp_gp_rho
#> 14:      refnp_gp_alpha
#> 15:       refp_mean_int
#> 16:         refp_sd_int
#> 17:            sqrt_phi
#>                                                                                                                                                            description
#>                                                                                                                                                                 <char>
#>  1:                                                                                                        Standard deviation of scaled pooled parametric mean effects
#>  2:                                                                                                          Standard deviation of scaled pooled parametric sd effects
#>  3:                                                                                                Scale of the ARIMA latent residual on the parametric reference mean
#>  4:                                                                                                  Scale of the ARIMA latent residual on the parametric reference sd
#>  5:     Partial autocorrelations of the ARIMA latent residual on the parametric reference; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
#>  6:                                                  Length scale of the Gaussian process on the parametric reference; log-normal prior on the (positive) length scale
#>  7:                                                Magnitude (marginal standard deviation) of the Gaussian process on the parametric reference mean; half-normal prior
#>  8:                                                  Magnitude (marginal standard deviation) of the Gaussian process on the parametric reference sd; half-normal prior
#>  9:                                                                                                                  Intercept for non-parametric reference date delay
#> 10:                                                                                                         Standard deviation of scaled pooled non-parametric effects
#> 11:                                                                          Standard deviation of the ARIMA latent residual on non-parametric reference logit hazards
#> 12: Partial autocorrelations of the ARIMA latent residual on the non-parametric reference; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
#> 13:                                              Length scale of the Gaussian process on the non-parametric reference; log-normal prior on the (positive) length scale
#> 14:                                                 Magnitude (marginal standard deviation) of the Gaussian process on the non-parametric reference; half-normal prior
#> 15:                                                                                                                                                               <NA>
#> 16:                                                                                                                                                               <NA>
#> 17:                                                                                                                                                               <NA>
#>              distribution      mean         sd
#>                    <char>     <num>      <num>
#>  1: Zero truncated normal 0.0000000 1.00000000
#>  2: Zero truncated normal 0.0000000 1.00000000
#>  3: Zero truncated normal 0.0000000 0.20000000
#>  4: Zero truncated normal 0.0000000 0.20000000
#>  5:               Uniform 0.0000000 0.00000000
#>  6:            Log normal 1.0986123 0.50000000
#>  7: Zero truncated normal 0.0000000 0.05000000
#>  8: Zero truncated normal 0.0000000 0.05000000
#>  9:                Normal 0.0000000 1.00000000
#> 10: Zero truncated normal 0.0000000 1.00000000
#> 11: Zero truncated normal 0.0000000 0.20000000
#> 12:               Uniform 0.0000000 0.00000000
#> 13:            Log normal 1.0986123 0.50000000
#> 14: Zero truncated normal 0.0000000 0.05000000
#> 15:                  <NA> 2.3281669 0.54845804
#> 16:                  <NA> 3.2157421 0.24959322
#> 17:                  <NA> 0.2519801 0.03421619
```
