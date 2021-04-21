---
layout: post
title: Accidentally Quadratic with DataFrames in Julia
---


```julia
using DataFrames, DataFramesMeta
using BenchmarkTools
using Plots
```

A post recently done the rounds where it looks like GTA had a bad
implementation of an algorithm that scaled in a quadratic fashion ([How I cut GTA Online loading times by 70%](https://nee.lv/2021/02/28/How-I-cut-GTA-Online-loading-times-by-70/)),
which echoed a [Bruce Dawson](https://randomascii.wordpress.com/) quote article about how it is common for
quadratically efficient processes to end up in production.
Quadratic
algorithms are fast enough when testing but once in production all of
a sudden the performance issues catch up with you and your sat with a
very inefficient process.

Well that happened to me. 

Every month I recalibrate a model using the latest data pulled from a
database. I take this raw data and generate some features, fit a model
and save down the results. One of those operations is to match all the
id's with the old data and new data to work out which trades need new features needed to be generated. 

Basically, imagine I have a dataframe, and I want to find all the rows
that match some values. In this mock example, column `B` contains the
IDs and I've some new IDs that I want to filter the dataframe for. 

I'll create a large mock dataframe as an example. 

```julia
N = 1000000
df = DataFrame(A = rand(N), B = 1:N);
```

My slow implementation use the `DataFramesMeta` package and used the broadcasted `in` function to check whether each value was in the new `ids`. This worked without a hitch last month, but then all of a sudden seemed to be incredibly slow. This was strange as I hadn't changed anything, did the usual reboot of the machine and start afresh but it was still painfully slow. 

```julia
function slow(df, ids)
  @where(df, in(ids).(:B))
end
```

After a quick profiling, I found that it was the above function that
was the bottleneck. So I refactored it to remove the `DataFramesMeta` dependancy and just used the base functions. 


```julia
function quick(df, ids)
  df[findall(in(ids), df.B), :]
end
```

Thankfully this solved the issue, was much quicker and allowed my
process to complete without a hitch. This got me thinking, how slow was my originally implementation and how much different is the new version. So onto the benchmarking. 

Using the `BenchmarkTools.jl` package I can run multiple iterations of each function across larger and larger IDs samples. 

```julia
nSamps = [1, 10, 100, 1000, 10000, 100000, 1000000]
resQuick = zeros(length(nSamps))
resSlow = zeros(length(nSamps))

for (i, n) in enumerate(nSamps)
  ids = collect(1:n) 
    
  qb = @benchmark quick($df, $ids)
  sb = @benchmark slow($df, $ids)
    
  resQuick[i] = median(qb).time
  resSlow[i] = median(sb).time
end
```

I've made sure that I compiled the original function before starting
this benchmarking too. 

```julia
plot(log.(nSamps), log.(resQuick), label="Quick", legend=:topleft, xlabel="log(Number of IDs selected)", ylab="log(Time)")
plot!(log.(nSamps), log.(resSlow), label="Slow")
```

![svg](/assets/quadratic/output_10_0.svg)

The difference in performance in remarkable. The `quick` function
is pretty much flat and just a slight increase towards the large sizes
in this log-log plot, whereas the slow version is always increasing. When we model the slow implementation performance as a power law we find that it is not quite quadratic, but more importantly, we can see that the faster method is pretty much constant, so a much scalable solution. 

```julia
using GLM
lm(@formula(LogTime ~ LogSamps),
     DataFrame(LogSamps = log.(nSamps), LogTime=log.(resSlow)))
```

    StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}
    
    LogTime ~ 1 + LogSamps
    
    Coefficients:
    ─────────────────────────────────────────────────────────────────────────
                     Coef.  Std. Error      t  Pr(>|t|)  Lower 95%  Upper 95%
    ─────────────────────────────────────────────────────────────────────────
    (Intercept)  15.1134     0.275726   54.81    <1e-07  14.4046    15.8221
    LogSamps      0.885168   0.0332117  26.65    <1e-05   0.799794   0.970541
    ─────────────────────────────────────────────────────────────────────────

When I first come across this issue I was ready to book out my week to rewriting the data functions to iron out any of the slow downs, so I was pretty happy that rewriting that one function made everything manageable. 
