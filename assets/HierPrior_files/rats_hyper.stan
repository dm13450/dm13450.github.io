data {
  
  int n;
  int y[n];
  int N[n];
  
}

parameters {
  
  real<lower=0, upper=1> theta[n];
  
  real<lower=0, upper=1> mu;
  real<lower=0> nu;
  
}

transformed parameters {
  
  real<lower=0> alpha0;
  real<lower=0> beta0;
  
  alpha0 = mu*nu;
  beta0 = (1-mu)*nu;
  
}

model {
  
  mu ~ uniform(0, 1);
  nu ~ inv_gamma(2,8);
  
  theta ~ beta(alpha0, beta0);
  y ~ binomial(N, theta);
  
}
