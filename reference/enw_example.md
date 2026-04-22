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
    [`epinowcast()`](https://package.epinowcast.org/reference/epinowcast.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/reference/germany_covid19_hosp.md)

  - "preprocessed_observations", for
    [`enw_preprocess_data()`](https://package.epinowcast.org/reference/enw_preprocess_data.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/reference/germany_covid19_hosp.md)

  - "observations", for
    [`enw_latest_data()`](https://package.epinowcast.org/reference/enw_latest_data.md)
    applied to
    [germany_covid19_hosp](https://package.epinowcast.org/reference/germany_covid19_hosp.md)

  - "script", the code used to generate these examples.

## Value

Depending on `type`, a `data.table` of the requested output OR the file
name(s) to generate these outputs (`type` = "script")

## See also

Package data sets
[`germany_covid19_hosp`](https://package.epinowcast.org/reference/germany_covid19_hosp.md)

## Examples

``` r
# Load the nowcast
enw_example(type = "nowcast")
#> ── epinowcast model output ───────────────────────────────────────────────────── 
#> Groups: 1 | Timestep: day | Max delay: 20 
#> Observations: 40 timepoints x 40 snapshots 
#> Max date: 2021-08-22 
#> 
#> Datasets (access with `enw_get_data(x, "<name>")`): 
#>   obs                :     650 x 9 
#>   new_confirm        :     610 x 11 
#>   latest             :      40 x 10 
#>   missing_reference  :      40 x 6 
#>   reporting_triangle :      40 x 22 
#>   metareference      :      40 x 9 
#>   metareport         :      59 x 12 
#>   metadelay          :      20 x 5 
#> 
#> Model objects (access with `enw_get_data(x, "<name>")`): 
#>   priors : 14 x 6 
#>   fit : CmdStanMCMC 
#>   data : list(112) 
#>   fit_args : list(5) 
#>   init_method_output : NULL 
#> Model fit: 
#>   Samples: 1,000 | Max Rhat: 1.01 
#>   Divergent transitions: 0 (0%) 
#>   Max treedepth: 8 (3 at max, 0.3%) 
#>   Run time: 26 secs 

# Load the preprocessed observations
enw_example(type = "preprocessed_observations")
#> ── Preprocessed nowcast data ─────────────────────────────────────────────────── 
#> Groups: 1 | Timestep: day | Max delay: 20 
#> Observations: 40 timepoints x 40 snapshots 
#> Max date: 2021-08-22 
#> 
#> Datasets (access with `enw_get_data(x, "<name>")`): 
#>   obs                :     650 x 9 
#>   new_confirm        :     610 x 11 
#>   latest             :      40 x 10 
#>   missing_reference  :      40 x 6 
#>   reporting_triangle :      40 x 22 
#>   metareference      :      40 x 9 
#>   metareport         :      59 x 12 
#>   metadelay          :      20 x 5 

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
#> [25] "latest_obs <- nat_germany_hosp |>"                                                 
#> [26] "  enw_obs_at_delay(max_delay = 20) |>"                                             
#> [27] "  enw_filter_reference_dates("                                                     
#> [28] "    remove_days = 40, include_days = 20"                                           
#> [29] "  )"                                                                               
#> [30] ""                                                                                  
#> [31] "# Preprocess observations"                                                         
#> [32] "pobs <- enw_preprocess_data(retro_nat_germany, max_delay = 20)"                    
#> [33] ""                                                                                  
#> [34] "# Reference date model"                                                            
#> [35] "reference_module <- enw_reference(~1, data = pobs)"                                
#> [36] ""                                                                                  
#> [37] "# Report date model"                                                               
#> [38] "report_module <- enw_report(~ (1 | day_of_week), data = pobs)"                     
#> [39] ""                                                                                  
#> [40] "# Fit nowcast model and produce a nowcast"                                         
#> [41] "# Note that we have reduced samples for this example to reduce runtimes"           
#> [42] "nowcast <- epinowcast(pobs,"                                                       
#> [43] "  reference = reference_module,"                                                   
#> [44] "  report = report_module,"                                                         
#> [45] "  fit = enw_fit_opts("                                                             
#> [46] "    save_warmup = FALSE, pp = TRUE,"                                               
#> [47] "    chains = 2, threads_per_chain = 2,"                                            
#> [48] "    iter_warmup = 500, iter_sampling = 500"                                        
#> [49] "  )"                                                                               
#> [50] ")"                                                                                 
```
