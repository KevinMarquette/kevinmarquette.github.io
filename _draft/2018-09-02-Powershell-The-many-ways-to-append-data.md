---
layout: post
title: "Powershell: The many ways to append data"
date: 2018-09-02
tags: [PowerShell]
---

Quite often you will have some data in a variable or in a file of some type and would like to add more data to it. We are going to take a step back and look at what it means to append data in different contexts.

<!--more-->

# Index

* TOC
{:toc}

# Append data to variables

When you are considering adding data to a variable, it is important to keep track of what type of variable you have. Knowing if you have a string or a collection can be important.

## Growing strings

Adding more characters to a string looks like one of the simplest things in PowerShell. We can use `+` to append them.

    $message = 'Hello'
    $message = $message + ' World!'

This works very well in most cases. You can alternitivly use the `+=` operator. 

    $message = 'Hello'
    $message += ' World!'

This is shorthand for adding the string to the current string and assigning it to the current variable.

If you are looking for other ways to build strings with variables, I have another write up that covers that in great detail: [Everything you wanted to know about variable substitution in strings](/2017-01-13-powershell-variable-substitution-in-strings/?utm_source=blog&utm_medium=blog&utm_content=append)

### StringBuilder

Growing a string like this is called concatination in most programming languages. It can get expensive if you are adding to the same string multiple times becuase a new array is created each time.

If you are doing a lot of appending, then `StringBuilder` is often a better choice.

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append( 'Was it a car ' )
    [void]$sb.AppendLine( 'or a cat I saw?' )
    $sb.ToString()

I go into more detail in this post: [Concatenate strings using StringBuilder](/2017-11-20-Powershell-StringBuilder/?utm_source=blog&utm_medium=blog&utm_content=append)

## Arrays and collections

You will find that adding data to arrays is very simular to adding data to string.

    $array = @(1,2,3,4,5)
    $array = $array + 6

You do have to be careful that your actually working with an array. It is very easy to get a single item and be adding two values instead of adding to the array.

    PS> $whatIThinkIsAnArray = Write-Output 1 2 3
    PS> $whatIThinkIsAnArray + 9
    1
    2
    3
    9

    PS> $whatIThinkIsAnArray = Write-Output 1
    PS> $whatIThinkIsAnArray + 9
    10

### ArrayList

Just like the string, you don't actually add to an existing array. You are creating a new one each time with the new value added. Instead of using a `StringBuilder` for arras, the common solution is the `ArrayList`.

    $arraylist = [System.Collections.ArrayList]::new()
    [void]$arraylist.add(1)
    [void]$arraylist.add(2)

This does a much better job of managing memory and you can work with it very much like you would a normal array.

    $arraylist[0]

### 

# What's next?


