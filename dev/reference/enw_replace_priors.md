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
#>             variable
#>               <char>
#> 1:     refp_mean_int
#> 2:       refp_sd_int
#> 3: refp_mean_beta_sd
#> 4:   refp_sd_beta_sd
#> 5:         refnp_int
#> 6:     refnp_beta_sd
#>                                                       description
#>                                                            <char>
#> 1:         Log mean intercept for parametric reference date delay
#> 2: Log standard deviation for the parametric reference date delay
#> 3:    Standard deviation of scaled pooled parametric mean effects
#> 4:      Standard deviation of scaled pooled parametric sd effects
#> 5:              Intercept for non-parametric reference date delay
#> 6:     Standard deviation of scaled pooled non-parametric effects
#>             distribution  mean    sd
#>                   <char> <num> <num>
#> 1:                Normal   1.0     1
#> 2: Zero truncated normal   0.5     1
#> 3: Zero truncated normal   0.0     1
#> 4: Zero truncated normal   0.0     1
#> 5:                Normal   0.0     1
#> 6: Zero truncated normal   0.0     1

fit_priors <- summary(
 enw_example("nowcast"), type = "fit",
 variables = c("refp_mean_int", "refp_sd_int", "sqrt_phi")
)
fit_priors
#>            variable      mean    median         sd        mad        q5
#>              <char>     <num>     <num>      <num>      <num>     <num>
#> 1: refp_mean_int[1] 2.8538466 2.8339088 0.60299691 0.62443435 1.9172352
#> 2:   refp_sd_int[1] 3.6893646 3.6917677 0.30337736 0.30959601 3.2030695
#> 3:      sqrt_phi[1] 0.3492024 0.3481456 0.03164753 0.03011692 0.2989725
#>          q20       q80       q95     rhat  ess_bulk ess_tail
#>        <num>     <num>     <num>    <num>     <num>    <num>
#> 1: 2.3202662 3.3509946 3.9807851 1.003710  606.3893 555.9773
#> 2: 3.4216331 3.9414908 4.2085437 1.001962  671.3773 487.2159
#> 3: 0.3228929 0.3739743 0.4046854 1.002404 1084.4296 806.2026

enw_replace_priors(default_priors, fit_priors)
#>             variable
#>               <char>
#> 1: refp_mean_beta_sd
#> 2:   refp_sd_beta_sd
#> 3:         refnp_int
#> 4:     refnp_beta_sd
#> 5:     refp_mean_int
#> 6:       refp_sd_int
#> 7:          sqrt_phi
#>                                                    description
#>                                                         <char>
#> 1: Standard deviation of scaled pooled parametric mean effects
#> 2:   Standard deviation of scaled pooled parametric sd effects
#> 3:           Intercept for non-parametric reference date delay
#> 4:  Standard deviation of scaled pooled non-parametric effects
#> 5:                                                        <NA>
#> 6:                                                        <NA>
#> 7:                                                        <NA>
#>             distribution      mean         sd
#>                   <char>     <num>      <num>
#> 1: Zero truncated normal 0.0000000 1.00000000
#> 2: Zero truncated normal 0.0000000 1.00000000
#> 3:                Normal 0.0000000 1.00000000
#> 4: Zero truncated normal 0.0000000 1.00000000
#> 5:                  <NA> 2.8538466 0.60299691
#> 6:                  <NA> 3.6893646 0.30337736
#> 7:                  <NA> 0.3492024 0.03164753
```
