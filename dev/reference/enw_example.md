# Load a package example

Loads examples of nowcasts produced using example scripts. Used to
streamline examples, in package tests and to enable users to explore
package functionality without needing to install `cmdstanr`.

## Usage

``` r
enw_example(
  type = c("nowcast", "preprocessed_observations", "observations", "script")
)
```

## Arguments

- type:

  A character string indicating the example to load. Supported options
  are

  - "nowcast", for
    [`epinowcast()`](https://package.epinowcast.org/dev/reference/epinowcast.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/dev/reference/germany_covid19_hosp.md)

  - "preprocessed_observations", for
    [`enw_preprocess_data()`](https://package.epinowcast.org/dev/reference/enw_preprocess_data.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/dev/reference/germany_covid19_hosp.md)

  - "observations", for
    [`enw_latest_data()`](https://package.epinowcast.org/dev/reference/enw_latest_data.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/dev/reference/germany_covid19_hosp.md)

  - "script", the code used to generate these examples.

## Value

Depending on `type`, a `data.table` of the requested output OR the file
name(s) to generate these outputs (`type` = "script")

## See also

Package data sets
[`germany_covid19_hosp`](https://package.epinowcast.org/dev/reference/germany_covid19_hosp.md)

## Examples

``` r
# Load the nowcast
enw_example(type = "nowcast")
#>                    obs          new_confirm              latest
#>                 <list>               <list>              <list>
#> 1: <data.table[650x9]> <data.table[610x11]> <data.table[40x10]>
#>     missing_reference  reporting_triangle      metareference
#>                <list>              <list>             <list>
#> 1: <data.table[40x6]> <data.table[40x22]> <data.table[40x9]>
#>             metareport          metadelay max_delay  time snapshots     by
#>                 <list>             <list>     <num> <int>     <int> <list>
#> 1: <data.table[59x12]> <data.table[20x5]>        20    40        40 [NULL]
#>    groups   max_date timestep             priors
#>     <int>     <IDat>   <char>             <list>
#> 1:      1 2021-08-22      day <data.table[14x6]>
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             fit
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          <list>
#> 1: <CmdStanMCMC>\n  Inherits from: <CmdStanFit>\n  Public:\n    clone: function (deep = FALSE) \n    cmdstan_diagnose: function () \n    cmdstan_summary: function (flags = NULL) \n    code: function () \n    config_files: function (include_failed = FALSE) \n    constrain_variables: function (unconstrained_variables, transformed_parameters = TRUE, \n    data_file: function () \n    diagnostic_summary: function (diagnostics = c("divergences", "treedepth", "ebfmi"), \n    draws: function (variables = NULL, inc_warmup = FALSE, format = getOption("cmdstanr_draws_format", \n    expose_functions: function (global = FALSE, verbose = FALSE) \n    functions: environment\n    grad_log_prob: function (unconstrained_variables, jacobian = TRUE, jacobian_adjustment = NULL) \n    hessian: function (unconstrained_variables, jacobian = TRUE, jacobian_adjustment = NULL) \n    init: function () \n    init_model_methods: function (seed = 1, verbose = FALSE, hessian = FALSE) \n    initialize: function (runset) \n    inv_metric: function (matrix = TRUE) \n    latent_dynamics_files: function (include_failed = FALSE) \n    log_prob: function (unconstrained_variables, jacobian = TRUE, jacobian_adjustment = NULL) \n    loo: function (variables = "log_lik", r_eff = TRUE, moment_match = FALSE, \n    lp: function () \n    metadata: function () \n    metric_files: function (include_failed = FALSE) \n    num_chains: function () \n    num_procs: function () \n    output: function (id = NULL) \n    output_files: function (include_failed = FALSE) \n    print: function (variables = NULL, ..., digits = 2, max_rows = getOption("cmdstanr_max_rows", \n    profile_files: function (include_failed = FALSE) \n    profiles: function () \n    return_codes: function () \n    runset: CmdStanRun, R6\n    sampler_diagnostics: function (inc_warmup = FALSE, format = getOption("cmdstanr_draws_format", \n    save_config_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_data_file: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_latent_dynamics_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_metric_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_object: function (file, ...) \n    save_output_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    save_profile_files: function (dir = ".", basename = NULL, timestamp = TRUE, random = TRUE) \n    summary: function (variables = NULL, ...) \n    time: function () \n    unconstrain_draws: function (files = NULL, draws = NULL, format = getOption("cmdstanr_draws_format", \n    unconstrain_variables: function (variables) \n    variable_skeleton: function (transformed_parameters = TRUE, generated_quantities = TRUE) \n  Private:\n    draws_: -1350.196 -1351.1578 -1352.7977 -1347.4477 -1344.1504 -1 ...\n    init_: NULL\n    inv_metric_: list\n    metadata_: list\n    model_methods_env_: environment\n    profiles_: NULL\n    read_csv_: function (variables = NULL, sampler_diagnostics = NULL, format = getOption("cmdstanr_draws_format", \n    return_codes_: 0 0\n    sampler_diagnostics_: 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7  ...\n    warmup_draws_: NULL\n    warmup_sampler_diagnostics_: NULL
#>           data  fit_args init_method_output samples max_rhat
#>         <list>    <list>             <list>   <int>    <num>
#> 1: <list[112]> <list[5]>             [NULL]    1000     1.01
#>    divergent_transitions per_divergent_transitions max_treedepth
#>                    <num>                     <num>         <num>
#> 1:                     0                         0             8
#>    no_at_max_treedepth per_at_max_treedepth run_time
#>                  <int>                <num>    <num>
#> 1:                   3                0.003       26

# Load the preprocessed observations
enw_example(type = "preprocessed_observations")
#>                    obs          new_confirm              latest
#>                 <list>               <list>              <list>
#> 1: <data.table[650x9]> <data.table[610x11]> <data.table[40x10]>
#>     missing_reference  reporting_triangle      metareference
#>                <list>              <list>             <list>
#> 1: <data.table[40x6]> <data.table[40x22]> <data.table[40x9]>
#>             metareport          metadelay max_delay  time snapshots     by
#>                 <list>             <list>     <num> <int>     <int> <list>
#> 1: <data.table[59x12]> <data.table[20x5]>        20    40        40 [NULL]
#>    groups   max_date timestep
#>     <int>     <IDat>   <char>
#> 1:      1 2021-08-22      day

# Load the latest observations
enw_example(type = "observations")
#>     reference_date location age_group report_date confirm
#>             <IDat>   <fctr>    <fctr>      <IDat>   <int>
#>  1:     2021-08-03       DE       00+  2021-10-01     156
#>  2:     2021-08-04       DE       00+  2021-10-01     183
#>  3:     2021-08-05       DE       00+  2021-10-01     147
#>  4:     2021-08-06       DE       00+  2021-10-01     155
#>  5:     2021-08-07       DE       00+  2021-10-01     159
#>  6:     2021-08-08       DE       00+  2021-10-01     119
#>  7:     2021-08-09       DE       00+  2021-10-01      65
#>  8:     2021-08-10       DE       00+  2021-10-01     204
#>  9:     2021-08-11       DE       00+  2021-10-01     275
#> 10:     2021-08-12       DE       00+  2021-10-01     273
#> 11:     2021-08-13       DE       00+  2021-10-01     270
#> 12:     2021-08-14       DE       00+  2021-10-01     262
#> 13:     2021-08-15       DE       00+  2021-10-01     192
#> 14:     2021-08-16       DE       00+  2021-10-01     140
#> 15:     2021-08-17       DE       00+  2021-10-01     323
#> 16:     2021-08-18       DE       00+  2021-10-01     409
#> 17:     2021-08-19       DE       00+  2021-10-01     370
#> 18:     2021-08-20       DE       00+  2021-10-01     361
#> 19:     2021-08-21       DE       00+  2021-10-01     339
#> 20:     2021-08-22       DE       00+  2021-10-01     258
#>     reference_date location age_group report_date confirm
#>             <IDat>   <fctr>    <fctr>      <IDat>   <int>

# Load the script used to generate these examples
# Optionally source this script to regenerate the example
readLines(enw_example(type = "script"))
#>  [1] "# Load epinowcast and data.table"                                                  
#>  [2] "library(epinowcast)"                                                               
#>  [3] "library(data.table)"                                                               
#>  [4] ""                                                                                  
#>  [5] "# Load and filter germany hospitalisations"                                        
#>  [6] "nat_germany_hosp <- germany_covid19_hosp[location == \"DE\"][age_group == \"00+\"]"
#>  [7] "nat_germany_hosp <- enw_filter_report_dates("                                      
#>  [8] "  nat_germany_hosp, latest_date = \"2021-10-01\""                                  
#>  [9] ")"                                                                                 
#> [10] ""                                                                                  
#> [11] "# Make sure observations are complete"                                             
#> [12] "nat_germany_hosp <- enw_complete_dates("                                           
#> [13] "  nat_germany_hosp, by = c(\"location\", \"age_group\")"                           
#> [14] ")"                                                                                 
#> [15] ""                                                                                  
#> [16] "# Make a retrospective dataset"                                                    
#> [17] "retro_nat_germany <- enw_filter_report_dates("                                     
#> [18] "  nat_germany_hosp, remove_days = 40"                                              
#> [19] ")"                                                                                 
#> [20] "retro_nat_germany <- enw_filter_reference_dates("                                  
#> [21] "  retro_nat_germany, include_days = 40"                                            
#> [22] ")"                                                                                 
#> [23] ""                                                                                  
#> [24] "# Get latest observations for the same time period"                                
#> [25] "latest_obs <- enw_latest_data(nat_germany_hosp)"                                   
#> [26] "latest_obs <- enw_filter_reference_dates("                                         
#> [27] "  latest_obs, remove_days = 40, include_days = 20"                                 
#> [28] ")"                                                                                 
#> [29] ""                                                                                  
#> [30] "# Preprocess observations"                                                         
#> [31] "pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)"                    
#> [32] ""                                                                                  
#> [33] "# Reference date model"                                                            
#> [34] "reference_module <- enw_reference(~1, data = pobs)"                                
#> [35] ""                                                                                  
#> [36] "# Report date model"                                                               
#> [37] "report_module <- enw_report(~ (1 | day_of_week), data = pobs)"                     
#> [38] ""                                                                                  
#> [39] "# Fit nowcast model and produce a nowcast"                                         
#> [40] "# Note that we have reduced samples for this example to reduce runtimes"           
#> [41] "nowcast <- epinowcast(pobs,"                                                       
#> [42] "  reference = reference_module,"                                                   
#> [43] "  report = report_module,"                                                         
#> [44] "  fit = enw_fit_opts("                                                             
#> [45] "    save_warmup = FALSE, pp = TRUE,"                                               
#> [46] "    chains = 2, threads_per_chain = 2,"                                            
#> [47] "    iter_warmup = 500, iter_sampling = 500"                                        
#> [48] "  )"                                                                               
#> [49] ")"                                                                                 
```
