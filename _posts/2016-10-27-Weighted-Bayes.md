---
layout: post
title: Thoughts on Weights in Bayesian Regression 
date: 16/10/27
---

Weighted regression is common in frequentist approaches to regression. Typically, the weights are known and can be interpreted as the amount each data point is allowed to influence the link between the variables in question. This can be written as
$$\mathbf{y} = \sum _i w_i \beta _i x_i$$ 
where $$w_i$$ is the 'weighting'. 

For example if you have some knowledge that a particular data point is less accurate than all the others. You can assign it a weight such that relative to all the other data points it has less of an impact on the final result. Weighted regression can also be a useful tool in building robust regression models - ones that are less susceptible to outliers as such outliers are given small weights.  

However, when it comes to adding in weights in a Bayesian manner for a regression problem the intuition falls apart. 

Weights in their nature imply that further information is known about the data and the model that it came from. This is a violation of Bayesian thinking as we are no longer considering the sample of data fixed but now dependent on some other function that is manifested in the weights. This weighting function in turn can only be found once we have observed all the data. 

Then by specifying a weighting function we are changing our posterior to be closer to some ideal distribution rather than just letting the data speak for itself. Essentially, changing the results to be closer to what we think the answer should be. Obviously this is not a good practise for any data analysis so we are forced to conclude that weights are not intuitive in a Bayesian way. Instead, if we think that there is a factor influencing the model we should include the factor as a parameter and assess its influence.  

Overall, the fact that weight cannot be thought of as Bayesian is cool little thought experiment and goes to show the divergence between frequentist and Bayesian approaches. 

The man himself, Andrew Gelman, discusses the issue of weighted regression and Bayesian thinking [here](https://groups.google.com/forum/#!msg/stan-dev/5pJdH72hoM8/GLW_mTeaObAJ). 
 
