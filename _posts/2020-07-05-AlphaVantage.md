---
layout: post
title:  AlphaVantage.jl - Getting Market Data into Julia
date: 2020-07-05
tags:
 - julia
---

[AlphaVantage](https://www.alphavantage.co/) is a market data provider that is nice enough to provide
free access to a wide variety of data. It is my goto financial data
provider ([State of the Market - Infinite State Hidden Markov Models](https://dm13450.github.io/2020/06/03/State-of-the-Market.html)) , because a) it's free and b) there is an R package that
accesses the API easily. However, there was no Julia package for
AlphaVantage, so I saw a gap in the market. 

After searching GitHub I found the [AlphaVantage.jl](https://github.com/ellisvalentiner/AlphaVantage.jl) repository that was two years out
of date, but had the bare bones of functionality that I knew I would
be able to build upon. I forked the project, brought it up to date
with all the AlphaVantage functions and have now released it to the
world in the Julia registry. You can easily install the package just
like any other Julia package using `Pkg.add("AlphaVantage")`.

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

This blog post will detail all the different function available and
illustrate how you can pull the data, massage it into a nice format
and plot using the typical Julia tools. 

## Available Functionality from AlphaVantage

1.  Stock data at both intraday, daily, weekly and monthly
frequencies.
2. Technical indicators for stocks.
3. FX rates at both intraday, daily, weekly and monthly frequencies.
4. Crypto currencies, again, at the intraday, daily, weekly and monthly
time scales.

So jump into the section that interests you.

The package is designed to replicate the API functions from the
[AlphaVantage documentation](https://www.alphavantage.co/documentation/),
so you can look up any of the functions there and find the
equivalent in this Julia package. If I've missed any or one isn't
working correctly, raise on issue on Github
[here](https://github.com/ellisvalentiner/AlphaVantage.jl).

These are the Julia packages I use in this blog post:

```julia
using AlphaVantage
using DataFrames
using DataFramesMeta
using Dates
using Plots
```

Plus we define some helper functions to convert between the raw
data and Julia dataframes. 

```julia
function raw_to_dataframe(rawData)
    df = DataFrame(rawData[1])
    dfNames = Symbol.(vcat(rawData[2]...))
    df = rename(df, dfNames)

    df.Date = Date.(df.timestamp)
    for x in (:open, :high, :low, :close, :adjusted_close, :dividend_amount)
        df[!, x] = Float64.(df[!, x])
    end 
    df.volume = Int64.(df.volume)
    return df
end

function intra_to_dataframe(rawData)
    df = DataFrame(rawData[1])
    dfNames = Symbol.(vcat(rawData[2]...))
    df = rename(df, dfNames)

    df.DateTime = DateTime.(df.timestamp, "yyyy-mm-dd HH:MM:SS")
    for x in (:open, :high, :low, :close)
        df[!, x] = Float64.(df[!, x])
    end 
    df.volume = Int64.(df.volume)
    return df
end
```

## Stock Market Data

AlphaVantage provides daily, weekly and monthly historical stock data from 2000 right up to when you call the function. With the `adjusted` functions you also get dividends and adjusted closing prices to account for these dividends. 


```julia
tslaRaw = AlphaVantage.time_series_daily_adjusted("TSLA", outputsize="full", datatype="csv")
tsla = raw_to_dataframe(tslaRaw);
first(tsla, 5)
```

<table class="data-frame"><thead><tr><th></th><th>timestamp</th><th>open</th><th>high</th><th>low</th><th>close</th><th>adjusted_close</th><th>volume</th><th>dividend_amount</th></tr><tr><th></th><th>Any</th><th>Float64</th><th>Float64</th><th>Float64</th><th>Float64</th><th>Float64</th><th>Int64</th><th>Float64</th></tr></thead><tbody><p>5 rows × 10 columns (omitted printing of 2 columns)</p><tr><th>1</th><td>2020-06-29</td><td>969.01</td><td>1010.0</td><td>948.52</td><td>1009.35</td><td>1009.35</td><td>8871356</td><td>0.0</td></tr><tr><th>2</th><td>2020-06-26</td><td>994.78</td><td>995.0</td><td>954.87</td><td>959.74</td><td>959.74</td><td>8854908</td><td>0.0</td></tr><tr><th>3</th><td>2020-06-25</td><td>954.27</td><td>985.98</td><td>937.15</td><td>985.98</td><td>985.98</td><td>9254549</td><td>0.0</td></tr><tr><th>4</th><td>2020-06-24</td><td>994.11</td><td>1000.88</td><td>953.141</td><td>960.85</td><td>960.85</td><td>10959593</td><td>0.0</td></tr><tr><th>5</th><td>2020-06-23</td><td>998.88</td><td>1012.0</td><td>994.01</td><td>1001.78</td><td>1001.78</td><td>6365271</td><td>0.0</td></tr></tbody></table>




```julia
plot(tsla.Date, tsla.open, label="Open", title="TSLA Daily")
```




![Daily TSLA Prices from AlphaVantage](/assets/alphavantage_files/output_6_0.svg
 "Daily TSLA Prices from AlphaVantage")

Here is the Tesla daily opening stock price. 

## Intraday Stock Data

What separates AlphaVantage from say google or yahoo finance data is the intraday data. They provide high frequency bars at intervals from 1 minute to an hour. The only disadvantage is that the maximum amount of data appears to be 5 days for a stock. Still better than nothing!


```julia
tslaIntraRaw = AlphaVantage.time_series_intraday("TSLA", "1min", outputsize="full", datatype="csv");
tslaIntra = intra_to_dataframe(tslaIntraRaw)
tslaIntraDay = @where(tslaIntra, :DateTime .> DateTime(today()-Day(1)))
subPlot = plot(tslaIntraDay.DateTime, tslaIntraDay.open, label="Open", title="TSLA Intraday $(today()-Day(1))")
allPlot = plot(tslaIntra.DateTime, tslaIntra.open, label="Open", title = "TSLA Intraday")
plot(allPlot, subPlot, layout=(1,2))
```

![Intraday TSLA Prices from AlphaVantage](/assets/alphavantage_files/output_10_0.svg
 "Intraday TSLA Prices from AlphaVantage")

## Stock Technical Indicators

AlphaVantage also provide a wide range of technical indicators, the
most of which I don't understand and will probably never use. But,
they provide them, so I've written an interface for them. In this
example I'm using the Relative Strength Index.


```julia
rsiRaw = AlphaVantage.RSI("TSLA", "1min", 10, "open", datatype="csv");
rsiDF = DataFrame(rsiRaw[1])
rsiDF = rename(rsiDF, Symbol.(vcat(rsiRaw[2]...)))
rsiDF.time = DateTime.(rsiDF.time, "yyyy-mm-dd HH:MM:SS")
rsiDF.RSI = Float64.(rsiDF.RSI);

rsiSub = @where(rsiDF, :time .> DateTime(today() - Day(1)));
plot(rsiSub[!, :time], rsiSub[!, :RSI], title="TSLA")
hline!([30, 70], label=["Oversold", "Overbought"])
```

![RSI Values from AlphaVantage](/assets/alphavantage_files/output_15_0.svg
 "RSI Values from AlphaVantage")

In this case, adding the threshold lines make a nice channel that the value falls between. 

## Sector Performance

AlphaVantage also provides the sector performance on a number of timescales through one API call. 


```julia
sectorRaw = AlphaVantage.sector_performance()
sectorRaw["Rank F: Year-to-Date (YTD) Performance"]
```

    Dict{String,Any} with 11 entries:
      "Health Care"            => "-3.46%"
      "Financials"             => "-25.78%"
      "Consumer Discretionary" => "4.79%"
      "Materials"              => "-9.33%"
      "Consumer Staples"       => "-7.80%"
      "Energy"                 => "-38.38%"
      "Real Estate"            => "-11.37%"
      "Information Technology" => "12.06%"
      "Utilities"              => "-12.96%"
      "Communication Services" => "-2.26%"
      "Industrials"            => "-16.05%"



Great year for IT, not so great for energy. 

## Forex Market Data

Moving onto the foreign exchange market, again, AlphaVantage provide multiple time scales and many currencies.


```julia
eurgbpRaw = AlphaVantage.fx_weekly("EUR", "GBP", datatype="csv");
eurgbp = DataFrame(eurgbpRaw[1])
eurgbp = rename(eurgbp, Symbol.(vcat(eurgbpRaw[2]...)))
eurgbp.Date = Date.(eurgbp.timestamp)
eurgbp.open = Float64.(eurgbp.open)
eurgbp.high = Float64.(eurgbp.high)
eurgbp.low = Float64.(eurgbp.low)
eurgbp.close = Float64.(eurgbp.close)
plot(eurgbp.Date, eurgbp.open, label="open", title="EURGBP")
```

![AlphaVantage Weekly FX Data](/assets/alphavantage_files/output_25_0.svg
 "AlphaVantage Weekly FX Data")

Which looks great for a liquid currency like EURGBP, but they have a whole host of currencies so don't limit yourself to just the basics, explore some NDF's. 


```julia
usdkrwRaw = AlphaVantage.fx_monthly("USD", "KRW", datatype="csv");
usdkrw = DataFrame(usdkrwRaw[1])
usdkrw = rename(usdkrw, Symbol.(vcat(usdkrwRaw[2]...)))
usdkrw.Date = Date.(usdkrw.timestamp)
usdkrw.open = Float64.(usdkrw.open)
usdkrw.high = Float64.(usdkrw.high)
usdkrw.low = Float64.(usdkrw.low)
usdkrw.close = Float64.(usdkrw.close)
plot(usdkrw.Date, usdkrw.open, label="open", title="USDKRW")
```

![AlphaVantage Monthly FX Data](/assets/alphavantage_files/output_28_0.svg
 "AlphaVantage Monthly FX Data")

Although I'm not sure exactly what they are providing here, be it a
spot price or a 1 month forward that is more typical for NDFs. 

## FX Intraday Data

Again, intraday data is available for the FX pairs. 

```julia
usdcadRaw = AlphaVantage.fx_intraday("USD", "CAD", datatype="csv");
usdcad = DataFrame(usdcadRaw[1])
usdcad = rename(usdcad, Symbol.(vcat(usdcadRaw[2]...)))
usdcad.timestamp = DateTime.(usdcad.timestamp, "yyyy-mm-dd HH:MM:SS")
usdcad.open = Float64.(usdcad.open)
plot(usdcad.timestamp, usdcad.open, label="Open", title="USDCAD")
```

![Alphva Vantage Intraday FX Data](/assets/alphavantage_files/output_33_0.svg
 "Alphva Vantage Intraday FX Data")

## Crypto Market Data

Now for digital currencies. The API follows the same style as traditional currencies and again has more digital currencies than you can shake a stick at. Again daily, weekly and monthly data is available plus a 'health-index' monitor that reports how healthy a cryptocurrency is based on different features.


```julia
ethRaw = AlphaVantage.digital_currency_daily("ETH", "USD", datatype="csv")
ethHealth = AlphaVantage.crypto_rating("ETH");
titleString = ethHealth["Crypto Rating (FCAS)"]
```

    Dict{String,Any} with 9 entries:
      "7. utility score"         => "972"
      "9. timezone"              => "UTC"
      "1. symbol"                => "ETH"
      "2. name"                  => "Ethereum"
      "4. fcas score"            => "957"
      "5. developer score"       => "964"
      "6. market maturity score" => "843"
      "8. last refreshed"        => "2020-06-29 00:00:00"
      "3. fcas rating"           => "Superb"



The health rating looks like that, four scores, a qualitative rating
and some meta information.  The price charts look like as you would expect. 


```julia
eth = DataFrame(ethRaw[1])
eth = rename(eth, Symbol.(vcat(ethRaw[2]...)), makeunique=true)
eth.Date = Date.(eth.timestamp)
eth.Open = Float64.(eth[!, Symbol("open (USD)")])

plot(eth.Date, eth.Open, label="Open", title = "Ethereum")
```

![ETH Daily Prices from AlphaVantage](/assets/alphavantage_files/output_39_0.svg
 "ETH Daily Prices from AlphaVantage")

## Conclusion

If you've ever wanted to explore financial timeseries you can't really
do much better than using AlphaVantage. So go grab yourself an API
key, download this package and see if you can work out what Hilbert
transform, dominant cycle phase (`HT_DCPHASE` in the package) represents for a stock! 

Be sure to checkout my other tutorials for AlphaVantage:

* [Fundamental Stock Data from AlphaVantage.jl](https://dm13450.github.io/2021/01/01/Fundamental-AlphaVantage.html)
* [Crypto Data using AlphaVantatge.jl](https://dm13450.github.io/2021/03/27/CryptoAlphaVantage.html)
* [Economic Indicators from AlphaVantage](https://dm13450.github.io/2021/11/08/AlphaVantage-Economic-Indicators.html)
