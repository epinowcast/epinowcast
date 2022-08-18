# enw_formula can return a basic fixed effects formula

    Code
      enw_formula(~ 1 + age_group, data)
    Output
      $formula
      [1] "~1 + age_group"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"         "age_group"
      
      $parsed_formula$random
      NULL
      
      $parsed_formula$rw
      character(0)
      
      
      $expanded_formula
      [1] "~1 + age_group"
      
      $fixed
      $fixed$formula
      [1] "~1 + age_group"
      
      $fixed$design
         (Intercept) age_group05-14 age_group15-34
      1            1              0              0
      12           1              1              0
      23           1              0              1
      
      $fixed$index
       [1] 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3
      
      
      $random
      $random$formula
      [1] "~1"
      
      $random$design
        (Intercept)
      1           1
      2           1
      attr(,"assign")
      [1] 0
      
      $random$index
      [1] 1 2
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can return a basic random effects formula

    Code
      enw_formula(~ 1 + (1 | age_group), data)
    Output
      $formula
      [1] "~1 + (1 | age_group)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 | age_group
      
      
      $parsed_formula$rw
      character(0)
      
      
      $expanded_formula
      [1] "~1 + age_group"
      
      $fixed
      $fixed$formula
      [1] "~1 + age_group"
      
      $fixed$design
         (Intercept) age_group00+ age_group05-14 age_group15-34
      1            1            1              0              0
      12           1            0              1              0
      23           1            0              0              1
      
      $fixed$index
       [1] 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3
      
      
      $random
      $random$formula
      [1] "~0 + fixed + age_group"
      
      $random$design
        fixed age_group
      1     0         1
      2     0         1
      3     0         1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1 2 3
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can return a model with a random effect and a random
           walk

    Code
      enw_formula(~ 1 + (1 | age_group) + rw(week), data)
    Output
      $formula
      [1] "~1 + (1 | age_group) + rw(week)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 | age_group
      
      
      $parsed_formula$rw
      [1] "rw(week)"
      
      
      $expanded_formula
      [1] "~1 + cweek1 + age_group"
      
      $fixed
      $fixed$formula
      [1] "~1 + cweek1 + age_group"
      
      $fixed$design
         (Intercept) cweek1 age_group00+ age_group05-14 age_group15-34
      1            1      0            1              0              0
      8            1      1            1              0              0
      12           1      0            0              1              0
      19           1      1            0              1              0
      23           1      0            0              0              1
      30           1      1            0              0              1
      
      $fixed$index
       [1] 1 1 1 1 1 1 1 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 5 5 5 5 5 5 5 6 6 6 6
      
      
      $random
      $random$formula
      [1] "~0 + fixed + age_group + week"
      
      $random$design
        fixed age_group week
      1     0         1    0
      2     0         1    0
      3     0         1    0
      4     0         0    1
      attr(,"assign")
      [1] 1 2 3
      
      $random$index
      [1] 1 2 3 4
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can return a model with a random effect
           and a random walk by group

    Code
      enw_formula(~ 1 + (1 | age_group) + rw(week, age_group), data)
    Output
      $formula
      [1] "~1 + (1 | age_group) + rw(week, age_group)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 | age_group
      
      
      $parsed_formula$rw
      [1] "rw(week, age_group)"
      
      
      $expanded_formula
      [1] "~1 + age_group:cweek1 + age_group"
      
      $fixed
      $fixed$formula
      [1] "~1 + age_group:cweek1 + age_group"
      
      $fixed$design
         (Intercept) age_group00+ age_group05-14 age_group15-34 age_group00+:cweek1
      1            1            1              0              0                   0
      8            1            1              0              0                   1
      12           1            0              1              0                   0
      19           1            0              1              0                   0
      23           1            0              0              1                   0
      30           1            0              0              1                   0
         age_group05-14:cweek1 age_group15-34:cweek1
      1                      0                     0
      8                      0                     0
      12                     0                     0
      19                     1                     0
      23                     0                     0
      30                     0                     1
      
      $fixed$index
       [1] 1 1 1 1 1 1 1 2 2 2 2 3 3 3 3 3 3 3 4 4 4 4 5 5 5 5 5 5 5 6 6 6 6
      
      
      $random
      $random$formula
      [1] "~0 + fixed + age_group + `age_group00+__week` + `age_group05-14__week` + `age_group15-34__week`"
      
      $random$design
        fixed age_group `age_group00+__week` `age_group05-14__week`
      1     0         1                    0                      0
      2     0         1                    0                      0
      3     0         1                    0                      0
      4     0         0                    1                      0
      5     0         0                    0                      1
      6     0         0                    0                      0
        `age_group15-34__week`
      1                      0
      2                      0
      3                      0
      4                      0
      5                      0
      6                      1
      attr(,"assign")
      [1] 1 2 3 4 5
      
      $random$index
      [1] 1 2 3 4 5 6
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can return a model with a fixed effect, random effect
           and a random walk

    Code
      enw_formula(~ 1 + day_of_week + (1 | age_group) + rw(week), data)
    Output
      $formula
      [1] "~1 + day_of_week + (1 | age_group) + rw(week)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"           "day_of_week"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 | age_group
      
      
      $parsed_formula$rw
      [1] "rw(week)"
      
      
      $expanded_formula
      [1] "~1 + day_of_week + cweek1 + age_group"
      
      $fixed
      $fixed$formula
      [1] "~1 + day_of_week + cweek1 + age_group"
      
      $fixed$design
         (Intercept) day_of_weekMonday day_of_weekSaturday day_of_weekSunday
      1            1                 0                   0                 0
      2            1                 0                   0                 0
      3            1                 0                   1                 0
      4            1                 0                   0                 1
      5            1                 1                   0                 0
      6            1                 0                   0                 0
      7            1                 0                   0                 0
      8            1                 0                   0                 0
      9            1                 0                   0                 0
      10           1                 0                   1                 0
      11           1                 0                   0                 1
      12           1                 0                   0                 0
      13           1                 0                   0                 0
      14           1                 0                   1                 0
      15           1                 0                   0                 1
      16           1                 1                   0                 0
      17           1                 0                   0                 0
      18           1                 0                   0                 0
      19           1                 0                   0                 0
      20           1                 0                   0                 0
      21           1                 0                   1                 0
      22           1                 0                   0                 1
      23           1                 0                   0                 0
      24           1                 0                   0                 0
      25           1                 0                   1                 0
      26           1                 0                   0                 1
      27           1                 1                   0                 0
      28           1                 0                   0                 0
      29           1                 0                   0                 0
      30           1                 0                   0                 0
      31           1                 0                   0                 0
      32           1                 0                   1                 0
      33           1                 0                   0                 1
         day_of_weekThursday day_of_weekTuesday day_of_weekWednesday cweek1
      1                    1                  0                    0      0
      2                    0                  0                    0      0
      3                    0                  0                    0      0
      4                    0                  0                    0      0
      5                    0                  0                    0      0
      6                    0                  1                    0      0
      7                    0                  0                    1      0
      8                    1                  0                    0      1
      9                    0                  0                    0      1
      10                   0                  0                    0      1
      11                   0                  0                    0      1
      12                   1                  0                    0      0
      13                   0                  0                    0      0
      14                   0                  0                    0      0
      15                   0                  0                    0      0
      16                   0                  0                    0      0
      17                   0                  1                    0      0
      18                   0                  0                    1      0
      19                   1                  0                    0      1
      20                   0                  0                    0      1
      21                   0                  0                    0      1
      22                   0                  0                    0      1
      23                   1                  0                    0      0
      24                   0                  0                    0      0
      25                   0                  0                    0      0
      26                   0                  0                    0      0
      27                   0                  0                    0      0
      28                   0                  1                    0      0
      29                   0                  0                    1      0
      30                   1                  0                    0      1
      31                   0                  0                    0      1
      32                   0                  0                    0      1
      33                   0                  0                    0      1
         age_group00+ age_group05-14 age_group15-34
      1             1              0              0
      2             1              0              0
      3             1              0              0
      4             1              0              0
      5             1              0              0
      6             1              0              0
      7             1              0              0
      8             1              0              0
      9             1              0              0
      10            1              0              0
      11            1              0              0
      12            0              1              0
      13            0              1              0
      14            0              1              0
      15            0              1              0
      16            0              1              0
      17            0              1              0
      18            0              1              0
      19            0              1              0
      20            0              1              0
      21            0              1              0
      22            0              1              0
      23            0              0              1
      24            0              0              1
      25            0              0              1
      26            0              0              1
      27            0              0              1
      28            0              0              1
      29            0              0              1
      30            0              0              1
      31            0              0              1
      32            0              0              1
      33            0              0              1
      
      $fixed$index
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33
      
      
      $random
      $random$formula
      [1] "~0 + fixed + age_group + week"
      
      $random$design
         fixed age_group week
      1      1         0    0
      2      1         0    0
      3      1         0    0
      4      1         0    0
      5      1         0    0
      6      1         0    0
      7      0         1    0
      8      0         1    0
      9      0         1    0
      10     0         0    1
      attr(,"assign")
      [1] 1 2 3
      
      $random$index
       [1]  1  2  3  4  5  6  7  8  9 10
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can handle random effects that are not factors

    Code
      enw_formula(~ 1 + (1 | d_week), test_data)
    Output
      $formula
      [1] "~1 + (1 | d_week)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 | d_week
      
      
      $parsed_formula$rw
      character(0)
      
      
      $expanded_formula
      [1] "~1 + d_week"
      
      $fixed
      $fixed$formula
      [1] "~1 + d_week"
      
      $fixed$design
        (Intercept) d_week0 d_week1
      1           1       1       0
      8           1       0       1
      
      $fixed$index
       [1] 1 1 1 1 1 1 1 2 2 2 2 2 2 2
      
      
      $random
      $random$formula
      [1] "~0 + fixed + d_week"
      
      $random$design
        fixed d_week
      1     0      1
      2     0      1
      attr(,"assign")
      [1] 1 2
      
      $random$index
      [1] 1 2
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can handle formulas that do not have sparse fixed
           effects

    Code
      enw_formula(~1, data[1:20, ], sparse = FALSE)
    Output
      $formula
      [1] "~1"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"
      
      $parsed_formula$random
      NULL
      
      $parsed_formula$rw
      character(0)
      
      
      $expanded_formula
      [1] "~1"
      
      $fixed
      $fixed$formula
      [1] "~1"
      
      $fixed$design
         (Intercept)
      1            1
      2            1
      3            1
      4            1
      5            1
      6            1
      7            1
      8            1
      9            1
      10           1
      11           1
      12           1
      13           1
      14           1
      15           1
      16           1
      17           1
      18           1
      19           1
      20           1
      attr(,"assign")
      [1] 0
      
      $fixed$index
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
      
      
      $random
      $random$formula
      [1] "~1"
      
      $random$design
           (Intercept)
      attr(,"assign")
      [1] 0
      
      $random$index
      integer(0)
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

# enw_formula can handle complex combined formulas

    Code
      enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt | am), mtcars)
    Output
      $formula
      [1] "~1 + disp + (1 + gear | cyl) + (0 + wt | am)"
      
      $parsed_formula
      $parsed_formula$fixed
      [1] "1"    "disp"
      
      $parsed_formula$random
      $parsed_formula$random[[1]]
      1 + gear | cyl
      
      $parsed_formula$random[[2]]
      0 + wt | am
      
      
      $parsed_formula$rw
      character(0)
      
      
      $expanded_formula
      [1] "~1 + disp + cyl + gear:cyl + wt:am"
      
      $fixed
      $fixed$formula
      [1] "~1 + disp + cyl + gear:cyl + wt:am"
      
      $fixed$design
         (Intercept)  disp cyl4 cyl6 cyl8 cyl4:gear cyl6:gear cyl8:gear wt:am0 wt:am1
      1            1 160.0    0    1    0         0         4         0  0.000  2.620
      2            1 160.0    0    1    0         0         4         0  0.000  2.875
      3            1 108.0    1    0    0         4         0         0  0.000  2.320
      4            1 258.0    0    1    0         0         3         0  3.215  0.000
      5            1 360.0    0    0    1         0         0         3  3.440  0.000
      6            1 225.0    0    1    0         0         3         0  3.460  0.000
      7            1 360.0    0    0    1         0         0         3  3.570  0.000
      8            1 146.7    1    0    0         4         0         0  3.190  0.000
      9            1 140.8    1    0    0         4         0         0  3.150  0.000
      10           1 167.6    0    1    0         0         4         0  3.440  0.000
      12           1 275.8    0    0    1         0         0         3  4.070  0.000
      13           1 275.8    0    0    1         0         0         3  3.730  0.000
      14           1 275.8    0    0    1         0         0         3  3.780  0.000
      15           1 472.0    0    0    1         0         0         3  5.250  0.000
      16           1 460.0    0    0    1         0         0         3  5.424  0.000
      17           1 440.0    0    0    1         0         0         3  5.345  0.000
      18           1  78.7    1    0    0         4         0         0  0.000  2.200
      19           1  75.7    1    0    0         4         0         0  0.000  1.615
      20           1  71.1    1    0    0         4         0         0  0.000  1.835
      21           1 120.1    1    0    0         3         0         0  2.465  0.000
      22           1 318.0    0    0    1         0         0         3  3.520  0.000
      23           1 304.0    0    0    1         0         0         3  3.435  0.000
      24           1 350.0    0    0    1         0         0         3  3.840  0.000
      25           1 400.0    0    0    1         0         0         3  3.845  0.000
      26           1  79.0    1    0    0         4         0         0  0.000  1.935
      27           1 120.3    1    0    0         5         0         0  0.000  2.140
      28           1  95.1    1    0    0         5         0         0  0.000  1.513
      29           1 351.0    0    0    1         0         0         5  0.000  3.170
      30           1 145.0    0    1    0         0         5         0  0.000  2.770
      31           1 301.0    0    0    1         0         0         5  0.000  3.570
      32           1 121.0    1    0    0         4         0         0  0.000  2.780
      
      $fixed$index
       [1]  1  2  3  4  5  6  7  8  9 10 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
      [26] 25 26 27 28 29 30 31
      
      
      $random
      $random$formula
      [1] "~0 + fixed + cyl + gear__cyl + wt__am"
      
      $random$design
        fixed cyl gear__cyl wt__am
      1     1   0         0      0
      2     0   1         0      0
      3     0   1         0      0
      4     0   1         0      0
      5     0   0         1      0
      6     0   0         1      0
      7     0   0         1      0
      8     0   0         0      1
      9     0   0         0      1
      attr(,"assign")
      [1] 1 2 3 4
      
      $random$index
      [1] 1 2 3 4 5 6 7 8 9
      
      
      attr(,"class")
      [1] "enw_formula" "list"       

