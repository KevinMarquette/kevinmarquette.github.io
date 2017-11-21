---
layout: post
title: "Powershell: Concatenate strings using StringBuilder"
date: 2017-11-20
tags: [PowerShell,DotNet]
---
Have you ever noticed that some people use [StringBuilder](https://msdn.microsoft.com/en-us/library/system.text.stringbuilder) in their PowerShell scripts and wondered why? The whole point of using `StringBuilder` is to concatenate or build large strings. There are ways to do this in PowerShell already, so why would someone turn to this DotNet object?
<!--more-->

They are trying to optimize for performance because the simple ways to join strings in PowerShell can become expensive very quickly. Let's take a look at this and other ways we can concatenate strings.

# Index

* TOC
{:toc}

# Setting our scope

The focus of this article will be on joining lots of values or lines of text together. Think of the scenario where you are adding to a string in a loop several times. I am not going to focus on the smaller strings where you are just formatting values on a single line.

With that said, I do have another post where I cover [Everything you wanted to know about variable substitution in strings](2017-01-13-powershell-variable-substitution-in-strings).

# What problem does StringBuilder solve?

We should start by taking a look at the problem. Strings in PowerShell and DotNet are immutable. From the [MDSN String Class](https://msdn.microsoft.com/en-us/library/system.string) documentation:

> A String object is called immutable (read-only), because its value cannot be modified after it has been created. Methods that appear to modify a String object actually return a new String object that contains the modification.

> Because strings are immutable, string manipulation routines that perform repeated additions or deletions to what appears to be a single string can exact a significant performance penalty.

In this next example, at least 5 strings are created in memory.

    $example = 'First'
    $example += 'Second'
    $example += 'Third'

We have the obvious literals `First`,`Second`,`Third`. `$example` starts with a value of `First`. Then a new string is created with the value `FirstSecond` and assigned to `$example`. Then a new string is created with the value `FirstSecondThird` and assigned to `$example`. All of that sits in ram until garbage collection.

Not only are we using a lot of ram that is not needed, we creating a lot of data copy operations. To create the string of `FirstSecond`, we have to allocate room for each character. We copy in the 5 characters `First` one at a time and then we repeat the process with the `Second` string. When we get to `FirstSecondThird`, the process starts over copying all the characters again. It looks like a simple operation to us, but PowerShell is doing a lot of work that we don't see.

# Using StringBuilder

`StringBuilder` is a DotNet object that builds strings. You can see the basics in this example.

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append( 'Was it a car ' )
    [void]$sb.AppendLine( 'or a cat I saw?' )
    $sb.ToString()

I start by creating a `StringBuilder` and then appending a few strings to it. I am using the `[void]` to suppress the output from the append functions. To get the string from the `StringBuilder`, we need to call `ToString()`.

`StringBuilder` uses an internal data structure that is built for quickly adding data to it. The whole purpose of this object is address the performance issue that I outlined previously.

## StringBuilder by the numbers

I pulled together a simple test to show how much faster `StringBuilder` can be.

    $string = ''
    Measure-Command {
        foreach( $i in 1..10000)
        {
            $string += 'Was it a car or a cat I saw? '
        }
        $string
    }
    #TotalMilliseconds : 1588.2549

    $sb = [System.Text.StringBuilder]::new()
    Measure-Command {
        foreach( $i in 1..10000)
        {
            [void]$sb.Append( 'Was it a car or a cat I saw? ')
        }
        $sb.ToString()
    }
    #TotalMilliseconds : 127.509

Running over 10 thousand iterations shows a huge gap between them.

# Shifting back to PowerShell

The use of `StringBuilder` comes from the C# or DotNet world. If we change our requirements a bit then there is another option available to us. Sometimes we need a single multi-line string and other times all we need is a collection of strings. If a collection of strings is what we are looking for, we can leverage the PowerShell pipeline.

I have 2 pipeline examples. The first is collecting the output of a `foreach` loop and the second is a function with a `process` block.

## Pipeline by the numbers

Let's run our tests again with these scenarios.

    $sb = [System.Text.StringBuilder]::new()
    Measure-Command {
        foreach( $i in 1..1000000)
        {
            [void]$sb.AppendLine( 'Was it a car or a cat I saw?')
        }
        $sb.ToString()
    }
    #TotalMilliseconds : 1234.2676


    $foreach = @()
    Measure-Command {
        $foreach = foreach( $i in 1..1000000)
        {
            'Was it a car or a cat I saw?'
        }
        $foreach
    }
    #TotalMilliseconds : 846.7726


    function PipelineTest{
        process{
            'Was it a car or a cat I saw?'
        }
    }
    $pipeline = ''
    Measure-Command {
        $pipeline = 1..1000000 | PipelineTest
        $pipeline
    }
    #TotalMilliseconds : 1164.6559

These numbers are a lot closer to each other. I really just wanted to show that we have a few options depending on what our needs are.

# Wrapping it up

There was a time where I would turn to `StringBuilder` quite quickly. As I got a better understanding of the PowerShell pipeline, I found myself using it more for situations like this. It's good to know the options and when you can shift your requirements for better results.

There is a common saying here when it comes to performance in PowerShell that I will leave you with.

> If performance matters, test it.
