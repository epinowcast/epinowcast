# enw_missing produces the expected model components

    Code
      miss <- enw_missing(formula = ~ 1 + rw(week), data = pobs)
      miss$inits <- NULL
      miss
    Output
      $formula
      [1] "~1 + rw(week)"
      
      $data
      $data$miss_fdesign
         (Intercept) cweek1 cweek2 cweek3 cweek4 cweek5 cweek6
      1            1      0      0      0      0      0      0
      2            1      0      0      0      0      0      0
      3            1      0      0      0      0      0      0
      4            1      1      0      0      0      0      0
      5            1      1      0      0      0      0      0
      6            1      1      0      0      0      0      0
      7            1      1      0      0      0      0      0
      8            1      1      0      0      0      0      0
      9            1      1      0      0      0      0      0
      10           1      1      0      0      0      0      0
      11           1      1      1      0      0      0      0
      12           1      1      1      0      0      0      0
      13           1      1      1      0      0      0      0
      14           1      1      1      0      0      0      0
      15           1      1      1      0      0      0      0
      16           1      1      1      0      0      0      0
      17           1      1      1      0      0      0      0
      18           1      1      1      1      0      0      0
      19           1      1      1      1      0      0      0
      20           1      1      1      1      0      0      0
      21           1      1      1      1      0      0      0
      22           1      1      1      1      0      0      0
      23           1      1      1      1      0      0      0
      24           1      1      1      1      0      0      0
      25           1      1      1      1      1      0      0
      26           1      1      1      1      1      0      0
      27           1      1      1      1      1      0      0
      28           1      1      1      1      1      0      0
      29           1      1      1      1      1      0      0
      30           1      1      1      1      1      0      0
      31           1      1      1      1      1      0      0
      32           1      1      1      1      1      1      0
      33           1      1      1      1      1      1      0
      34           1      1      1      1      1      1      0
      35           1      1      1      1      1      1      0
      36           1      1      1      1      1      1      0
      37           1      1      1      1      1      1      0
      38           1      1      1      1      1      1      0
      39           1      1      1      1      1      1      1
      40           1      1      1      1      1      1      1
      41           1      1      1      1      1      1      1
      attr(,"assign")
      [1] 0 1 2 3 4 5 6
      
      $data$miss_fnrow
      [1] 41
      
      $data$miss_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$miss_fnindex
      [1] 41
      
      $data$miss_fncol
      [1] 6
      
      $data$miss_rdesign
        fixed week
      1     0    1
      2     0    1
      3     0    1
      4     0    1
      5     0    1
      6     0    1
      attr(,"assign")
      [1] 1 2
      
      $data$miss_rncol
      [1] 1
      
      $data$missing_ref
           2021-07-13 2021-07-14 2021-07-15 2021-07-16 2021-07-17 2021-07-18
      [1,]          0          0          0          0          0          0
           2021-07-19 2021-07-20 2021-07-21 2021-07-22 2021-07-23 2021-07-24
      [1,]          0          0          0          0          0          0
           2021-07-25 2021-07-26 2021-07-27 2021-07-28 2021-07-29 2021-07-30
      [1,]          0          0          0          0          0          0
           2021-07-31 2021-08-01 2021-08-02 2021-08-03 2021-08-04 2021-08-05
      [1,]          0          0          0          0          0          0
           2021-08-06 2021-08-07 2021-08-08 2021-08-09 2021-08-10 2021-08-11
      [1,]          0          0          0          0          0          0
           2021-08-12 2021-08-13 2021-08-14 2021-08-15 2021-08-16 2021-08-17
      [1,]          0          0          0          0          0          0
           2021-08-18 2021-08-19 2021-08-20 2021-08-21 2021-08-22
      [1,]          0          0          0          0          0
      
      $data$model_miss
      [1] 1
      
      
      $priors
             variable
      1:     miss_int
      2: miss_beta_sd
                                                                              description
      1:          Intercept on the logit scale for the proportion missing reference dates
      2: Standard deviation of scaled pooled logit missing reference date\n       effects
                  distribution mean sd
      1:                Normal    0  1
      2: Zero truncated normal    0  1
      

# enw_missing returns an empty model when required

    Code
      miss <- enw_missing(formula = ~0, data = pobs)
      miss$inits <- NULL
      miss
    Output
      $formula
      [1] "~0"
      
      $data
      $data$miss_fdesign
      numeric(0)
      
      $data$miss_fnrow
      [1] 0
      
      $data$miss_findex
      numeric(0)
      
      $data$miss_fnindex
      [1] 0
      
      $data$miss_fncol
      [1] 0
      
      $data$miss_rdesign
      numeric(0)
      
      $data$miss_rncol
      [1] 0
      
      $data$model_miss
      [1] 0
      
      $data$missing_ref
      numeric(0)
      
      
      $priors
             variable
      1:     miss_int
      2: miss_beta_sd
                                                                              description
      1:          Intercept on the logit scale for the proportion missing reference dates
      2: Standard deviation of scaled pooled logit missing reference date\n       effects
                  distribution mean sd
      1:                Normal    0  1
      2: Zero truncated normal    0  1
      

