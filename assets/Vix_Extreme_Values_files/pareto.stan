data {
  
  int N;
  real y[N];
  real mu;
}

parameters {
  
  real<lower=0> lambda;
  real<lower=0> alpha;
  
}

model {
  
  y ~ pareto_type_2(mu, lambda, alpha);
  
}

generated quantities {
  
  vector[N] yPred;
  
  for(i in 1:N)
    yPred[i] = pareto_type_2_rng(mu, lambda, alpha);
  
}
