---
layout: post
title: Inhomogenous Poisson Process
---

My first forray into statistics and finance begins with the simulation, fitting and checking of the inhomogenous poisson process.
THe inhomogenous poisson process is easily defined, instead of constant rate $\lambda$ as per the usual Poisson process, the rate can now varry in time. 

Simulating this is done using a method called thinning; a Poisson process is simulated with rate greater than the inhomogenous rate, with points being rejected, or "thinned" out to give the final inhomogenous process. 

Therefore the algorithm runs as follows: 
1. Generate a Poisson varaible with rate $\lambda ^*$ such that $\lambda ^* > \lambda (t) \forall t$. Increment time by this variable. 
2. Calculate the ratio $\lambda (t) / \lambda ^*$ and compare this to a unifromally distributed variable. If the ratio is greater then accept the time else reject the time and continue with step one again. 
3. The accepted times are the correct times of the inhomogenous process. 

 

