---
layout: post
title: Crypto Data using AlphaVantatge.jl 
date: 2021-03-27
tags:
  - julia
---

Julia 1.6 is hot off the press, so I've installed it and fired off this quick blog post to give 1.6 a test drive. So far, so good and there is a real decrease now in the latencies in both loading up packages and getting things going. 

AlphaVantage have data on cryptocurrencies and not just stocks and fx. Each of which are implemented in [AlphaVantage.jl](https://github.com/ellisvalentiner/AlphaVantage.jl). This is a simple blogpost that takes you through each function and how it might be useful to analyse cryptocurrencies. 

Firstly, what coins are available? Over 500 (542 to be precise). Now as a crypto tourist, I'm only really familiar with the most popular ones that are causing the headlines. So I've taken the top 10 from [coinmarketcap](https://coinmarketcap.com/) and will use those to demonstrate what AlphaVantage can do.


```julia
using AlphaVantage
using Plots
using DataFrames, DataFramesMeta
using CSV, Dates, Statistics

ccys = ["BTC", "ETH", "ADA", "DOT", "BNB", "USDT", "XRP", "UNI", "THETA", "LTC"]
```

# FCAS Health Index from Flipside Crypto

AlphaVantage have partnered with [Flipside Crypto](https://flipsidecrypto.com/) to provide their ratings of different coins. This is designed to give some further info on different coins rather than just looking at what recently increased massively.


```julia
ratings = crypto_rating.(ccys);
```

Simple broadcasted call to get the ratings for each of the 10 currencies above. We format the response into a dataframe and get a nice table out. Not all the coins have a rating, so we have to filter out any empty ratings. 


```julia
inds = findall(.!isempty.(ratings))
ratingsFrame = vcat(map(x->DataFrame(x["Crypto Rating (FCAS)"]), ratings[inds])...)
rename!(ratingsFrame, Symbol.(["Symbol", "Name", "Rating", "Score", "DevScore", "Maturity", "Utility", "LastRefresh", "TZ"]))
for col in (:Score, :DevScore, :Maturity, :Utility)
    ratingsFrame[!, col] .= parse.(Int64, ratingsFrame[!, col])
end
ratingsFrame
```




<table class="data-frame"><thead><tr><th></th><th>Symbol</th><th>Name</th><th>Rating</th><th>Score</th><th>DevScore</th><th>Maturity</th><th>Utility</th><th>LastRefresh</th></tr><tr><th></th><th>String</th><th>String</th><th>String</th><th>Int64</th><th>Int64</th><th>Int64</th><th>Int64</th><th>String</th></tr></thead><tbody><p>7 rows × 9 columns (omitted printing of 1 columns)</p><tr><th>1</th><td>BTC</td><td>Bitcoin</td><td>Superb</td><td>910</td><td>868</td><td>897</td><td>965</td><td>2021-03-26 00:00:00</td></tr><tr><th>2</th><td>ETH</td><td>Ethereum</td><td>Superb</td><td>973</td><td>966</td><td>896</td><td>997</td><td>2021-03-26 00:00:00</td></tr><tr><th>3</th><td>ADA</td><td>Cardano</td><td>Superb</td><td>964</td><td>969</td><td>931</td><td>966</td><td>2021-03-26 00:00:00</td></tr><tr><th>4</th><td>BNB</td><td>Binance Coin</td><td>Attractive</td><td>834</td><td>745</td><td>901</td><td>932</td><td>2021-03-26 00:00:00</td></tr><tr><th>5</th><td>XRP</td><td>XRP</td><td>Attractive</td><td>842</td><td>881</td><td>829</td><td>794</td><td>2021-03-26 00:00:00</td></tr><tr><th>6</th><td>THETA</td><td>THETA</td><td>Caution</td><td>588</td><td>726</td><td>915</td><td>353</td><td>2021-03-26 00:00:00</td></tr><tr><th>7</th><td>LTC</td><td>Litecoin</td><td>Attractive</td><td>775</td><td>652</td><td>899</td><td>905</td><td>2021-03-26 00:00:00</td></tr></tbody></table>



Three superb, three attractive and one caution. THETA gets a lower utility score which is dragging down its overal rating. By the looks of it, THETA is some sort of streaming/YouTube-esque project, get paid their token by giving your excess computing power to video streams. There website is [here](https://www.thetatoken.org/) and I'll let you judge whether they deserve that rating. 

To summarise briefly each of the ratings is on a 0 to 1000 scale in three different areas: 

* Developer Score (`DevScore`) 

Things like code changes, improvements all taken from the repositories of the coins. 

* Market Maturity (`Maturity`) 

This looks at the market conditions around the coin, so things like liquidity and volatility.

* User Activity (`Utility`) 

On chain activities, network activity and transactions, so is the coin being used for something actually useful. Hence why you can see why ETH is ranked the highest here. 

More details are on their website [here](https://flipsidecrypto.com/products/ratings).

# Timeseries Data

AlphaVantage also offer the usual time series data at daily, weekly and monthly frequencies. Hopefully you've read my other posts ([basic market data](https://dm13450.github.io/2020/07/05/AlphaVantage.html) and [fundamental data](https://dm13450.github.io/2021/01/01/Fundamental-AlphaVantage.html)), so this is nothing new! 

Now for each 10 tokens we can grab their monthly data and calculate some stats and plot some graphs.


```julia
monthlyData = digital_currency_monthly.(ccys[inds], datatype = "csv");
```

Again formatting the returned data into a nice dataframe gives us a monthly view of the price action for each of the currencies. I format the date column, calculate the monthly log return and cumulative log return.


```julia
function format_data(x, ccy)
    df = DataFrame(x[1])
    rename!(df, Symbol.(vec(x[2])), makeunique=true)
    df[!, :timestamp] = Date.(df[!, :timestamp])
    sort!(df, :timestamp)
    df[!, :Return] = [NaN; diff(log.(df[!, Symbol("close (USD)")]))]
    df[!, :CumReturn] = [0; cumsum(diff(log.(df[!, Symbol("close (USD)")])))]
    df[!, :Symbol] .= ccy
    df
end

prices = vcat(map(x -> format_data(x[1], x[2]), zip(monthlyData, ccys[inds]))...)
first(prices, 5)
```




<table class="data-frame"><thead><tr><th></th><th>timestamp</th><th>open (USD)</th><th>high (USD)</th><th>low (USD)</th><th>close (USD)</th><th>open (USD)_1</th><th>high (USD)_1</th></tr><tr><th></th><th>Date</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th></tr></thead><tbody><p>5 rows × 14 columns (omitted printing of 7 columns)</p><tr><th>1</th><td>2018-08-31</td><td>7735.67</td><td>7750.0</td><td>5880.0</td><td>7011.21</td><td>7735.67</td><td>7750.0</td></tr><tr><th>2</th><td>2018-09-30</td><td>7011.21</td><td>7410.0</td><td>6111.0</td><td>6626.57</td><td>7011.21</td><td>7410.0</td></tr><tr><th>3</th><td>2018-10-31</td><td>6626.57</td><td>7680.0</td><td>6205.0</td><td>6371.93</td><td>6626.57</td><td>7680.0</td></tr><tr><th>4</th><td>2018-11-30</td><td>6369.52</td><td>6615.15</td><td>3652.66</td><td>4041.32</td><td>6369.52</td><td>6615.15</td></tr><tr><th>5</th><td>2018-12-31</td><td>4041.27</td><td>4312.99</td><td>3156.26</td><td>3702.9</td><td>4041.27</td><td>4312.99</td></tr></tbody></table>




```julia
returnPlot = plot(prices[!, :timestamp], prices[!, :CumReturn], group=prices[!, :Symbol],
                  title="Cummulative Return",
                  legend=:topleft)
mcPlot = plot(prices[!, :timestamp], 
              prices[!, Symbol("market cap (USD)")] .* prices[!, Symbol("close (USD)")], 
              group=prices[!, :Symbol],
              title="Market Cap",
              legend=:none)

plot(returnPlot, mcPlot)
```




![svg](/assets/AlphaVantageCrypto/output_15_0.svg)



There we go, solid cumulative monthly returns (to the moon!) but bit of a decline in market cap recently after a week of negative returns. If you want higher frequencies there is always 

* `digital_currency_daily`
* `digital_currency_weekly`

which will return the same type of data, just indexed differently. 

# Is the Rating Correlated with Monthly Trading Volume?

We've got two data sets, now we want to see if we can explain some the crypto scores with how much is traded each month. For this we simply take the monthly data, average the monthly volume traded and join it with the ratings dataframe. 


```julia
gdata = groupby(prices, :Symbol)
avgprices = @combine(gdata, MeanVolume = mean(:volume .* cols(Symbol("close (USD)"))))
avgprices = leftjoin(avgprices, ratingsFrame, on=:Symbol)
```




<table class="data-frame"><thead><tr><th></th><th>Symbol</th><th>MeanVolume</th><th>Name</th><th>Rating</th><th>Score</th><th>DevScore</th><th>Maturity</th><th>Utility</th></tr><tr><th></th><th>String</th><th>Float64</th><th>String?</th><th>String?</th><th>Int64?</th><th>Int64?</th><th>Int64?</th><th>Int64?</th></tr></thead><tbody><p>7 rows × 10 columns (omitted printing of 2 columns)</p><tr><th>1</th><td>BTC</td><td>2.473e10</td><td>Bitcoin</td><td>Superb</td><td>910</td><td>868</td><td>897</td><td>965</td></tr><tr><th>2</th><td>ETH</td><td>9.6248e9</td><td>Ethereum</td><td>Superb</td><td>973</td><td>966</td><td>896</td><td>997</td></tr><tr><th>3</th><td>ADA</td><td>2.6184e9</td><td>Cardano</td><td>Superb</td><td>964</td><td>969</td><td>931</td><td>966</td></tr><tr><th>4</th><td>BNB</td><td>3.7598e9</td><td>Binance Coin</td><td>Attractive</td><td>834</td><td>745</td><td>901</td><td>932</td></tr><tr><th>5</th><td>XRP</td><td>3.28003e9</td><td>XRP</td><td>Attractive</td><td>842</td><td>881</td><td>829</td><td>794</td></tr><tr><th>6</th><td>THETA</td><td>6.36549e8</td><td>THETA</td><td>Caution</td><td>588</td><td>726</td><td>915</td><td>353</td></tr><tr><th>7</th><td>LTC</td><td>1.71448e9</td><td>Litecoin</td><td>Attractive</td><td>775</td><td>652</td><td>899</td><td>905</td></tr></tbody></table>



Visually, lets just plot the different scores on the x-axis and the monthly average volume on the y-axis. Taking logs of both variables stops BTC dominating the plots. 


```julia
scorePlots = [plot(log.(avgprices[!, x]), 
                   log.(avgprices.MeanVolume), 
                   seriestype=:scatter, 
                   series_annotations = text.(avgprices.Symbol, :bottom),
                   legend=:none, 
                   title=String(x)) 
    for x in (:Score, :DevScore, :Maturity, :Utility)]
plot(scorePlots...)
```




![svg](/assets/AlphaVantageCrypto/output_19_0.svg)



Solid linear relationship in the score and dev score metrics, not so much for the maturity and utility scores. Of course, as this is a log-log plot a linear relationship indicates power law behaviour. 

Side note though, the graphs are a bit rough around the edges, labels are overlapping and even crossing though the axis. Julia needs a `ggrepel` equivalent. 

# Summary

Much like the other functions in AlphaVantage.jl everything comes through quite nicely and once you have the data its up to you to find something interesting!
