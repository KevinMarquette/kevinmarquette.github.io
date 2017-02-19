---
layout: post
title: "Powershell: Everything you wanted to know about Domain-Specific Languages"
date: 2017-02-17
tags: [PowerShell, DSL, Domain Specific Language]
---

I always considered myself a Powershell purist. A DSL (Domain-Specific Language) written in Powershell abuses all the rules that I have grown to embrace. I recently found myself building a module that was implemented as a DSL and I really like how it turned out. Not only that, but I also had fun writing it.

# What exactly is a DSL?
"A domain-specific language (DSL) is a computer language specialized to a particular application domain. This is in contrast to a general-purpose language (GPL), which is broadly applicable across domains, and lacks specialized features for a particular domain." -[Wikipedia](https://en.wikipedia.org/wiki/Domain-specific_language)

## Say that again?
An application domain may be specialized enough that it has it's own language to describe things. Sometimes that does not translate well to the tools we are use to using. There are many ways to approach these problems and using a DSL is one of them.

## Any good examples?
HTML, CSS, SQL and XML are all DSLs. We also have a lot of good examples in Powershell now. DSC, [Pester](https://github.com/pester/Pester/wiki), [psake](http://psake.readthedocs.io/en/latest/) and [PSGraph](https://kevinmarquette.github.io/2017-01-30-Powershell-PSGraph/) are all DSL implementations. 

# How to create a DSL in Powershell
There are two approaches to creating a DSL. The first one uses data sections limit available commands. The other abuses the mechanics of parameters. These can be mixed together. 

# Data Sections
There is a little known keyword in Powershell that lets you define [data section](https://technet.microsoft.com/en-us/library/dd347678.aspx). This is a script block that only contains data.

    Data {'Hellow Wolrd'}

It can handle some basic logic but most cmdlets are not allowed to be executed in a data section. If you have some special commands that you want to include, then you can specify them as needed.

    DATA -SupportedCommand Format-XML {    
        Format-XML -strings string1, string2, string3
    }

## In practice
I went looking for examples online. The common use case I saw for this was when importing a text file what contained their specific DSL. The `-SuppportedCommand` was used to limit the text file to only data and their DSL commands.

Here is an example of how it was used:

    $Content = Get-Conent -Path $Path
    Invoke-Expression -Command "DATA -SupportedCommand Import-DscConfigurationData,Import-PSEncryptedCredential,Import-PSEncryptedData {$($Content)}" 

The pattern was to import the contents of a file into a string like the one above and either `Invoke-Expression` on it or create a `[scriptblock]` and run `invoke()`.

# CmdLet based DSL
The most common way we have seen a DSL implemented in Powershell is with CmdLets. They tend not to use the noun-verb structure and they make heavy use of positional parameters. Lets take a look at an example from pester.

    Describe "Unit Test" {
        It "Does something" {
            "Something" | Should Be "Something"
        }
    }

At first glance, that looks nothing like Powershell. Let me translate that into traditional Powershell.

    Describe -Name "Unit Test" -Fixture {
        It -Name "Does Something" -Fixture {
            Should -ActualValue "Something" -Be -ExpectedContent "Something"
        }
    }

