vector prob_to_hazard(vector p) {
  int l = num_elements(p);
  vector[l] h;
  vector[l + 1] cum_p;
  cum_p[1] = 0;
  cum_p[2:(l+1)] = cumulative_sum(p);
  h[1:(l-1)] = p[1:(l-1)] ./ (1 - cum_p[1:(l-1)]);
  h[l] = 1;
  return(h);
}

vector hazard_to_prob(vector h) {
  int l = num_elements(h);
  vector[l] p;
  real p_sum = 0;
  for (i in 1:l) { 
    p[i] = (1 - p_sum) * h[i];
    p_sum += p[i];
  }
  return(p);
}
