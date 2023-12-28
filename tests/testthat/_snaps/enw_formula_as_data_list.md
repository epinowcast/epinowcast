# enw_formula_as_data_list produces expected output using a simple formula

    Code
      enw_formula_as_data_list(enw_formula(~ 1 + (1 | cyl), test_cars), prefix = "simple")
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
      [1] 1 1 2 1 3
      
      $simple_fnindex
      [1] 5
      
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
      enw_formula_as_data_list(enw_formula(~ 0 + (1 | cyl), test_cars), prefix = "simple")
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
      [1] 1 1 2 1 3
      
      $simple_fnindex
      [1] 5
      
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
      enw_formula_as_data_list(enw_formula(~ 1 + (1 | cyl), test_cars), prefix = "simple",
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
      [1] 1 1 2 1 3
      
      $simple_fnindex
      [1] 5
      
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
        am), test_cars), prefix = "complex")
    Output
      $complex_fdesign
        (Intercept) disp cyl4 cyl6 cyl8 cyl4:gear cyl6:gear cyl8:gear wt:am0 wt:am1
      1           1  160    0    1    0         0         4         0  0.000  2.620
      2           1  160    0    1    0         0         4         0  0.000  2.875
      3           1  108    1    0    0         4         0         0  0.000  2.320
      4           1  258    0    1    0         0         3         0  3.215  0.000
      5           1  360    0    0    1         0         0         3  3.440  0.000
      
      $complex_fintercept
      [1] 1
      
      $complex_fnrow
      [1] 5
      
      $complex_findex
      [1] 1 2 3 4 5
      
      $complex_fnindex
      [1] 5
      
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
        am), test_cars), prefix = "comple", drop_intercept = TRUE)
    Output
      $comple_fdesign
        (Intercept) disp cyl4 cyl6 cyl8 cyl4:gear cyl6:gear cyl8:gear wt:am0 wt:am1
      1           1  160    0    1    0         0         4         0  0.000  2.620
      2           1  160    0    1    0         0         4         0  0.000  2.875
      3           1  108    1    0    0         4         0         0  0.000  2.320
      4           1  258    0    1    0         0         3         0  3.215  0.000
      5           1  360    0    0    1         0         0         3  3.440  0.000
      
      $comple_fintercept
      [1] 1
      
      $comple_fnrow
      [1] 5
      
      $comple_findex
      [1] 1 2 3 4 5
      
      $comple_fnindex
      [1] 5
      
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
      

