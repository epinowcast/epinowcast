# convolution matrix can construct matrices of the correct form

    Code
      convolution_matrix(c(1, 2, 3), 10)
    Output
            [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
       [1,]    0    0    0    0    0    0    0    0    0     0
       [2,]    0    0    0    0    0    0    0    0    0     0
       [3,]    3    2    1    0    0    0    0    0    0     0
       [4,]    0    3    2    1    0    0    0    0    0     0
       [5,]    0    0    3    2    1    0    0    0    0     0
       [6,]    0    0    0    3    2    1    0    0    0     0
       [7,]    0    0    0    0    3    2    1    0    0     0
       [8,]    0    0    0    0    0    3    2    1    0     0
       [9,]    0    0    0    0    0    0    3    2    1     0
      [10,]    0    0    0    0    0    0    0    3    2     1

---

    Code
      convolution_matrix(c(1, 2, 3), 10, include_partial = TRUE)
    Output
            [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
       [1,]    1    0    0    0    0    0    0    0    0     0
       [2,]    2    1    0    0    0    0    0    0    0     0
       [3,]    3    2    1    0    0    0    0    0    0     0
       [4,]    0    3    2    1    0    0    0    0    0     0
       [5,]    0    0    3    2    1    0    0    0    0     0
       [6,]    0    0    0    3    2    1    0    0    0     0
       [7,]    0    0    0    0    3    2    1    0    0     0
       [8,]    0    0    0    0    0    3    2    1    0     0
       [9,]    0    0    0    0    0    0    3    2    1     0
      [10,]    0    0    0    0    0    0    0    3    2     1

---

    Code
      convolution_matrix(c(rep(list(c(1, 2, 3)), 10), list(c(4, 5, 6))), 11)
    Output
            [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11]
       [1,]    0    0    0    0    0    0    0    0    0     0     0
       [2,]    0    0    0    0    0    0    0    0    0     0     0
       [3,]    3    2    1    0    0    0    0    0    0     0     0
       [4,]    0    3    2    1    0    0    0    0    0     0     0
       [5,]    0    0    3    2    1    0    0    0    0     0     0
       [6,]    0    0    0    3    2    1    0    0    0     0     0
       [7,]    0    0    0    0    3    2    1    0    0     0     0
       [8,]    0    0    0    0    0    3    2    1    0     0     0
       [9,]    0    0    0    0    0    0    3    2    1     0     0
      [10,]    0    0    0    0    0    0    0    3    2     1     0
      [11,]    0    0    0    0    0    0    0    0    3     2     4

