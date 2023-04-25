# enw_incidence_to_linelist can return a linelist

    Code
      enw_incidence_to_linelist(incidence, reference_date = "onset_date",
        report_date = "test_date")
    Output
                id onset_date location age_group  test_date delay
          1:     1 2021-10-10       DE       00+ 2021-10-10     0
          2:     2 2021-10-10       DE       00+ 2021-10-10     0
          3:     3 2021-10-10       DE       00+ 2021-10-10     0
          4:     4 2021-10-10       DE       00+ 2021-10-10     0
          5:     5 2021-10-10       DE       00+ 2021-10-10     0
         ---                                                     
      18753: 18753 2021-10-20       DE       80+ 2021-10-20     6
      18754: 18754 2021-10-20       DE       80+ 2021-10-20     6
      18755: 18755 2021-10-20       DE       80+ 2021-10-20     6
      18756: 18756 2021-10-20       DE       80+ 2021-10-20     6
      18757: 18757 2021-10-20       DE       80+ 2021-10-20     6

---

    Code
      enw_incidence_to_linelist(incidence)
    Output
                id reference_date location age_group report_date delay
          1:     1     2021-10-10       DE       00+  2021-10-10     0
          2:     2     2021-10-10       DE       00+  2021-10-10     0
          3:     3     2021-10-10       DE       00+  2021-10-10     0
          4:     4     2021-10-10       DE       00+  2021-10-10     0
          5:     5     2021-10-10       DE       00+  2021-10-10     0
         ---                                                          
      18753: 18753     2021-10-20       DE       80+  2021-10-20     6
      18754: 18754     2021-10-20       DE       80+  2021-10-20     6
      18755: 18755     2021-10-20       DE       80+  2021-10-20     6
      18756: 18756     2021-10-20       DE       80+  2021-10-20     6
      18757: 18757     2021-10-20       DE       80+  2021-10-20     6

