---
layout: post
title: Bulk Downloading from Turnitin using Python.
date: 2016-01-28
---

As a teaching assistant, occasionally I get assigned to marks a series of papers. This involves tediously searching for the students paper on the Turnitin app inside moodle before clicking a download button. When you've got 36 papers to download, this is far to much clicking and mouse movement. So I wrote a Python script to automate it. 

Firstly, I had to consider how the file was pulled from the server. Thankfully, it was a simple POST request with the paper id as one of the parameters. Using the FireFox addon Tamper, I was able to easily view and submit a custom post request. All it required was a session id and paper id. 

Moving onto Python, I used the urllib2 package to open the custom POST url. Then it was a case of writing the response to a pdf file. Extending this to 36 urls is as simple as looping through each line in a file. 

In Python-esque pseudo-code, this looks like:

~~~
for line in id_list:
    response = urllib2.urlopen(base_url + sessionid + paperid)
    pdf_file = write(response.read())
    pdf_file.close()
~~~
{: .language-python}

The simplicity of the urllib2 is what makes this short script so easy to construct and use. 

Future work would be to get the session id automatically rather than manually copying and pasting it in. 

On an unrelated note, looks like I need to fix the code formatting above. I'll save that for another day. 
