---
layout: post
title: Does a Terror Attack Lead to More Terror Attacks?
---

Do terror attacks cause more terror attacks? If they do then they are
*self exciting*. In this post I will do some programming in  Julia and apply a type of
self-exciting statistical model to a dataset of terror attacks to see
whether each attack leads to an increase in probability of another
terror attack.

To cut to the chase I find that terror attacks **are** self exciting
and each terror attack has a 93% chance of spawning another attack. This probability of another attack lasts on
average for about two months, decreasing with each day that passes.

But why terror attacks?

One of the chapters in my PhD was all about applying Hawkes processes
to terror attacks. I was concerned about *extreme* terror attacks and
how a Hawkes process can model them in  variety of ways to try and
understand the statistical consequences of a large terror attack.

In this blog post I will do the same, but focus on *all* terror attacks across a variety of countries and build two Hawkes models to see how well they describe these attacks. This will be the first blog post I've written on applying my `HawkesProcesses.jl` Julia [package](https://github.com/dm13450/HawkesProcesses.jl), so should serve as a more practical introduction than my previous outline of the package which I wrote about previously [here](http://dm13450.github.io/2020/05/26/HawkesProcessesPackage.html). 

This is a chunky blog post and is laid out as follows: 

* [The Data](#the-data)
* [Hawkes Processes](#hawkes-processes)
* [The Models](#the-models)
  * [Individual Model](#the-individual-model)
  * [Hierarchical Model](#the-hierarhical-model)
* [Model Checking](#model-checking)
* [Model Comparisons](#model-comparison)
* [National Security Policy Implications](#national-security-policy-implications)

***
Before I get into the meat and bones of the work though, I'd like the
chance to ask you to sign up to my newsletter. Its a short monthly
recap of anything and everything I've found interesting recently plus
any posts I've written. So sign up and stay informed!

<p>
<form
  action="https://buttondown.email/api/emails/embed-subscribe/dm13450"
  method="post"
  target="popupwindow"
  onsubmit="window.open('https://buttondown.email/dm13450', 'popupwindow')"
  class="embeddable-buttondown-form"
>
  <label for="bd-email">Enter your email</label>
  <input type="email" name="email" id="bd-email" />
  <input type="hidden" value="1" name="embed" />
  <input type="submit" value="Subscribe" />
  </form>
  </p>
***

With that out the way, onto the statistics. 

## The Data

```julia
using CSV, DataFrames, DataFramesMeta
using Dates, HawkesProcesses
using Statistics, Distributions, StatsBase
```

I will be using the RAND MIT database of terror attacks that you can download from [here](https://www.rand.org/nsrd/projects/terrorism-incidents/download.html). 


```julia
rawData = CSV.read("/Users/deanmarkwick/Downloads/RAND_Database_of_Worldwide_Terrorism_Incidents.csv")
rawData |> head
```

<table class="data-frame"><thead><tr><th></th><th>Date</th><th>City</th><th>Country</th><th>Perpetrator</th><th>Weapon</th></tr><tr><th></th><th>String</th><th>String?</th><th>String</th><th>String?</th><th>String?</th></tr></thead><tbody><p>6 rows × 8 columns (omitted printing of 3 columns)</p><tr><th>1</th><td>9-Feb-68</td><td>Buenos Aires</td><td>Argentina</td><td>Unknown</td><td>Firearms</td></tr><tr><th>2</th><td>12-Feb-68</td><td>Santo Domingo</td><td>Dominican Republic</td><td>Unknown</td><td>Explosives</td></tr><tr><th>3</th><td>13-Feb-68</td><td>Montevideo</td><td>Uruguay</td><td>Unknown</td><td>Fire or Firebomb</td></tr><tr><th>4</th><td>20-Feb-68</td><td>Santiago</td><td>Chile</td><td>Unknown</td><td>Explosives</td></tr><tr><th>5</th><td>21-Feb-68</td><td>Washington, D.C.</td><td>United States</td><td>Unknown</td><td>Explosives</td></tr><tr><th>6</th><td>21-Feb-68</td><td>Neot Hakikar</td><td>Israel</td><td>Unknown</td><td>Unknown</td></tr></tbody></table>

For each terror attack we get a date, city, country, perpetrator and weapon. We are just interested in the country and date of the attack. The dates are formatted unconventionally, so takes a little bit of formatting. 


```julia
function formatDate(dt::Date)
    (year.(dt) .<= 9) && (year.(dt) .>= 0) ? dt + Year(2000) : dt + Year(1900)
end

rawData = @transform(rawData, DateF = Date.(:Date, "dd-u-YY"))
rawData = @transform(rawData, DateF2 =  formatDate.(:DateF))

minDate = minimum(rawData.DateF2)
maxDate = maximum(rawData.DateF2)
maxT = (maxDate - minDate).value;
```

As there are days where there are potentially more than one terror attacks, we group by the country and date and sum the total number of attacks on that day.


```julia
gdata = groupby(rawData, [:DateF2, :Country])
sumData = @based_on(gdata, N=length(:Date))
sumDataCountry = groupby(sumData, :Country)
totalData = @based_on(sumDataCountry, N=sum(:N))
sort!(totalData, :N, rev=true) |> head
```




<table class="data-frame"><thead><tr><th></th><th>Country</th><th>N</th></tr><tr><th></th><th>String</th><th>Int64</th></tr></thead><tbody><p>6 rows × 2 columns</p><tr><th>1</th><td>Iraq</td><td>10763</td></tr><tr><th>2</th><td>West Bank/Gaza</td><td>2038</td></tr><tr><th>3</th><td>Afghanistan</td><td>2025</td></tr><tr><th>4</th><td>Thailand</td><td>2009</td></tr><tr><th>5</th><td>Colombia</td><td>1913</td></tr><tr><th>6</th><td>Israel</td><td>1687</td></tr></tbody></table>



Iraq experienced over 100,000 terror attacks and comes out as the most
eventful country, five times more than the next country.

## Hawkes Processes

A Hawkes process use three parameters to describe events.

* **The background rate**, $$\mu$$

This describes when random terror attacks happen that weren't spawned
from any other attack. 

* **The child rate**,  $$\kappa$$

On average, how many terror attacks does each terror attack
cause. This is a number between 0 and 1. If the $$\kappa$$ value was
greater than 1 then the process would explode and never stop.

* **The kernel**, $$\beta \exp(-\beta t)$$

How long the impact of each terror attack lasts. It's an exponential
distribution so the impact decays over time. 

Every time a terror attack happens, the probability of another terror
attack increases from the background rate with an addition of $$\kappa
\beta \exp(-\beta t)$$. If that attack then causes another attack we
get another addition of $$\kappa \exp(-\beta t)$$. In short, we can
see where the self exciting comes from, each event increases the
probability of another event.

When we fit a Hawkes process to the data, we want to find the best
$$\mu, \kappa, \beta$$ values that fit the data.

If you want the full technical details on how to fit a Hawkes process
check out my Github repo [here](https://github.com/dm13450/HawkesProcesses.jl).

## The Models

We are fitting two models 

1. *Individual* 

Each country has its own set of Hawkes parameters (a background rate, $$\kappa$$ and kernel value) which means using the `fit` function of `HawkesProcesses` to each countries terror attacks separately. 

2. *Hierarchical* 

There will be just three Hawkes parameters that describe the terror attacks. This means that the terror attacks of each country will influence these overall parameters, but not as if a terror attack in Iraq could influence a further terror attack in say, the Philippines. 

These two models represent the two extremes of modeling choice, we want to know if there is enough information in the data to warrant individual parameters, or is the nature of terror attacks across all countries similar such that the parameters can be homogenous. 
Or more simply, do we overfit if we let each country have their own set of parameters?

### The Individual Model

For the top 50 countries, we find the best fitting $$\mu, \kappa, 
\beta$$ value using the ```fit``` function. We train on 70% of the
data, leaving the last 30% for model checking. 

```julia
modelCountries = totalData.Country[1:50]

dataset = Array{DataFrame}(undef, length(modelCountries))
modelParams = Array{DataFrame}(undef, length(modelCountries))
intensity = Array{DataFrame}(undef, length(modelCountries))

allEvents = Array{Array{Float64}}(undef, length(modelCountries))
allEventsTrain = Array{Array{Float64}}(undef, length(modelCountries))

for (i, country) in enumerate(modelCountries)
    println(country)
    subData = @where(sumData, :Country .== country)
    rawTS = subData.DateF2
    ts = getfield.(rawTS .- minDate, :value)
    
    trainInds = Int64(floor(length(ts)*0.7))
    trainEvents = ts[1:trainInds]
    
    allEventsTrain[i] = trainEvents 
    allEvents[i] = ts
    
    #Fit the models
    bgSamps1, kappaSamps1, kernSamps1 = HawkesProcesses.fit(allEventsTrain[i] .+ rand(length(allEventsTrain[i])), maxT, 5000)
    bgSamps2, kappaSamps2, kernSamps2 = HawkesProcesses.fit(allEventsTrain[i] .+ rand(length(allEventsTrain[i])), maxT, 5000)
    
    #Take averages of the parameters
    bgEst = mean(bgSamps1[500:end])
    kappaEst = mean(kappaSamps1[500:end])
    kernEst = mean(kernSamps1[500:end])
    
    #Calculate the intensity over time
    intens = HawkesProcesses.intensity(collect(0:maxT), ts, bgEst, kappaEst, Exponential(1/kernEst))

    #Calculate the likelihood
    likelihoodTrain = HawkesProcesses.likelihood(allEventsTrain[i], bgEst, kappaEst, Exponential(1/kernEst), maxT)
    likelihoodAll = HawkesProcesses.likelihood(ts, bgEst, kappaEst, Exponential(1/kernEst), maxT)
    
    intensity[i] = DataFrame(Country = country, Intensity=intens, t=collect(0:maxT), Date = collect(minDate:Day(1):maxDate))
    dataset[i] = DataFrame(Country = country, EventTimes = ts, Dates = rawTS)    
    modelParams[i] = DataFrame(Country = country, N=length(ts), 
                       BG = bgEst,
                       Kappa = kappaEst,
                       Kern = kernEst,
                       LikelihoodTrain = likelihoodTrain,
                       LikelihoodAll = likelihoodAll)
    
end

allData = vcat(dataset...)
allParams = vcat(modelParams...)
allIntensities = vcat(intensity...);
```


With the fitting complete we can now examine the final parameters. I select 10 random countries out of the 50 the model was fitted and plot there individual parameters.


```julia
using Plots
using StatsPlots
sort!(allParams, :Kappa)

plotInds = Int64.(floor.(rand(10) * 50))
paramPlot = Array{Plots.Plot}(undef, 3)
for (i, param) in enumerate((:BG, :Kappa, :Kern))
    paramPlot[i] = bar(allParams[plotInds, :Country], allParams[plotInds, param], orientation = :horizontal, label=:none, title=string(param))
end

plot(vcat(paramPlot)...)
```

![svg](/assets/terrorhawkes/output_10_1.svg)

* Higher background values: the overall rate of terror attack is higher. 
* Higher $$\kappa$$ values: the self-exciting jump is higher as each event has $\kappa$ children events. 
* Higher kernel value, $$\beta$$: the decay of the terror attack excitement is quicker.


We can also examine the intensity profiles of some countries. If the
intensity is high, the probability of another terror attack is also
high. 


```julia
selCountrys = ["Iran", "Russia", "Spain", "Israel"]
intPlots = Array{Plots.Plot}(undef, length(selCountrys))
for (i, country) in enumerate(selCountrys)
    subData = @where(allIntensities, :Country .== country, year.(:Date) .>= 2000)
    intPlots[i] = plot(subData.Date, subData.Intensity, label=country,
                       linecolour=Int64(ceil(rand()*10)))
end
plot(vcat(intPlots)...)
```




![svg](/assets/terrorhawkes/output_12_0.svg)



For Iran, we can see that the attacks are coming in bursts with periods of down time. Whereas for the other three countries there is a more fluid ebb and flow of the intensity. 

## The Hierarchical Model

We now turn to fitting the hierarchical model, where there is just one background, $\kappa$ and kernel parameter shared across all the countries. This is a newly implemented feature of my `HawkesProcesses` package and you can fit a simple Hawkes process with exponential kernel across multiple timeseries in a hierarchical model. 

```julia
hierParams1 = HawkesProcesses.hierarchical_fit(allEventsTrain, maxT, 5000);
hierParams2 = HawkesProcesses.hierarchical_fit(allEventsTrain, maxT, 5000);
paramEstimates = map(x->mean(x[500:end]), hierParams1)
```




    (0.0011, 0.94, 0.016)

Here we can see that across all countries, each terror attack has on
average 0.94 children terror attack. So they are very self
exciting. From the kernel parameter we can see that this impact lasts
60 days on average. 

Now all the models I've been fitting have been using a Bayesian algorithm, so
we want to assess whether the parameters have converged to the same
value. I've fit two chains to also assess the convergence of the model.

```julia
bgPlot = plot(hierParams1[1][500:end], title="Background", label=:none)
plot!(bgPlot, hierParams2[1][500:end], label=:none)

kappaPlot = plot(hierParams1[2][500:end], title="Kappa", label=:none)
plot!(kappaPlot, hierParams2[2][500:end], label=:none)

kernPlot = plot(hierParams1[3][500:end], title="Kernel", label=:none)
plot!(kernPlot, hierParams2[3][500:end], label=:none)

plot(bgPlot, kappaPlot, kernPlot)
```




![svg](/assets/terrorhawkes/output_19_0.svg)


Everything is looking good.


Now we are happy with the model, we can compare their outputs and see
how they differ.

We will calculate the likelihood and intensity functions. The likelihoods will allow us to perform some model criticism later, whereas the intensity will give us a visual inspection of the model output. 


```julia
hierIntensities = Array{DataFrame}(undef, length(modelCountries))
hierLikelihood = Array{DataFrame}(undef, length(modelCountries))
for (i, country) in enumerate(modelCountries)
    
  intens = HawkesProcesses.intensity(collect(0:maxT), allEvents[i], 
                                     paramEstimates[1], paramEstimates[2], Exponential(1/paramEstimates[3]))
    hierIntensities[i] = DataFrame(Intensity = intens, t=collect(0:maxT), 
                                   Country=country, Date = collect(minDate:Day(1):maxDate))
    hierLikelihood[i] = DataFrame(HierLikelihoodAll=HawkesProcesses.likelihood(allEvents[i], paramEstimates[1], paramEstimates[2], Exponential(1/paramEstimates[3]), maxT),
                               Country = country,
                               HierLikelihoodTrain = HawkesProcesses.likelihood(allEventsTrain[i], paramEstimates[1], paramEstimates[2], Exponential(1/paramEstimates[3]), maxT))
end

hierIntensities = vcat(hierIntensities...);
hierLikelihood = vcat(hierLikelihood...);
```

Likelihoods calculated, I can compare the intensities for both models
and see how different they look. 

```julia
selCountrys = ["Iran", "Russia", "Spain", "Israel"]
intPlots = Array{Plots.Plot}(undef, length(selCountrys))
for (i, country) in enumerate(selCountrys)
    subData = @where(allIntensities, :Country .== country, year.(:Date) .>= 2000)
    subDataHier = @where(hierIntensities, :Country .== country, year.(:Date) .>= 2000)
    p = plot(subData.Date, subData.Intensity, label="Individual", title=country)
    plot!(subDataHier.Date, subDataHier.Intensity, label="Hierarchical")
    intPlots[i] = p
end
plot(vcat(intPlots)...)
```




![svg](/assets/terrorhawkes/output_22_0.svg)



Despite the difference in parameters, the final output appear quite similar. Which is reassuring. For Iraq we can see that the hierarchical model decaying slower, but across all countries the spike after each attack is of similar magnitude. 

## Model Checking

Are terror attacks actually self exciting though? To check for this we
fit a model that doesn't have any self exciting behaviour and see if
it is better than the Hawkes models.

To check if one model is better than the other, we use the time change
theorem. By using the intensity functions we can transform the event
times and see how close they fall to a straight line. A perfect model
would fall exactly on the straight, a bad model would be far away from
a straight line. 


```julia
residPlots= Array{Plots.Plot}(undef, length(selCountrys))

for (i, country) in enumerate(selCountrys)
    
   subData = @where(allData, :Country .== country)
   subParams = @where(allParams, :Country .== country)
    
   nullResid = HawkesProcesses.time_change_null(subData.EventTimes, maxT) 
   hierResid = HawkesProcesses.time_change_hawkes(subData.EventTimes, paramEstimates[1], paramEstimates[2], Exponential(1/paramEstimates[3])) 
   indResid = HawkesProcesses.time_change_hawkes(subData.EventTimes, subParams.BG[1], subParams.Kappa[1], Exponential(1/subParams.Kern[1]))
    
   p1 = plot(nullResid[1], nullResid[2], label="Null", title=country)
   plot!(p1, hierResid[1], hierResid[2], label="Hierarchical")
   plot!(p1, indResid[1], indResid[2], label="Individual")
   plot!(0:0.1:1, 0:0.1:1, label="Theoretical", colour="black", legend=:topleft) 
   residPlots[i] = p1
end
plot(residPlots...)
```




![svg](/assets/terrorhawkes/output_25_0.svg)

Here we can see that both Hawkes models improve on the model without
self exciting (the null model)  as they are closer to the theoretical
straight black line. This suggests there is some notion of self
excitability between the events, which means we can move onto deciding
which Hawkes model is better, the individual or the hierarchical
model? 

## Model Comparison

How do we know what model is better? I've written about deviance
information criteria before
([here](http://dm13450.github.io/2020/08/26/Hawkes-and-DIC.html)) and
it is implemented in this `HawkesProcesses` package. But I might aswell use this to illustrate other information criteria's; Bayesian and Akaike. Both are about weighing up the likelihood with the number of parameters in the model. There is an important point to note that these methods are not strictly Bayesian and don't make full use of the full posterior sampling, but I think it is useful to have a general indicator and comparison between models, even if it isn't strictly pure. Plus this also highlights the benefits of a Bayesian approach, you can reduce it to a frequentist estimate just by taking your point estimate of the parameters. 

By assuming that each country is independent of each other, we arrive at a final likelihood value by summing up each individual likelihood for the country. Then by separating the training set likelihood and total likelihood we can come up with a test set likelihood, which we can use to perform our model comparison. 


```julia
indLikelihood = @select(allParams, :Country, :LikelihoodAll, :LikelihoodTrain)
allLikelihood = leftjoin(indLikelihood, hierLikelihood, on=:Country)
allLikelihood = @transform(allLikelihood, 
                        LikelihoodTest = :LikelihoodAll - :LikelihoodTrain, 
                        HierLikelihoodTest = :HierLikelihoodAll - :HierLikelihoodTrain)

indAll = sum(allLikelihood.LikelihoodAll)
indTest = sum(allLikelihood.LikelihoodTest)
indTrain = sum(allLikelihood.LikelihoodTrain)

hierAll = sum(allLikelihood.HierLikelihoodAll)
hierTrain = sum(allLikelihood.HierLikelihoodTrain)
hierTest = sum(allLikelihood.HierLikelihoodTest)

allEventsN = sum(map(length, allEvents))
trainEventsN = sum(map(length, allEventsTrain))
testEventsN = allEventsN - trainEventsN

finalResults = vcat(DataFrame(Model = "Ind", 
                              Params = 3*length(modelCountries),
                              Sample = ["All", "Test", "Train"], 
                              Likelihood = [indAll, indTest, indTrain],
                              NEvents = [allEventsN, testEventsN, trainEventsN]),
                    DataFrame(Model = "Hier", 
                              Params = 3,
                              Sample = ["All", "Test", "Train"],  
                              Likelihood = [hierAll, hierTest, hierTrain],
                              NEvents = [allEventsN, testEventsN, trainEventsN])
)
```




<table class="data-frame"><thead><tr><th></th><th>Model</th><th>Params</th><th>Sample</th><th>Likelihood</th><th>NEvents</th></tr><tr><th></th><th>String</th><th>Int64</th><th>String</th><th>Float64</th><th>Int64</th></tr></thead><tbody><p>6 rows × 5 columns</p><tr><th>1</th><td>Ind</td><td>150</td><td>All</td><td>-65332.8</td><td>20466</td></tr><tr><th>2</th><td>Ind</td><td>150</td><td>Test</td><td>-18064.0</td><td>6163</td></tr><tr><th>3</th><td>Ind</td><td>150</td><td>Train</td><td>-47268.8</td><td>14303</td></tr><tr><th>4</th><td>Hier</td><td>3</td><td>All</td><td>-65715.0</td><td>20466</td></tr><tr><th>5</th><td>Hier</td><td>3</td><td>Test</td><td>-18023.3</td><td>6163</td></tr><tr><th>6</th><td>Hier</td><td>3</td><td>Train</td><td>-47691.8</td><td>14303</td></tr></tbody></table>

Here we can see that the individual model has a lower likelihood by around 600. But, it has 150 parameters compared to the hierarchical model that has just 3. We can use Akaike Information Criteria which takes into account the number of parameters. 

$$\text{AIC} = 2k - 2\mathcal{L}$$

The better model will have a lower AIC value. 

There is also the Bayesian information criteria, which is slightly different in that it also takes into account the number of datapoints.

$$\text{BIC} = k\ln(n) - 2 \mathcal{L}$$

Again, we want the model with the lower BIC.


```julia
finalResults = @transform(finalResults, AIC = 2*:Params - 2*:Likelihood)
finalResults = @transform(finalResults, BIC = :Params .* log.(:NEvents) - 2*:Likelihood)
@where(finalResults, :Sample .== "Test")
```




<table class="data-frame"><thead><tr><th></th><th>Model</th><th>Params</th><th>Sample</th><th>Likelihood</th><th>NEvents</th><th>AIC</th><th>BIC</th></tr><tr><th></th><th>String</th><th>Int64</th><th>String</th><th>Float64</th><th>Int64</th><th>Float64</th><th>Float64</th></tr></thead><tbody><p>2 rows × 7 columns</p><tr><th>1</th><td>Ind</td><td>150</td><td>Test</td><td>-18064.0</td><td>6163</td><td>36427.9</td><td>37436.9</td></tr><tr><th>2</th><td>Hier</td><td>3</td><td>Test</td><td>-18023.3</td><td>6163</td><td>36052.6</td><td>36072.7</td></tr></tbody></table>

When we look at just the test set we can see that the likelihood is higher and both the BIC and AIC are lower, which shows the hierarchical model is preferred. Especially since there are just 3 parameters compared to the 150. 

The hierarchical model is also preferred as it shows how the model is generalisable to countries not included in the test set. Whereas for the individual model there is no way of using parameters of other countries to apply to a new country. 

There is another model that is in between both one set of parameters for all countries and $$3N$$ parameters for $$N$$ countries and that involves partial pooling, I've written about pooling before [here](http://dm13450.github.io/2018/10/24/Referee-Cautions.html) and you can take similar ideas and apply them to this applications. It takes a bit more work and is beyond the scope of this blog post, so I will save that for another blog post. 

## National Security Policy Implications

Let's say you are a government official reading this post and think it is useful but want to know how the Hawkes parameters and structure could be directly incorporated into terror attack responses. In the UK we have threat levels: Low, Moderate, Substantial, Severe and Critical. So we could split up the Hawkes intensity in 5 quantiles, where each quantile occupies one of these levels. 


```julia
ukIntensity = @where(hierIntensities, :Country .== "United Kingdom")
levls = quantile(ukIntensity.Intensity, [0.2, 0.4, 0.5, 0.8])

plot(ukIntensity.Date, ukIntensity.Intensity, label="Hawkes Intensity")
hline!(levls, label="Threat Level Boundaries")
```


![svg](/assets/terrorhawkes/output_35_0.svg)

Each horizontal line represents the boundary between the different threat levels. Each attack causes a move across two boundaries making it quite reactive. As you can see at the end of this dataset we were back into "low" level having not seen an attack in a while. 

We can also use the parameters to learn about the structure between events. As it is also a hierarchical model, these interpretations apply to all terror attacks not just those in the UK. 


```julia
paramEstimates
```

    (0.0011, 0.94, 0.016)

Each terror attack has 0.94 children terror attacks, which is very
high and suggests quite a bit of self-excitation. We can see this
above as each terror attack causes that large spike. Using the kernel
parameter we see that the half-life of the kernel is
$$\frac{1}{0.016} = 62.5$$ days. So it takes roughly two months for the
increased intensity to reduce by half. So, after each terror attack
increase readiness for 60 days! It is a shame that the data set is
almost 10 years out of date so we can't get an to date picture of
where we are right now. If you know of a more recent datasource, please let me know below. 

## Summary

Quite the chunky blog post and on a heavier subject than what I usually write about, but a nice application of the Hawkes process and how it can be used in this terror attack context. I've fitted two Hawkes models and shown that they improve on a null Poisson model, then between the Hawkes models I found that the hierarchical model with the same parameters per country was a better model than one with separate parameters for each country. Potentially, the individual parameter model overfit the data and didn't generalise to the unseen events. I then has a guess about how the outputs from this type of model could be used to adjust terror related public policy. 
