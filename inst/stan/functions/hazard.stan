vector prob_to_hazard(vector p) {
  int l = num_elements(p);
  int i = l - 1;
  vector[l] h;
  vector[i] cum_p;
  cum_p[1] = 0;
  cum_p[2:i] = cumulative_sum(p[1:(i-1)]);
  h[1:i] = p[1:i] ./ (1 - cum_p);
  h[l] = 1;
  return(h);
}

vector cumulative_converse_log_hazard(vector h) {
  int l = num_elements(h);
  vector[l] h_shifted;
  vector[l] ch;
  h_shifted[1] = 0;
  if (l > 1) {
    h_shifted[2:l] = h[1:(l-1)];
  }
  ch = log1m(h_shifted);
  ch = cumulative_sum(ch);
  return(ch);
}

vector hazard_to_log_prob(vector h) {
  int l = num_elements(h);
  vector[l] p;
  p[1:l] = log(h[1:l]) + cumulative_converse_log_hazard(h[1:l]);
  return(p);
}
