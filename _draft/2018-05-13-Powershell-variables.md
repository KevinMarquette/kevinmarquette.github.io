---
layout: post
title: "Powershell: Everything you wanted to know about variables"
date: 2018-05-13
tags: [PowerShell]
---

One of the fundamental concepts in PowerShell (and most languages) is the use of [variables](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_variables?view=powershell-6). They allow you to hold information or data and user it later in your script. This looks to be such a simple topic on face value, but there is so much more to learn.

<!--more-->

# Index

* TOC
{:toc}

# What is a variable?

Variables are used to store data. This data can be a number or a string or something more complex. Think of them as a named container. Variable names are prefixed with a `$` sign in PowerShell to work with them.

## Assigning a value

We use the `=` operator to assign values to variables. The `=` is known as the equals sign but we call it the assignment operator in this case.

    $myVariable = 1

Here we assign the value `1` to a variable named `myVariable`. We can also store the results of a command to a variable.

    $myServices = Get-Service

Instead of all the services getting listed in the console, they are all stored in the `$myServices`

## Using a variable

Once you assign a value to a variable, you can then retrieve the value it contains by using the variable name in this way:

    $myVariable = 1
    $myVariable + 2

    $myMessage = 'Test message'
    Write-Output $myMessage

If you just place the variable all by itself on a line, it will place the value on the pipeline (output stream).

    $myVariable

You can also use variables inside string.

    "This is my $myVariable"

Working with variables inside strings is a whole topic on its own and I have another blog post that covers that: [Everything you wanted to know about variable substitution in strings](/2017-01-13-powershell-variable-substitution-in-strings)

## Default value

Because PowerShell is a scripting language, you don't have to define a variable before you use it. While you should always assign a value to your variable, PowerShell will not throw an error if you use a variable that is not yet defined. You will get a $null value instead.

    $null -eq $undefinedVariable

This is an important detail because if you misspell a variable name, you will get that `$null` value that could cause unexpected results in your scripts.

## Types

PowerShell variables are untyped by default. What I mean by that is that a variable can contain any data of any type. You are free to reuse variables for different things. As a scritping language, this is very common feature. But there are good reasons to understand the type of data that you have.

Every value and object has a type associated with it. Variables can be strongly typed so that they only contain data of a specified type.

    [int]$number = 1

By specifying that this is an `int` or integer, it can only contain numbers. By typing it that way, you can trust the contents. This is a simple way to add some basic validation. If we try to assign a differnt type, we get an error:

    PS> $number = 'one'
    Cannot convert value "one" to type "System.Int32". Error: "Input string was not in a correct format."

To see the type of a variable, you can call GetType() on it or pipe it to Get-Member.

    PS> $number.gettype()

    IsPublic IsSerial Name  BaseType
    -------- -------- ----  --------
    True     True     Int32 System.ValueType

    PS> $number | Get-Member
 
   TypeName: System.Int32

    Name        MemberType Definition
    ----        ---------- ----------
    CompareTo   Method     int CompareTo(System.Object value), int CompareTo(int value), int ICompara...
    Equals      Method     bool Equals(System.Object obj), bool Equals(int obj), bool IEquatable[int]...
    GetHashCode Method     int GetHashCode()
    ...




# Variable Cmdlets

PowerShell has a few cmdlets for working with variables.

    Get-Command -Noun Variable

    CommandType Name            Version Source
    ----------- ----            ------- ------
    Cmdlet      New-Variable    3.1.0.0 Microsoft.PowerShell.Utility
    Cmdlet      Set-Variable    3.1.0.0 Microsoft.PowerShell.Utility
    Cmdlet      Clear-Variable  3.1.0.0 Microsoft.PowerShell.Utility
    Cmdlet      Get-Variable    3.1.0.0 Microsoft.PowerShell.Utility
    Cmdlet      Remove-Variable 3.1.0.0 Microsoft.PowerShell.Utility

It is very rare for me to ever use these cmdlets, but there are some things that you can only do by using them.

## New-Variable

I was able to create a new variable in my first example by assigning a value to a new variable name. We can use `New-Variable` to also create them.

    New-Variable -Name myVariable -Value 1
    $myVariable

The `Name` does not include the `$` sign when using the `New-Variable` Cmdlet.

# What's next?


