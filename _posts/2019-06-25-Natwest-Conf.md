---
layout: post
title: Natwest Markets Quant Conference
date: 25-06-2019
---

Natwest Markets held (in their words) the first quant conference organised by a bank on the 21st of June. Strong words and not something I can really verify. But I went along to this conference and this post is a summary of the talks that I found interesting.

<p></p>
***
Enjoy these types of posts? Then you should sign up for my newsletter. 
<div style="text-align: center;">
<iframe src="https://dm13450.substack.com/embed" width="480"
height="150" style="border:1px solid ##fdfdfd; background:#fdfdfd;"
frameborder="0" scrolling="no"></iframe>
</div>
***
<p></p>

It kicked off with Vladimir Piterbarg talking about the optimal investment problem. This deals with the dynamic allocation of money to risky and riskless assets to maximise some utility function. He outlined two different approaches, one where the volatility is modelled with different frameworks and another where a reinforcement learning approach is taken which gives a 'model free' view of the problem. Both approches lead to the same conclusion which shows how the reinforcement learning problem is able to learn the same dynamics that the volatility models provide.

The next session was the 'Innovation Roundup' from the sponsors of the conference:

* [causaLens](https://www.causalens.com/) - They provide automatic signal discovery and testing which can give an indication of much predictive power a new dataset can provide.
* [NAG](https://www.nag.co.uk/) - a high powered computing library that all the big banks use.
* Growth  Enabler - a B2B marketplace for products that startups provide.
* Intel - Advertising their FGPA solution for easier development on dedicated hardware.
* [ReInfer](https://reinfer.io/) - Provide a tool for analysing unstructured comment data, things like email Bloomberg chat etc.

My favourite talk of the day was by Standard Chartered. They introduced quantum machine learning and how it can be used in training neural networks. In a deep recess of my brain was the remnants of my quantum mechanics course from my undergrad years as a theoretical physicist, so it was interesting to see how things like superposition and Dirac matrices are being applied to computing.

The talk started by introducing the difference between classical and quantum computers - things like qubits and quantum boolean operators. Instead of 1 and 0 states, the qubit represents a superposition of both these states and then quantum weirdness can be exploited. One such example is the quantum equivalent to simulated annealing. 

In an optimisation task, you want to find the global minimum, the overal low point of the objective function and not a local minimum.

![](/assets/natwest/quantPlot1.png)

This function would be hard to optimise using classical techniques, most likely it would get stuck in one of the local minimums and report that as that as the optimal value. But, if you use a quantum algorithm, quantum tunnelling becomes an option. The qubit state would have a nonzero probability of being in the global state and tunnel through the high energy barrier. 

![](/assets/natwest/quantPlot2.png)

Quantum tunneling is a well studied phenomena, so to see it being used in terms of machine learning is quite special. Normally you would just think of it as being a mathematical perk of quantum effects, not something with practical application.

This type of quantum algorithm was applied to training neural networks to provide speed ups in the training time. The neural network is was developed with the aim of generating fake financial data. The full details of both the network and the application are in the paper [here](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3384948).

Overall, it was a nice conference that had more practical examples than your typical academic conference. It was good to see a good mix of both new research, practical considerations of implementing the research and what some new startups are doing in the space. I look forward to the next one! 
