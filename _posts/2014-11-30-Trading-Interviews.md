---
layout: post 
title: "Prop Shop Interviews"
date: 14/11/30 
---

I thought I would try my hand at applying to a few proprietary trading firms in London. Having read Scott Pattersons books (Dark Pools and Quants) I felt like I had a decent grasp on the industry and felt that my skills from physics would set me up well for a trading job. 

What I didn't bank on was a minefield of an interview experience that involved calculator like tasks, running through matrix algebra and computer science terms that I had a 'brief skim over wikipedia' knowledge of. So here's a run down of both interviews for each company. 

The first one was an hour long, asked a few questions of my experience at UBS before jumping into the maths. 

>Consider a bag with 3 balls; each a different colour. You remove 2 balls, paint them one colour and replace the balls in the bag. What's the expected amount of moves before all the balls are the same colour?

My first instinct was to set up the transition matrix and take it from there. Points for correctly identifying that it was a Markov chain. 

I believed that the transition matrix would be a 3x3 matrix as there are three possible states that the bag could be in: 

- All the balls are different colours.
- One ball is a different colour to the other two. 
- All the balls are the same colour. 

This is correct, but not the 'smart' way to do. As the first move always takes the system from state 1 to state 2 you can simplify the matrix to just a 2x2 but remembering to add one to the average at the end.

Now to calculate the transition probabilities. If we call state 1 the state in which there are two of one colour and one of the other and state 2 as all balls the same colour. 

From state 1, there are two possibilities when drawing two balls. You pick two balls that are the same colour; this returns you too the same state. You chose two different colour balls, if you paint them the same colour as the remaining one, then the system is in the final state. If you paint them one of the other two colours, then the system stays in the same state. 

This amounts to the probability of the system becoming fixed after one move:

$$P(\text{fixed}) = \frac{1}{3} \cdot \frac{1}{3} + \frac{1}{3} \cdot \frac{1}{3} = \frac{2}{9}$$ 

Therefore the expected number of transitions is the reciprocal of this fixation probability. BUT plus an extra one, due to the first move. 

Therefore the average number of transitions is:

$$N = \frac{9}{2} + 1 = \frac{11}{2} $$

The second question was to write a function that would reverse a linked list. This was a bit daunting seens as my familiarity with linked lists is next to none. But, in truth, I understand what pointers are, therefore a linked list isn't something too abstract. 

My first thought out loud ended up transpiring to reading the node pointers one by one into a new array and then returning the array. This is wrong, as the function then doesn't return a linked list explicitly, instead just a list of pointers. It then clicked that I was going to have to change what way the pointer was pointing for each element in the list and this would involve a temporary variable. However, my use of temporary variable on reflection was not correct and whilst in the process of writing this post I realise that my solution was very incorrect. 

For the second interview, the questions asked were much less involved and basic maths but where you had to invoke a few tricks. For example, $$41 \times 39$$ is daunting withouta calculator, or at least it was to me. However, it can be simplified to $$(40+1)(40-1) = 40 ^2 - 1 = 1599$$. After four questions were answered, I was then asked to estimate my confidence that I had answered them all correctly. I was 100% confident on 3 of them but less so on 1 other, therefore I believe a 75% confidence level would be sufficient.

Overall, both interviews have highlighted the skills needed to succeed in these types of interviews. Tautology, but both times I asked catheter the interviewer used any of the topics in their daily work. They said no.  
 





