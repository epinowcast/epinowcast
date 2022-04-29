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

vector cumulative_converse_hazard(vector h) {
  int l = num_elements(h);
  vector[l] ch;
  ch = log1m(h);
  ch = cumulative_sum(ch);
  ch = exp(ch);
  return(ch);
}

vector hazard_to_prob(vector h) {
  int l = num_elements(h);
  int i = l - 1;
  vector[l] p;
  p[1] = h[1]; 
  if (i) {
    vector[i] ch;
    ch = cumulative_converse_hazard(h[1:i]);
    p[2:l] = h[2:l] .* ch;
  }
  return(p);
}
