---
layout: page
title: About Me
permalink: /about/
---

I am a quant researcher focused on execution at both the high (parent) and low (order routing) level. I also dabble in market-making and alpha signals when there is a spare 5 minutes at work. 

Previously, I was a quant at [BestX](https://www.bestx.co.uk/) and spent the day
researching financial markets with a focus on transaction cost
analysis (TCA). Hopefully I shared some interesting insights about the world
of FX, fixed income and equity trading and built some cool product features.

I have a PhD in Statistical Science from University College London
(UCL) and my thesis was [Bayesian Nonparametric Hawkes Processes with Applications](https://discovery.ucl.ac.uk/id/eprint/10109374/). I also have an MRes in Computer Science and an MPhys in Theoretical Physics from the University of Manchester. 

I run a dashboard for crypto liquidity and pre-trade analytics: <https://cryptoliquiditymetrics.com/>

I'm an open source contributor with multiple projects
ongoing: [dirichletprocess](https://github.com/dm13450/dirichletprocess),
[HawkesProcesses.jl](https://github.com/dm13450/HawkesProcesses.jl),
[AlphaVantage.jl](https://github.com/ellisvalentiner/AlphaVantage.jl),
[CoinbsePro.jl](https://github.com/dm13450/CoinbasePro.jl), [AlpacaMarkets.jl](https://github.com/dm13450/AlpacaMarkets.jl).

I've written guest posts for [QuestDB](https://questdb.io/):

* [High frequency finance with Julia and QuestDB](https://questdb.io/blog/2021/09/17/high-frequency-finance-julia-lang)
* [A tour of high-frequency finance via the Julia language and QuestDB](https://questdb.io/tutorial/2021/11/22/high-frequency-finance-introduction-julia-lang/)

Want me to write for you or have something else interesting? Email me
at dean[dot]markwick[at]talk21[dot]com

## Talks

* Execution algorithms and adaptive strategies, FX Markets Europe 2025
* Disruption or Optimisation? AI’s Role in the Future of Trading, Fixed Income Leaders Summit 2025
* From Capitol Hill to the FX desk: How US policy impacts FX execution, TradeTechFX 2025
* Mo Dealers, Mo Problems, QuantMinds 2023
* Unique Liquidity and Measuring Execution Quality, TradeTechFX 2023
* [Machine Learning Property Loans for Fun and Profit](https://www.youtube.com/watch?v=7MbjHNpycbc)
* [Simulating RFQ Trading in Julia](https://www.youtube.com/watch?v=dWgyrH6B5AY)
* [Using Hawkes Processes in Julia: Finance and More!](https://www.youtube.com/watch?v=LhnCr7R_Jf0)
* [Optimising Fantasy Football with JuMP](https://www.youtube.com/watch?v=IS-lziTqClE)
* [Building the BestX Event Risk Model using HawkesProcesses.jl](https://www.youtube.com/watch?v=3ulzb6qnOXY)
* [State of the Market](https://youtu.be/6kSPwHcO6L0)

## Articles

* [FX Execution Costs and US Policy: What Does Liberation Day Tell Us?](https://thefullfx.com/fx-execution-costs-and-us-policy-what-does-liberation-day-tell-us/)
* [What Happens When a Primary FX Venue Goes Offline?](https://thefullfx.com/what-happens-when-a-primary-fx-venue-goes-offline/) -
  3rd most read article of 2023 on Full FX. 
* [FX Markets Remained Orderly During Recent Interventions](https://thefullfx.com/fx-markets-remained-orderly-during-recent-interventions-bofa/)
* [To Cross or Not to Cross](https://www.profit-loss.com/to-cross-or-not-to-cross)
* [Choppy markets revive quest for RFQs magic number](https://www.fx-markets.com/trading/7550661/choppy-markets-revive-quest-for-rfqs-magic-number)
* [Volatile FX markets reveal pitfalls of RFQ](https://www.fx-markets.com/infrastructure/7539591/volatile-fx-markets-reveal-pitfalls-of-rfq)
* [Price limits in FX algos: fill your boots](https://www.fx-markets.com/tech-and-data/4336451/price-limits-in-fx-algos-fill-your-boots)
* [BestX RFQ Par Introduces a New Way to Look at Hit Ratios](https://thefullfx.com/bestx-rfq-par-introduces-a-new-way-to-look-at-hit-ratios/)
* [How Long Should TWAP algos run?](https://www.fx-markets.com/trading/7859441/how-long-should-twap-algos-run)

Some of which are behind a paywall. 

## Outside the Day Job

I also have a keen interest in sports modelling and how statistics can
be used in professional sports and gambling, I enjoy a good film,
watching a boxset too quickly and a bit of a foodie. Here I am enjoying some delicious Korean BBQ.

![Delicious BBQ](/assets/kbbq.JPG){: .center-image}

My blog is also aggregated on <https://www.r-bloggers.com/> and <https://www.juliabloggers.com/>.

<h3>Recent Post:</h3>
<ul>
  {% for post in site.posts limit:1 %}
      <a href="{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
  {% endfor %}
</ul>
