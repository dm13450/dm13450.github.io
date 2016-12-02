---
layout: post
title: Notes from a Quantcast Talk 
date: 2016-12-02
---


As I sit on the train to London waiting for my model to finish fitting I realised that it had been a while since I had written a blog post. 

My PhD school holds a bimonthly seminar and this weeks guest speaker was Dr. Peter Day who is a director of engineering at [Quantcast](https://www.quantcast.com). 

Now Quantcast is a 21st century advertising agency offering real time advertisement strategy and analytic tools. The lecture was based around their use of data and how statistics and infrastructure has helped make advertising more relevant and serve better adds. 

My first `did you know` was that the adverts you see on websites are sold in real time as you load the page. So in the time it takes from clicking a link on Goole to the page appearing in your browser, the add space has been bought microseconds earlier and now serving a specific add designed for you. A remarkable engineering achievement, that in the short time it takes from clicking a link to seeing a page that an auction takes place, a winner is found and the add is served. But this is not the main product of Quantcast. 

Instead, Quantcast is more about finding out more about population behaviours and how effective that advert will be. They crunch the necessary data from the variety of cookies they collect and come up with a pricing strategy based on who might see the add. Where as one company might try to show the add to as many people as possible (the fire-hose strategy) Quantcast might drill down on certain factors and change their bidding price based on these factors. 

This problem is the standard `big data` problem. The amount of data you can collect from cookies; visited websites, location, device etc. can lead to many other inferences which gives a large amount of variables for a large amount of people. Computing this information lead to Quantcast developing their own database and data tools as the current market leaders (Hadoop and derivatives) where not performing well enough. Although they did hint that they was looking at moving to AWS to solve some of their infrastructure problems. 


Overall, it was an interesting talk about a field that I hadn't really paid that much attention too previously and I definitely learnt something new. It also made me thankful of my add blocker and slightly more paranoid. So thank to Quantcast for coming down and delivering an enjoyable seminar!
