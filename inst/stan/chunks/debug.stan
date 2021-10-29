    for (i in 1:npmfs) {
      int j = 0;
      for (k in 1:dmax) {
        j += is_nan(pmfs[k, i]) ? 1 : 0;
      }
      j += phi <= 1e-3 ? 1 : 0;
      if (j) {
        print("Issue with pmf");
        print(i);
        print("Truncation  distribution estimate");
        print(pmfs[, i]);
        print("Logmean and Logsd intercept");
        print(logmean_int);
        print(logsd_int);
        print("Logmean and Logsd for pmf");
        print(logmean[i]);
        print(logsd[i]);
        print("Unique report day hazards");
        print(srdlh);
        print("Overdispersion");
        print(sqrt_phi);
      }
    }
