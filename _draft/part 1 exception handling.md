---
layout: post
title: "Powershell: Introduction to error handling theory, part 1"
date: 2017-03-10
tags: [PowerShell, Error Handling]
---

In every script that you write, you will have to consider how to handle errors. This is really important and can often be overlooked. It is always better to work this into the script as you write it instead of adding error handling after you are done.

This is the introduction to a mutipart series on Error handling.

* Error handling theory (this post)
* Defensive programing
* Testing for $null or empty
* Exception handling
* Excpetions indepth

# Two schools of thought

There are two differing approaches to error handling. I will call one approach defensive programming and the other is exception handling. These ideas are not exclusive to each other.

## Defensive programming

Defensive programming is about writing your code to mitigate all the known error conditions. This means that you test your inputs and system states before your code runs and often verify that it ran correctly. Each line assumes that the code before may have failed to run correctly. Testing for `$null` is faster than throwing and handling exceptions.

A defensive programmer will tend to shy away from throwing error that they feel are not needed. They are more often to use return codes on set functions and return `$null` when a get function fails. 

# Exception handling

Exception based error handling watches a section of code for errors and catches them when the code runs into a situation that it was not expecting. This is required when the code you are calling already uses exceptions to indicate errors. This is also very common when dealing with command over the network or working with COM objects. Catching an exception allows you to release any resource locks that you may be holding onto.

A programmer that embraces the use of exceptions can use them to give clean and clear information about failures when they happen. 

# The view from the community

The reality is that you will apply both approaches to your code. I feel that the PowerShell community at large encourages the use of exception handling. You wil find a lot more information and examples on that approach. In many cases, it is easier to use when you are introduced to error handling.

# My view on the topic

I am in the minority on this one, but I greatly prefer to write more defensive code. I would say that part of the reasoning is that I grew into PowerShell from other languages. I saw exception handling an expensive operation to be avoided. Old habits are hard to break. 

I am also not saying that I don't use any exception handling. I just minimize my use of them. 

Now that we have that out of the way, I can focus on the PowerShell for the rest of the series. 
