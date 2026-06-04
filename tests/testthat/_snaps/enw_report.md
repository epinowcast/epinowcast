# enw_report supports non-parametric models

    Code
      rep <- enw_report(~ 1 + day_of_week, data = pobs)
      rep$inits <- NULL
      rep
    Output
      $formula
      $formula$non_parametric
      [1] "~1 + day_of_week"
      
      
      $data
      $data$rep_fintercept
      [1] 1
      
      $data$rep_fnrow
      [1] 7
      
      $data$rep_findex
           [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13] [,14]
      [1,]    1    2    3    4    5    6    7    1    2     3     4     5     6     7
           [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25] [,26]
      [1,]     1     2     3     4     5     6     7     1     2     3     4     5
           [,27] [,28] [,29] [,30] [,31] [,32] [,33] [,34] [,35] [,36] [,37] [,38]
      [1,]     6     7     1     2     3     4     5     6     7     1     2     3
           [,39] [,40] [,41] [,42] [,43] [,44] [,45] [,46] [,47] [,48] [,49] [,50]
      [1,]     4     5     6     7     1     2     3     4     5     6     7     1
           [,51] [,52] [,53] [,54] [,55] [,56] [,57] [,58] [,59]
      [1,]     2     3     4     5     6     7     1     2     3
      
      $data$rep_fnindex
      [1] 59
      
      $data$rep_fncol
      [1] 6
      
      $data$rep_rncol
      [1] 0
      
      $data$rep_fdesign
        day_of_weekMonday day_of_weekSaturday day_of_weekSunday day_of_weekThursday
      1                 0                   0                 0                   0
      2                 0                   0                 0                   1
      3                 0                   0                 0                   0
      4                 0                   1                 0                   0
      5                 0                   0                 1                   0
      6                 1                   0                 0                   0
      7                 0                   0                 0                   0
        day_of_weekTuesday day_of_weekWednesday
      1                  0                    1
      2                  0                    0
      3                  0                    0
      4                  0                    0
      5                  0                    0
      6                  0                    0
      7                  1                    0
      
      $data$rep_rdesign
        (Intercept)
      1           1
      2           1
      3           1
      4           1
      5           1
      6           1
      attr(,"assign")
      [1] 0
      
      $data$rep_arima_present
      [1] 0
      
      $data$rep_arima_T
      [1] 0
      
      $data$rep_arima_G
      [1] 0
      
      $data$rep_arima_p
      [1] 0
      
      $data$rep_arima_d
      [1] 0
      
      $data$rep_arima_q
      [1] 0
      
      $data$rep_arima_n_obs
      [1] 0
      
      $data$rep_arima_flat_idx
      integer(0)
      
      $data$rep_gp_present
      [1] 0
      
      $data$rep_gp_T
      [1] 0
      
      $data$rep_gp_G
      [1] 0
      
      $data$rep_gp_M
      [1] 0
      
      $data$rep_gp_type
      [1] 0
      
      $data$rep_gp_nu
      [1] 0
      
      $data$rep_gp_d
      [1] 0
      
      $data$rep_gp_L
      [1] 0
      
      $data$rep_gp_n_obs
      [1] 0
      
      $data$rep_gp_PHI
      <0 x 0 matrix>
      
      $data$rep_gp_flat_idx
      integer(0)
      
      $data$rep_agg_p
      [1] 0
      
      $data$rep_agg_n_selected
      <0 x 0 x 0 array of integer>
          
      
      
      $data$rep_agg_selected_idx
      <0 x 0 x 0 x 0 array of integer>
          
      
      
      $data$rep_t
      [1] 59
      
      $data$model_rep
      [1] 1
      
      
      $priors
                variable
      1:     rep_beta_sd
      2: rep_arima_sigma
      3:  rep_arima_pacf
      4:      rep_gp_rho
      5:    rep_gp_alpha
                                                                                                                                                                 description
      1:                                                                                                             Standard deviation of scaled pooled report date effects
      2:                                                                                        Standard deviation of the ARIMA latent residual on report-time logit hazards
      3: Partial autocorrelations of the ARIMA latent residual on the report-time logit hazards; Uniform(-1, 1) when sd = 0, otherwise Normal(mean, sd) truncated to (-1, 1)
      4:                                              Length scale of the Gaussian process on the report-time logit hazards; log-normal prior on the (positive) length scale
      5:                                                 Magnitude (marginal standard deviation) of the Gaussian process on the report-time logit hazards; half-normal prior
                  distribution     mean   sd
      1: Zero truncated normal 0.000000 1.00
      2: Zero truncated normal 0.000000 0.20
      3:               Uniform 0.000000 0.00
      4:            Log normal 1.098612 0.50
      5: Zero truncated normal 0.000000 0.05
      

