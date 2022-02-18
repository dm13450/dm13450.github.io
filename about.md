---
layout: page
title: About Me
permalink: /about/
---

I have recently finished my PhD in Statistical Science where I studied
at University College London (UCL)  and a member of the Financial
Computing CDT. I also have an MRes in Computer Science and an MPhys in
Theoretical Physics from the University of Manchester. 

I have worked in the finance industry at large investment bank as part
of an equity derivatives team that engineered software to price a
large range of securities. I have also worked at a smaller firm as an
intern trading ETFs across the globe.

I'm an open source contributor with multiple projects
ongoing: [dirichletprocess](https://github.com/dm13450/dirichletprocess),
[HawkesProcesses.jl](https://github.com/dm13450/HawkesProcesses.jl),
[AlphaVantage.jl](https://github.com/ellisvalentiner/AlphaVantage.jl),
[CoinbsePro.jl](https://github.com/dm13450/CoinbasePro.jl).

I've written guest posts for [QuestDB](https://questdb.io/):

* [High frequency finance with Julia and QuestDB](https://questdb.io/blog/2021/09/17/high-frequency-finance-julia-lang)
* [A tour of high-frequency finance via the Julia language and QuestDB](https://questdb.io/tutorial/2021/11/22/high-frequency-finance-introduction-julia-lang/)

Want me to write for you or have something else interesting? Email me
at dean[dot]markwick[at]talk21[dot]com

# My Day Job Now

I'm currently an electronic trading quant working on both principal
and algo exectution. I build models, analyse data and construct
algorithms to try and get the best prices in the market with the
lowest impact. 

I'm was a quant at [BestX](https://www.bestx.co.uk/) and spent the day
researching financial markets with a focus on transaction cost
analysis (TCA).  This involved cleaning data, making graphs and trying
to come up with some (hopefully) interesting insights about the world
of FX, fixed income and equity trading.

Examples of my work can be found in the trade press:

* [To Cross or Not to Cross](https://www.profit-loss.com/to-cross-or-not-to-cross)
* [Choppy markets revive quest for RFQs magic number](https://www.fx-markets.com/trading/7550661/choppy-markets-revive-quest-for-rfqs-magic-number)
* [Volatile FX markets reveal pitfalls of RFQ](https://www.fx-markets.com/infrastructure/7539591/volatile-fx-markets-reveal-pitfalls-of-rfq)
* [Price limits in FX algos: fill your boots](https://www.fx-markets.com/tech-and-data/4336451/price-limits-in-fx-algos-fill-your-boots)
* [BestX RFQ Par Introduces a New Way to Look at Hit Ratios](https://thefullfx.com/bestx-rfq-par-introduces-a-new-way-to-look-at-hit-ratios/)
* [How Long Should TWAP algos run?](https://www.fx-markets.com/trading/7859441/how-long-should-twap-algos-run)

Some of which are behind a paywall. 

# Outside the Day Job

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
