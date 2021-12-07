---
layout: post
title: Turing.jl Performance Updates
date: 20-09-2019
tags:
 -julia
---

One of the creators of the Turing.jl package messaged me a few weeks ago to ask me to rerun my benchmarking tests of the different samplers because they had made some performance improvements. So here I am, being the independent third party to verify these improvements. I hope I can see them and I don't want to ruin anyones Friday night!

In my last blog post ([here](https://dm13450.github.io/2019/04/10/Turing-Sampling-Speed.html)) I didn't actually record what version of Julia or Turing I was using which is a bit annoying. I'm 99% certain I was using Julia 1.1 and looking at the  Turing releases I imagine it might have been version  0.6.14. My current version of Turing is 0.6.17, but I think I might have updated it at some point after the original blog post so a bit tricky to tell what was used. My plan for this rerun is to update Julia to 1.2 and Turing to the latest version in the package manager, rerun the notebook and post the results. 

So after doing exactly that here are the results. 

![svg](/assets/turing-redo.svg)

A stunning improvement and quite frankly I'm seriously impressed. Looking at my previous post, NUTS was the slowest with almost 5 seconds for 1000 iterations. Using the latest version of Turing and you get an average of about 0.4 seconds for 1000 iterations so a 10x speed up. Not bad at all! So well done to the Turing team, really knocked it out the park with these latest updates. 

In conclusion it looks like  Julia 1.2 and Turing 0.6.23 have resulted in a massive performance update for the package and I'm looking forward to where it goes next. 


