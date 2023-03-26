# enw_manual_formula can return a basic fixed effects formula

    Code
      enw_manual_formula(data, fixed = "day_of_week")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekTuesday
      1           1                  0
      2           1                  1
      
      $fixed$index
      [1] 1 2 1 2
      
      
      $random
      $random$formula
      [1] "~1"
      
      $random$design
        (Intercept)
      1           1
      attr(,"assign")
      [1] 0
      
      $random$index
      [1] 1
      
      

# enw_manual_formula can return a basic random effects formula

    Code
      enw_manual_formula(data, random = "day_of_week")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekMonday day_of_weekTuesday
      1           1                 1                  0
      2           1                 0                  1
      
      $fixed$index
      [1] 1 2 1 2
      
      
      $random
      $random$formula
      [1] "~0 + fixed + day_of_week"
      
      $random$design
        fixed day_of_week
      1     0           1
      2     0           1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1 2
      
      

# enw_manual_formula can return a basic custom random effects formula

    Code
      enw_manual_formula(data, custom_random = "day_of")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekTuesday
      1           1                  0
      2           1                  1
      
      $fixed$index
      [1] 1 2 1 2
      
      
      $random
      $random$formula
      [1] "~0 + fixed + day_of"
      
      $random$design
        fixed day_of
      1     0      1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1
      
      

