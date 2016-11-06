---
layout: post
title: "Introduction to Operational Validation"
date: 2016-11-04
tags: [Operational Validation]
---

A new trend this year in the Powershell community is Operational Validation. It is very easy to get lost in the tools when you are first introduced to the idea. I am going to take a step back and talk about this at a higher level.  

## The beauty of a simple idea
At face value, all we are really talking about is a Powershell script that checks the system (a health check). The idea is that you run your health check after your deployment scripts run or any time you make changes to the system. This is what we are calling Operational Validaiton.

After you deploy a new system, what checks do you do before you release it? RDP into it? Verify the application got installed? Is the service running on the port? Are there any manual steps left in the process? What goes wrong that you need to check?

You are already doing operational validation without even thinking about it. Working these post deployment checks into a validation script is all we are talking about. Once you hvae it in a script then we can leverage for several things.

## Quicker system diagnotics
Any time you are troubleshooting issues with your system, running your validation script will help you see the scope of the issue. All the stuff you are looking at by hand are good things to work into your system validation. 

Then once you are done fixing the issue, you run your validation to ensure that you fixed it. Any time you miss an issue, work that back into your validation script.