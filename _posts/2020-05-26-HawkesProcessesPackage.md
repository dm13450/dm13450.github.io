---
layout: post
title: "HawkesProcesses.jl: An Introduction"
date: 2020-05-26
tags:
  -julia
---

```julia
using HawkesProcesses
using Distributions
using Plots
```

`HawkesProcesses` is a Julia package that provides a number of functions to model events using a Hawkes process. This vignette demonstrates how you can use the package. For details on the maths involved in the functions see the pdf document [here](https://dm13450.github.io/assets/hawkesprocesses.pdf).

## Intensity of a Hawkes Process


```julia
bg = 0.5
kappa = 0.5
kernel(x) = pdf.(Distributions.Exponential(1/0.5), x)
maxT = 100;
```

We calculate the intensity of a Hawkes process with default parameters all equal to 0.5 between 0 and 10 with two events at t = 3 and 6. 


```julia
ts = 0:0.1:10
testEvents = [3, 6]
intensity = HawkesProcesses.intensity(collect(ts), testEvents, bg, kappa, kernel);
```


```julia
plot(ts, intensity, xlabel = "Time", ylabel = "Intensity", label="")
```




![svg](/assets/hawkesvignette/output_7_0.svg)



As expected two spikes of intensity when the events occur.

## Simulation


```julia
simevents = HawkesProcesses.simulate(bg, kappa, kernel, maxT);
```

We now simulate events with default parameters from t=0 to t=100. 


```julia
ts = collect(0:0.1:maxT)
intensity = HawkesProcesses.intensity(ts, simevents, bg, kappa, kernel)
plot(ts, intensity, xlabel="Time", ylabel = "Intensity", label="")
plot!(simevents, repeat([mean(intensity)], length(simevents)), seriestype=:scatter, label="Events")
```




![svg](/assets/hawkesvignette/output_12_0.svg)



Again, spikes of events occurring followed by slightly quieter periods which shows the clustering effect of the Hawkes process. 

## Bayesian Estimation using a Latent Variable

This package provides an enhanced method of MCMC sampling of the Hawkes process parameters. By exploiting a latent variable (mathematical details can be found [here]()) we are able to more efficiently sample from the posterior distribution than by doing direct Gibbs sampling using the likelihood and prior. 


```julia
bg = 0.5
kappa = 0.5
kernel(x) = pdf.(Distributions.Exponential(1/0.5), x)
maxT = 1000
simevents = HawkesProcesses.simulate(bg, kappa, kernel, maxT);
```


```julia
bgSamps, kappaSamps, kernSamps = HawkesProcesses.fit(simevents, maxT, 1000);
```


```julia
plot(histogram(bgSamps, label="Background", colour=:darkred), 
    histogram(kappaSamps, label="Kappa", colour=:darkblue), 
    histogram(kernSamps, label="Kernel", colour=:darkgreen), layout = (1, 3))
```




![svg](/assets/hawkesvignette/output_18_0.svg)



The histograms of the parameter samples are distributed around the true values as expected which shows our method is working. We run another chain to check convergence. 


```julia
bgSamps2, kappaSamps2, kernSamps2 = HawkesProcesses.fit(simevents, maxT, 1000);

bgplot = plot(bgSamps, label="Chain 1", title="Background")
bgplot = plot!(bgplot, bgSamps2, label="Chain 2")

kappaplot = plot(kappaSamps, label="Chain 1", title="Kappa")
kappaplot = plot!(kappaSamps2, label="Chain 2")

kernplot = plot(kernSamps, label="Chain 1", title="Kernel")
kernplot = plot!(kernSamps2, label="Chain 2")

plot(bgplot, kappaplot, kernplot, layout = (1, 3))
```




![svg](/assets/hawkesvignette/output_20_0.svg)



A basic visual inspection shows that the chains are exploring the parameter space nicely. 

## Likelihood

The likelihood of a Hawkes process can be used in a number of ways. It can assess the goodness of fit of a particular parameter set or it can be used to estimate parameters aswell. 


```julia
bg = 0.5
kappa = 0.5
kernelDist =  Distributions.Exponential(1/0.5)
kernel_f(x) = pdf.(kernelDist, x)
maxT = 1000
simevents = HawkesProcesses.simulate(bg, kappa, kernel_f, maxT);
```


```julia
trueLikelihood = HawkesProcesses.likelihood(simevents, bg, kappa, kernelDist, maxT)
```




    -963.4283337185043




```julia
bgArray = collect(0.1:0.05:1)
bgLikelihood = map(x -> HawkesProcesses.likelihood(simevents, x, kappa, kernelDist, maxT), bgArray)
bgPlot = plot(bgArray, bgLikelihood, xlabel="Parameter Values", ylabel = "Likelihood", label="Background", colour=:darkred);
```


```julia
kappaArray = collect(0.1:0.05:1)
kappaLikelihood = map(x -> HawkesProcesses.likelihood(simevents, bg, x, kernelDist, maxT), kappaArray)
kappaPlot = plot(kappaArray, kappaLikelihood, xlabel="Parameter Values", ylabel = "Likelihood", label="Kappa", colour=:darkblue);
```


```julia
kernArray = collect(0.01:0.01:1)
kernLikelihood = map(x -> HawkesProcesses.likelihood(simevents, bg, kappa, Distributions.Exponential(1/x), maxT), kernArray)
kernPlot = plot(kernArray, kernLikelihood, xlabel="Parameter Values", ylabel = "Likelihood", label="Kernel", colour=:darkgreen);
```


```julia
plot(bgPlot, kappaPlot, kernPlot, layout=(3,1))
```

![svg](/assets/hawkesvignette/output_29_0.svg)

Here we demonstrate the shape of the likelihood for the different values in parameters. As expected the likelihood reaches its maximum value at the true values. 

## Maximum Likelihood Estimation

Using the likelihood function from HawkesProcesses we can use optimisation to find the parameters that produce the maximum values of the likelihood. 


```julia
using Optim
function exp_mle(params, events, maxT)
    if any(params .< 0)
        return Inf
    end
    
    bg = params[1]
    kappa = params[2]
    kernParam = params[3]
    
    -1*HawkesProcesses.likelihood(events, bg, kappa, Distributions.Exponential(kernParam), maxT)
end
```

```julia
opt = optimize(x->exp_mle(x, simEvents, maxT), rand(3)*10)
Optim.minimizer(opt)
```
    3-element Array{Float64,1}:
     0.5155810722101667 
     0.47205389686884425
     2.8440961890338596 

The parameters are close to the true values but this isn't always the case. In practise the likelihood function of a Hawkes process is very flat around the maximum and can prove difficult to optimise over. 