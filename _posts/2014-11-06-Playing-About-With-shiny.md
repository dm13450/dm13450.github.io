---
layout: post
title: "Playing About with Shiny"
date: 14-11-06 20:00
---

As an update to my MPhys project, I am currently building a webapp using the R package shiny to display the data from the simulations that have been run. 

It has been almost too easy to use, basically just a few user interface lessons and playing around with how the app looks.

The app flow is as follows: 

1. The app grep's in the directory for the unique ID of the data file that has been chosen. 
2. It then plots the displacement, velocity and variance graph using ggplot with a custom theme. This is basically the black and white theme (theme_bw()) with removal of y label markings.
3. For a given user inputed time stamp, the app outputs the distribution of the populations. A red marker point is displayed on the previous graphs to indicate where that time occurs. 
4. The fitness and mutation landscapes are drawn below the population graph to easily show whether the cloud is in a trap etc. 

What I am most pleased about this app is the interactivity and ability to view the populations at a given interval. While not exactly the most "physicsy" bit of the project, it will help communicate the results of the data. 

Further work can be done to generally improve the aesthetic look of the app. 

A link will be added to the app once it is fully fit for public consumption! 

UPDATE: 

[Statistic Visulisation App](http://deanmarkwick.shinyapps.io/CancerStatsVis)

[Animator App](http://deanmarkwick.shinyapps.io/CancerAnimator)

Feedback appreciated!
