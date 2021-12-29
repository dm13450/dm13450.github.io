---
layout: post
title: Fundamental Stock Data from AlphaVantage.jl
date: 2021-01-01
tags:
  -julia
---

AlphaVantage recently made fundamental data for stocks available through their
API and thanks to some new contributors to the `AlphaVantage.jl` Julia
package you can now easily import this data into your Julia project.

This fundamental data describes the underlying business information
about a company and is more fluid and open to interpretation than the
stock price. I'll run through each of the new functions and try and
explain what data it returns. 

The new data comes in through four different categories and functions:

* [Company Overview](#companyoverview)
* [Balance Sheet](#balancesheet)
* [Cash Flow](#cashflow)
* [Earnings](#earnings)

plus a listing status to see what stocks are active. 

The real value add though (if I do say so myself) comes from the
ability to pull out the annual or quarterly time series of a metric of
a stock easily and in a programatic manner. Using the metaprogramming
capabilities of Julia I was able to generate hundreds of functions
with just a for loop. Using these new functions you can now easily pull the quarterly revenue of Apple, cash flow from financing of Tesla or a timeseries of the current liabilities for Ford. 

```julia
using AlphaVantage
using DataFrames, DataFramesMeta, Dates
using Plots
```

## Listing Status

Firstly, we can get a list of stocks that are actively trading. 

```julia
listingData = AlphaVantage.listing_status()
stocks = DataFrame(listingData[1], :auto)
rename!(stocks, Symbol.(vec(listingData[2])))
first(stocks, 5)
```


<table class="data-frame"><thead><tr><th></th><th>symbol</th><th>name</th><th>exchange</th><th>assetType</th><th>ipoDate</th><th>delistingDate</th></tr><tr><th></th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th></tr></thead><tbody><p>5 rows × 7 columns (omitted printing of 1 columns)</p><tr><th>1</th><td>A</td><td>Agilent Technologies Inc</td><td>NYSE</td><td>Stock</td><td>1999-11-18</td><td>null</td></tr><tr><th>2</th><td>AA</td><td>Alcoa Corp</td><td>NYSE</td><td>Stock</td><td>2016-11-01</td><td>null</td></tr><tr><th>3</th><td>AAA</td><td>AAF First Priority CLO Bond ETF</td><td>NYSE ARCA</td><td>ETF</td><td>2020-09-09</td><td>null</td></tr><tr><th>4</th><td>AAAU</td><td>Goldman Sachs Physical Gold ETF</td><td>NYSE ARCA</td><td>ETF</td><td>2018-08-15</td><td>null</td></tr><tr><th>5</th><td>AACG</td><td>ATA Inc</td><td>NASDAQ</td><td>Stock</td><td>2008-01-29</td><td>null</td></tr></tbody></table>


Over 9000 stocks and ETF's are listed. Which you can then do some simple sorting to look at the oldest listed stocks.

```julia
first(sort!(stocks, :ipoDate), 5)
```


<table class="data-frame"><thead><tr><th></th><th>symbol</th><th>name</th><th>exchange</th><th>assetType</th><th>ipoDate</th><th>delistingDate</th></tr><tr><th></th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th></tr></thead><tbody><p>5 rows × 7 columns (omitted printing of 1 columns)</p><tr><th>1</th><td>BA</td><td>Boeing Company</td><td>NYSE</td><td>Stock</td><td>1962-01-02</td><td>null</td></tr><tr><th>2</th><td>CAT</td><td>Caterpillar Inc</td><td>NYSE</td><td>Stock</td><td>1962-01-02</td><td>null</td></tr><tr><th>3</th><td>DD</td><td>DuPont de Nemours Inc</td><td>NYSE</td><td>Stock</td><td>1962-01-02</td><td>null</td></tr><tr><th>4</th><td>DIS</td><td>Walt Disney Co (The)</td><td>NYSE</td><td>Stock</td><td>1962-01-02</td><td>null</td></tr><tr><th>5</th><td>GE</td><td>General Electric Company</td><td>NYSE</td><td>Stock</td><td>1962-01-02</td><td>null</td></tr></tbody></table>


When googling some of these stocks though, the IPO date doesn't appear to be 100% correct. General Electric became a public company in 1896! 


```julia
@where(stocks, :symbol .== "AAPL")
```


<table class="data-frame"><thead><tr><th></th><th>symbol</th><th>name</th><th>exchange</th><th>assetType</th><th>ipoDate</th><th>delistingDate</th><th>status</th></tr><tr><th></th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th><th>Any</th></tr></thead><tbody><p>1 rows × 7 columns</p><tr><th>1</th><td>AAPL</td><td>Apple Inc</td><td>NASDAQ</td><td>Stock</td><td>1980-12-12</td><td>null</td><td>Active</td></tr></tbody></table>



They have correctly recorded Apple's IPO date though, so it might just
be something about older stocks, or something else I am missing. 

## Company Overview {#companyoverview}

The first new function is `company_overview` which does what it says
on the tin. 

```julia
co = AlphaVantage.company_overview("AAPL", datatype = "json")
```

    Dict{String,Any} with 59 entries:
      "SharesOutstanding"          => "17102499840"
      "ExDividendDate"             => "2020-11-06"
      "52WeekLow"                  => "52.8225"
      "ReturnOnEquityTTM"          => "0.7369"
      "LatestQuarter"              => "2020-09-30"
      "200DayMovingAverage"        => "111.2946"
      "EVToEBITDA"                 => "27.9399"
      "RevenuePerShareTTM"         => "15.82"
      "Beta"                       => "1.2976"
      "Sector"                     => "Technology"
      "ForwardAnnualDividendYield" => "0.0062"
      "Exchange"                   => "NASDAQ"
      "PercentInsiders"            => "0.066"
      "QuarterlyEarningsGrowthYOY" => "-0.023"
      "Currency"                   => "USD"
      "EBITDA"                     => "77343997952"
      "ShortRatio"                 => "1"
      "DividendYield"              => "0.0062"
      "AnalystTargetPrice"         => "127.11"
      "DilutedEPSTTM"              => "3.28"
      "BookValue"                  => "3.849"
      "LastSplitDate"              => "2020-08-31"
      "SharesFloat"                => "16984460162"
      "PriceToSalesRatioTTM"       => "8.4207"
      "FullTimeEmployees"          => "147000"

Here we get a dictionary with 59 different metrics about the company. There are lots of different quantitate and qualitative values about the company in question and provides a useful overview. 

## Income Statement {#incomestatement}

The income statement summarises a companies revenues and expenses. In short it shows where the money was coming in (revenue) and where it was going out (expenses).

```julia
is = AlphaVantage.income_statement("AAPL", datatype = "json")
```

    Dict{String,Any} with 3 entries:
      "annualReports"    => Any[Dict{String,Any}("incomeTaxExpense"=>"9680000000","…
      "symbol"           => "AAPL"
      "quarterlyReports" => Any[Dict{String,Any}("incomeTaxExpense"=>"2228000000","…


Both the annual and quarterly results come back. For the annual reports there are the last 5 years. For the quarterly reports, the last 21 quarters.   


```julia
keys(is["annualReports"][1])
```

    Base.KeySet for a Dict{String,Any} with 29 entries. Keys:
      "incomeTaxExpense"
      "reportedCurrency"
      "otherNonOperatingIncome"
      "minorityInterest"
      "discontinuedOperations"
      "incomeBeforeTax"
      "totalOtherIncomeExpense"
      "interestIncome"
      "researchAndDevelopment"
      "grossProfit"
      "totalRevenue"
      "otherOperatingExpense"
      "taxProvision"
      "extraordinaryItems"
      "ebit"
      "otherItems"
      "netIncomeApplicableToCommonShares"
      "totalOperatingExpense"
      "costOfRevenue"
      "fiscalDateEnding"
      "interestExpense"
      "sellingGeneralAdministrative"
      "operatingIncome"
      "netIncomeFromContinuingOperations"
      "netIncome"
      ⋮




```julia
extrema(Date.(get.(is["annualReports"], "fiscalDateEnding", "")))
```




    (Date("2016-09-30"), Date("2020-09-30"))




```julia
extrema(Date.(get.(is["quarterlyReports"], "fiscalDateEnding", "")))
```




    (Date("2015-09-30"), Date("2020-09-30"))



Then what I have done is written the functions that allow you to extract any of the fields on a quarterly or annual basis. Which means you can easily plot some graphs and summarise the results. 


```julia
totalRevenue = AlphaVantage.totalRevenue_quarterlys("AAPL", datatype =
"json")
plot(Date.(totalRevenue[:Date]), 
     parse.(Float64, totalRevenue[:totalRevenue]) ./ 1e9, 
     label = "Revenue (billions)",
     title = "Apple")
```

![Apple Total Revenue](/assets/fundamental/output_23_0.svg "Apple Total Revenue")

Here we have Apple quarterly total revenue, with a predictable pattern peaking in the first quarter. 

## Balance Sheet {#balancesheet}

A balance sheet summarises a companies assets, what it owns and its liabilities, what it owns to other people.


```julia
bs = AlphaVantage.balance_sheet("AAPL", datatype = "json")
```


    Dict{String,Any} with 3 entries:
      "annualReports"    => Any[Dict{String,Any}("totalPermanentEquity"=>"None","wa…
      "symbol"           => "AAPL"
      "quarterlyReports" => Any[Dict{String,Any}("totalPermanentEquity"=>"None","wa…


```julia
string.(keys(bs["quarterlyReports"][1]))
```

    51-element Array{String,1}:
     "totalPermanentEquity"
     "warrants"
     "negativeGoodwill"
     "preferredStockTotalEquity"
     "accumulatedAmortization"
     "inventory"
     "additionalPaidInCapital"
     "commonStockTotalEquity"
     "longTermInvestments"
     "fiscalDateEnding"
     "netTangibleAssets"
     "cashAndShortTermInvestments"
     "longTermDebt"
     ⋮
     "retainedEarnings"
     "shortTermInvestments"
     "propertyPlantEquipment"
     "goodwill"
     "preferredStockRedeemable"
     "totalLiabilities"
     "otherNonCurrentLiabilities"
     "currentLongTermDebt"
     "intangibleAssets"
     "accumulatedDepreciation"
     "otherCurrentLiabilities"
     "deferredLongTermAssetCharges"



Again, like the income statement, any of these keys can be extracted quarterly or annually. 


```julia
fCash = AlphaVantage.cashAndShortTermInvestments_quarterlys("F",
datatype = "json")
fLiabilities = AlphaVantage.totalLiabilities_quarterlys("F", datatype
= "json")
cashPlot = plot(Date.(fCash[:Date]), 
                parse.(Float64, fCash[:cashAndShortTermInvestments])/1e9, 
                label="Cash and Short Term Investments (billions)",
                colour = "green")
liabPlot = plot(Date.(fLiabilities[:Date]), 
                parse.(Float64, fLiabilities[:totalLiabilities])/1e9, 
                label="Total Liabilities (billions)")
plot(cashPlot, liabPlot)
```

![Ford Balance Sheet](/assets/fundamental/output_30_0.svg "Ford
 Balance Sheet")

As per the intro I've plotted Fords cash and short term investment balance against something the owe, the total liabilities. 

## Cash Flow {#cashflow}

The cash flow statement shows the changes in the balance sheet. It helps judge a companies ability to meet its cash needs, i.e. pay their employers or service their debt. 


```julia
cf = AlphaVantage.cash_flow("TSLA", datatype = "json")
```




    Dict{String,Any} with 3 entries:
      "annualReports"    => Any[Dict{String,Any}("cashflowFromInvestment"=>"-428900…
      "symbol"           => "AAPL"
      "quarterlyReports" => Any[Dict{String,Any}("cashflowFromInvestment"=>"5531000…




```julia
string.(keys(cf["quarterlyReports"][1]))
```




    24-element Array{String,1}:
     "cashflowFromInvestment"
     "changeInInventory"
     "reportedCurrency"
     "changeInAccountReceivables"
     "changeInCashAndCashEquivalents"
     "otherOperatingCashflow"
     "dividendPayout"
     "changeInReceivables"
     "capitalExpenditures"
     "changeInExchangeRate"
     "operatingCashflow"
     "cashflowFromFinancing"
     "changeInLiabilities"
     "stockSaleAndPurchase"
     "otherCashflowFromFinancing"
     "changeInOperatingActivities"
     "depreciation"
     "fiscalDateEnding"
     "changeInCash"
     "netBorrowings"
     "investments"
     "netIncome"
     "changeInNetIncome"
     "otherCashflowFromInvestment"




```julia
cashflow = AlphaVantage.cashflowFromFinancing_annuals("TSLA", datatype="json")

plot(Date.(cashflow[:Date]), 
     parse.(Float64, cashflow[:cashflowFromFinancing]) ./ 1e9, 
     label="Cash Flow from Financing (billions)",
     title = "Tesla")
```




![Tesla Cash Flow](/assets/fundamental/output_36_0.svg "Tesla Cash
 Flow")



## Earnings {#earnings}

Each company reports their earnings each quarter and summarise their performance of the previous quarter. There are more dates available for earnings, but also slightly different fields for the quarterly and annual results. 


```julia
earnings = AlphaVantage.earnings("AAPL", datatype = "json")
```




    Dict{String,Any} with 3 entries:
      "annualEarnings"    => Any[Dict{String,Any}("fiscalDateEnding"=>"2020-09-30",…
      "quarterlyEarnings" => Any[Dict{String,Any}("reportedDate"=>"2020-10-29","est…
      "symbol"            => "AAPL"




```julia
string.(keys(earnings["annualEarnings"][1]))
```




    2-element Array{String,1}:
     "fiscalDateEnding"
     "reportedEPS"




```julia
string.(keys(earnings["quarterlyEarnings"][1]))
```




    6-element Array{String,1}:
     "reportedDate"
     "estimatedEPS"
     "surprise"
     "surprisePercentage"
     "fiscalDateEnding"
     "reportedEPS"




```julia
extrema(Date.(get.(earnings["quarterlyEarnings"], "reportedDate", "")))
```




    (Date("1996-04-17"), Date("2020-10-29"))




```julia
extrema(Date.(get.(earnings["annualEarnings"], "fiscalDateEnding", "")))
```




    (Date("1996-09-30"), Date("2020-09-30"))




```julia
reported = AlphaVantage.reportedEPS_quarterlyEarnings("AAPL",
datatype="json")
plot(Date.(reported[:Date]), 
     parse.(Float64, reported[:reportedEPS]), 
     label="Reported EPS",
     title = "Apple")
```

![Apple Earnings](/assets/fundamental/output_44_0.svg "Apple Earnings")

There you go, lots more functions for the package and something
different than just looking at stock prices. This fundamental data
adds another dimension to any quantitate analysis of different stocks
so go grab your free API key from
[AlphaVantage](https://www.alphavantage.co/) and get exploring!

If you are new to AlphaVantage you can also check out my previous post
on [getting market data into Julia](https://dm13450.github.io/2020/07/05/AlphaVantage.html).
