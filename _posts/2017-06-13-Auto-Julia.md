---
layout: post
title: Julia Code for Sampling an AR(1) model
date: 12/06/2017
---

In my previous blog post I outlined the basic AR(1) model and the necessary maths needed to infer the unknown parameter $$\phi$$. In this post I will outline some basic Julia code to build a MCMC sampler for such a model to infer the unknown parameter $$\phi$$. 

Firstly, we need to simulate some data. From the previous post we know that the data $$y$$ comes simply from the previous value, plus some fixed noise. In Julia this is simply writing a for loop and using the Distributions package to sample some white noise. 

{% highlight julia %}
function simulate_ar(phi, n)

	 dist = Normal()

	 y = [0.0 for i = 1:n]

	 noise = rand(dist, n)

	 for i in 1:(n-1)

	     y[i+1] = phi*y[i] + noise[i] 
	 end

	 return y
end
{% endhighlight %}
	
For 1000 data points with $$\phi=0.5$$ such a process looks like: 

![AR1 Process Plot](/assets/y_plot.svg){: .center-image }

Pretty much looks like a random walk around 0 as expected. 

Now to compute the statistics for the posterior distribution we need
the sum of squares and the lagged sum of squares ( [see here] (https://dm13450.github.io/2017/06/09/Bayesian-Auto-Process.html)). Then using the Distributions package again we can sample from a truncated normal distribution. We have used a prior distribution of a truncated normal distribution with 0 mean and a standard deviation of 5. 

{% highlight julia %}
function posterior_ar(n, y)
	 n = length(y)
	 ss = sum(y .* y) + 1/25 
	 ss_lagged = sum(y .* vcat(y[2:n],0))
	 
	 dist = Truncated(Normal(ss_lagged/ss, sqrt(1/ss)), -1, 1)
	 smps = rand(dist, n)

	 return smps
end
{% endhighlight %}


![Phi Density Plot](/assets/phi_density.svg){: .center-image }

So we can see that the posterior distribution for $$\phi$$ is close to the true value of 0.5, so it looks like our algorithm is working. 

Although its just a toy model in these posts I have shown how to calculate the posterior for an autoregressive process and how to draw from such a distribution using Julia. Next stop, include more parameters and see how flexible autoregressive models can be. 
