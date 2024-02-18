---
layout: post
title: Optimising FPL with Julia and JuMP
date: 2022-08-05
tags:
- julia
---


One of my talks for JuliaCon 2022 explored the use of JuMP to optimise a Fantasy Premier League (FPL) team. You can watch my presentation here: [Optimising Fantasy Football with JuMP](https://www.youtube.com/watch?v=IS-lziTqClE&list=PLIojEI1c4KwPW08-qXN2tL1ra1HV6XyJu&index=2) and this blog post is an accompaniment and extension to that talk. I've used [FPL Review](https://fplreview.com/) free expected points model and their tools to generate the team images, go check them out. 

<p></p>
***
Enjoy these types of posts? Then you should sign up for my newsletter. 
<div style="text-align: center;">
<iframe src="https://dm13450.substack.com/embed" width="480"
height="150" style="border:1px solid ##fdfdfd; background:#fdfdfd;"
frameborder="0" scrolling="no"></iframe>
</div>
***
<p></p>

Now last season was my first time playing this game. I started with an analytical approach but didn't write the team optimising routines until later in the season, by which time it was too late to make too much of a difference. I finished at 353k, so not too bad for a first attempt, but quite a way off from that 100k "good player" milestone. I won't be starting a YouTube channel for FPL anytime soon.

Still, a new season awaits, and with more knowledge, a hand-crafted optimiser, and some expected points, let's see if I can do any better. 

## A Quick Overview of FPL

FPL is a fantasy football game where you need to choose a team of 15 players that consists of: 

* 2 goalkeepers
* 5 defenders
* 5 midfielders
* 3 forwards

Then from these 15 players, you chose a team of 11 each week that must conform to: 

* 1 goalkeeper
* Between 3 and 5 defenders
* Between 2 and 5 midfielders
* Between 1 and 3 forwards

You have a budget of £100 million and you can have at most 3 players from a given team. So no more than 3 Liverpool players etc. 

You then score points based on how many goals a player scores, how many assists, and other ways. Each week you can transfer one player out of your squad of 15 for a new player. 

That's the long and short of it, you want to score the most points each week and be forwarding looking to ensure you are set for getting the most points.

## A Quick Overview of JuMP

[JuMP](https://jump.dev/JuMP.jl/stable/) is an optimisation library for Julia. You write out your problem in the JuMP language, supply an optimiser and let it work its magic. For a detailed explanation of how you can solve the FPL problem in JuMP I recommend you watch my JuliaCon talk here: 

But in short, we want to maximise the number of points based on the above constraints while sticking to the overall budget. The code is easy to interpret and there is just the odd bit of code massage to make it do what we want. 

All my optimising functions are in the below file which is will be hosted on Github shortly so you can keep up to date with my tweaks. 

```julia
include("team_optim_functions.jl")
```


## FPL Review Expected Points

To start, we need some indication of each player's ability. This is an expected points model and will take into account the player's position, form, and overall ability to score FPL points. Rather than build my expected models I'm going to be using FPL Reviews numbers. They are a very popular site for this type of data and the amount of time I would have to invest to come up with a better model would be not worth the effort. Plus, I feel that the amount of variance in FPL points means that it's a tough job anyway, it's better to crowdsource the effort and use other results. 

That being said, once you've set your team, there might be some edge in interpreting the statistics. But that's a problem for another day. 

FPL Review is nice enough to make their free model as a downloadable CSV so you can head there, download the file and pull it into Julia. 

```julia
df = CSV.read("fplreview_1658563959", DataFrame)
```

To verify the numbers they have produced we can look and the total number of points each team is expected to score over the 5 game weeks they provide. 


```julia
sort(@combine(groupby(df, :Team), 
       :TotalPoints_1 = sum(cols(Symbol("1_Pts"))),
       :TotalPoints_2 = sum(cols(Symbol("2_Pts"))),
       :TotalPoints_3 = sum(cols(Symbol("3_Pts"))),
       :TotalPoints_4 = sum(cols(Symbol("4_Pts"))),
       :TotalPoints_5 = sum(cols(Symbol("5_Pts"))) 
        ), :TotalPoints_5, rev=true)
```

<div class="data-frame"><p>20 rows × 3 columns</p><table class="data-frame"><thead><tr><th></th><th>Team</th><th>TotalPoints_1_2</th><th>TotalPointsAll</th></tr><tr><th></th><th title="String15">String15</th><th title="Float64">Float64</th><th title="Float64">Float64</th></tr></thead><tbody><tr><th>1</th><td>Man City</td><td>117.63</td><td>296.58</td></tr><tr><th>2</th><td>Liverpool</td><td>115.52</td><td>284.36</td></tr><tr><th>3</th><td>Chelsea</td><td>94.37</td><td>243.1</td></tr><tr><th>4</th><td>Arsenal</td><td>90.38</td><td>241.0</td></tr><tr><th>5</th><td>Spurs</td><td>90.85</td><td>237.81</td></tr><tr><th>6</th><td>Man Utd</td><td>92.77</td><td>215.76</td></tr><tr><th>7</th><td>Brighton</td><td>79.35</td><td>205.93</td></tr><tr><th>8</th><td>Wolves</td><td>87.02</td><td>203.23</td></tr><tr><th>9</th><td>Aston Villa</td><td>88.65</td><td>202.32</td></tr><tr><th>10</th><td>Brentford</td><td>74.75</td><td>199.51</td></tr><tr><th>11</th><td>Leicester</td><td>77.99</td><td>197.34</td></tr><tr><th>12</th><td>West Ham</td><td>76.19</td><td>197.33</td></tr><tr><th>13</th><td>Leeds</td><td>80.61</td><td>194.82</td></tr><tr><th>14</th><td>Newcastle</td><td>89.81</td><td>190.98</td></tr><tr><th>15</th><td>Everton</td><td>68.46</td><td>189.73</td></tr><tr><th>16</th><td>Crystal Palace</td><td>64.95</td><td>180.66</td></tr><tr><th>17</th><td>Southampton</td><td>72.23</td><td>176.97</td></tr><tr><th>18</th><td>Fulham</td><td>63.02</td><td>172.57</td></tr><tr><th>19</th><td>Bournemouth</td><td>62.31</td><td>161.9</td></tr><tr><th>20</th><td>Nott&apos;m Forest</td><td>69.65</td><td>161.05</td></tr></tbody></table></div>



So looks pretty sensible, Man City and Liverpool up the top, the newly promoted teams at the bottom. So looks like the FPL Review knows what they are doing. 

With that done, let's move on to optimising. I have to take the dataframe and prepare the inputs for my optimising functions. 


```julia
expPoints1 = df[!, "1_Pts"]
expPoints2 = df[!, "2_Pts"]
expPoints3 = df[!, "3_Pts"]
expPoints4 = df[!, "4_Pts"]
expPoints5 = df[!, "5_Pts"]

cost = df.BV*10
position = df.Pos
team = df.Team

#currentSquad = rawData.Squad

posInt = recode(position, "M" => 3, "G" => 1, "F" => 4, "D" => 2)
df[!, "PosInt"] = posInt
df[!, "TotalExpPoints"] = expPoints1 + expPoints2 + expPoints3 + expPoints4 + expPoints5
teamDict = Dict(zip(sort(unique(team)), 1:20))
teamInt = get.([teamDict], team, NaN);
```

I have to multiply the buy values (`BV`) by 10 to get the values in the same units as my optimising code. 

## The Set and Forget Team

In this scenario, we add up all the expected points for the five game weeks and run the optimiser to select the highest scoring team over the 5 weeks. No transfers and we set the bench-weighting to 0.5. 


```julia
# Best set and forget
modelF, resF = squad_selector(expPoints1 + expPoints2 + expPoints3 + expPoints4 + expPoints5, 
    cost, posInt, teamInt, 0.5, false)
```

![Set and forget](/assets/fpl_setforget.png "Set and forget"){: .center-image}

It's a pretty strong-looking team. Big at the back with all the premium defenders which is a slight danger as one conceded goal by either Liverpool or Man City could spell disaster for your rank. Plus no Salah is a bold move. 

To add some human input, we can look at the other £5 million defenders to assess who to swap Walker with. 

```julia
first(sort(@subset(df[!, [:Name, :Team, :Pos, :BV, :TotalExpPoints]], :BV .<= 5.0, :Pos .== "D", :Team .!= "Arsenal"), 
     :TotalExpPoints, rev=true), 5)
```




<div class="data-frame"><table class="data-frame"><thead><tr><th></th><th>Name</th><th>Team</th><th>Pos</th><th>BV</th><th>TotalExpPoints</th></tr><tr><th></th><th title="String31">String31</th><th title="String15">String15</th><th title="String1">String1</th><th title="Float64">Float64</th><th title="Float64">Float64</th></tr></thead><tbody><tr><th>1</th><td>Walker</td><td>Man City</td><td>D</td><td>5.0</td><td>16.53</td></tr><tr><th>2</th><td>Digne</td><td>Aston Villa</td><td>D</td><td>5.0</td><td>15.25</td></tr><tr><th>3</th><td>Doherty</td><td>Spurs</td><td>D</td><td>5.0</td><td>15.18</td></tr><tr><th>4</th><td>Romero</td><td>Spurs</td><td>D</td><td>5.0</td><td>15.03</td></tr><tr><th>5</th><td>Dunk</td><td>Brighton</td><td>D</td><td>4.5</td><td>14.74</td></tr></tbody></table></div>



So Doherty or Digne seems like a decent shout. This just goes to show though that you can't blindly follow the optimiser and you can add some alpha by tweaking as you see fit. 

## Update After Two Game Weeks

What about if we now allow transfers? We will optimise for the first two game weeks and then see how many transfers are needed afterward to maximise the number of points. 


```julia
model, res1 = squad_selector(expPoints1 + expPoints2, cost, posInt, teamInt, 0.5)
currentSquad = zeros(nrow(df))
currentSquad[res1[1]["Squad"] .> 0.5] .= 1

res = Array{Dict{String, Any}}(undef, length(0:5))

expPoints = zeros(length(0:5))

for (i, t) in enumerate(0:5)
    model, res3 = transfer_test(expPoints3 + expPoints4 + expPoints5, cost, posInt, teamInt, 0.5, currentSquad, t, true)
    res[i] = res3[1]
    expPoints[i] = res3[1]["ExpPoints"]
end
```

Checking the expected points of the teams and adjusting for any transfers after the first two free ones gives us:

```julia
expPoints .- [0,0,0,1,2,3]*4
```

    6-element Vector{Float64}:
     162.385
     164.295
     167.987
     165.767
     164.084
     161.726


So making two transfers improve our score by 5 points, so seems worth it. If we go beyond two transfers, then we will pay a 4 point penalty, so it seems worth 

![Update after 2 GWs](/assets/fpl_update.png){: .center-image}

So Botman and Watkins are switched out for Gabriel and Toney. Again, not a bad-looking team, and making these transfers improves the expected points by 5.

## Shortcomings

The FPL community can be split into two camps, those that think data help and those that think watching the games and the players help. So what are the major issues with these teams? 

Firstly, Spurs have a glaring omission from any of the results. Given their strong finish to the season and high expectations coming into the season this is potentially a problem. 

Things can change very quickly. After the first week, we will have some information on how different players are looking and by that time these teams could be very wrong with little flexibility to change them to adjust to the new information. I am reminded of last year where Luke Shaw was a hot pick in lots of initial teams and look how that turned out. 

How off-meta these teams are. It's hard to judge what the current template team is going to be at these early stages in the pre-season, but if you aren't accounting for who other people will be owning you can find yourself being left behind all for the sake of being contrarian. For example, this team has put lots of money into goalkeepers when you could potentially spend that elsewhere. 

Some of the players in the teams listed might not get that many minutes. Especially for the cheaper players, I could be selecting fringe players rather than the reliable starters for the lower teams. Again, similar to the last point, there is are 'enablers' that the wider community believes to be the most reliable at the lower price points. 

And finally variance. FPL is a game of variance. Haaland is projected to score 7 points in his first match, which is the equivalent to playing the full 90 minutes and a goal/assist. He could quite easily only score 1 point after not starting and coming on for the last 10 minutes and you are then panicking about the future game weeks. Relying on these optimised teams can sometimes mean you forget about the variance and how easy it is for a player to not get close to the number of points they are predicted. 

## Conclusion and What Next

Overall using the optimiser helps reduce the manual process of working out if there is a better player at each price point. Instead, you can use it to inspire some teams and build on them from there adjusting accordingly. There are still some tweaks that I can build into the optimiser, making sure it doesn't overload the defence with players from the same team and see if I can simulate week-by-week what the optimal transfer if there is one, should be. 

I also want to try and make this a bit more interactive so I'm less reliant on the notebooks and have something more production-ready that other people can play with.

Also given we get a free wildcard over Christmas I can do a mid-season review and essentially start again! So check back here in a few months time. 
