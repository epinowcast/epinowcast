# Report date logit hazard reporting model module

Report date logit hazard reporting model module

## Usage

``` r
enw_report(non_parametric = ~0, structural = NULL, data)
```

## Arguments

- non_parametric:

  A formula (as implemented in
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md))
  describing the non-parametric logit hazard model for report date
  effects. This can use features defined by report date as defined in
  `metareport` as produced by
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).
  Note that the intercept for this model is set to 0 as it should be
  used for specifying report date related hazards rather than
  time-invariant hazards, which should instead be modelled using the
  `non_parametric` argument of
  [`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md).
  Set to `~0` to disable (internally converted to `~1` and flagged as
  inactive). See
  [`enw_formula()`](https://package.epinowcast.org/dev/reference/enw_formula.md)
  for details on formula syntax.

- structural:

  A `data.table` describing the known reporting structure (e.g.,
  weekday-only reporting). This should be created using
  [`enw_dayofweek_structural_reporting()`](https://package.epinowcast.org/dev/reference/enw_dayofweek_structural_reporting.md)
  for day-of-week patterns, or
  [`enw_structural_reporting_metadata()`](https://package.epinowcast.org/dev/reference/enw_structural_reporting_metadata.md)
  as a base for custom patterns. The data.table must have columns:
  `.group`, `date`, `report_date`, and `report` (binary indicator where
  1 = reporting occurs). This is particularly useful for modeling fixed
  reporting cycles, such as Wednesday-only reporting. Set to `NULL` to
  disable (default).

- data:

  Output from
  [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md).

## Value

A list containing the supplied formulas, data passed into a list
describing the models, a `data.frame` describing the priors used, and a
function that takes the output data and priors and returns a function
that can be used to sample from a tightened version of the prior
distribution.

## See also

Model modules
[`.expectation_is_minimal()`](https://package.epinowcast.org/dev/reference/dot-expectation_is_minimal.md),
[`enw_expectation()`](https://package.epinowcast.org/dev/reference/enw_expectation.md),
[`enw_fit_opts()`](https://package.epinowcast.org/dev/reference/enw_fit_opts.md),
[`enw_missing()`](https://package.epinowcast.org/dev/reference/enw_missing.md),
[`enw_obs()`](https://package.epinowcast.org/dev/reference/enw_obs.md),
[`enw_reference()`](https://package.epinowcast.org/dev/reference/enw_reference.md)

## Examples

``` r
# Basic report model
enw_report(data = enw_example("preprocessed"))
#> $formula
#> $formula$non_parametric
#> [1] "~1"
#> 
#> 
#> $data
#> $data$rep_fintercept
#> [1] 1
#> 
#> $data$rep_fnrow
#> [1] 1
#> 
#> $data$rep_findex
#>      [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13] [,14]
#> [1,]    1    1    1    1    1    1    1    1    1     1     1     1     1     1
#>      [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25] [,26]
#> [1,]     1     1     1     1     1     1     1     1     1     1     1     1
#>      [,27] [,28] [,29] [,30] [,31] [,32] [,33] [,34] [,35] [,36] [,37] [,38]
#> [1,]     1     1     1     1     1     1     1     1     1     1     1     1
#>      [,39] [,40] [,41] [,42] [,43] [,44] [,45] [,46] [,47] [,48] [,49] [,50]
#> [1,]     1     1     1     1     1     1     1     1     1     1     1     1
#>      [,51] [,52] [,53] [,54] [,55] [,56] [,57] [,58] [,59]
#> [1,]     1     1     1     1     1     1     1     1     1
#> 
#> $data$rep_fnindex
#> [1] 59
#> 
#> $data$rep_fncol
#> [1] 0
#> 
#> $data$rep_rncol
#> [1] 0
#> 
#> $data$rep_fdesign
#>  
#> 1
#> 
#> $data$rep_fdesign_means
#> numeric(0)
#> 
#> $data$rep_rdesign
#>      (Intercept)
#> attr(,"assign")
#> [1] 0
#> 
#> $data$rep_arima_present
#> [1] 0
#> 
#> $data$rep_arima_T
#> [1] 0
#> 
#> $data$rep_arima_G
#> [1] 0
#> 
#> $data$rep_arima_p
#> [1] 0
#> 
#> $data$rep_arima_d
#> [1] 0
#> 
#> $data$rep_arima_q
#> [1] 0
#> 
#> $data$rep_arima_n_obs
#> [1] 0
#> 
#> $data$rep_arima_flat_idx
#> integer(0)
#> 
#> $data$rep_gp_present
#> [1] 0
#> 
#> $data$rep_gp_T
#> [1] 0
#> 
#> $data$rep_gp_G
#> [1] 0
#> 
#> $data$rep_gp_M
#> [1] 0
#> 
#> $data$rep_gp_type
#> [1] 0
#> 
#> $data$rep_gp_nu
#> [1] 0
#> 
#> $data$rep_gp_d
#> [1] 0
#> 
#> $data$rep_gp_L
#> [1] 0
#> 
#> $data$rep_gp_n_obs
#> [1] 0
#> 
#> $data$rep_gp_PHI
#> <0 x 0 matrix>
#> 
#> $data$rep_gp_flat_idx
#> integer(0)
#> 
#> $data$rep_agg_p
#> [1] 0
#> 
#> $data$rep_agg_n_selected
#> <0 x 0 x 0 array of integer>
#>     
#> 
#> 
#> $data$rep_agg_selected_idx
#> <0 x 0 x 0 x 0 array of integer>
#>     
#> 
#> 
#> $data$rep_t
#> [1] 59
#> 
#> $data$model_rep
#> [1] 0
#> 
#> 
#> $priors
#>           variable
#>             <char>
#> 1:     rep_beta_sd
#> 2: rep_arima_sigma
#> 3:  rep_arima_pacf
#> 4:      rep_gp_rho
#> 5:    rep_gp_alpha
#>                                                                                                                                                            description
#>                                                                                                                                                                 <char>
#> 1:                                                                                                             Standard deviation of scaled pooled report date effects
#> 2:                                                                                        Standard deviation of the ARIMA latent residual on report-time logit hazards
#> 3: Partial autocorrelations of the ARIMA latent residual on the report-time logit hazards; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
#> 4:                                              Length scale of the Gaussian process on the report-time logit hazards; log-normal prior on the (positive) length scale
#> 5:                                                 Magnitude (marginal standard deviation) of the Gaussian process on the report-time logit hazards; half-normal prior
#>             distribution     mean    sd
#>                   <char>    <num> <num>
#> 1: Zero truncated normal 0.000000  1.00
#> 2: Zero truncated normal 0.000000  0.20
#> 3:               Uniform 0.000000  0.00
#> 4:            Log normal 1.098612  0.50
#> 5: Zero truncated normal 0.000000  0.05
#> 
#> $inits
#> function (data, priors) 
#> {
#>     priors <- enw_priors_as_data_list(priors)
#>     fn <- function() {
#>         init <- list(rep_beta = numeric(0), rep_beta_sd = numeric(0))
#>         if (data$rep_fncol > 0) {
#>             init$rep_beta <- array(rnorm(data$rep_fncol, 0, 0.01))
#>         }
#>         if (data$rep_rncol > 0) {
#>             init$rep_beta_sd <- array(abs(rnorm(data$rep_rncol, 
#>                 priors$rep_beta_sd_p[1], priors$rep_beta_sd_p[2]/10)))
#>         }
#>         init <- c(init, .arima_inits(data, priors, "rep"))
#>         init <- c(init, .gp_inits(data, priors, "rep"))
#>         init
#>     }
#>     fn
#> }
#> <bytecode: 0x5606b958ac80>
#> <environment: 0x5606b957ec10>
#> 

if (FALSE) { # \dontrun{
# With Wednesday-only reporting structure
pobs <- enw_example("preprocessed")
structural <- enw_dayofweek_structural_reporting(
  pobs,
  day_of_week = "Wednesday"
)
enw_report(structural = structural, data = pobs)
} # }
```
