---
layout: post
title: Thoughts on Weights in Bayesian Regression 
date: 16/09/28
---

Weighted regression is common in frequentist approaches to regression. Typically, the weights are known and can be interpreted as the amount each datapoint is allowed to influence the link between the variables in question. For example if you have some knowlege that a particular datapoint is less accurate than all the others you might assign it a weight such that relative to all the other data point it has less of an impact on the final result. Weighted regression can also be a useful tool in building robust regression models - ones that are less suseceptable to outliers. However, when it comes to adding in weights in a Bayesian regression problem the intuition falls apart. 

Weights in their nature imply that further information is known about the data and the model that it came from. This is a violation of Bayesian thinking as we are no longer considering the sample of data fixed but now dependent on some other function that is manifested in the weights. This weighting function in turn can only be found once we have observed all the data. 

The man himself, Andrew Gelman, discusses the issue of weighted regression and Bayesian thinking here https://groups.google.com/forum/#!msg/stan-dev/5pJdH72hoM8/GLW_mTeaObAJ 
 
