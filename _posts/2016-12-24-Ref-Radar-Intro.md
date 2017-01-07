---
layout: post
title: Introducing the Referee Radar
date: 2016-12-24
---

The radar plot is a good way to analyse different metrics across a group. The football player radar made popular by [Ted Knutson](http://statsbomb.com/2016/04/understand-football-radars-for-mugs-and-muggles/) is good at comparing players and seeing how their stats stack up against one another. Here I will be taking a similar concept and using the radar plot to analyse the referee's in the professional game in England. 

First, we need to chose some metrics. Using the data from [Football-Data](http://www.football-data.co.uk/) we can download all the league matches from the last three seasons. In this data we are privy to the number of fouls, yellow cards and red cards for both the home and away team. That gives us 6 variables for each match and each referee, the perfect amount for a radar plot. 

For each referee we can calculate the average amount of fouls, yellow and red cards the gave to both the home and away team. This will allow us to detect whether a referee is particularly card happy or even has a home or away bias. In terms of practicality, we have to set a threshold for minimum number of games officiated. We remove any ref that has refereed less than 20 games over the three seasons. 

Using the [ggradar](https://github.com/ricardo-bion/ggradar) package  and tweaking some of the graphical parameters we are able to come up with the following plot. 

![RefereeRadar](/assets/RefereeRadar.png){:. center-image}

Here we are comparing four referees (at random) and how their metrics personally match against the population of all referees. Here we can see Andy D'Urso is particular for sending an away player off. Simon Hooper is quite a stickler for a foul. Nigel Miller is laid back, not giving many fouls and not giving out the yellow cards either. Chris Kavanagh is very middle of the pack, consistent across home and away for both fouls and cautions. 

The package `ggradar` requires all the variables to have a consistent range. For this I used the `rescale` function of R to remap the averages to $$[0,1]$$. Therefore the actual values of the metrics are lost in the radar plot. This is something I'll work on to include in future versions. I'll also be creating an app, either in shiny or JavaScript that will allow users to compare different referees as they see fit. 
