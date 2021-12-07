---
layout: post
title: Converting an Edward Tutorial (Python) to Flux (Julia)
date: 2020-12-19
tags:
  -julia 
---

Edward is a probabilistic programming language like Stan, PyMC3
 and Turing.jl. You write a model out and can perform statistical
 inference on some data. Edward is a more 'machine learning' focused than Stan as
 you can build neural nets and all the fun, modern techniques that the cool kids
 are using. Flux.jl takes a similar 'machine learning' approach but this
 time in Julia. Flux can build neural nets and also much
 more. There is an intersection here between Edward and Flux, so it
 makes sense to think that you can perform similar tasks. That is the whole point of this blog post, translating this
 Edward tutorial: <http://edwardlib.org/getting-started> into Julia code
 for Flux. So anyone reading this can get an idea of:
 
* what Flux is all about,
* how the Python Edward code can be transformed into Julia,
* how to build a simple neural nets and infer the parameters in a Bayesian way. 

I'll start off by reproducing the model in Flux before calling on
Turing to do the Bayes bit. This is my first time writing about Flux,
so hopefully you'll find this useful if it is also your first foray into doing some machine learning in Julia. 


```julia
using Flux
using Plots
using Distributions
```

The original tutorial wants to learn the `cos` function of which we add some Gaussian noise.


```julia
f(x) = cos(x) + rand(Normal(0, 0.1))

xTrain = collect(-3:0.1:3)
yTrain = f.(xTrain)
plot(xTrain, yTrain, seriestype=:scatter, label="Train Data")
plot!(xTrain, cos.(xTrain), label="Truth")
```

![svg](/assets/edwardflux/output_4_0.svg)

To build the neural net we chain two dense layers with `tanh` nonlinearities inbetween the layers. We use the mean square error as our loss function which we minimise using gradient descent. This is the most basic way in which you can build and train the neural net. Directly replicating what Edward does comes later, for now we just want to get things working. 

With Flux you can specify what type of loss quite easily, with a list
of all that comes prepackaged found here
<https://fluxml.ai/Flux.jl/stable/models/losses>. But if none of those
take your fancy you can write your own and pass a simple Julia
function. 

```julia
model = Chain(Dense(1, 2, tanh), Dense(2, 1))
loss(x, y) = Flux.Losses.mse(model(x), y)
optimiser = Descent(0.1);
```

Likewise for the optimiser. I've chose gradient descent, but again,
you can switch it out for a more advanced approach, such as ADAM. See
if any of those listed here
<https://fluxml.ai/Flux.jl/stable/training/optimisers/> take your
fancy. 

In short, the neural net takes one value as an input, passes through to two nodes on the hidden layer with a `tanh` activation function before outputting a single value as the output. 

We now set up the training data. We take 100 random normal samples as our inputs, use our `f` function to generate the outputs and then repeat the dataset 100 times. 


```julia
x = rand(Normal(), 100)
y = f.(x)
train_data = Iterators.repeated((Array(x'), Array(y')), 100);
```

We train the model for 10 epochs.

```julia
Flux.@epochs 10 Flux.train!(loss, Flux.params(model), train_data, optimiser)
```

Which takes no time at all to complete. We now want to make sure the
results are sensible and it has actually learnt the underlying
function. 

```julia
yOut = zeros(length(xTrain))
for (i, x) in enumerate(xTrain)
    yOut[i] = model([xTrain[i]])[1]
end

plot(xTrain, yOut, label="Predicted")
plot!(xTrain, cos.(xTrain), label="True")
plot!(x, y, seriestype=:scatter, label="Data")
```

![svg](/assets/edwardflux/output_11_0.svg)

Everything looking good. Our neural net has found something similar to the true function, so hopefully you are convinced that we can now add a layer of complexity. Slight disagreement around the tails, but that is where we are lacking some data, so not too big of a deal. 

# The Same - But Bayes

All the above captured the spirit, but not the whole point of the
Edward tutorial, which is to create a *Bayesian* neural net. With a Bayesian neural net there is a probability distribution over the weights, rather than just singular values to maximise. In Julia, we have to call upon our old friend `Turing.jl`. The Turing team have written about Bayesian nets [here](https://turing.ml/dev/tutorials/3-bayesnn/). I've taken some of that code and shuffled it about for this application. 

```julia
using Turing
```

Firstly, have the parameters for each of the layers of the neural net. In total there are 6 parameters for the two layer model, so using the `unpack` function we take a vector of length 6 and break it up into the weights and biases for each layer which we then build in the `nn_forward` function. 

```julia
function unpack(nn_params::AbstractVector)
    W₁ = reshape(nn_params[1:2], 2, 1);   
    b₁ = reshape(nn_params[3:4], 2)
    
    W₂ = reshape(nn_params[4:5], 1, 2); 
    b₂ = [nn_params[6]]
    
    return W₁, b₁, W₂, b₂
end

function nn_forward(xs, nn_params::AbstractVector)
    W₁, b₁, W₂, b₂ = unpack(nn_params)
    nn = Chain(Dense(W₁, b₁, tanh), Dense(W₂, b₂))
    return nn(xs)
end
```

These utility functions mean that we are tearing down the neural net and rebuilding it with the new parameters with each iteration. `Turing` deals with finding the best parameters by doing the Bayesian sampling (see my previous [post](https://dm13450.github.io/2020/11/03/BayesPointProcess.html) on Hamilton MCMC sampling).

We think the 6 parameters of the neural net are drawn from a multivariate normal distribution and the parameters are all uncorrelated with each other. The observations are also from a normal distribution with mean from the neural net and variance $$\sigma$$.

```julia
alpha = 0.1
sig = sqrt(1.0 / alpha)

@model bayes_nn(xs, ys) = begin
    
    nn_params ~ MvNormal(zeros(6), sig .* ones(6)) #Prior
    
    preds = nn_forward(xs, nn_params) #Build the net
    sigma ~ Gamma(0.01, 1/0.01) # Prior for the variance
    for i = 1:length(ys)
        ys[i] ~ Normal(preds[i], sigma)
    end
end;
```

Model built, we now want to use the NUTS algorithm to sample from the
posterior. Again, like Flux, you can use other sampling methods such as HMC
or Metropolis-Hastings. 

```julia
N = 5000
ch1 = sample(bayes_nn(hcat(x...), y), NUTS(0.65), N);
ch2 = sample(bayes_nn(hcat(x...), y), NUTS(0.65), N);
```

We sample from posterior 5,000 times with two chains to check the convergence later. When selecting the final parameters we chose those that maximise the log posterior of the model. For each of the datapoints we add the prediction from the neural net. 

```julia
lp, maxInd = findmax(ch1[:lp])

params, _ = ch1.name_map
bestParams = map(x-> ch1[x].data[maxInd], params[1:6])
plot(x, cos.(x), seriestype=:line, label="True")
plot!(x, Array(nn_forward(hcat(x...), bestParams)'), 
      seriestype=:scatter, label="MAP Estimate")
```

![svg](/assets/edwardflux/output_22_0.svg)

We can also sample from this posterior distribution by looking at the different parameters from the sampling process. 

```julia
xPlot = sort(x)

sp = plot()

for i in max(1, (maxInd[1]-100)):min(N, (maxInd[1]+100))
    paramSample = map(x-> ch1[x].data[i], params)
    plot!(sp, xPlot, Array(nn_forward(hcat(xPlot...), paramSample)'), 
        label=:none, colour="blue")
    
end

plot!(sp, x, y, seriestype=:scatter, label="Training Data", colour="red")

sp
```

![svg](/assets/edwardflux/output_24_0.svg)

Again, looking sensible and representing the true underlying
function. Plus as we have done this using Bayes, we have a good
visualisation of the uncertainty of the model too. 

And then finally we can assess how the chains of the model look and make a judgement on whether they have converged.

```julia
lPlot = plot(ch1[:lp], label="Chain 1", title="Log Posterior")
plot!(lPlot, ch2[:lp], label="Chain 2")

sigPlot = plot(ch1[:sigma], label= "Chain 1", title="Variance")
plot!(sigPlot, ch2[:sigma], label="Chain 2")

plot(lPlot, sigPlot)
```

![svg](/assets/edwardflux/output_26_0.svg)

Both chains are looking like they have converged, so we can trust our sampling process. 

# Conclusion

I actually surprised myself with how easy it was to build and sample
from the neural net in a Bayesian manner. I originally thought that I
would only be able to replicate the model using frequentist methods,
but not the Bayes steps. This just goes to show what a great job the Turing.jl team have done, making the whole model building and sampling simple. 
So after reading this you can extended these models to bigger
and badder neural nets if that is what your problem needs. Easily swapping out
losses, optimisers and posterior sampling methods as needed.

This post also shows how easy it is to translate back and forth
between the different machine learning libraries and even programming
languages, although there is not too much of a difference between
Julia and Python. So if anyone out there is reading this trying to
decide on what language to pick up, I'd be biased and say Julia, but
really, you'll be fine with either one. 
