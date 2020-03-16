---
layout: post
title: "Powershell: Creating a Custom Testing Framework"
date: 2019-12-16
tags: [PowerShell,Class,Testing]
---
I have been a big fan of Pester for a long time. It's a great tool for testing so many things. Sometimes I push it a little too far or using it in places where it does not belong. In those scenarios, I end up writing my own testing framework to handle my special needs. Let's take a look at one of those scenarios and see how creating a custom testing framework can help us.
<!--more-->


# Index

* TOC
{:toc}

# What is Pester?

Pester is the standard PowerShell testing framework. Initially, it was intended to be used for unit testing your PowerShell projects. The idea behind unit testing is that you capturing your testing efforts into a script to make it repeatable. Then you can run the full set of tests every time you change something because it is automated.

Operational Validation Testing is another strong use case for Pester. Imaging having a set of tests you run after deploying a server that tells you everything is configured correctly and is working. Then also running those same tests before and after you run Windows Updates or any other maintenance tasks. They can prove your system is operationally valid at any point in time.

Pester makes those tasks easier and allows you to write less PowerShell to accomplish the same thing.

## Why not use Pester?

This article is really about using the right tool for the job. 

# What is our scenario?


# What's next?


