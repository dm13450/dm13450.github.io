---
layout: post
date: 17-04-2019
title: Speed differences between a map and a loop in Julia
tags:
 -julia
---

I'm currently writing some of my R functions in Julia to improve
performance. In R it is bad form to write a loop. Instead there are
functions like `lapply` and `vapply` that map a function across a
list. They are much faster and can be more readable than writing a
loop. So in converting the code to Julia I was replacing the `lapply`
functions to `map`. Then I would benchmark the Julia function compared
to the R function and I was seeing a performance benefit but nothing
to write home about. This was troubling as the
[benchmarks](https://julialang.org/benchmarks/) suggest that Julia is
*much* faster than R. I was doing something wrong and decided to
investigate the performance difference between a loop and map in
Julia.


```julia
using BenchmarkTools
using Statistics
```

In this simple example, we want to count the amount of elements are
assigned a cluster label. 

```julia
clusterLabels = [1,1,2,2,3,3,5]
```

The naive implementation using `map` can be written as:

```julia
function pointsPerCluster_map(clusterLabels)
    map(i-> sum(clusterLabels .== i), 1:maximum(clusterLabels))
end

pointsPerCluster(clusterLabels)

mapBM = @benchmark pointsPerCluster_map($clusterLabels)
```

    BenchmarkTools.Trial: 
      memory estimate:  21.73 KiB
      allocs estimate:  18
      --------------
      minimum time:     2.794 μs (0.00% GC)
      median time:      4.319 μs (0.00% GC)
      mean time:        6.917 μs (41.06% GC)
      maximum time:     6.618 ms (99.87% GC)
      --------------
      samples:          10000
      evals/sample:     8


So of the order of microseconds, which seems reasonable enough. When
you write the same code in R you get a median of about 6-7
microseconds. So the Julia gets about a 2x speed up, nice!

But when you unpack the map and write it in a loop the results are
almost unbelievable. 

```julia
function pointsPerCluster_loop(clusterLabels)

    maxSize = maximum(clusterLabels)
    ppc = zeros(Int64, maxSize)
    
    for i in clusterLabels
        ppc[i] += 1
    end
    ppc
end
pointsPerCluster_loop(clusterLabels)

loopBM = @benchmark pointsPerCluster_loop($clusterLabels)
```

    BenchmarkTools.Trial: 
      memory estimate:  128 bytes
      allocs estimate:  1
      --------------
      minimum time:     53.101 ns (0.00% GC)
      median time:      57.738 ns (0.00% GC)
      mean time:        91.857 ns (13.29% GC)
      maximum time:     57.285 μs (99.79% GC)
      --------------
      samples:          10000
      evals/sample:     985

By using a for loop we are now in nanosecond territory. We can
extract the median runtime of both approaches and use the `judge`
function to give a final say.

```julia
judge(median(mapBM), median(loopBM))
```

    BenchmarkTools.TrialJudgement: 
      time:   +7380.62% => regression (5.00% tolerance)
      memory: +17287.50% => regression (1.00% tolerance)

A performance improvement of 7,000% and 17,000% better memory performance. Unbelievable results! 

If you are making the leap from R to Julia like for like
translation might not be optimal. Instead start thinking about loops again
