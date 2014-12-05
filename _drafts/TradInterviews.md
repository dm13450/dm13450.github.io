---
layout: post 
title: "Prop Shop Interviews"
date: 30/11/14 
---

I thought I would try my hand at applying to a few propietry trading firms in London. Having read Scott Pattersons books (Dark Pools and Quants) I felt like I had a decent grasp on the industry and felt that my skills from physics would set me up well for a trading job. 

What I didn't bank on was a minefield of an interview experience that involved calculator like tasks, running thourgh matrix algebra and computer science terms that I had a 'brief skim over wikipedia' knowledge of. So here's a run down of both interviews for each company. 

The first one was an hour long, asked a few questions of my experience at UBS before jumping into the maths. 

Consider a bag with 3 balls; each a different colour. You remove 2 balls, paint them one colour and replace the balls in the bag. What's the expected amount of moves before all the balls are the same colour?

My first instinct was to set up the transition matrix and take it from there. Points for correctly identifying that it was a Markov chain. 

I believed that the transition matrix would be a 3x3 as there are possible states that the bag could be in. 




The second question was to write a function that would reverse a linked list. Which was a bit daunting seens as my familiraty with linked lists is next to none. But, in truth, I understand what pointers are, therefore a linked list isn't exactly something too abstract. 

My first thought outloud ended up traspiring to reading the node pointers one by one into a new array and then returning the array. This is wrong, as the function then doeesn't return a linked list explicity, instead just a list of pointers. It then clicked that I was going to have to change what way the pointer was pointing for each element in the list and this would involve a temporary variable. 

	while(node != null)

		list[i].node




