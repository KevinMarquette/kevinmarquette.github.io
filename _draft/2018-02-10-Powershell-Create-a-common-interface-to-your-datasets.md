---
layout: post
title: "Powershell: You need a Get-MyServer function"
date: 2018-02-10
tags: [PowerShell]
---

As your library of scripts and automation grows, everything you do will start to depend on your common datasets. Datasets like your user information or server details. Just think about how many scripts and tools you already have that either get a list of servers or you provide it a list of servers. It may be time for you to create a common interface to your data.

<!--more-->
# Get-MyServer

What you need is a `Get-MyServer` function. Put all your server list building logic into that function. Even if all it does is import a csv at first.

    function Get-MyServer
    {
        Import-CSV $PSScriptRoot\servers.csv
    }

Over time, you can add features to your function and all your future scripts will benefit from it. Adding a quick filter can make a big difference in a `Get-MyServer` function.

    function Get-MyServer
    {
        param($ComputerName = '*')

        Import-CSV $PSScriptRoot\servers.csv | 
            Where ComputerName -like $ComputerName
    }

I would create a module just for functions like these.

# Hide the details




# Putting it all together


# What's next?


