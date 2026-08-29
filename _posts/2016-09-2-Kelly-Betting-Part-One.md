---
layout: post
title: Kelly Criterion for Betting - Formula, Decimal Odds & Worked Example
date: 16/09/02
description: Learn the Kelly criterion formula for betting with decimal odds, including a step-by-step derivation, positive expected value test
tags: [betting]
---

In my current experiments I have been using the Kelly criterion to place theoretical bets on certain events. In the process, I found myself wanting to use the Kelly criterion for multiple simultaneous and independent events but come across a number of problems. 

* Generally, most of the easily accessible Kelly tutorials only cover betting on one event. 
* Simultaneous Kelly bets are either behind a pay-wall or just a calculator is offered which doesn't derive any of the results and show how they are obtained. 

So like any good scientist I've decided to give writing my own guide to Kelly betting. This will be the first part and go through the basic mathematics of the Kelly criterion. The second part will contain the simultaneous Kelly bet methodology. 

{% include newsletter.html %} 

## Why Kelly Bet? 

Imagine you have a model that predicts the outcome of the event with a probability $$p$$. You wish to place a bet on this outcome occurring and find that the bookmakers offer (decimal) odds $$b$$. Do you bet the whole house, or are you more conservative? What is the optimal bet size? This was answered by Kelly in 1956.

To derive the result, we wish to maximise the expected log value of the event. The expected value is 

$$\mathbb{E} \left[ \log X \right] = p \log (1+ (b-1) x) + (1-p) \log (1- x),$$

where $$x$$ is the amount that is bet. So to find the value of $$x$$ that maximises the expected bank roll we need to do some differentiation

$$\frac{\partial}{\partial x} \mathbb{E} \left[ \log X \right] = \frac{p(b-1)}{1 + (b-1)x} - \frac{1-p}{1-x}=0,$$

$$ \frac{p(b-1)}{1 + (b-1)x} = \frac{1-p}{1-x},$$

$$x = \frac{pb-1}{b-1} $$

Now if we check the Wikipedia article on the [Kelly criterion](https://en.wikipedia.org/wiki/Kelly_criterion) we find that this is the same result if we convert from decimal odds to fractional odds. Therefore, for whatever probability your model spits out and whatever the odds the bookmaker offers you, you can place a bet that has a positive expected value and thus probably a good idea. 

If the result from the Kelly formula is negative, this means that you wish to take the other side of the bet. With some betting exchanges, this is possible ("laying odds"). But due to the spread between the back and lay odds, you will not be able to immediately lay at the same odds you can back. Therefore you will need to consider the appropriate Kelly bet for laying an odd. 

## Worked Kelly Betting Example

Let's say we have a bankroll of £100, decimal odds of 2.20 and a model that thinks the outcome is 50%. Plugging all of this into the above formulae gives

$$x = \frac{0.5 \cdot 2.2 - 1}{2.2 - 1} = 0.08\dot{3},$$

so about 8% of you bank roll. Don't just trust my maths though this [Kelly Criterion calculator](https://oddlylikely.com/kelly-criterion-calculator.html) agrees. 

Now in this game there is much more than just bet sizing. Making sure your model probabilities are good is much more important. 

In the next part, I look at [Kelly betting with multiple simultaneous events]({% post_url 2016-09-29-Kelly-Betting-Part-Two %}). I will be looking at multiple bets occurring at the same time and how you can correctly split your bankroll whilst remaining in positive expected value territory.