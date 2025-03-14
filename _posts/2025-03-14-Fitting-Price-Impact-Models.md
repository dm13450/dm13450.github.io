---
layout: post
title: Fitting Price Impact Models
date: 2025-03-14
tags:
  - julia
images:
  path: /assets/priceimpact/priceimpact.png
  width: 500
  height: 500
---

A big part of market microstructure is price impact and understanding how you move the market every time you trade. In the simplest sense, every trade upends the supply and demand of an asset even for a tiny amount of time. The market responds to this change, then responds to the response, then responds to that response, etc. You get the idea. It's a cascading effect of interactions between all the people in the market.

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

Price impact is happening both at the micro and macro level. At the micro level each trade moves the market a little bit based on the instantaneous market conditions commonly called 'liquidity'. At the macro level, continuous trades in one direction have a compounding and overlapping effect. In reality, you can't separate out either effect so the market impact models need to work for both small and large scales. 

This post is inspired by two sources:

1. [Handbook of Price Impact Modelling](https://www.routledge.com/Handbook-of-Price-Impact-Modeling/Webster/p/book/9781032328225) - Chapter 7
2. [Stochastic Liquidity as a Proxy for Nonlinear Price Impact](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4286108)

Both cover very similar models but one is a fairly expensive
book and the other is on SSRN for free. The same author is involved in
both of them too. 

In terms of data, there are two routes you can go down.

1. You have your own, private, execution data and can build out a data set for the models. 
2. You use publicly available trades and adjust the models to account for the anonymous data. 

In the first case, you will know when an execution started and stopped so can record how the price changed. In the second case, the data will be made up of lots of trades and less obvious when some parent execution started and stopped.

We will take the 2nd route and using Bitcoin data to look at different price impact models.

As ever I will be using Julia with some of the standard packages.

```julia
using LibPQ
using DataFrames, DataFramesMeta
using Dates
using Plots
using GLM, Statistics, Optim
```

## Bitcoin Price Impact Data

We will use my old trusty Bitcoin data set that I collected
in 2021. It's just over a day's worth of Bitcoin trades and L1 prices
that I piped into QuestDB. Full detail in [Using QuestDB to Build a Crypto Trade Database in Julia](https://dm13450.github.io/2021/08/05/questdb-part-1.html
).

First, we connect to the database. 

```julia
conn = LibPQ.Connection("""
             dbname=qdb
             host=127.0.0.1
             password=quest
             port=8812
             user=admin""");
```
			 
For each trade recorded in the database, we also want to join the best bid and offer immediately before it. This is where an `ASOF` join is useful. It joins two tables with timestamps using the entry of the 2nd table with time before the first table row. Sounds more complicated than it really is. In short, it takes the trade table and adds in the prices using the price just before the trade. 


```julia
trades = execute(conn, 
    "WITH
trades AS ( 
   SELECT * FROM coinbase_trades
   ),
prices as (
  select * from coinbase_bbo
)
select * from trades ASOF JOIN prices") |> DataFrame
dropmissing!(trades);
trades = @transform(trades, :mid = 0.5*(:ask .+ :bid))
```

For these small tables, it calculates pretty much instantly and we are
able to return a Julia data frame. Plus we calculate the mid-price for each row.

In all the price impact models we are aggregating this data: 
1. Group the data by some time bucket (seconds or minutes etc.)
2. Calculate the net amount, total absolute amount and open and close prices of the bucket. 
3. Calculate the price return using the close-to-close prices. 

```julia
function aggregate_data(trades, smp)
    tradesAgg = @combine(groupby(@transform(trades, :ts = floor.(:timestamp, smp)), :ts), 
             :q = sum(:size .* :side), 
             :absq = sum(:size), 
             :o = first(:mid), 
             :c = last(:mid));
    tradesAgg[!, "price_return"] .= [NaN; (tradesAgg.c[2:end]./ tradesAgg.c[1:(end-1)]) .- 1]
    tradesAgg[!, "ofi"] .= tradesAgg.q ./ tradesAgg.absq

    tradesAgg
end
```

We are going to bucket the data by 10 seconds.

```julia
aggData  = aggregate_data(trades, Dates.Second(10))
```

As ever, let's split this data into a training and test set.

```julia
aggDataTrain = aggData[1:7500, :]
aggDataTest = aggData[7501:end, :];
```

It's just a simple split on time.

```julia
plot(aggDataTrain.ts, aggDataTrain.c, label = "Train")
plot!(aggDataTest.ts, aggDataTest.c, label = "Test")
```

![](/assets/priceimpact/traintest.png){:width="80%" .center-image}

## Calculating the Volatility and ADV

All the models require a volatility and ADV calculation. My data runs just over a day, so need to adjust for that.  

For the ADV we take the sum of the total volume traded and divide by the length of time converted to days.

```julia
deltaT = maximum(trades.timestamp) - minimum(trades.timestamp)
deltaTDays = (deltaT.value * 1e-3)/(24*60*60)
adv = sum(trades.size)/deltaTDays
aggDataTrain[!, "ADV"] .= adv
aggDataTest[!, "ADV"] .= adv;
```

For the volatility, we take the square root of the sum of the 5-minute return squared. Should probably be annualised if we were comparing the parameters across different assets.

```julia
min5Agg = aggregate_data(trades, Dates.Minute(5))
volatility = sqrt(sum(min5Agg.price_return[2:end] .* min5Agg.price_return[2:end]))
aggDataTrain[!, "Vol"] .= volatility;
aggDataTest[!, "Vol"] .= volatility;
```

The ADV and volatility have a normalising effect across assets. So if we had multiple coins, we could use the same model even if one was a highly traded coin like BTC or ETH vs a lower volume coin (the rest of them?!). This would give us comparable model parameters to judge the impact effect. 

As our data sample is so small we are only calculating 1 volatility and 1 ADV. In reality, you calculate the volatility/ADV on a rolling basis and then do the train/test split. 

## Models of Market Impact

The paper and book describe different market impact models that all follow a similar functional form. I've chosen four of them to illustrate the model fitting process. 

* The Order Flow Imbalance model (OFI)
* The Obizhaeva-Wang (OW) model
* The Concave Propagator model
* The Reduced Form model

For all the models we will state the form of the market impact
$$\Delta I$$ and use the price returns over the same period to find
the best parameters of the model.

The overarching idea is that the return in each bucket is proportional
to the amount of volume traded in that bucket plus some
contribution from the previous volumes earlier - suitably decayed. 

### Order Flow Imbalance

This is the simplest model as it just uses the imbalance over the
bucket to predict return. For the OFI we are just using the trade
imbalance, the net volume divided by the total volume in the bucket. 

$$\Delta I = \lambda \sigma \frac{q_t}{| q_t | \text{ADV}}$$

As there is no dependence on the previous returns, we can use simple linear regression to estimate $\lambda$.

```julia
aggDataTrain[!, "x_ofi"] = aggDataTrain.Vol .* (aggDataTrain.ofi ./ aggDataTrain.ADV)
aggDataTest[!, "x_ofi"] = aggDataTest.Vol .* (aggDataTest.ofi ./ aggDataTest.ADV)

ofiModel = lm(@formula(price_return ~ x_ofi + 0), aggDataTrain[2:end, :])
```
The model has returned a significant value of $$\lambda = 59$$ and has an in sample $$R^2$$ of 11% and our of sample RMSE of 0.0003. Encouraging and off to a good start!

Side note, I've written about Order Flow Imbalance before in [Order Flow Imbalance - A High Frequency Trading Signal](https://dm13450.github.io/2022/02/02/Order-Flow-Imbalance.html).

### The Obizhaeva-Wang (OW) Model

The OW model is a foundational model of market impact and you will see this model frequently across different microstructure papers. It suggests a linear dependence between the signed order flow and price impact but again normalising against the ADV and volatility. 

$$\Delta I = -\beta I_t + \lambda \sigma \frac{q_t}{ADV}$$

Again, we create the $$x$$ variable in the data frame specific for this model but this will need special attention to fit.

```julia
aggDataTrain[!, "x_ow"] = aggDataTrain.Vol .* (aggDataTrain.q ./ aggDataTrain.ADV);
aggDataTest[!, "x_ow"] = aggDataTest.Vol .* (aggDataTest.q ./ aggDataTest.ADV);
```

From the market impact formula, we can see that the relationship is
recursive. The impact at time $$t$$ depends on the impact at time
$$t-1$$. How much of the previous impact is carried over is controlled
by $$\beta$$ and in the paper they fix this at $$\frac{\log 2}{\beta}
= 60 \text{ Minutes}$$. This means we have to fit the model as: 

1. Calculate the $$I$$ given an estimate of $$\lambda$$
2. Adjust the price returns by this impact
3. Regress the adjusted price returns against the $$x$$ variable. 
4. Repeat with the new estimate of $$\lambda$$ until converged. 

This is a simple 1 parameter optimisation where we minimise the RMSE.

```julia
function calcImpact(x, beta, lambda)
    impact = zeros(length(x))
    impact[1] = x[1]
    for i in 2:length(impact)
        impact[i] = (1-beta)*impact[i-1] + lambda*x[i]
    end
    impact
end
	
function fitLambda(x, y, beta, lambda)
    I = calcImpact(x, beta, lambda)
    y2 = y .+ (beta .* I)
    model = lm(reshape(x, (length(x), 1))[2:end, :], y2[2:end])
    model
end

rmse(x) = sqrt(mean(residuals(x) .^2))
```

We start with $$\lambda = 1$$ and let the optimiser do the work.

```julia
res = optimize(x -> rmse(fitLambda(aggDataTrain[!, "x_ow"], aggDataTrain[!, "price_return"], 0.01, x[1])), [1.0])
```

It's converged! We plot the different values of the objective function and show that this process can find the minimum.

```julia
lambdaRes = rmse.(fitLambda.([aggDataTrain[!, "x_ow"]], [aggDataTrain[!, "price_return"]], 0.01, 0:1:20))
plot(0:1:20, lambdaRes, label = :none, xlabel = L"\lambda", ylabel = "RMSE", title = "OW Model")
vline!(Optim.minimizer(res), label = "Optimised Value")
```

![](/assets/priceimpact/ow.png){:width="80%" .center-image}

We then pull out the best-fitting model and estimate the $$R^2$$.
We have a nice convex relationship which is always a good sign. 

```julia
owModel = fitLambda(aggDataTrain[!, "x_ow"], aggDataTrain[!, "price_return"], 0.01, first(Optim.minimizer(res)))
```

Which gives $$R^2 = 11\%$$. So roughly the same as the OFI model. For the out-of-sample RMSE we get 0.0006.

## Concave Propagator Model

This model follows the belief that market impact is a power law and
that power is close to 0.5. Using the square root of the total amount
traded and the net direction gives us the $$x$$ variable.

$$\Delta I = -\beta I_t + \lambda \sigma \text{sign} (q_t) \sqrt
{\frac{| q_t |}{\text{ADV}}}$$


```julia
aggDataTrain[!, "x_cp"] = aggDataTrain.Vol .* sign.(aggDataTrain.q) .* sqrt.((aggDataTrain.absq ./ aggDataTrain.ADV));
aggDataTest[!, "x_cp"] = aggDataTest.Vol .* sign.(aggDataTest.q) .* sqrt.((aggDataTest.absq ./ aggDataTest.ADV));
```

Again, we optimise using the same methodology as above.

```julia
res = optimize(x -> rmse(fitLambda(aggDataTrain[!, "x_cp"], aggDataTrain[!, "price_return"], 0.01, x[1])), [1.0])
lambdaRes = rmse.(fitLambda.([aggDataTrain[!, "x_cp"]], [aggDataTrain[!, "price_return"]], 0.01, 0:0.1:1))
plot(0:0.1:1, lambdaRes, label = :none, xlabel = L"\lambda", ylabel = "RMSE", title = "Concave Propagator Model")
vline!(Optim.minimizer(res), label = "Optimised Value")
```

![](/assets/priceimpact/concaveprop.png){:width="80%" .center-image}

Another success! This time the $$R^2$$ is 17% so an improvement on the other two models. It's out of sample RMSE is 0.0008.

## Reduced Form Model

The paper suggests that as the number of trades and time increment
increases the market impact function converges to a linear form with a
dependence on the stochastic volatility of the order flow.

$$\Delta I = -\beta I_t + \lambda \sigma \frac{q_t}{\sqrt{v_t \cdot \text{ADV}}}$$

For this, we need to calculate the stochastic liquidity parameter, $$v_t$$, which is simply the moving average of the absolute market volumes.

```julia
function calcLiquidity(absq, beta)
    v = zeros(length(absq))
    v[1] = absq[1]
    for i in 2:length(v)
        v[i] = (1-beta)*v[i-1] + absq[i]
    end
    return v
end

v = calcLiquidity(aggDataTrain[!, "absq"], 0.01)
vTest = calcLiquidity(aggDataTest[!, "absq"], 0.01)

plot(aggDataTrain.ts, v, label = "Stochastic Liquidity")
plot!(aggDataTest.ts, vTest, label = "Test Set")
```

![](/assets/priceimpact/stochliq.png){:width="80%" .center-image}

Adding this into our data frame and calculating the $$x$$ variable is simple.

```julia
aggDataTrain[!, "v"] = v
aggDataTest[!, "v"] = vTest

aggDataTrain[!, "x_rf"] = aggDataTrain.Vol .* aggDataTrain.q ./ sqrt.((aggDataTrain.ADV .* aggDataTrain[!, "v"]));
aggDataTest[!, "x_rf"] = aggDataTest.Vol .* aggDataTest.q ./
sqrt.((aggDataTest.ADV .* aggDataTest[!, "v"]));
```

And again, we repeat the fitting process.

```julia
lambdaVals = 0:0.1:5
res = optimize(x -> rmse(fitLambda(aggDataTrain[!, "x_rf"], aggDataTrain[!, "price_return"], 0.01, x[1])), [1.0])
lambdaRes = rmse.(fitLambda.([aggDataTrain[!, "x_rf"]], [aggDataTrain[!, "price_return"]], 0.01, lambdaVals))
plot(lambdaVals, lambdaRes, label = :none, xlabel = L"\lambda", ylabel = "RMSE", title = "Reduced Form Model")
vline!(Optim.minimizer(res), label = "Optimised Value")
```

![](/assets/priceimpact/rf.png){:width="80%" .center-image}

This model gives an $$R^2=10%$$ and out-of-sample RMSE of 0.0009.

With all four models fitted, we can now look at the differences statistically and how the impact state evolves over the course of the day. 


| Model               | $$\lambda$$ | $$R^2$$  | OOS RMSE |
|---------------------|-------------|----------|
| OFI                 | 43     | 0.11 | 0.0003 |
| OW                  | 14     | 0.11 |0.0006 |
| Concave Propagator | 0.34    | 0.17 | 0.0008  |
| Reduced Form        | 1.7     | 0.10 | 0.0009 |

So, the concave propagator model has the highest $$R^2$$ followed by the reduced form model. The OFI and OW models have slightly lower $$R^2$$.
But, looking at the RMSE values from the out-of-sample performance its
clear that the OFI model seems to be the best.

When we plot the resulting impacts from the 4 models we generally see
they agree, with only the OFI model being the most different. This
difference comes from the lack of time decay from the previous volumes.

![](/assets/priceimpact/priceimpact.png){:width="80%" .center-image}

## Conclusion

Overall, I don't think these results are that informative, my data set is tiny
compared to the paper (1 day vs months). Instead, use this as more of
an instructional on how to fit these models. We didn't even explore
optimising the time decay ($$\beta$$ values) for Bitcoin which could
be substantially different from the paper dataset on equities. So
there is plenty more to do!



























