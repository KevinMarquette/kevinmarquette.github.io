---
layout: post
title: "Powershell: isNullOrEmpty"
date: 2017-03-10
tags: [PowerShell, isNullOrEmpty]
---

One of the most common things you will do in Powershell is test to see if a value is empty or `$null`. Generally, any time I call a function that I expect will return an object or collection, I will test it for null before I continue on. The main reason I do this is to protect my code from external code. I don't trust that they will throw an error if something goes wrong. They may just return nothing. Because of that, I run into many different scenarios where I need to make sure I have a value before continuing.

# before we begin

I am going to present these code samples as snippets of Pester. Some will pass and others will fail. I have a complete set of Pester tests at the end of this post that tests all of the scenarios that we talk about.

# $null but not empty

By far the easiest thing to do is check to see if the value is not `$null`.

    It '$null value is $null' {
        $value = $null
        ($value -eq $null) | should be $true 
    }    

This will catch the `$null` condition, but not if we have an empty string.

    It 'empty string is not $null' {
        $value = ''
        ($value -eq $null) | should be $false 
    } 



# full set of $null and empty tests

Here is a full set of tests to check every type of `$null` or empty value. These are based on the examples above. All the examples above should pass the given tests but 

    