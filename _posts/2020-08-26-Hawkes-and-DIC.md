---
layout: post
title: Hawkes Processes and DIC
date: 2020-08-26
tags:
 - julia
---

My [post](http://dm13450.github.io/2018/01/18/DIC.html) on the deviance information criteria on my blog is one of the most popular ones I've ever written. So to take that theoretical concept and apply it to my new package [HawkesProcesses.jl](http://dm13450.github.io/2020/05/26/HawkesProcessesPackage.html) and show you how to construct the different functions needed to calculate the DIC. 

Firstly, a recap on the DIC,

$$
\begin{align*}
\text{DIC} & = - 2 \log p (y \mid \hat{\theta}) + 2 p_\text{DIC},  \\
p_\text{DIC} & = 2 \left( \log p(y \mid \hat{\theta} ) - \mathbb{E} \left[
\log p (y \mid \theta ) \right]  \right),
\end{align*}
$$

where these components are balancing up both the variation in the
parameters and how well the parameters fit the model to come up with a
number to assess the overall performance. Think of it as a more
intelligent likelihood calculation.

To calculate the DIC we need to construct the posterior distribution of the Hawkes process 

$$p(\theta \mid y) = p(y \mid \theta) p(\theta),$$

where $$y$$ are the event times. We've got the likelihood, $$p(y \mid \theta)$$, already exposed from the package, so just have to add on the prior distribution of the parameters. 

```julia
using HawkesProcesses
using Distributions

function posterior(events::Array{<:Number}, bg::Number, kappa::Number, kernelParam::Number, maxT::Number)
    kernel = Distributions.Exponential(1/kernelParam)
    lik::Float64 = HawkesProcesses.likelihood(events, bg, kappa, kernel, maxT)
    bgPrior = logpdf(Distributions.Gamma(0.01, 0.01), bg)
    kappaPrior = logpdf(Distributions.Gamma(0.01, 0.01), bg)
    kernPrior = logpdf(Distributions.Gamma(0.01, 0.01), kernelParam)
    lik + bgPrior + kappaPrior + kernPrior
end
```

This allows us evaluate the posterior for one sample, but what about multiple samples? Thankfully in Julia you don't get punished for using `for` loops, so we can simply iterate through all the samples to calculate the posterior values. 

```julia
function posterior(events::Array{<:Number}, bg::Array{<:Number}, kappa::Array{<:Number}, kernelParam::Array{<:Number}, maxT::Number)
    posteriorVals = Array{Float64}(undef, length(bg))
    for i in 1:length(bg)
        posteriorVals[i] = posterior(events, bg[i], kappa[i], kernelParam[i], maxT)
    end
    posteriorVals
end
```

We've got some functions, now just need some events and parameter samples to put everything into practise. Lets set up a standard Hawkes process.  

```julia
bg = 0.5
kappa = 0.5
kernel = Distributions.Exponential(1/0.5)

simEvents = HawkesProcesses.simulate(bg, kappa, kernel, 1000)

bgSamples, kappaSamples, kernelSamples = HawkesProcesses.fit(simEvents, 1000, 1000)

bgSamples = bgSamples[500:end]
kappaSamples = kappaSamples[500:end]
kernelSamples = kernelSamples[500:end]

(mean(bgSamples), mean(kappaSamples), mean(kernelSamples))
```

    (0.41608630082628845, 0.5735136278565907, 0.45633101066029247)

The final posterior samples are quite close the actually values, which is reassuring! We can now calculate the components of the DIC. 

```julia
posteriorSamples = posterior(simEvents, bgSamples, kappaSamples, kernelSamples, 1000)
posteriorMean = posterior(simEvents, mean(bgSamples), mean(kappaSamples), mean(kernelSamples), 1000)
pdic = 2*(posteriorMean - mean(posteriorSamples))
dic = -2*mean(posteriorSamples) + 2*pdic
```

    2147.693328671947

There we have it, simple to calculate and can now be used to critique the model. For example, we could fit another Hawkes model with a different kernel, calculate the DIC using the new samples and compare the values, the better fitting model will have a lower DIC value. 

# Bonus: Multithreading


```julia
using BenchmarkTools
```

The above function for calculating the posterior across the parameter samples can be easily parallelised in Julia 1.5 with some multithreading. Giving Julia access to the threads and the decorating the for loop with `Threads.@threads` will give us an easy speed boost in calculating the values. 

To let Julia know you've got threads available you'll need to prefix
your Julia startup:

```bash
> NUM_JULIA_THREADS=4 julia
```

To see if it worked then call (in Julia)

```julia
Threads.nthreads()
```

which should print out what ever number you set it too above (or the
maximum number of threads you've got on your machine). 

We can now adapt the `posterior` function to take advantage of
threads. 

```julia
function posterior_threaded(events::Array{<:Number}, bg::Array{<:Number}, kappa::Array{<:Number}, kernelParam::Array{<:Number}, maxT::Number)
    posteriorVals = Array{Float64}(undef, length(bg))
    Threads.@threads for i in 1:length(bg)
        posteriorVals[i] = posterior(events, bg[i], kappa[i], kernelParam[i], maxT)
    end
    posteriorVals
end
```

Call both functions to make sure they are compiled then we are ready to benchmark them using the same data that we calculated the DIC with. 

```julia
posterior(simEvents, bgSamples, kappaSamples, kernelSamples, 1000)
posterior_threaded(simEvents, bgSamples, kappaSamples, kernelSamples, 1000);
```

And now to benchmark:

```julia
benchmarkBasic = @benchmarkable posterior($simEvents, $bgSamples, $kappaSamples, $kernelSamples, $1000)
benchmarkThreaded = @benchmarkable posterior_threaded($simEvents, $bgSamples, $kappaSamples, $kernelSamples, $1000)

benchmarkBasic = run(benchmarkBasic, seconds=300)
benchmarkThreaded = run(benchmarkThreaded, seconds=300)
judge(median(benchmarkThreaded), median(benchmarkBasic))
```

    BenchmarkTools.TrialJudgement: 
      time:   -36.63% => improvement (5.00% tolerance)
      memory: +0.00% => minvariant (1.00% tolerance)

There we have it, using 4 threads instead of just the 1 gives us a 35% time improvement without too much hard work, which is nice. 
