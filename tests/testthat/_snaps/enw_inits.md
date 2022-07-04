# enw_inits produces initial conditions with default example data

    Code
      names(inits)
    Output
       [1] "logmean_int"  "logsd_int"    "leobs_init"   "eobs_lsd"     "leobs_resids"
       [6] "sqrt_phi"     "logmean"      "logsd"        "phi"          "logmean_eff" 
      [11] "logsd_eff"    "logmean_sd"   "logsd_sd"     "rd_eff"       "rd_eff_sd"   

---

    Code
      purrr::compact(purrr::map(inits, length))
    Output
      $logmean_int
      [1] 1
      
      $logsd_int
      [1] 0
      
      $leobs_init
      [1] 1
      
      $eobs_lsd
      [1] 1
      
      $leobs_resids
      [1] 40
      
      $sqrt_phi
      [1] 1
      
      $logmean
      [1] 1
      
      $logsd
      [1] 0
      
      $phi
      [1] 1
      
      $logmean_eff
      [1] 0
      
      $logsd_eff
      [1] 0
      
      $logmean_sd
      [1] 0
      
      $logsd_sd
      [1] 0
      
      $rd_eff
      [1] 7
      
      $rd_eff_sd
      [1] 1
      

---

    Code
      purrr::compact(purrr::map(inits, dim))
    Output
      $leobs_init
      [1] 1
      
      $eobs_lsd
      [1] 1
      
      $leobs_resids
      [1] 40  1
      

# enw_inits produces initial conditions with optional parameters
           inverted

    Code
      names(inits)
    Output
       [1] "logmean_int"  "logsd_int"    "leobs_init"   "eobs_lsd"     "leobs_resids"
       [6] "sqrt_phi"     "logmean"      "logsd"        "phi"          "logmean_eff" 
      [11] "logmean_sd"   "logsd_sd"     "rd_eff"       "rd_eff_sd"   

---

    Code
      purrr::compact(purrr::map(inits, length))
    Output
      $logmean_int
      [1] 1
      
      $logsd_int
      [1] 0
      
      $leobs_init
      [1] 1
      
      $eobs_lsd
      [1] 1
      
      $leobs_resids
      [1] 40
      
      $sqrt_phi
      [1] 1
      
      $logmean
      [1] 1
      
      $logsd
      [1] 0
      
      $phi
      [1] 1
      
      $logmean_eff
      [1] 2
      
      $logmean_sd
      [1] 1
      
      $logsd_sd
      [1] 1
      
      $rd_eff
      [1] 0
      
      $rd_eff_sd
      [1] 0
      

---

    Code
      purrr::compact(purrr::map(inits, dim))
    Output
      $leobs_init
      [1] 1
      
      $eobs_lsd
      [1] 1
      
      $leobs_resids
      [1] 40  1
      

