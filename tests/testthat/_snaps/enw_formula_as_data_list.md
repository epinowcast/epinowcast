# enw_formula_as_data_list produces expected output using a simple
           formula

    Code
      enw_formula_as_data_list(enw_formula(~ 1 + (1 | cyl), mtcars), prefix = "simple")
    Output
      $simple_fdesign
        (Intercept) cyl4 cyl6 cyl8
      1           1    0    1    0
      3           1    1    0    0
      5           1    0    0    1
      
      $simple_fintercept
      [1] 1
      
      $simple_fnrow
      [1] 3
      
      $simple_findex
       [1] 1 1 2 1 3 1 3 2 2 1 1 3 3 3 3 3 3 2 2 2 2 3 3 3 3 2 2 2 3 1 3 2
      
      $simple_fnindex
      [1] 32
      
      $simple_fncol
      [1] 4
      
      $simple_rdesign
        fixed cyl
      1     0   1
      2     0   1
      3     0   1
      attr(,"assign")
      [1] 1 2
      
      $simple_rncol
      [1] 1
      

---

    Code
      enw_formula_as_data_list(enw_formula(~ 0 + (1 | cyl), mtcars), prefix = "simple")
    Output
      $simple_fdesign
        cyl4 cyl6 cyl8
      1    0    1    0
      3    1    0    0
      5    0    0    1
      
      $simple_fintercept
      [1] 0
      
      $simple_fnrow
      [1] 3
      
      $simple_findex
       [1] 1 1 2 1 3 1 3 2 2 1 1 3 3 3 3 3 3 2 2 2 2 3 3 3 3 2 2 2 3 1 3 2
      
      $simple_fnindex
      [1] 32
      
      $simple_fncol
      [1] 3
      
      $simple_rdesign
        fixed cyl
      1     0   1
      2     0   1
      3     0   1
      attr(,"assign")
      [1] 1 2
      
      $simple_rncol
      [1] 1
      

---

    Code
      enw_formula_as_data_list(enw_formula(~ 1 + (1 | cyl), mtcars), prefix = "simple",
      drop_intercept = TRUE)
    Output
      $simple_fdesign
        (Intercept) cyl4 cyl6 cyl8
      1           1    0    1    0
      3           1    1    0    0
      5           1    0    0    1
      
      $simple_fintercept
      [1] 1
      
      $simple_fnrow
      [1] 3
      
      $simple_findex
       [1] 1 1 2 1 3 1 3 2 2 1 1 3 3 3 3 3 3 2 2 2 2 3 3 3 3 2 2 2 3 1 3 2
      
      $simple_fnindex
      [1] 32
      
      $simple_fncol
      [1] 3
      
      $simple_rdesign
        fixed cyl
      1     0   1
      2     0   1
      3     0   1
      attr(,"assign")
      [1] 1 2
      
      $simple_rncol
      [1] 1
      

# enw_formula_as_data_list produces expected output using a more
           complex formula

    Code
      enw_formula_as_data_list(enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt |
        am), mtcars), prefix = "complex")
    Output
      $complex_fdesign
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
      
      $complex_fintercept
      [1] 1
      
      $complex_fnrow
      [1] 31
      
      $complex_findex
       [1]  1  2  3  4  5  6  7  8  9 10 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
      [26] 25 26 27 28 29 30 31
      
      $complex_fnindex
      [1] 32
      
      $complex_fncol
      [1] 10
      
      $complex_rdesign
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
      
      $complex_rncol
      [1] 3
      

---

    Code
      enw_formula_as_data_list(enw_formula(~ 1 + disp + (1 + gear | cyl) + (0 + wt |
        am), mtcars), prefix = "comple", drop_intercept = TRUE)
    Output
      $comple_fdesign
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
      
      $comple_fintercept
      [1] 1
      
      $comple_fnrow
      [1] 31
      
      $comple_findex
       [1]  1  2  3  4  5  6  7  8  9 10 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
      [26] 25 26 27 28 29 30 31
      
      $comple_fnindex
      [1] 32
      
      $comple_fncol
      [1] 9
      
      $comple_rdesign
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
      
      $comple_rncol
      [1] 3
      

