# enw_design can make a design matrix

    Code
      enw_design(a ~ b + c, data)
    Output
      $formula
      [1] "a ~ b + c"
      
      $design
        (Intercept) b2 b3 c
      1           1  0  0 1
      2           1  1  0 1
      3           1  0  1 2
      
      $index
      [1] 1 2 3
      

---

    Code
      enw_design(a ~ b + c, data, no_contrasts = TRUE)
    Output
      $formula
      [1] "a ~ b + c"
      
      $design
        (Intercept) b1 b2 b3 c
      1           1  1  0  0 1
      2           1  0  1  0 1
      3           1  0  0  1 2
      
      $index
      [1] 1 2 3
      

---

    Code
      enw_design(a ~ b + c, data, no_contrasts = "b")
    Output
      $formula
      [1] "a ~ b + c"
      
      $design
        (Intercept) b1 b2 b3 c
      1           1  1  0  0 1
      2           1  0  1  0 1
      3           1  0  0  1 2
      
      $index
      [1] 1 2 3
      

---

    Code
      enw_design(a ~ c, data, sparse = TRUE)
    Output
      $formula
      [1] "a ~ c"
      
      $design
        (Intercept) c
      1           1 1
      3           1 2
      
      $index
      [1] 1 1 2
      

---

    Code
      enw_design(a ~ c, data, sparse = FALSE)
    Output
      $formula
      [1] "a ~ c"
      
      $design
        (Intercept) c
      1           1 1
      2           1 1
      3           1 2
      attr(,"assign")
      [1] 0 1
      
      $index
      [1] 1 2 3
      

