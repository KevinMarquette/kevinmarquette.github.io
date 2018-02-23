---
layout: post
title: "Powershell: You need a Get-MyServer function"
date: 2018-02-23
tags: [PowerShell]
share-img: "http://kevinmarquette.github.io/img/share-img/2018-02-23-Powershell-Create-a-common-interface-to-your-datasets.png"
---

As your library of scripts and automation grows, everything you do will start to depend on your common datasets. Datasets like your user information or server details. Just think about how many scripts and tools you already have that either get a list of servers or you provide it a list of servers. It may be time for you to create a common interface to your data.

<!--more-->
# Get-MyServer

What you need is a `Get-MyServer` function. Put all your server list building logic into that function. Even if all it does is import a csv at first.

    function Get-MyServer
    {
        Import-CSV $PSScriptRoot\servers.csv
    }

Over time, you can add features to your function and all your future scripts will benefit from it. Adding a quick filter can make a big difference in your `Get-MyServer` function.

    function Get-MyServer
    {
        param($ComputerName = '*')

        Import-CSV $PSScriptRoot\servers.csv |
            Where ComputerName -like $ComputerName
    }

I would even go so far as to create a module just for functions like these.

# Hide the details

These `Get` functions hide the implementation details from your other scripts. Your other scripts should not care where the data comes from, only that the `Get` functions provides the needed information.

This allows you to change your data source much easier. You could easily switch to using Active Directory or SQL server or complex JSON files. As long as you keep the shape of the output object the same, your scripts may never know that anthing changed.

# Data at your fingertips

I find having simple get functions readily available makes all my other scripts easier to write. I can't tell you how many times I reach for our `Get-MyServer` list in a given week.

We track additional metadata on our servers that is available in our version of `Get-MyServer`. We assign each server to a role and tag it with an environment in our data. By exposing that info in our `Get-MyServer`, we can do queries like this:

    PS:> Get-MyServer -Environment Production -Role SQL

    ComputerName Role Environment IP
    ------------ ---- ----------- --
    MyServer01   SQL  Production  172.169.10.3
    MyServer02   SQL  Production  172.169.10.4

Or do the reverse and query a server to figure out what role or environment it is assigned to.

    PS:> Get-MyServer MyServer01

    ComputerName Role Environment IP
    ------------ ---- ----------- --
    MyServer01   SQL  Production  172.169.10.3

# Closing thoughts

My main example was servers, but this applies to all common sources of data. Having the data available makes it easier for you to use it too. So go make your `Get-MyServer` function and let me know how well it works for you.
