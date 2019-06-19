
//Add back in lambda parameter

data {
  int<lower=0> N; //Num obs
  int<lower=0> P; //Num contracts
  matrix[N, P] y;
  vector[P] tau;
  
  int forward;
}

parameters {
  
  real<lower=0> lambda;
  
  real<lower=0> sigma;
  
  real<lower=0> betaSigma0;
  real<lower=0> betaSigma1;
  real<lower=0> betaSigma2;
  
  real theta00;
  real theta01;
  real theta02;
  
  real theta10;
  real theta11;
  real theta12;
  
  real beta0[N];
  real beta1[N];
  real beta2[N];
  
}

transformed parameters {
  
  vector[P] tauScale;
  
  tauScale = tau/lambda;
}


model {
  
  lambda ~ normal(0, 1.5);
  
  sigma ~ cauchy(0, 2);
  
  betaSigma0 ~ cauchy(0, 1);
  betaSigma1 ~ cauchy(0, 1);
  betaSigma2 ~ cauchy(0, 1);
  
  //theta00 ~ normal(0, 3);
  //theta01 ~ normal(0, 3);
  //theta02 ~ normal(0, 3);
  
  //theta10 ~ normal(0, 3);
  //theta11 ~ normal(0, 3);
  //theta12 ~ normal(0, 3);
  
  // State 
  
  beta0[1] ~ normal(theta00, betaSigma0);
  beta1[1] ~ normal(theta01, betaSigma1);
  beta2[1] ~ normal(theta02, betaSigma2);
  
  for(i in 2:N){
    beta0[i] ~ normal(theta00 + theta10*beta0[i-1], betaSigma0);
    beta1[i] ~ normal(theta01 + theta11*beta1[i-1], betaSigma1);
    beta2[i] ~ normal(theta02 + theta12*beta2[i-1], betaSigma2);
  }
  
  // Obs
  
  
  for(n in 1:N){
    for(p in 1:P){
      
      if(y[n,p] != -1){
      
        real mu;
      
        mu = beta0[n] + (1/tauScale[p]) * (beta1[n] + beta2[n])*(1 - exp(-tauScale[p])) - beta2[n] * exp(-tauScale[p]);
      
        y[n, p] ~ normal(mu, sigma);    
      }
    }
  }
  
}

// generated quantities {
//   
//   matrix[N+forward, P] yGen;
//   
//   real beta0Gen[N+forward];
//   real beta1Gen[N+forward];
//   real beta2Gen[N+forward];
//   
//   
//   beta0Gen[1:N] = beta0;
//   beta1Gen[1:N] = beta1;
//   beta2Gen[1:N] = beta2;
//   
//   for(i in (N+1):forward){
//     beta0Gen[i] = normal_rng(theta00 + theta10*beta0Gen[i-1], betaSigma0);
//     beta1Gen[i] = normal_rng(theta01 + theta11*beta1Gen[i-1], betaSigma1);
//     beta2Gen[i] = normal_rng(theta02 + theta12*beta2Gen[i-1], betaSigma2);
//   }
//   
//     for(n in 1:(N+forward)){
//       for(p in 1:P){
//       
//       real mu;
//       
//       mu = beta0Gen[n] + (1/tauScale[p]) * (beta1Gen[n] + beta2Gen[n])*(1 - exp(-tauScale[p])) - beta2Gen[n] * exp(-tauScale[p]);
//       
//       yGen[n, p] = normal_rng(mu, sigma);    
//     }
//   }
//   
//   
// }
// 

