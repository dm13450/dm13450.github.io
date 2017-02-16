---
layout: post
title: Gaussian Processes In Julia
---

Gaussian processes are a way of modelling. 

In a very simple example, lets generate some data from a 2D Gaussian with zero mean and unit variance. 
If we plot this with both dimmensions on either axis we get the familiar scatter plot. 

![2D Normal Distribtuion](/assets/gp2d_simple.svg)

But if rethink the dimmensions as categories on the x-axis, we flip the point to two sperate groups. 

![2D Split](/assets/gp2d_split.svg)

Each point is connected by its corrosponding point in the next dimmension. We build up a connection between the two dimmensions based on the correlation between each dimmension. We know that the coupling between the two dimmensions in two dimmensional Gaussian is controlled by the off diagonal elements in the variance matrix, which in the above example are zero. What happens if we include some correlation?

![2D Split Correlation](/assets/gp2d_split_cor.svg)

Here the variance matrix has -0.8 on the off diagonals and 1 on the diagnoals. So each point in the first direction is negativly correlated with the second dimmesnsion. This is easily observed in this graph, the higher points in the first dimmension lead to the lower points in the next dimmension and vice-versa. 

