
data {
  int<lower=0> N;
  vector[N] y;
  vector[N] tau;
}


parameters {
  
  real beta0;
  real beta1;
  real beta2;
  real<lower=0> lambda;
  
  real<lower=0> sigma;
  
}

transformed parameters {
  
  vector[N] mu;
  vector[N] tauScale;
  
  tauScale = tau / lambda;
   
  for(i in 1:N)
    mu[i] = beta0 + (1 / tauScale[i]) * (beta1 + beta2)*(1 - exp(-tauScale[i])) - beta2 * exp(-tauScale[i]);
  
}


model {
  
  beta0 ~ normal(0, 1);
  beta1 ~ normal(0, 1);
  beta2 ~ normal(0, 1);
  
  lambda ~ normal(0, 1);
  sigma ~ normal(0, 1);
  
  y ~ normal(mu, sigma);
}

