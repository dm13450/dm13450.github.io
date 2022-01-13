---
layout: post
title: Fitting Mixed Effects Models - Python, Julia or R?
tags:
  - python
  - R
  - julia
---

I'm benchmarking how long it takes to fit a mixed
effects model using `lme4` in R, `statsmodels` in Python, plus
showing how `MixedModels.jl` in Julia is also a viable option.

<p></p>

***
Enjoy these types of posts? Then you should sign up for my newsletter. It's a short monthly recap of anything and everything I've found interesting recently plus
any posts I've written. So sign up and stay informed!

<p>
<form
	action="https://buttondown.email/api/emails/embed-subscribe/dm13450"
	method="post"
	target="popupwindow"
	onsubmit="window.open('https://buttondown.email/dm13450', 'popupwindow')"
	class="embeddable-buttondown-form">
	<label for="bd-email">Enter your email</label>
	<input type="email" name="email" id="bd-email" />
	<input type="hidden" value="1" name="embed" />
	<input type="submit" value="Subscribe" />
</form>
</p>

***

<p></p>

Data science is always up for debating whether R or Python is the better
language when it comes to analysing some data. Julia has been
making its case as a viable alternative as well. In most cases you can
perform a task in all three with a little bit of syntax
adjustment, so no need for any real commitment.  Yet, I've
recently been having performance issues in R with a mixed model.

I have a dataset with 1604 groups for a random effect that has been
grinding to a halt when fitting in R using `lme4`. The team at `lme4`
have a vignette titled
[performance tips](https://cran.r-project.org/web/packages/lme4/vignettes/lmerperf.html)
which at the bottom suggests using Julia to speed things up. So I've
taken it upon myself to benchmark the basic model-fitting performances
to see if there is a measurable difference. You can use this post as
an example of fitting a mixed effects model in Python, R and Julia.

## The Setup

In our first experiment, I am using the [palmerspenguins](https://allisonhorst.github.io/palmerpenguins/) dataset to
fit a basic linear model. I've followed the most basic method in all
three languages, using what the first thing in Google
displays.

The dataset has 333 observations with 3 groups for the random effects
parameter.

I'll make sure all the parameters are close across the three
languages before benchmarking the performance, again, using what
Google says is the best approach to time some code.

I'm running everything on a Late 2013 Macbook. 2.6GHz i5 with 16GB of
RAM. I'm more than happy to repeat this on an M1 Macbook if someone is
willing to sponsor the purchase!

Now onto the code. 

## Mixed Effects Models in R with lme4

We will start with R as that is where the dataset comes from. Loading
up the `palmerspenguins` package and filtering out the NaN in the
relevant columns provide a consistent dataset for the other
languages. 

* R - 4.1.0
* lme4 - 1.1-27.1

```r
require(palmerpenguins)
require(lme4)
require(microbenchmark)

testData <- palmerpenguins::penguins %>%
                    drop_na(sex, species, island, bill_length_mm)
lmer(bill_length_mm ~ (1 | species) + sex + 1,  testData)
```
* Intercept - 43.211
* sex:male - 3.694
* species variance - 29.55 

This `testData` gets saved as a csv for the rest of the languages
to read and use in the benchmarking.

To benchmark the function I use the
[microbenchmark](https://github.com/joshuaulrich/microbenchmark)
package. It is an excellent and lightweight way of quickly working out
how long a function takes to run. 

```r
microbenchmark(lmer(bill_length_mm ~ (1 | species) + sex + 1,  testData), times = 1000)
```

This outputs the relevant quantities of the benchmarking times.


## Mixed Effects Models Python with statsmodels

The Python syntax for fitting these types of models is similar to R.

* Python 3.9.4
* statmodels 0.13.1

```python
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf
import timeit as tt

modelData = pd.read_csv("~/Downloads/penguins.csv")

md = smf.mixedlm("bill_length_mm  ~ sex + 1", modelData, groups=modelData["species"])
mdf = md.fit(method=["lbfgs"])
```

Which gives us parameter values:

* Intercept - 43.211
* sex:male - 3.694
* Species variance: 29.496

When we benchmark the code, we define a specific function and
repeatedly run it 10000 times. This is all contained in the `timeit`
module, part of the Python standard library. 

```python
def run():
    md = smf.mixedlm("bill_length_mm  ~ sex + 1", modelData, groups=modelData["species"])
    mdf = md.fit(method=["lbfgs"])

times = tt.repeat('run()', repeat = 10000, setup = "from __main__ import run", number = 1)
```

We'll be taking the mean, median and, range of the `times` array. 

## Mixed Effects Models in Julia with MixedModels.jl

* Julia 1.6.0
* MixedModels 4.5.0

Julia follows the R syntax very closely, so this needs little
explanation. 

```julia
using DataFrames, DataFramesMeta, CSV, MixedModels
using BenchmarkTools

modelData = CSV.read("/Users/deanmarkwick/Downloads/penguins.csv",
                                     DataFrame)

m1 = fit(MixedModel, @formula(bill_length_mm ~ 1 + (1|species) + sex), modelData)
```

* Intercept - 43.2
* sex:male coefficient - 3.694
* group variance of - 19.68751

We notice that the variance in the intercept here is different
compared to the previous methods. Julia uses maximum likelihood by
default whereas R and Python default to REML (Restricted Maximum
Likelihood) for fitting the models. As the dataset only has three
groups, (there are three penguin species) then these methods will
start to produce different results, as we can see. Thanks to Phillip
Alday and Reddit user PuppySteaks for pointing this out. For more info
you can read Phillip's comment on the [differences between ML and REML](https://github.com/dm13450/dm13450.github.io/issues/9).


We use the
[BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
package to run the function 10,000 times.

```julia
@benchmark fit(MixedModel, @formula(bill_length_mm ~ 1 + (1|species) + sex), $modelData)
```

As a side note, if you run this benchmarking code in a Jupyter
notebook, you get this beautiful output from the BenchmarkTools
package. Gives you a lovely overview of all the different metrics and
the distribution on the running times. 

![Julia benchmarking screenshot](/assets/mm_benchmark.png "Julia
 BenchmarkTools screenshot"){: .center-image}


## Timing Results

All the parameters are close enough, how about the running times?

In milliseconds:

| Language  | Mean   | Median   | Min   | Max   |
|---|---|---|---|---|
| Julia  | 0.482  | 0.374  | 0.320   | 34   |
| Python   | 340     | 260  | 19   | 1400   |
|  R | 29.5   | 24.5  | 20.45  | 467   |

Julia blows both Python and R out of the water. About 60 times
faster.

I don't think Python is that slow in practice, I think it is more of
an artefact of the benchmarking code that doesn't behave in the
same way as Julia and R.

## What About Bigger Data and More Groups?

What if we increased the scale of the problem and also the number of
groups in the random effects parameters?

I'll now fit a Poisson mixed model to some football data. I'll
be modeling the goals scored by each team as a Poisson variable, with
a fixed effect of whether the team played at home or not and random
effects for the team and another random effect of the opponent.

This new data set is from
[football-data.co.uk](https://www.football-data.co.uk/) and has 98,242
rows with 151 groups in the random effects. Much bigger than the
Palmer Penguins dataset. 

Now, poking around the `statsmodels` documentation, there doesn't
appear to be a way to fit this model in a frequentist
way. The closest is the `PoissonBayesMixedGLM`, which isn't comparable
to the R/Julia methods. So in this case we will be dropping Python
from the analysis. If I'm wrong, please let me know in the comments
below and I'll add it to the benchmarking. 

With generalised linear models in both R and Julia, there are
additional parameters to help speed up the fitting but at the expense of
the parameter accuracy. I'll be testing these parameters to judge how
much of a tradeoff there is between speed and accuracy.

### R

The basic mixed-effects generalised linear model doesn't change much from the
above in R.

```r
glmer(Goals ~ Home + (1 | Team) + (1 | Opponent), data=modelData, family="poisson")
```

The documentation states that you can pass `nAGQ=0` to speed up the
fitting process but might lose some accuracy. So our fast version of
this model is simply:

```r
glmer(Goals ~ Home + (1 | Team) + (1 | Opponent), data=modelData, family="poisson", nAGQ = 0)
```
### Julia

Likewise for Julia hardly any difference in fitting this type of Poisson model.

```julia
fit(MixedModel, @formula(Goals ~ Home + (1 | Team) + (1 | Opponent)), footballData, Poisson())
```

And even mode simply, there is a `fast` parameter to use which speeds
up the fitting.

```julia
fit(MixedModel, @formula(Goals ~ Home + (1 | Team) + (1 | Opponent)), footballData, Poisson(), fast = true)
```


### Big Data Results

Let's check the fitted coefficients. 

| Method | Intercept | Home | $$\sigma _\text{Team}$$ | $$\sigma_\text{Opponent}$$ |
| --- | --- | --- | --- | --- | 
R slow | 0.1345 | 0.2426 | 0.2110 | 0.2304 | 
R fast| 0.1369| 0.2426|   0.2110 | 0.2304 |
Julia slow | 0.13455| 0.242624| 0.211030 | 0.230415 |
Julia fast | 0.136924| 0.242625| 0.211030| 0.230422 |

The parameters are all very similar, showing that for this parameter
specification the different speed flags do not change the coefficient
results, which is good. But for any specific model, you should verify
on a subsample at least to make sure the flags don't change anything. 

Now, what about speed. 

| Language  | Additional Parameter | Mean   | Median   | Min   | Max   |
|---|---|---|---|---|
| Julia  | - | 11.151  | 10.966  | 9.963 | 16.150 |
| Julia  | `fast=true` | 5.94| 5.924 | 4.98 | 8.15 |
|  R | - | 35.4 | 33.12 | 24.33 | 66.48 | 
|  R | `nAGQ=0` | 8.06  | 7.99  | 7.37  | 9.56   |

So setting `fast=true` gives a 2x speed boost in Julia which is
nice. Likewise, setting `nAGQ=0` in R improves the speed by almost 3x over
the default. Julia set to `fast = true` is the quickest, but I'm
surprised that R can get close with its speed-up parameter.

## Conclusion

If you are fitting a large mixed-effects model with lots of groups
hopefully, this convinces you that Julia is the way forward. The syntax
for fitting the model is equivalent, so you can do all your
preparation in R before importing the data into Julia to do the model
fitting. 

