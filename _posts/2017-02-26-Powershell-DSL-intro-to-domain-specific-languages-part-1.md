---
layout: post
title: "Powershell: Intro to DSLs (Domain-Specific Languages), part 1"
date: 2017-02-26
tags: [PowerShell,DSL,Advanced]
---

I always considered myself a Powershell purist. A DSL (Domain-Specific Language) written in Powershell abuses all the rules that I have grown to embrace. I recently found myself building a module that was implemented as a DSL and I really like how it turned out. Not only that, but I also had fun writing it.<!--more-->

This is the first post in a series covering what a DSL is and how to write one.
* Part 1: Intro to Domain-Specific Languages (This post)
* Part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)
* Part 3: [DSL design patterns](/2017-03-13-Powershell-DSL-design-patterns/)
* Part 4: [Writing a TypeExtension DSL](/2017-05-05-PowerShell-TypeExtension-DSL-part-4)
* Part 5: [Writing an alternate TypeExtension DSL](/2017-05-18-PowerShell-TypeExtension-DSL-part-5)

# Index

* TOC
{:toc}

# What exactly is a DSL?
"A domain-specific language (DSL) is a computer language specialized to a particular application domain. This is in contrast to a general-purpose language (GPL), which is broadly applicable across domains, and lacks specialized features for a particular domain." -[Wikipedia](https://en.wikipedia.org/wiki/Domain-specific_language)

## Say that again?
An application domain may be specialized enough that it has it's own language to describe things. Sometimes that does not translate well to the tools we are using. We have many ways to approach these problems and using a DSL is one of them.

## Any good examples?
HTML, CSS, XML and SQL are all DSLs. Here are some basic snippets.

_HTML_

    <html>
        <body>
        <h1>My heading</h1>
            A basic page of html
        </body>
    </html>

_CSS_

    h1 {
        color: red;
    }
    
_XML_

    <persons>
        <person name="Kevin Marquette" />
    <persons>

_SQL_

    Select Name From tablePerson Where ID = 1

In each case they have their own domain of terminology and patterns. We also have several good examples in Powershell now. DSC, [Pester](https://github.com/pester/Pester/wiki), [psake](http://psake.readthedocs.io/en/latest/) and [PSGraph](https://kevinmarquette.github.io/2017-01-30-Powershell-PSGraph/) are all implemented as a DSL. 

_DSC_

    Configuration myConfig {
        Node 'localhost' {
            File 'tools' {
                Destination = 'c:\tools'
            }
        }
    }

_Pester_

    Describe "Unit Test" {
        It "Does something" {
            "Something" | Should Be "Something"
        }
    }

_psake_

    Task default -Depends Test

    Task Test -Depends Compile {
        "This is a test"
    }

    Task Compile {
        "Compile"
    }

_psraph_

    Graph "myGraph" {
        Node @{shape='rectangle'}
        Edge start,middle,end        
    }

# A DSL in Powershell
There are two approaches to creating a DSL. The first one uses data sections to limit available commands. The other abuses the mechanics of parameters. It is worth learning both because they can be mixed together.

# Data sections
There is a little known keyword in Powershell that lets you define a [data section](https://technet.microsoft.com/en-us/library/dd347678.aspx). This is a script block that only contains data unless you specify otherwise. 

    Data {'Hellow Wolrd'}

It can handle some basic logic but most cmdlets are not allowed to be executed in a data section. If you have some special commands that you want to include, then you need specify them as `-SupportedCommands`.

    DATA -SupportedCommand Format-XML {    
        Format-XML -strings string1, string2, string3
    }

## In practice
I went looking for examples in Github. The common use case I saw for this was when importing a text file that contained their specific DSL. The `-SuppportedCommand` was used to limit the text file to only data and their DSL commands.

Here is an example of how it was used:

    $Content = Get-Conent -Path $Path
    Invoke-Expression -Command "DATA -SupportedCommand Import-DscConfigurationData,Import-PSEncryptedCredential,Import-PSEncryptedData {$($Content)}" 

The pattern was to import the contents of a file into a string like the one above and either `Invoke-Expression` on it or create a `[scriptblock]` and run `invoke()`.

## The original DSL feature
After tracking down some early talks about how Powershell can be used for creating a DSL, I feel that this was the feature they were talking about. I think the use of CmsLets for DSLs the way I describe in the next section was unexpected when they first arrived on the scene.  

# CmdLet based DSL example
The most common way we have seen a custom DSL implemented in Powershell is with CmdLets. They tend not to use the noun-verb structure and they make heavy use of positional parameters. Lets take a look at an example from pester.

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

This looks a little more like the Powershell we know, but it still takes advantage of the `[scriptblock]` in a less common way. Here is one more translation that don't nest the `[scriptblock]`.

    $TestScript = {
        Should -ActualValue "Something" -Be -ExpectedContent "Something"
    }
    $DescribeScript = {
        It -Name "Does Something" -Fixture $TestScript
    }
    Describe -Name "Unit Test" -Fixture $DescribeScript

If you had to write all your tests like that it would be easier to just write your tests with normal Powershell. Hopefully that helps show the value of a well written DSL.

# What's next?
Next week we will build a DSL based CmdLet to generate rdg files for Microsoft's Remote Desktop Connection Manager. I can't say that we need a DSL for that but it will be a simple example that introduces a few different techniques.

Continue to part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)