# enw_obs() produces the expected output

    Code
      obs <- enw_obs(family = "negbin", data = pobs)
      obs$inits <- NULL
      obs
    Output
      $family
      [1] "negbin"
      
      $data
      $data$n
      [1] 45
      
      $data$t
      [1] 11
      
      $data$s
      [1] 11
      
      $data$g
      [1] 1
      
      $data$groups
      [1] 1
      
      $data$st
       [1]  1  2  3  4  5  6  7  8  9 10 11
      
      $data$ts
             1
       [1,]  1
       [2,]  2
       [3,]  3
       [4,]  4
       [5,]  5
       [6,]  6
       [7,]  7
       [8,]  8
       [9,]  9
      [10,] 10
      [11,] 11
      
      $data$sl
       [1] 5 5 5 5 5 5 5 4 3 2 1
      
      $data$csl
       [1]  5 10 15 20 25 30 35 39 42 44 45
      
      $data$lsl
       [1] 5 5 5 5 5 5 5 4 3 2 1
      
      $data$clsl
       [1]  5 10 15 20 25 30 35 39 42 44 45
      
      $data$nsl
       [1] 5 5 5 5 5 5 5 4 3 2 1
      
      $data$cnsl
       [1]  5 10 15 20 25 30 35 39 42 44 45
      
      $data$sg
       [1] 1 1 1 1 1 1 1 1 1 1 1
      
      $data$dmax
      [1] 5
      
      $data$sdmax
       [1] 5 5 5 5 5 5 5 5 5 5 5
      
      $data$csdmax
       [1]  5 10 15 20 25 30 35 40 45 50 55
      
      $data$obs
             0  1  2  3  4
       [1,] 89 48 28  8  1
       [2,] 86 44  9  3 27
       [3,] 79 36  7 16 19
       [4,] 22 24 35 18 10
       [5,] 23 32 22 10  8
       [6,] 96 85 30 18 10
       [7,] 92 86 23 18  4
       [8,] 84 87 27  4  0
       [9,] 98 61 12  0  0
      [10,] 69 43  0  0  0
      [11,] 45  0  0  0  0
      
      $data$flat_obs
       [1] 89 48 28  8  1 86 44  9  3 27 79 36  7 16 19 22 24 35 18 10 23 32 22 10  8
      [26] 96 85 30 18 10 92 86 23 18  4 84 87 27  4 98 61 12 69 43 45
      
      $data$flat_obs_lookup
       [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
      [26] 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45
      
      $data$latest_obs
              1
       [1,] 174
       [2,] 169
       [3,] 157
       [4,] 109
       [5,]  95
       [6,] 239
       [7,] 223
       [8,] 202
       [9,] 171
      [10,] 112
      [11,]  45
      
      $data$model_obs
      [1] 1
      
      
      $priors
         variable                                              description
      1: sqrt_phi One over the square root of the reporting overdispersion
                  distribution mean sd
      1: Zero truncated normal    0 0.5
      

---

    Code
      obs_missing <- enw_obs(family = "negbin", data = pobs_missing,
        observation_indicator = ".observed")
      obs_missing$inits <- NULL
      obs_missing
    Output
      $family
      [1] "negbin"
      
      $data
      $data$n
      [1] 43
      
      $data$t
      [1] 11
      
      $data$s
      [1] 11
      
      $data$g
      [1] 1
      
      $data$groups
      [1] 1
      
      $data$st
       [1]  1  2  3  4  5  6  7  8  9 10 11
      
      $data$ts
             1
       [1,]  1
       [2,]  2
       [3,]  3
       [4,]  4
       [5,]  5
       [6,]  6
       [7,]  7
       [8,]  8
       [9,]  9
      [10,] 10
      [11,] 11
      
      $data$sl
       [1] 5 5 5 5 5 5 5 4 3 2 1
      
      $data$csl
       [1]  5 10 15 20 25 30 35 39 42 44 45
      
      $data$lsl
       [1] 5 5 5 5 5 5 5 4 3 2 1
      
      $data$clsl
       [1]  5 10 15 20 25 30 35 39 42 44 45
      
      $data$nsl
       [1] 4 4 5 5 5 5 5 4 3 2 1
      
      $data$cnsl
       [1]  4  8 13 18 23 28 33 37 40 42 43
      
      $data$sg
       [1] 1 1 1 1 1 1 1 1 1 1 1
      
      $data$dmax
      [1] 5
      
      $data$sdmax
       [1] 5 5 5 5 5 5 5 5 5 5 5
      
      $data$csdmax
       [1]  5 10 15 20 25 30 35 40 45 50 55
      
      $data$obs
             0   1  2  3  4
       [1,] 89   0 76  8  1
       [2,]  0 130  9  3 27
       [3,] 79  36  7 16 19
       [4,] 22  24 35 18 10
       [5,] 23  32 22 10  8
       [6,] 96  85 30 18 10
       [7,] 92  86 23 18  4
       [8,] 84  87 27  4  0
       [9,] 98  61 12  0  0
      [10,] 69  43  0  0  0
      [11,] 45   0  0  0  0
      
      $data$flat_obs
       [1]  89  76   8   1 130   9   3  27  79  36   7  16  19  22  24  35  18  10  23
      [20]  32  22  10   8  96  85  30  18  10  92  86  23  18   4  84  87  27   4  98
      [39]  61  12  69  43  45
      
      $data$flat_obs_lookup
       [1]  1  3  4  5  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
      [26] 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45
      
      $data$latest_obs
              1
       [1,] 174
       [2,] 169
       [3,] 157
       [4,] 109
       [5,]  95
       [6,] 239
       [7,] 223
       [8,] 202
       [9,] 171
      [10,] 112
      [11,]  45
      
      $data$model_obs
      [1] 1
      
      
      $priors
         variable                                              description
      1: sqrt_phi One over the square root of the reporting overdispersion
                  distribution mean sd
      1: Zero truncated normal    0 0.5
      

