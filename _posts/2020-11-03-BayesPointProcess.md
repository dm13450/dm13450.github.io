---
layout: post
title: Proper Bayesian Estimation of a Point Process in Julia
date: 03-11-2020
---


I know how to use Stan and I know how to use Turing. But how do
those packages perform the posterior sampling for the underlying
models. Can I write a posterior distribution down and get
`AdvancedHMC.jl` to sample it? This is exactly what I want to do with
a point process where the posterior distribution of the model is a
touch more complicated than your typical regression problems. 

This post will take you through my thought process and how you got from an idea, to a simulation of that idea, frequentist estimation of the simulated data and then a full Bayesian sampling of the problem. 

But first, these are the Julia libraries that we will be using.

```julia
using Plots
using PlotThemes
using StatsPlots
using Distributions
```

# Inhomogeneous Point Processes

A point process basically describes the time when something happens. That "thing" we can call an event and they happen between $$0$$ and some maximum time $$T$$. We describe the probability of an event happening at time $$t$$ with an intensity $$\lambda$$. Specifically we are going to use 4 different parameters for a polynomial.  

$$\lambda (t) = \exp \left( \beta _0 + \beta _1 t + \beta _2 t^2 + \beta _3 ^2 t^3 \right)$$

We take the exponent to ensure that the function is positive throughout the time period. What does this look like? We can simple plot the function from 0 to 100 with some random values for the $$\beta _i$$s. 

```julia
λ(t::Number, params::Array{<:Number}) = exp(params[1] + params[2]*(t/100) + params[3]*(t/100)^2 + params[4]*(t/100)^3)
λ(t::Array{<:Number}, params::Array{<:Number}) = map(x-> λ(x, params), t)

testParams = [3, -0.5, -0.8, -2.9]
maxT = 100

plot(λ(collect(0:maxT), testParams), label=:none)
```

![](/assets/juliapointprocess/output_7_0.svg)

This looks like something that definitely changes over time. When
$$\lambda(t)$$ is high we expect more events and likewise when it is
low there will be fewer events. 

# Simulating by Thinning

Let us simulate a point process using this intensity function. To do
so we use a procedure called thinning. This can be explained as a
three step process: 

1. Firstly simulate a *constant* Poisson process with intensity $$\lambda ^\star$$ which is greater than $$\lambda (t)$$ for all $$t$$. This gives the un-thinned events, $$t^*_i$$. 
2. For each un-thinned event calculate the probability it will become one of the final events as $$\frac{\lambda (t^*_i)}{\lambda ^\star}$$.
3. Sample from these probabilities to get the final events. 

Simple enough to code up in a few lines of Julia.  


```julia
lambdaMax = maximum(λ(collect(0:0.1:100), testParams)) * 1.1
rawEvents = rand(Poisson(lambdaMax * maxT), 1)[1]
unthinnedEvents = sort(rand(Uniform(0, maxT), rawEvents))
acceptProb = λ(unthinnedEvents, testParams) / lambdaMax
events = unthinnedEvents[rand(length(unthinnedEvents)) .< acceptProb];
histogram(events,label=:none)
```

![svg](/assets/juliapointprocess/output_12_0.svg)

A steady decreasing amount of events following the intensity function from above. 

# Maximum Likelihood Estimation

The log likelihood of a point process can be written as:

$$\mathcal{L} = \Sigma _{i = 1} ^N \log \lambda (t_i) - \int _0 ^T \lambda (t) \mathrm{d} t$$

Again, easy to write the code for this. The only technical difference is I am using the `QuadGK.jl` package to numerically integrate the function rather than doing the maths myself. This keeps it simple and also flexible if we decided to change the intensity function later. 


```julia
function likelihood(params, rate, events, maxT)
    sum(log.(rate(events, params))) - quadgk(t-> rate(t, params), 0, maxT)[1]
end
```

For maximum likelihood estimation we simply pass this function through to an optimiser and find the maximum point. As `optimize` actually finds minimum points we have to invert the function.

```julia
using Optim
using QuadGK
opt = optimize(x-> -1*likelihood(x, λ, events, maxT), rand(4))
plot(λ(collect(0:maxT), testParams), label="True")
plot!(λ(collect(0:maxT), Optim.minimizer(opt)), label = "MLE")
```

![svg](/assets/juliapointprocess/output_21_0.svg)

Not a bad result! Our estimated intensity function is pretty close to
the actual function. So now we know that we can both simulate from a inhomogeneous point
process and that our likelihood can infer the correct parameters. 

# Bayesian Inference

Now for the good stuff. All of the above is needed for the Bayesian inference procedure. If you can't get the maximum likelihood working for a relatively simple problem like above, adding in the complications of Bayesian inference will just get you knotted up without any results. So with the good results from above let us proceed to the Bayes methods. With the `AdvancedHMC.jl` package I can use all the fancy MCMC algos and upgrade from the basic Metropolis Hastings sampling. 

I've shamelessly copied the README from `AdvancedHMC.jl` and changed the bits needed for this problem. 

```julia
using AdvancedHMC, ForwardDiff

D = 4; initial_params = rand(D)

n_samples, n_adapts = 5000, 2000

target(x) = likelihood(x, λ, events, maxT) + sum(logpdf.(Normal(0, 5), x))

metric = DiagEuclideanMetric(D)
hamiltonian = Hamiltonian(metric, target, ForwardDiff)

initial_ϵ = find_good_stepsize(hamiltonian, initial_params)
integrator = Leapfrog(initial_ϵ)
proposal = NUTS{MultinomialTS, GeneralisedNoUTurn}(integrator)
adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(0.8, integrator))

samples1, stats1 = sample(hamiltonian, proposal, initial_params, 
                        n_samples, adaptor, n_adapts; progress=true);
samples2, stats2 = sample(hamiltonian, proposal, initial_params, 
                        n_samples, adaptor, n_adapts; progress=true);
```

Samples done, now to manipulate the results to get the parameter
estimation. 

```julia
a11 = map(x -> x[1], samples1)
a12 = map(x -> x[1], samples2)
a21 = map(x -> x[2], samples1)
a22 = map(x -> x[2], samples2)
a31 = map(x -> x[3], samples1)
a32 = map(x -> x[3], samples2)
a41 = map(x -> x[4], samples1)
a42 = map(x -> x[4], samples2)

bayesEst = map( x -> mean(x[1000:end]), [a11, a21, a31, a41])
bayesLower = map( x -> quantile(x[1000:end], 0.25), [a11, a21, a31, a41])
bayesUpper = map( x -> quantile(x[1000:end], 0.75), [a11, a21, a31, a41])
```

```julia
density(a21, label="Chain 1")
density!(a22, label="Chain 2")
vline!([testParams[2]], label="True")
plot!(-4:4, pdf.(Normal(0, 5), -4:4), label="Prior")
```

![svg](/assets/juliapointprocess/output_28_0.svg)

The chains have sampled correctly and are centered around the correct
value. Plus it's suitably different from the prior, which shows it has
updated with the information from the events. 

```julia
plot(a11, label="Chain 1")
plot!(a12, label="Chain 2")
```

![svg](/assets/juliapointprocess/output_29_0.svg)

Looking at the convergence of the chains is also positive. So for this
simple model, everything looks like it has worked correctly. 

```julia
plot(λ(collect(0:maxT), testParams), label="True")
plot!(λ(collect(0:maxT), Optim.minimizer(opt)), label = "MLE")
plot!(λ(collect(0:maxT), bayesEst), label = "Bayes")
```

![svg](/assets/juliapointprocess/output_30_0.svg)


Again, the bayesian estimate of the function isn't too far from the true intensity. Success!

# Conclusion

So what have I learnt after writing all this: 
* `AdvancedHMC.jl` is easy to use and despite all the scary terms and settings you can get away with the defaults. 

What I have hopefully taught you after reading this: 

* Point process simulation through thinning. 
* What the likelihood of a point process looks like. 
* Maximum likelihood using `Optim.jl` 
* How to use `AdvancedHMC.jl` for that point process likelihood to get the posterior distribution. 
