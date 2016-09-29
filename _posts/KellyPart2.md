---
layout: post
date: 16/09/07
title: Kelly Betting - Part Two
---

In my previous post I have outlined the basics of Kelly betting. Now I will be looking at the optimal bet size for placing bets on multiple simultaneous events that are independent of one another. We will be using R to numerically solve the resulting equations and hopefully learn some quirks of function optimisation in R.  

Again this requires maximising the expected value of the log of the bankroll

$$\mathbb{E} \left[ \log (x)\right] = \sum _i p_i \log (1+ (b_i-1) x_i) + (1-p_i) \log (1- x_i)$$,

where each event $$i$$ has a probability $$p_i$$ of occurring, decimal odds of $$b_i$$ and $$x_i$$ is the size of the bet. 

Now that we have multiple bets, the total amount staked must be less than 1 

$$\sum _i x_i \leq 1$$,

however in practise this is usually capped at some lesser value which is then referred to as fractional Kelly betting. 

Now solving this sum of bets is possible analytically but it is not the easiest nor instructive. Instead, lets turn to maximising the expectation numerically. For this, we turn to R and its optim function.

Firstly, let us define our expectation function


    expectedBankRoll <- function(x, p, b){
      expBankRoll = p*log(1+(b-1)*x) + (1-p)*log(1-x)
      return(sum(expBankRoll))
    }
    
due to the vectorised nature of R functions both $$p$$ and $$b$$ can be lists and there is no need to loop through each value. 

To find the $$x$$ values for given $$p$$ and $$b$$ values that maximise the bank roll we can use the ```optim``` function. [Optim](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/optim.html) is R's numerical optimisation routine that can implement a number of different algorithms for finding the minimum of a given function. Therefore, for it to be any use to us, we need to multiply our function by -1 such that the maximum now becomes the minimum. 

    p = c(0.7, 0.8)
    b = c(1.3, 1.2)
    optim(c(0.5, 0.5), function(x) (-1)*expectedBankRoll(x, p, b))

This code will find the two $$x$$ values that maximise the expected bank roll and therefore consider the output as the Kelly bet for two simultaneous results. 

But there is a few caveats. Firstly we need to account for the fact that the sum of our bets must be less than 1. Secondly, the bets must also be positive numbers. To account for these restrictions we must modify our expected bank roll function 

    expectedBankRoll <- function(x, p, b){
      if(sum(x) > 1 | any(x<0)){return(-99999)}
      expBankRoll = p*log(1+(b-1)*x) + (1-p)*log(1-x)
      return(sum(expBankRoll))
    }

The returning of a large value if any of the restrictions of $$x$$ are broken ensures that we get reasonable results from optim. This also has the added benefit of setting $$x_i$$ to zero for any event that does not have a positive expected value based on the odds offered. Therefore, to arrive at the optimal bet sizes for a collection of events, just pass in the probabilities and the odds.

In the next part I will be looking at bet hedging and how this can effect the stake size and overall profitability of a betting system. 
