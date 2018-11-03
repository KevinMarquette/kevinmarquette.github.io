---
layout: post
title: "Powershell: Everything you ever wanted to know about HashSet"
date: 2018-08-25
tags: [PowerShell, .NET, Collections]
---

One of my new favorite data structures is the [HashSet](https://docs.microsoft.com/en-us/dotnet/api/system.collections.generic.hashset-1?view=netstandard-2.0). This special collection is something we get access to in PowerShell because of .Net. Let's take a look at what that really means and why you would want to use one.

<!--more-->

# Index

* TOC
{:toc}

# The basics

Before we take a look at the hashset, I want to quickly review [hashtables](/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog&utm_content=hashset).

## Hashtable

A Hashtable is a collection of key value pairs. You use the key to look up the value. The key is unique within the hashtable and is used to retrieve the value.

    $hashtable = [System.Collections.Hashtable]::New()
    $hashtable.Add('Key','Value')
    $hashtable.Item('Key')

Ok, that syntax is a little verbose. You probably see it used more like this in PowerShell:


``` csharp
    $hashtable = @{}
    $hashtable['Key'] = 'Value'
    $hashtable['Key']

    $hashtable.OtherKey = 'OtherValue'
    $hashtable.OtherKey

We get this friendly syntax because hashtables are first class citizens in PowerShell.

I go into more detail in a previous article.

* [Everything you wanted to know about hashtables](/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog&utm_content=hashset)

## HashSet

A hashset on the other hand is only a list of unique keys. Because of this, the keys are also the values. What this offers us is a simple way to build and work with a list of unique values.

I like to make the comparison to hashtables because they are very similar and I would often use a hashtable to find unique keys. Let's say we wanted to generate a list of unique process names using a hashtable.

    $processList = Get-Process
    $hashtable = @{}
    
    foreach($process in $processList)
    {
        $hashtable[$process.Name] = $true
    }

    $hashtable.keys



# Putting it all together


# What's next?


