# enw_manual_formula can return a basic fixed effects formula

    Code
      enw_manual_formula(test_data, fixed = "day_of_week")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekMonday day_of_weekSaturday day_of_weekSunday
      1           1                 0                   0                 0
      2           1                 0                   0                 0
      3           1                 0                   0                 0
      4           1                 0                   0                 0
      5           1                 0                   1                 0
      6           1                 0                   0                 1
      7           1                 1                   0                 0
        day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
      1                   0                  1                    0
      2                   0                  0                    1
      3                   1                  0                    0
      4                   0                  0                    0
      5                   0                  0                    0
      6                   0                  0                    0
      7                   0                  0                    0
      
      $fixed$index
       [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
      [39] 4 5 6
      
      
      $random
      $random$formula
      [1] "~1"
      
      $random$design
        (Intercept)
      1           1
      2           1
      3           1
      4           1
      5           1
      6           1
      attr(,"assign")
      [1] 0
      
      $random$index
      [1] 1 2 3 4 5 6
      
      

# enw_manual_formula can return a basic random effects formula

    Code
      enw_manual_formula(test_data, random = "day_of_week")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekFriday day_of_weekMonday day_of_weekSaturday
      1           1                 0                 0                   0
      2           1                 0                 0                   0
      3           1                 0                 0                   0
      4           1                 1                 0                   0
      5           1                 0                 0                   1
      6           1                 0                 0                   0
      7           1                 0                 1                   0
        day_of_weekSunday day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
      1                 0                   0                  1                    0
      2                 0                   0                  0                    1
      3                 0                   1                  0                    0
      4                 0                   0                  0                    0
      5                 0                   0                  0                    0
      6                 1                   0                  0                    0
      7                 0                   0                  0                    0
      
      $fixed$index
       [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
      [39] 4 5 6
      
      
      $random
      $random$formula
      [1] "~0 + fixed + day_of_week"
      
      $random$design
        fixed day_of_week
      1     0           1
      2     0           1
      3     0           1
      4     0           1
      5     0           1
      6     0           1
      7     0           1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1 2 3 4 5 6 7
      
      

# enw_manual_formula can return a basic custom random effects
           formula

    Code
      enw_manual_formula(test_data, custom_random = "day_of")
    Output
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week"
      
      $fixed$design
        (Intercept) day_of_weekMonday day_of_weekSaturday day_of_weekSunday
      1           1                 0                   0                 0
      2           1                 0                   0                 0
      3           1                 0                   0                 0
      4           1                 0                   0                 0
      5           1                 0                   1                 0
      6           1                 0                   0                 1
      7           1                 1                   0                 0
        day_of_weekThursday day_of_weekTuesday day_of_weekWednesday
      1                   0                  1                    0
      2                   0                  0                    1
      3                   1                  0                    0
      4                   0                  0                    0
      5                   0                  0                    0
      6                   0                  0                    0
      7                   0                  0                    0
      
      $fixed$index
       [1] 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3 4 5 6 7 1 2 3
      [39] 4 5 6
      
      
      $random
      $random$formula
      [1] "~0 + fixed + day_of"
      
      $random$design
        fixed day_of
      1     0      1
      2     0      1
      3     0      1
      4     0      1
      5     0      1
      6     0      1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1 2 3 4 5 6
      
      

