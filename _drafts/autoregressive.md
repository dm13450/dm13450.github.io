---
layout: post
title: Bayesian Autoregressive Processes
date: 09-06-2017
---

An autoregressive process can be described by the equation 

$$y_t = c + \phi y_{t-1} + \epsilon.$$ 

The parameter $$c$$ is some baseline, $$\phi$$ if between -1 and 1, and $$\epsilon$$ is some white noise process. If we consult the Wikipedia article on such process we find that there it is fairly trivial to calculate the unknown parameter $$\phi$$ in a frequentist setting. Googling about for a Bayesian introduction didn't turn up anything particularly helpful, so here I try to plug that gap. 

For any Bayesian method we need to decompose our problem into three parts; likelihood, prior and posterior distribution. For simplicity we will be setting $$c=0$$.

For the likelihood we can see that each observation $$y_i$$ is normally distributed around $$\phi y_{i-1}$$ with variance equal to that of the white noise process $$\epsilon$$

$$p(y_i | y_1, \ldots , y_n , \sigma _\epsilon ^2) \propto \frac{1}{\sigma _\epsilon} \exp \left( \frac{-(y_i - \phi y_{i-1})^2}{2 \sigma _\epsilon ^2} \right),$$

now the likelihood is just this density multiplied across all the data. 

Now for the prior. Like any Gaussian inference problem it is a smart choice to use a Gaussian prior on $$ \phi $$ so that we get a conjugate prior. But there is a hard limit on the values of the parameter in question $$ -1 < \phi  < 1 $$, therefore we must use the truncated normal distribution.  


$$(\phi | \mu _0 , \sigma _0 ^2) = \frac{\exp \left( - \frac{ (\phi - \mu_0) ^2}{2 \sigma _0 ^2} \right)}{\sqrt{2 \pi} \sigma_0 \left(\Phi \left( \frac{b-\mu_0}{\sigma _0} \right) - \Phi \left( \frac{a-\mu_0}{\sigma _0} \right) \right) }$$ 

the values of $$a , b$$ set the limits of the truncation, so in our case they will be $$-1, 1$$ respectively. 

So lets combine both the likelihood and the prior to get our posterior distribution for $$\phi$$. Due to the conjugacy of the prior, we know that the posterior is also going to be a truncated normal distribution. 

$$p( \phi | y_1 , \ldots , y_n, \mu _0  , \sigma _0 ^2, \sigma _{\epsilon} ^2 ) = \text{Truncated-Normal} ( \mu  \sigma ^{2 } , \sigma ^2  )$$

$$\mu  = \frac{\sum _i y_i y_{i-1}}{\sigma _\epsilon ^2} + \frac{\mu _0}{ \sigma _0 ^2}$$

$$\sigma ^{2 } = \left( \frac{\sum_i y_i ^2}{\sigma _\epsilon ^2} + \frac{1}{\sigma _0^2} \right)^{-1}$$

Now these are simple enough to implement in a few lines of R and with such a simple model I'll leave that as an exercise to the reader. 


#### References

<https://arxiv.org/ftp/arxiv/papers/1611/1611.08747.pdf>

<https://en.wikipedia.org/wiki/Truncated_normal_distribution>

<https://en.wikipedia.org/wiki/Autoregressive_model>
