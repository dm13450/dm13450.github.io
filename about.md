---
layout: page
title: About
permalink: /about/
---

I have recently finished my PhD in Statistical Science where I studied
at University College London (UCL)  and a member of the Financial
Computing CDT. I also have an MRes in Computer Science and an MPhys in
Theoretical Physics from the University of Manchester. 

I have worked in the finance industry at large investment bank as part
of an equity derivatives team that engineered software to price a
large range of securities. I have also worked at a smaller firm as an
intern trading ETFs across the globe

# My Day Job Now

I'm a Quant at BestX and spend the day researching financial markets,
which typically involves cleaning data, making graphs and trying to
come up with some (hopefully) interesting insights about the world of FX, fixed
income and equity trading.

Examples of my work can be found in the trade press:

* [To Cross or Not to Cross](https://www.profit-loss.com/to-cross-or-not-to-cross)
* [Choppy markets revive quest for RFQs magic number](https://www.fx-markets.com/trading/7550661/choppy-markets-revive-quest-for-rfqs-magic-number)
* [Volatile FX markets reveal pitfalls of RFQ](https://www.fx-markets.com/infrastructure/7539591/volatile-fx-markets-reveal-pitfalls-of-rfq)
* [Price limits in FX algos: fill your boots](https://www.fx-markets.com/tech-and-data/4336451/price-limits-in-fx-algos-fill-your-boots)
* [BestX RFQ Par Introduces a New Way to Look at Hit Ratios](https://thefullfx.com/bestx-rfq-par-introduces-a-new-way-to-look-at-hit-ratios/)
* [How Long Should TWAP algos run?](https://www.fx-markets.com/trading/7859441/how-long-should-twap-algos-run)

All of which you probably need to be a subscriber to. 

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
