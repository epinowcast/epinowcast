# enw_linelist_to_incidence can return incidence

    Code
      enw_linelist_to_incidence(linelist, reference_date = "onset_date", report_date = "test_date")
    Message <simpleMessage>
      Using the maximum observed delay of 4 days to complete the incidence data.
    Output
          reference_date report_date new_confirm confirm delay
       1:           <NA>  2021-01-02           0       0     0
       2:           <NA>  2021-01-03           0       0     1
       3:           <NA>  2021-01-04           0       0     2
       4:           <NA>  2021-01-05           0       0     3
       5:     2021-01-02  2021-01-02           0       0     0
       6:     2021-01-02  2021-01-03           1       1     1
       7:     2021-01-02  2021-01-04           1       2     2
       8:     2021-01-02  2021-01-05           0       2     3
       9:     2021-01-03  2021-01-03           0       0     0
      10:     2021-01-03  2021-01-04           0       0     1
      11:     2021-01-03  2021-01-05           1       1     2
      12:     2021-01-04  2021-01-04           0       0     0
      13:     2021-01-04  2021-01-05           0       0     1
      14:     2021-01-05  2021-01-05           0       0     0

---

    Code
      enw_linelist_to_incidence(linelist_right_names, max_delay = 2)
    Message <simpleMessage>
      Using the maximum observed delay of 4 days as greater than the maximum specified to complete the incidence data.
    Output
          reference_date report_date new_confirm confirm delay
       1:           <NA>  2021-01-02           0       0     0
       2:           <NA>  2021-01-03           0       0     1
       3:           <NA>  2021-01-04           0       0     2
       4:           <NA>  2021-01-05           0       0     3
       5:     2021-01-02  2021-01-02           0       0     0
       6:     2021-01-02  2021-01-03           1       1     1
       7:     2021-01-02  2021-01-04           1       2     2
       8:     2021-01-02  2021-01-05           0       2     3
       9:     2021-01-03  2021-01-03           0       0     0
      10:     2021-01-03  2021-01-04           0       0     1
      11:     2021-01-03  2021-01-05           1       1     2
      12:     2021-01-04  2021-01-04           0       0     0
      13:     2021-01-04  2021-01-05           0       0     1
      14:     2021-01-05  2021-01-05           0       0     0

---

    Code
      enw_linelist_to_incidence(linelist_right_names, max_delay = 6)
    Output
          reference_date report_date new_confirm confirm delay
       1:           <NA>  2021-01-02           0       0     0
       2:           <NA>  2021-01-03           0       0     1
       3:           <NA>  2021-01-04           0       0     2
       4:           <NA>  2021-01-05           0       0     3
       5:     2021-01-02  2021-01-02           0       0     0
       6:     2021-01-02  2021-01-03           1       1     1
       7:     2021-01-02  2021-01-04           1       2     2
       8:     2021-01-02  2021-01-05           0       2     3
       9:     2021-01-03  2021-01-03           0       0     0
      10:     2021-01-03  2021-01-04           0       0     1
      11:     2021-01-03  2021-01-05           1       1     2
      12:     2021-01-04  2021-01-04           0       0     0
      13:     2021-01-04  2021-01-05           0       0     1
      14:     2021-01-05  2021-01-05           0       0     0

---

    Code
      enw_linelist_to_incidence(linelist_right_names, by = "age")
    Message <simpleMessage>
      Using the maximum observed delay of 4 days to complete the incidence data.
    Output
          age reference_date report_date new_confirm confirm delay
       1:  20           <NA>  2021-01-02           0       0     0
       2:  20           <NA>  2021-01-03           0       0     1
       3:  20           <NA>  2021-01-04           0       0     2
       4:  20           <NA>  2021-01-05           0       0     3
       5:  20     2021-01-02  2021-01-02           0       0     0
       6:  20     2021-01-02  2021-01-03           1       1     1
       7:  20     2021-01-02  2021-01-04           0       1     2
       8:  20     2021-01-02  2021-01-05           0       1     3
       9:  20     2021-01-03  2021-01-03           0       0     0
      10:  20     2021-01-03  2021-01-04           0       0     1
      11:  20     2021-01-03  2021-01-05           1       1     2
      12:  20     2021-01-04  2021-01-04           0       0     0
      13:  20     2021-01-04  2021-01-05           0       0     1
      14:  20     2021-01-05  2021-01-05           0       0     0
      15:  40           <NA>  2021-01-02           0       0     0
      16:  40           <NA>  2021-01-03           0       0     1
      17:  40           <NA>  2021-01-04           0       0     2
      18:  40           <NA>  2021-01-05           0       0     3
      19:  40     2021-01-02  2021-01-02           0       0     0
      20:  40     2021-01-02  2021-01-03           0       0     1
      21:  40     2021-01-02  2021-01-04           1       1     2
      22:  40     2021-01-02  2021-01-05           0       1     3
      23:  40     2021-01-03  2021-01-03           0       0     0
      24:  40     2021-01-03  2021-01-04           0       0     1
      25:  40     2021-01-03  2021-01-05           0       0     2
      26:  40     2021-01-04  2021-01-04           0       0     0
      27:  40     2021-01-04  2021-01-05           0       0     1
      28:  40     2021-01-05  2021-01-05           0       0     0
          age reference_date report_date new_confirm confirm delay

