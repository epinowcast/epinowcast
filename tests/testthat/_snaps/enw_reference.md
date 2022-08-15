# enw_reference supports parametric models

    Code
      ref <- enw_reference(~ 1 + (1 | day_of_week) + rw(week), distribution = "lognormal",
      data = pobs)
      ref$inits <- NULL
      ref
    Output
      $formula
      $formula$parametric
      [1] "~1 + (1 | day_of_week) + rw(week)"
      
      
      $data
      $data$refp_fdesign
         (Intercept) cweek1 cweek2 cweek3 cweek4 cweek5 day_of_weekFriday
      1            1      0      0      0      0      0                 0
      2            1      0      0      0      0      0                 0
      3            1      0      0      0      0      0                 0
      4            1      0      0      0      0      0                 1
      5            1      0      0      0      0      0                 0
      6            1      0      0      0      0      0                 0
      7            1      0      0      0      0      0                 0
      8            1      1      0      0      0      0                 0
      9            1      1      0      0      0      0                 0
      10           1      1      0      0      0      0                 0
      11           1      1      0      0      0      0                 1
      12           1      1      0      0      0      0                 0
      13           1      1      0      0      0      0                 0
      14           1      1      0      0      0      0                 0
      15           1      1      1      0      0      0                 0
      16           1      1      1      0      0      0                 0
      17           1      1      1      0      0      0                 0
      18           1      1      1      0      0      0                 1
      19           1      1      1      0      0      0                 0
      20           1      1      1      0      0      0                 0
      21           1      1      1      0      0      0                 0
      22           1      1      1      1      0      0                 0
      23           1      1      1      1      0      0                 0
      24           1      1      1      1      0      0                 0
      25           1      1      1      1      0      0                 1
      26           1      1      1      1      0      0                 0
      27           1      1      1      1      0      0                 0
      28           1      1      1      1      0      0                 0
      29           1      1      1      1      1      0                 0
      30           1      1      1      1      1      0                 0
      31           1      1      1      1      1      0                 0
      32           1      1      1      1      1      0                 1
      33           1      1      1      1      1      0                 0
      34           1      1      1      1      1      0                 0
      35           1      1      1      1      1      0                 0
      36           1      1      1      1      1      1                 0
      37           1      1      1      1      1      1                 0
      38           1      1      1      1      1      1                 0
      39           1      1      1      1      1      1                 1
      40           1      1      1      1      1      1                 0
      41           1      1      1      1      1      1                 0
         day_of_weekMonday day_of_weekSaturday day_of_weekSunday day_of_weekThursday
      1                  0                   0                 0                   0
      2                  0                   0                 0                   0
      3                  0                   0                 0                   1
      4                  0                   0                 0                   0
      5                  0                   1                 0                   0
      6                  0                   0                 1                   0
      7                  1                   0                 0                   0
      8                  0                   0                 0                   0
      9                  0                   0                 0                   0
      10                 0                   0                 0                   1
      11                 0                   0                 0                   0
      12                 0                   1                 0                   0
      13                 0                   0                 1                   0
      14                 1                   0                 0                   0
      15                 0                   0                 0                   0
      16                 0                   0                 0                   0
      17                 0                   0                 0                   1
      18                 0                   0                 0                   0
      19                 0                   1                 0                   0
      20                 0                   0                 1                   0
      21                 1                   0                 0                   0
      22                 0                   0                 0                   0
      23                 0                   0                 0                   0
      24                 0                   0                 0                   1
      25                 0                   0                 0                   0
      26                 0                   1                 0                   0
      27                 0                   0                 1                   0
      28                 1                   0                 0                   0
      29                 0                   0                 0                   0
      30                 0                   0                 0                   0
      31                 0                   0                 0                   1
      32                 0                   0                 0                   0
      33                 0                   1                 0                   0
      34                 0                   0                 1                   0
      35                 1                   0                 0                   0
      36                 0                   0                 0                   0
      37                 0                   0                 0                   0
      38                 0                   0                 0                   1
      39                 0                   0                 0                   0
      40                 0                   1                 0                   0
      41                 0                   0                 1                   0
         day_of_weekTuesday day_of_weekWednesday
      1                   1                    0
      2                   0                    1
      3                   0                    0
      4                   0                    0
      5                   0                    0
      6                   0                    0
      7                   0                    0
      8                   1                    0
      9                   0                    1
      10                  0                    0
      11                  0                    0
      12                  0                    0
      13                  0                    0
      14                  0                    0
      15                  1                    0
      16                  0                    1
      17                  0                    0
      18                  0                    0
      19                  0                    0
      20                  0                    0
      21                  0                    0
      22                  1                    0
      23                  0                    1
      24                  0                    0
      25                  0                    0
      26                  0                    0
      27                  0                    0
      28                  0                    0
      29                  1                    0
      30                  0                    1
      31                  0                    0
      32                  0                    0
      33                  0                    0
      34                  0                    0
      35                  0                    0
      36                  1                    0
      37                  0                    1
      38                  0                    0
      39                  0                    0
      40                  0                    0
      41                  0                    0
      
      $data$refp_fnrow
      [1] 41
      
      $data$refp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$refp_fnindex
      [1] 41
      
      $data$refp_fncol
      [1] 12
      
      $data$refp_rdesign
         fixed day_of_week week
      1      0           1    0
      2      0           1    0
      3      0           1    0
      4      0           1    0
      5      0           1    0
      6      0           1    0
      7      0           1    0
      8      0           0    1
      9      0           0    1
      10     0           0    1
      11     0           0    1
      12     0           0    1
      attr(,"assign")
      [1] 1 2 3
      
      $data$refp_rncol
      [1] 2
      
      $data$model_refp
      [1] 2
      
      
      $priors
                  variable
      1:     refp_mean_int
      2:       refp_sd_int
      3: refp_mean_beta_sd
      4:   refp_sd_beta_sd
                                                            description
      1:         Log mean intercept for parametric reference date delay
      2: Log standard deviation for the parametric reference date delay
      3:    Standard deviation of scaled pooled parametric mean effects
      4:      Standard deviation of scaled pooled parametric sd effects
                  distribution mean sd
      1:                Normal  1.0  1
      2: Zero truncated normal  0.5  1
      3: Zero truncated normal  0.0  1
      4: Zero truncated normal  0.0  1
      

