---
layout: post
title: Using QuestDB to Build a Crypto Trade Database in Julia
date: 2021-08-05
tags:
- julia
---

[QuestDB](https://questdb.io/) is a timeseries database that is well suited for financial
data. It is built with timestamps in mind both when storing the data
and also when getting the data out. This makes it the ideal candidate
as a storage system for crypto trades. 

You might have heard of [KDB](https://code.kx.com/q/learn/) (or q the language used to work in KDB)
which is a popular comercial timeseries database. You'll see it being
used all over the finance industry. Unfortunately KDB
costs money if you go beyond their personal license terms whereas
QuestDB is a free and also open source.

So this is a blog post on how to get started with QuestDB. We will be
connecting to Coinbase WebSockets in Julia to download trades that
will be stored in a QuestDB table.

***
Enjoy these types of post? Then you should sign up to my newsletter. It's a short monthly recap of anything and everything I've found interesting recently plus
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



I've written about getting data using [Coinbase's REST APIs](https://dm13450.github.io/2021/06/25/HighFreqCrypto.html) and
this WebSocket method is an alternative way to get the same
data. Using a WebSocket though has other benefits. With the REST API it is impolite to constantly query the endpoint to pull data in realtime. Plus you don't know when something has changed, you pull the data, compare it to what you know and then see if there has been an update. With a WebSocket, it just tells you when something has changed, like when a new trade has occurred. This makes it great for building up a database, you can just connect to the firehose and save down all the trades that are coming through. Open the flood gates rather than always asking if something had changed. 

Before we get started though you need to download and install QuestDB. As I'm on a Mac I downloaded it using Homebrew and started the process like `questdb start`.
You can get more information on downloading QuestDB [here](https://questdb.io/get-questdb/) for your system. 

The rest of the blog cost will walk you through the following steps.

* The Producer/Consumer pattern
* Using WebSockets in Julia
* Putting data into QuestDB

In part two, which I will post sometime next week, I will show you how
we get data out of the database and use some of the specialised
features for timeseries data. 

## The Producer/Consumer Pattern

I am setting the processes up using a programming pattern called
'product/consumer'. This means building one process that produces data and a separate process that can consume data. Having the two functions separate allows for a better scalability if you wanted to add in more exchanges or workers. It also means that there is a degree of independence between the two processes and reducing the coupling should make for an easier development experience. 

To set this up in Julia we need to create a `RemoteChannel` which is how the producer and consumer processes will comunicate. It will be filled up with the type `Trade` that we will also create. 


```julia
struct Trade
    id::String
    time::String
    price::Float64
    size::Float64
    side::Int64
    exchange::String
end

Trade() = Trade("", "", NaN, NaN, 0, "")

Base.isempty(x::Trade) = x.id == ""
```

After creating the struct we also add in the null creator function and also a method for checking whether a trade but overall it is a simple type that just contains the relevant information for each trade found. 

The `RemoteChannel` comes from the `Distributed` package. 


```julia
using Distributed

const trades = RemoteChannel(()->Channel{Trade}(500));
```

It can store 500 trades and we will fill it up by connecting to the CoinbasePro WebSocket feed. Any of the producer processes would be able to add to this `trades` channel if needed.

## WebSockets in Julia

A WebSocket needs a url and a call back function to run on the WebSocket. In our case we want to connect to the WebSocket, subscribe to the market data and parse the incoming messages. 

Parsing the message is simple. As it is a JSON object it gets converted to a Julia dictionary, so we can just pull the appropriate fields and parse them to number if needed. 

This can be accomplished as so: 


```julia
using JSON
using Dates
using WebSockets

coinbase_url = "wss://ws-feed.pro.coinbase.com"
coinbase_subscribe_string = JSON.json(Dict(:type=>"subscribe", 
                         :product_ids=>["BTC-USD"], 
                         :channels=>["ticker", "heartbeat"]))

function parse_coinbase_data(x)
    if (get(x, "type", "") == "heartbeat") || (haskey(x, "channels"))
        println("Worker $(myid()): Coinbase Heartbeat")
        return Trade()
    end
    
    ts = get(x, "time", "")
    
    side = get(x, "side", "")
    tradedprice = parse(Float64, get(x, "price", "NaN"))
    size = parse(Float64, get(x, "last_size", "NaN"))
    id = get(x, "trade_id", "")
    
    Trade(string(id), ts, tradedprice, size, lowercase(side) == "buy" ? 1 : -1, "Coinbase")
end

function save_coinbase_trades(coinbase_url, coinbase_subscribe_string)

    WebSockets.open(coinbase_url) do ws
        write(ws, coinbase_subscribe_string)
        data, success = readguarded(ws)
        println("Entering Loop")
        while true
            data, success = readguarded(ws)
            jdata = JSON.parse(String(data))
            clean_data = parse_coinbase_data(jdata)
            if !isempty(clean_data)
              put!(trades, clean_data)
            end
        end
    end
    
end
```

We subscribe to the ticker channel, which gives us trades as they occur and we also use the heartbeat channel to keep the WebSocket alive.

Once the message has been parsed and we have created a `Trade` object, we can then add it to the queue for the database writer to pick up and save down. 

This is finishes the producer part. We can now move onto the consumer process. 

## Getting Julia to Talk to QuestDB

We've connected to the WebSocket and our `RemoteChannel` is filling up. How do we get this into a database?. QuestDB exposes a socket (a normal socket not a WebSocket!) that Julia can connect to. So we simply connect to that exposed port and can send data to QuestDB. 

QuestDB uses the
[InfluxDB line protocol](https://questdb.io/docs/develop/insert-data#influxdb-line-protocol)
to ingest data. This is as easy as sending a string down the
connection and QuestDB does the parsing to place it into the database
table. This string needs to take on a specific format: 

`table, string_column=value, numeric_column_1=value, numeric_column_2=value timestamp`

We build this using an `IOBuffer` to incrementally add to the payload string. 

The timestamp is the number of nanoseconds since the UNIX epoch. The timestamp of the trade from Coinbase does have this precision, but unfortunately Julia `DateTime`'s do not support nanoseconds but the `Time` type does. So we have to be a bit creative. 

The timestamp looks like `2021-01-01T12:00:00.123456`. I split on the `.` to get the datetime up to seconds and the nanoseconds. The datetime gets easily parsed into epoch time which we get into nanoseconds since the epoch by multiplying by 1e9. For the nanoseconds, we right pad it with any 0 to makes sure it is 9 digits long and can then convert to nanoseconds. Then it is as simple as adding the two values together and using `@sprintf` to get the full integer number without scientific notation. 


```julia
using Printf

function parse_timestamp(ts::String)
    
    p1, p2 = split(ts, ".")
    
    ut = datetime2unix(DateTime(p1)) * 1e9
    ns = Nanosecond(rpad(chop(String(p2), tail=1), 9, "0"))
    
    @sprintf "%.0f" ut + ns.value 
end

function build_payload(x::Trade)
    buff = IOBuffer()
    write(buff, "coinbase_trades2,")
    write(buff, "exchange=$(getfield(x, :exchange)), ")
    for field in [:id, :price, :size]
        val = getfield(x, field)
        write(buff, "$(field)=$(val),")
    end
    write(buff, "side=$(getfield(x, :side)) ")
    
    tspretty = parse_timestamp(getfield(x, :time))
    
    write(buff, tspretty)
    write(buff, "\n")
    String(take!(buff))
end
```

The `build_payload` function takes in a trade and outputs a string to
write to QuestDB. We connect to port 9009 and continuously take trades
from the `trades` RemoteChannel and write it to the database. 


```julia
using Sockets
function save_trades_quest(trades)
    cs = connect("localhost", 9009)
    while true
        payload = build_payload(take!(trades))
        write(cs, (payload))
    end
    close(cs)
end
```

All pretty simple. The annoying thing is that it won't give any
indication as to whether it was successful in writing the file or
not. You can check by looking at the QuestDB web interface and seeing
if your value appears after querying the database or you can check the
QuestDB logs to see if any errors have been found. You'll find the logs at `/usr/local/var/questdb` on a Mac. 

Now we've got everything sorted we just need to get both processes
running. We will kick off the WebSocket process asynchronously so that is runs in the background and likewise, the `save_trades_quest` function so that it doesn't lock your computer up if you are running the code along side it. With scaling in mind, you could run both of these processes on different threads or cores if needed. But in this case, both processes are light enough to be ran asynchronously on the main thread. 


```julia
@async save_coinbase_trades(coinbase_url, coinbase_subscribe_string)
@async save_trades_quest(trades)
```

This is now saving down into the database every time a new trade is seen. If you go to `localhost:9000` you query the data and see how it is evolving. QuestDB uses SQL like equivalent and so you can write things like 

```sql
select * from coinbase_trades
```

and it will show you all the trades saved down so far. Or 

```sql
select min(timestamp), max(timestamp) from coinbase_trades
```

to see the earliest and latest timestamp in traditional SQL. Or using the timeseries database features: 

```sql
select * from coinbase_trades
latest by exchange
```

which will pull out the last timestamp. 

## Summary

That's the end of part 1. You should hopefully QuestDB installed and slowly filling up with trades from Coinbase now. In the next part, I'll show you how to connect to the database and pull the data to do some analysis. 

If you want something extra to do, why not try extending the program to pull in other cryptocurrencies, you'll want to edit the subscribe string and how each message is parsed. 
You can also connect to QuestDB using [Grafana](https://grafana.com/) and build out some dashboards to monitor the trades without needing any other code. 

Questions? Feedback? Comments? Let me know below! 

## Version Info

* QuestDB 6.0.4
* Julia 1.6


## Related Posts

* (QuestDB Part 2 - High Frequency Finance
(again!))[https://dm13450.github.io/2021/08/12/questdb-part2.html]
* (Order Flow Imbalance - A High Frequency Trading Signal)[https://dm13450.github.io/2022/02/02/Order-Flow-Imbalance.html]
