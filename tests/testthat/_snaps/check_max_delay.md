# check_max_delay produces the expected output

    Code
      check_max_delay(pobs, max_delay = 15)
    Output
         .group coverage below_coverage
      1:      1      0.8      0.2173913
      2:      2      0.8      0.1754386
      3:      3      0.8      0.2926829
      4:      4      0.8      0.1847826
      5:      5      0.8      0.3750000
      6:      6      0.8      0.2826087
      7:      7      0.8      0.1684783
      8:    all      0.8      0.2423403

# check_max_delay() works with different timesteps

    Code
      check_max_delay(weekly_pobs)
    Output
         .group coverage below_coverage
      1:      1      0.8              0
      2:    all      0.8              0

---

    Code
      check_max_delay(weekly_pobs)
    Output
         .group coverage below_coverage
      1:      1      0.8              0
      2:    all      0.8              0

---

    Code
      suppressWarnings(check_max_delay(weekly_pobs, max_delay = 1))
    Output
         .group coverage below_coverage
      1:      1      0.8      0.6363636
      2:    all      0.8      0.6363636

