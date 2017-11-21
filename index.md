---
title: Home
layout: default
---
I am a newly started graduate student at University College London (UCL)  and a member of the Financial Computing CDT. I have just completed my MRes in Computer Science and now started my PhD in the Statistical Science department.  Previously, I completed an MPhys in Theoretical Physics at the University of Manchester. 

I have worked in the finance industry at large investment bank as part of an equity derivatives team that engineered software to price a large range of securities. I have also worked at a smaller firm as an intern trading emerging market products in both European and American markets.  

I also have a keen interest in sports modelling and how statistics can be used in professional sports and gambling.

Outside of academia, I enjoy a good film and a bit of a foodie. Here I am enjoying some delicious Korean BBQ.

![Delicous BBQ]({{site.url}}/assets/kbbq.JPG){: .center-image}

<h3>Recent Post:</h3>
<ul>
  {% for post in site.posts limit:1 %}
      <a href="{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
  {% endfor %}
</ul>

