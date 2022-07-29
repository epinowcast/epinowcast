# enw_expectation produces the expected default model

    Code
      expectation <- enw_expectation(data = pobs)
    Message <simpleMessage>
      A grouped random walk using .group is not possible as this variable has fewer than 2 unique values.
    Code
      expectation$inits <- NULL
      expectation
    Output
      $formula
      $formula$expectation
      [1] "~rw(day, .group)"
      
      
      $data
      $data$exp_fdesign
         (Intercept) cday1 cday2 cday3 cday4 cday5 cday6 cday7 cday8 cday9 cday10
      1            1     0     0     0     0     0     0     0     0     0      0
      2            1     1     0     0     0     0     0     0     0     0      0
      3            1     1     1     0     0     0     0     0     0     0      0
      4            1     1     1     1     0     0     0     0     0     0      0
      5            1     1     1     1     1     0     0     0     0     0      0
      6            1     1     1     1     1     1     0     0     0     0      0
      7            1     1     1     1     1     1     1     0     0     0      0
      8            1     1     1     1     1     1     1     1     0     0      0
      9            1     1     1     1     1     1     1     1     1     0      0
      10           1     1     1     1     1     1     1     1     1     1      0
      11           1     1     1     1     1     1     1     1     1     1      1
      12           1     1     1     1     1     1     1     1     1     1      1
      13           1     1     1     1     1     1     1     1     1     1      1
      14           1     1     1     1     1     1     1     1     1     1      1
      15           1     1     1     1     1     1     1     1     1     1      1
      16           1     1     1     1     1     1     1     1     1     1      1
      17           1     1     1     1     1     1     1     1     1     1      1
      18           1     1     1     1     1     1     1     1     1     1      1
      19           1     1     1     1     1     1     1     1     1     1      1
      20           1     1     1     1     1     1     1     1     1     1      1
      21           1     1     1     1     1     1     1     1     1     1      1
      22           1     1     1     1     1     1     1     1     1     1      1
      23           1     1     1     1     1     1     1     1     1     1      1
      24           1     1     1     1     1     1     1     1     1     1      1
      25           1     1     1     1     1     1     1     1     1     1      1
      26           1     1     1     1     1     1     1     1     1     1      1
      27           1     1     1     1     1     1     1     1     1     1      1
      28           1     1     1     1     1     1     1     1     1     1      1
      29           1     1     1     1     1     1     1     1     1     1      1
      30           1     1     1     1     1     1     1     1     1     1      1
      31           1     1     1     1     1     1     1     1     1     1      1
      32           1     1     1     1     1     1     1     1     1     1      1
      33           1     1     1     1     1     1     1     1     1     1      1
      34           1     1     1     1     1     1     1     1     1     1      1
      35           1     1     1     1     1     1     1     1     1     1      1
      36           1     1     1     1     1     1     1     1     1     1      1
      37           1     1     1     1     1     1     1     1     1     1      1
      38           1     1     1     1     1     1     1     1     1     1      1
      39           1     1     1     1     1     1     1     1     1     1      1
      40           1     1     1     1     1     1     1     1     1     1      1
      41           1     1     1     1     1     1     1     1     1     1      1
         cday11 cday12 cday13 cday14 cday15 cday16 cday17 cday18 cday19 cday20 cday21
      1       0      0      0      0      0      0      0      0      0      0      0
      2       0      0      0      0      0      0      0      0      0      0      0
      3       0      0      0      0      0      0      0      0      0      0      0
      4       0      0      0      0      0      0      0      0      0      0      0
      5       0      0      0      0      0      0      0      0      0      0      0
      6       0      0      0      0      0      0      0      0      0      0      0
      7       0      0      0      0      0      0      0      0      0      0      0
      8       0      0      0      0      0      0      0      0      0      0      0
      9       0      0      0      0      0      0      0      0      0      0      0
      10      0      0      0      0      0      0      0      0      0      0      0
      11      0      0      0      0      0      0      0      0      0      0      0
      12      1      0      0      0      0      0      0      0      0      0      0
      13      1      1      0      0      0      0      0      0      0      0      0
      14      1      1      1      0      0      0      0      0      0      0      0
      15      1      1      1      1      0      0      0      0      0      0      0
      16      1      1      1      1      1      0      0      0      0      0      0
      17      1      1      1      1      1      1      0      0      0      0      0
      18      1      1      1      1      1      1      1      0      0      0      0
      19      1      1      1      1      1      1      1      1      0      0      0
      20      1      1      1      1      1      1      1      1      1      0      0
      21      1      1      1      1      1      1      1      1      1      1      0
      22      1      1      1      1      1      1      1      1      1      1      1
      23      1      1      1      1      1      1      1      1      1      1      1
      24      1      1      1      1      1      1      1      1      1      1      1
      25      1      1      1      1      1      1      1      1      1      1      1
      26      1      1      1      1      1      1      1      1      1      1      1
      27      1      1      1      1      1      1      1      1      1      1      1
      28      1      1      1      1      1      1      1      1      1      1      1
      29      1      1      1      1      1      1      1      1      1      1      1
      30      1      1      1      1      1      1      1      1      1      1      1
      31      1      1      1      1      1      1      1      1      1      1      1
      32      1      1      1      1      1      1      1      1      1      1      1
      33      1      1      1      1      1      1      1      1      1      1      1
      34      1      1      1      1      1      1      1      1      1      1      1
      35      1      1      1      1      1      1      1      1      1      1      1
      36      1      1      1      1      1      1      1      1      1      1      1
      37      1      1      1      1      1      1      1      1      1      1      1
      38      1      1      1      1      1      1      1      1      1      1      1
      39      1      1      1      1      1      1      1      1      1      1      1
      40      1      1      1      1      1      1      1      1      1      1      1
      41      1      1      1      1      1      1      1      1      1      1      1
         cday22 cday23 cday24 cday25 cday26 cday27 cday28 cday29 cday30 cday31 cday32
      1       0      0      0      0      0      0      0      0      0      0      0
      2       0      0      0      0      0      0      0      0      0      0      0
      3       0      0      0      0      0      0      0      0      0      0      0
      4       0      0      0      0      0      0      0      0      0      0      0
      5       0      0      0      0      0      0      0      0      0      0      0
      6       0      0      0      0      0      0      0      0      0      0      0
      7       0      0      0      0      0      0      0      0      0      0      0
      8       0      0      0      0      0      0      0      0      0      0      0
      9       0      0      0      0      0      0      0      0      0      0      0
      10      0      0      0      0      0      0      0      0      0      0      0
      11      0      0      0      0      0      0      0      0      0      0      0
      12      0      0      0      0      0      0      0      0      0      0      0
      13      0      0      0      0      0      0      0      0      0      0      0
      14      0      0      0      0      0      0      0      0      0      0      0
      15      0      0      0      0      0      0      0      0      0      0      0
      16      0      0      0      0      0      0      0      0      0      0      0
      17      0      0      0      0      0      0      0      0      0      0      0
      18      0      0      0      0      0      0      0      0      0      0      0
      19      0      0      0      0      0      0      0      0      0      0      0
      20      0      0      0      0      0      0      0      0      0      0      0
      21      0      0      0      0      0      0      0      0      0      0      0
      22      0      0      0      0      0      0      0      0      0      0      0
      23      1      0      0      0      0      0      0      0      0      0      0
      24      1      1      0      0      0      0      0      0      0      0      0
      25      1      1      1      0      0      0      0      0      0      0      0
      26      1      1      1      1      0      0      0      0      0      0      0
      27      1      1      1      1      1      0      0      0      0      0      0
      28      1      1      1      1      1      1      0      0      0      0      0
      29      1      1      1      1      1      1      1      0      0      0      0
      30      1      1      1      1      1      1      1      1      0      0      0
      31      1      1      1      1      1      1      1      1      1      0      0
      32      1      1      1      1      1      1      1      1      1      1      0
      33      1      1      1      1      1      1      1      1      1      1      1
      34      1      1      1      1      1      1      1      1      1      1      1
      35      1      1      1      1      1      1      1      1      1      1      1
      36      1      1      1      1      1      1      1      1      1      1      1
      37      1      1      1      1      1      1      1      1      1      1      1
      38      1      1      1      1      1      1      1      1      1      1      1
      39      1      1      1      1      1      1      1      1      1      1      1
      40      1      1      1      1      1      1      1      1      1      1      1
      41      1      1      1      1      1      1      1      1      1      1      1
         cday33 cday34 cday35 cday36 cday37 cday38 cday39 cday40
      1       0      0      0      0      0      0      0      0
      2       0      0      0      0      0      0      0      0
      3       0      0      0      0      0      0      0      0
      4       0      0      0      0      0      0      0      0
      5       0      0      0      0      0      0      0      0
      6       0      0      0      0      0      0      0      0
      7       0      0      0      0      0      0      0      0
      8       0      0      0      0      0      0      0      0
      9       0      0      0      0      0      0      0      0
      10      0      0      0      0      0      0      0      0
      11      0      0      0      0      0      0      0      0
      12      0      0      0      0      0      0      0      0
      13      0      0      0      0      0      0      0      0
      14      0      0      0      0      0      0      0      0
      15      0      0      0      0      0      0      0      0
      16      0      0      0      0      0      0      0      0
      17      0      0      0      0      0      0      0      0
      18      0      0      0      0      0      0      0      0
      19      0      0      0      0      0      0      0      0
      20      0      0      0      0      0      0      0      0
      21      0      0      0      0      0      0      0      0
      22      0      0      0      0      0      0      0      0
      23      0      0      0      0      0      0      0      0
      24      0      0      0      0      0      0      0      0
      25      0      0      0      0      0      0      0      0
      26      0      0      0      0      0      0      0      0
      27      0      0      0      0      0      0      0      0
      28      0      0      0      0      0      0      0      0
      29      0      0      0      0      0      0      0      0
      30      0      0      0      0      0      0      0      0
      31      0      0      0      0      0      0      0      0
      32      0      0      0      0      0      0      0      0
      33      0      0      0      0      0      0      0      0
      34      1      0      0      0      0      0      0      0
      35      1      1      0      0      0      0      0      0
      36      1      1      1      0      0      0      0      0
      37      1      1      1      1      0      0      0      0
      38      1      1      1      1      1      0      0      0
      39      1      1      1      1      1      1      0      0
      40      1      1      1      1      1      1      1      0
      41      1      1      1      1      1      1      1      1
      attr(,"assign")
       [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
      [26] 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
      
      $data$exp_fnrow
      [1] 41
      
      $data$exp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$exp_fnindex
      [1] 41
      
      $data$exp_fncol
      [1] 40
      
      $data$exp_rdesign
         fixed day
      1      0   1
      2      0   1
      3      0   1
      4      0   1
      5      0   1
      6      0   1
      7      0   1
      8      0   1
      9      0   1
      10     0   1
      11     0   1
      12     0   1
      13     0   1
      14     0   1
      15     0   1
      16     0   1
      17     0   1
      18     0   1
      19     0   1
      20     0   1
      21     0   1
      22     0   1
      23     0   1
      24     0   1
      25     0   1
      26     0   1
      27     0   1
      28     0   1
      29     0   1
      30     0   1
      31     0   1
      32     0   1
      33     0   1
      34     0   1
      35     0   1
      36     0   1
      37     0   1
      38     0   1
      39     0   1
      40     0   1
      attr(,"assign")
      [1] 1 2
      
      $data$exp_rncol
      [1] 1
      
      $data$exp_order
      [1] 1
      
      
      $priors
            variable                                             description
      1: exp_beta_sd Standard deviation of scaled pooled expectation effects
      2:    eobs_lsd      Standard deviation for expected final observations
                  distribution mean sd
      1: Zero truncated normal    0  1
      2: Zero truncated normal    0  1
      

# enw_expectation supports custom expectation models

    Code
      expectation <- enw_expectation(~ 1 + (1 | day_of_week), data = pobs)
      expectation$inits <- NULL
      expectation
    Output
      $formula
      $formula$expectation
      [1] "~1 + (1 | day_of_week)"
      
      
      $data
      $data$exp_fdesign
         (Intercept) day_of_weekFriday day_of_weekMonday day_of_weekSaturday
      1            1                 0                 0                   0
      2            1                 0                 0                   0
      3            1                 0                 0                   0
      4            1                 1                 0                   0
      5            1                 0                 0                   1
      6            1                 0                 0                   0
      7            1                 0                 1                   0
      8            1                 0                 0                   0
      9            1                 0                 0                   0
      10           1                 0                 0                   0
      11           1                 1                 0                   0
      12           1                 0                 0                   1
      13           1                 0                 0                   0
      14           1                 0                 1                   0
      15           1                 0                 0                   0
      16           1                 0                 0                   0
      17           1                 0                 0                   0
      18           1                 1                 0                   0
      19           1                 0                 0                   1
      20           1                 0                 0                   0
      21           1                 0                 1                   0
      22           1                 0                 0                   0
      23           1                 0                 0                   0
      24           1                 0                 0                   0
      25           1                 1                 0                   0
      26           1                 0                 0                   1
      27           1                 0                 0                   0
      28           1                 0                 1                   0
      29           1                 0                 0                   0
      30           1                 0                 0                   0
      31           1                 0                 0                   0
      32           1                 1                 0                   0
      33           1                 0                 0                   1
      34           1                 0                 0                   0
      35           1                 0                 1                   0
      36           1                 0                 0                   0
      37           1                 0                 0                   0
      38           1                 0                 0                   0
      39           1                 1                 0                   0
      40           1                 0                 0                   1
      41           1                 0                 0                   0
         day_of_weekSunday day_of_weekThursday day_of_weekTuesday
      1                  0                   0                  1
      2                  0                   0                  0
      3                  0                   1                  0
      4                  0                   0                  0
      5                  0                   0                  0
      6                  1                   0                  0
      7                  0                   0                  0
      8                  0                   0                  1
      9                  0                   0                  0
      10                 0                   1                  0
      11                 0                   0                  0
      12                 0                   0                  0
      13                 1                   0                  0
      14                 0                   0                  0
      15                 0                   0                  1
      16                 0                   0                  0
      17                 0                   1                  0
      18                 0                   0                  0
      19                 0                   0                  0
      20                 1                   0                  0
      21                 0                   0                  0
      22                 0                   0                  1
      23                 0                   0                  0
      24                 0                   1                  0
      25                 0                   0                  0
      26                 0                   0                  0
      27                 1                   0                  0
      28                 0                   0                  0
      29                 0                   0                  1
      30                 0                   0                  0
      31                 0                   1                  0
      32                 0                   0                  0
      33                 0                   0                  0
      34                 1                   0                  0
      35                 0                   0                  0
      36                 0                   0                  1
      37                 0                   0                  0
      38                 0                   1                  0
      39                 0                   0                  0
      40                 0                   0                  0
      41                 1                   0                  0
         day_of_weekWednesday
      1                     0
      2                     1
      3                     0
      4                     0
      5                     0
      6                     0
      7                     0
      8                     0
      9                     1
      10                    0
      11                    0
      12                    0
      13                    0
      14                    0
      15                    0
      16                    1
      17                    0
      18                    0
      19                    0
      20                    0
      21                    0
      22                    0
      23                    1
      24                    0
      25                    0
      26                    0
      27                    0
      28                    0
      29                    0
      30                    1
      31                    0
      32                    0
      33                    0
      34                    0
      35                    0
      36                    0
      37                    1
      38                    0
      39                    0
      40                    0
      41                    0
      attr(,"assign")
      [1] 0 1 1 1 1 1 1 1
      attr(,"contrasts")
      attr(,"contrasts")$day_of_week
                Friday Monday Saturday Sunday Thursday Tuesday Wednesday
      Friday         1      0        0      0        0       0         0
      Monday         0      1        0      0        0       0         0
      Saturday       0      0        1      0        0       0         0
      Sunday         0      0        0      1        0       0         0
      Thursday       0      0        0      0        1       0         0
      Tuesday        0      0        0      0        0       1         0
      Wednesday      0      0        0      0        0       0         1
      
      
      $data$exp_fnrow
      [1] 41
      
      $data$exp_findex
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
      
      $data$exp_fnindex
      [1] 41
      
      $data$exp_fncol
      [1] 7
      
      $data$exp_rdesign
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
      
      $data$exp_rncol
      [1] 1
      
      $data$exp_order
      [1] 1
      
      
      $priors
            variable                                             description
      1: exp_beta_sd Standard deviation of scaled pooled expectation effects
      2:    eobs_lsd      Standard deviation for expected final observations
                  distribution mean sd
      1: Zero truncated normal    0  1
      2: Zero truncated normal    0  1
      

