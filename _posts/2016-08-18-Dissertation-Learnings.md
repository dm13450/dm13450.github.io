---
layout: post
title: Dissertation Construction Learnings 
date: 16/08/17
---

With my dissertation handed in it is time to reflect on what I've learnt in terms from constructing the 20,000 word file. 

Firstly, the importance of having an established workflow. If I was to calculate how my time was divided in writing my dissertation an unfortunate amount of time would have been dedicated to collating the many graphs that my work produced. I didn't have dedicated functions outputting graphs ready to be saved into hard copies at later dates. Instead, I had a variety of functions that produced the results, but using different methods, different representations and different formats. Therefore, for my future work, every time I produce new results which leads to new graphs I need to have functions that can easily output the appropriate data when needed. 

Secondly, my interweaving of Tikz and LaTeX lead to a few troubles. Mainly due to the size of the graphs and lack of available memory for Latex when compiling. My previous method of importing the raw .tex files of the graphs will need to be changed such that all the .tex files are compiled into pdf's before being imported into Latex. This will also lead to quicker compile times for my Latex document. At some points I was seeing compile times of >5 minutes! 

The use of tables and summarising the final results also lead to some troubles. Copying and pasting the results from the R output to the latex document was not the most efficient use and led to frequent updating each time the results were updated. The solution to this is slightly trickier. Perhaps an interwoven use of RMarkdown and Latex could solve this problem. But at the minute it remains unsolved. 

In an attempt to develop a better workflow I've taken to use RMarkdown to construct my research in a more verbose way. This allows me to write around code and output the results straight away without having to translate between R and latex. So far it seems to be working nicely but I've yet to try and output to latex. 

Overall, the process of writing my dissertation has shown the importance in establishing good techniques in outputting the results you find and not just focusing on getting the results. With these learnings I'll be in good preparation for my next dissertation-like project. 

RMarkdown: <http://rmarkdown.rstudio.com/ > 
