---
layout: post
title: Introduction To Bayseian Inference
date: 16/01/04 
---

As you move into more complicated Bayesian problems things get more computationally inclined. For most cases, the posterior you arrive at cannot be calculated analytically. Therefore, once you have an expression for your posterior distribution, you need to sample from it to gain an understanding of how it looks. 

In this post we will look at the most simple of cases: using Bayesian methods to estimate the mean and variance of data that has been obtained from a normal distribution. 

## The Likelihood

In this simple example we know that the data is normally distributed $$x_i \sim \mathcal{N} ( \mu , \sigma ^2)$$. We can define the unknown parameters as a vector $$\boldsymbol{\theta} = (\mu, \sigma ^2)$$. The likelihood is obtained by multiplying the distribution together for each data point 

$$\mathcal{L} = \prod _i \frac{1}{\sqrt{2 \pi \sigma ^2}} \exp \left( - \frac{(x_i - \mu)^2}{2 \sigma^2} \right),$$

$$ \propto \frac{1}{\sigma ^n} \exp \left(- \frac{1}{2\sigma^2} \sum _i (x_i - \mu )^2 \right).$$

This can be simplified using the sample variance and sample mean, but this unnessacry detail in this simple case. 

## The Prior

As there are two unknown parameters, our prior distribution is a joint distribution

$$p(\mu, \sigma ^2) = p(\mu) p (\sigma )$$

(To be completed)

## The Posterior and Metropolis Sampling

Now we multiply the likelihood and the prior together to arrive at the psoterior 

$$p(\mu , \sigma ^2 | \underline{x} ) \propto \frac{1}{\sigma _{n+1}} \exp \left( - \frac{1}{2 \sigma ^2} \sum _i (x_i - \mu )^2 \right).$$

Now to make this a proper probability distribution it would need a normalaisation constant, in this simple case, the constant is trivial. Butwe will not be calculating to illustrate the case when you the constant is not trivial.

Now, how do we understand what the posterior looks like if we haven't got an exact expression for it? We sample from it, in such a way that the normalising constant isn't needed. There are a number of alogrithms that can do this, but first we weill start off with Metropolis sampling. 

This algorithm works by taking as follows:

1. Initialise $$\theta$$
2. Propose candidate parameter, $$\theta _{\text{cand}}$$
3. Calculate the ratio of posteriors $$r = \frac{p(\theta _{\text{cand}}|\bfseries{x})}{p(\theta_{old} | \bfseries{x})}$$.
4. Calculate $$\alpha = \min \left[ 1, r \right].
5. We accept $$\theta _{\text{cand}}$ with probability $\alpha$ and add it to the list of sampled points. 

The list of $$\theta$$ is the sample from the posterior. 


## Example 

To see this algorithm in practise it is easy enough to write the functions in R and generate some test data. For this we generate 100 normally distributed points with 

