---
layout: post
title: An Introduction to Julia and Distributions
date: 17/01/26
---

Julia is a new language on the block aimed at being a suitable mid point between the adaptability of Python and the speed of Matlab. Its a nice fall-back when my R code is just that bit too slow to really churn through some numbers. 

On of the main benefits of using R is the ease at which the 'standard' distributions are available. Want exponentially distributed random variables? Just call rexp()! Want the pdf of the gamma distribution? dgamma() is there to help you. With Julia this type of functionality is in the [Distribution module](https://github.com/JuliaStats/Distributions.jl), so takes just a little bit more of work to get the same functionality.  

In this post I will outline how the basics of the distributions package and how you can replicate some of the functionality of R.

Firstly, we need to install the Distributions package. This is done by calling `Pkg.add("Distributions")`. Now that is installed we need to load it into the namespace. Open a new Julia instance and load the package with `using Distributions`. The necessary functions are now loaded. 

Our first exercise will be to sample $$N$$ exponentially distributed variables and check that the density of the samples tends to the pdf of the exponential distribution as $$N$$ becomes larger. 
The first step in this code is to define our distribution. As the exponential distribution only requires one parameter, $$m$$, this is as simple as calling `Exponential(m)` in our code. Now we use a number of different functions on the distribution. 

We can sample from this distribution using `rand(dist, N)` where $$N$$ is the number of samples to draw. We can then overlay the pdf of the distribution by using `pdf(dist, x)`. 

Combing these commands allows us to draw a graph (using the Julia package [Gadfly](http://gadflyjl.org/stable/)) like this:

![Exponential Plot](/assets/expPlot.svg){:. center-image}

Here we can see the small sample size does not resemble the pdf but the large sample size does. So we are correctly drawing from the exponential distribution as expected. 


There are also other functions available. A great example is calculating the mean of a log-normal distribution. This distribution is defined with two parameters; $$m$$ and $$s^2$$. However, the mean of the distribution is not equal to $$m$$. Instead it is $$ \exp(m+\frac{s^2}{2})$$. The Distributions package in Julia knows this. So by simply calling `mean` on the `LogNormal()` object you can return the theoretical mean of the distribution and not have to worry about the parametrisation specifics of the distribution.

    dist = LogNormal(1,4)
    mean(dist) == exp(1 + 4^2/2)

Overall, Julia and the Distributions package offer similar functionality to R. You can easily replicate some of the functions in R with very effort in Julia. This can be a useful tool if R is not quite cutting it on the speed front.  



 

 


