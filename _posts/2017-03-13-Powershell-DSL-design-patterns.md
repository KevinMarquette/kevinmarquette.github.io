---
layout: post
title: "Powershell: DSL design patterns, DSLs part 3"
date: 2017-03-13
tags: [PowerShell, DSL, Advanced]
---

When I was working on my DSL, I found that I had to be more creative with my advanced function implementations than I do with normal advanced functions. When it comes to writing a script CmdLet, there are lots of community standards and expected behaviors already defined.

When creating a DSL, you may be bending a lot of those best practices to create the best user experience. When optimizing for the user, you may find yourself collecting and processing data using different technique.<!--more-->

The goal of this post is to show you different approaches you can take in crafting a DSL.

This is the third post in a series on writing DSLs in PowerShell.

* Part 1: [Intro to Domain-Specific Languages](/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1)
* Part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)
* Part 3: CmdLet based DSL design patterns (This post)
* Part 4: [Writing a TypeExtension DSL](/2017-05-05-PowerShell-TypeExtension-DSL-part-4)
* Part 5: [Writing an alternate TypeExtension DSL](/2017-05-18-PowerShell-TypeExtension-DSL-part-5)

# Index

* TOC
{:toc}

# Design patterns and DSL command types

The rest of this post is full of design patterns and different types of commands that I found useful when crafting DSLs. Some of these are very obvious but I wanted to mention them in this context. There are other patterns that you may not find as useful until you are dealing with a specific problem that they may solve.

## Value passthu

You may want to have a command with a specific name to fit your DSL but all it does it pass on the values that is given to it. These DSLs are often shorthand for more complex commands and that is all you are doing here.

    function Set-State 
    {
        param($State)
        return $State
    }

This could be done by creating an alias on `Write-Output`.

## Simple template

The idea behind a template is that you accept basic parameters, pass them into a template and return the resulting text. Our `RdcServer` command from the last post is a good example of that.

    function Get-RdcServer
    {
        param($ComputerName)
        @"
        <server>
          <properties>
            <name>$ComputerName</name>
          </properties>
        </server>
    "@
    }

    RdcServer Server01

I mostly think of returning strings to build a document when using this approach. You can also build more complicated objects. This could be a full XML object or any other type of object that ypu are working with.

## Nested template

This pattern generally involves using template data for the header and footer of the content. Then allowing the user to specify a script block to be invoked for the body of the content. Our RdcGroup command from the last week is a good example for this one.

    function Get-RdcGroup
    {
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $true,
                Position = 0
            )]
            [string]
            $GroupName,

            [Parameter(
                Mandatory = $true,
                Position = 1
            )]
            [scriptblock]
            $ChildItem
        )
        process
        {
            @"
        <group>
          <properties>
            <name>$GroupName</name>
          </properties>
    "@
           $ChildItem.Invoke()

            '    </group>'
        }
    }

This command can be nested with itself and joined with this simple template pattern.

    RdcGroup GroupATX {
        RdcServer Server1
        RDCServer Server2
    }

    RdcGroup GroupATX {
        RdcGroup GroupDMZ {
            RdcServer ServerDMZ01
            RdcServer ServerDMZ02
        }
        RdcGroup GroupInternal {
        }
    }

This is an example where you execute the `scriptblock` inline as the command is running. I mention that because there are situations where you would not execute that `[scriptblock]`

## Hashtable passthru

You can use a DSL to easily build a `[hashtable] ` based on the command parameters. This can be a great way to build a validated `[hashtable]` that must have a specific structure.

    function Get-State 
    {
        [cmdletbinding()]
        param(
            $State,
        
            [scriptblock]
            $StateScript
        )
        return $PSBoundParameters
    }

The idea with using a passthru type of command is that something else will be collecting this data and processing it.

## Hashtable builder

A true `[hashtable]` builder will allow the user to specify key value pairs and properly convert them to a `[hashtable]` or `[pscustomobject]`. It could be implemented like this:

    function Get-ServerDetails
    {
        param([scriptblock]$ScriptBlock)

        $newScript = "[ordered]@{$($ScriptBlock.ToString())}"
        $newScriptBlock = [scriptblock]::Create($newScript)
        & $newScriptBlock
    }

Then you could have a DSL command in place that looks like this:

    ServerDetails {
        Name = 'test'
        IP = '10.0.0.1'
    }

The `scriptblock` is still a key component in the way the command is used. The key value pairs are provided in the `scriptblock` and then we reformat the input to become a valid `hashtable` before executing it. 

This is a great time to point out that you can modify the contents of the script before you run it.

## Hashtable collector

If you have a hashtable passthru or hashtable builder, then you may need to have a hashtable collector. This pattern uses a script block to hold the hashtable passthru values. The `[scriptblock]` is invoked and the return values are captured. We can use this to flesh out a statemachine.

    function Get-StateMachine
    {
        [cmdletbinding()]
        param(
            [scriptblock]
            $StateScript
        )
    
        $userScripts = & $StateScript   
        [hashtable]$stateEngine = @{}
        $userScripts | ForEach-Object {$stateEngine[$_.State] = $_}

        return $stateEngine        
    }

This example captures all the hashtables that are created when the `$StateScript` is invoked. It performs some processing and then returns a statemachine based on this structure:

    StateMachine {

        State Start {
            Write-Verbose "Start"
            Set-State "Monitor"
        }  

        State Monitor {
            Write-Verbose "Monitor"
            Set-State "End"
        }  
    }

## Restricted DSL

When using a `[scriptblock]`, you leave your DSL open to allow any PowerShell commands to be ran. You can restrict this to the DSL commands you specify with the data command.

    
    $newScript = "DATA -SupportedCommand Get-State,Set-State {{{0}}}" -f $ScriptBlock.ToString()
    $newScriptBlock = [scriptblock]::Create($newScript)
    & $newScriptBlock

This is most valuable when you are defining your DSL to be used in files that are to be executed by PowerShell. This allows you to treat your DSL based files more like plain text configs and less like scripts that execute code.

## Internal or private commands

You may have a command that you don't want to export or to be usable outside your DSL implementation. You can do this by defining your functions inside your container functions. The commands will be valid inside the script block when executed.

    
    function Get-StateMachine
    {
        [cmdletbinding()]
        param(
            [scriptblock]
            $StateScript
        )
        
        function Set-State 
        {
            param($State)
            return $State
        }
        
        $userScripts = & $StateScript 
        [hashtable]$stateEngine = @{}
        $userScripts | ForEach-Object {$stateEngine[$_.State] = $_}

        return $stateEngine        
    }

In the example above, `Set-State` is defined inside `Get-StateMachine`. 

# Focus on the user experience

No matter what pattern you use, make sure you focus on how the user will interact with your DSL. When I write a DSL, I often mock up several ways to describe something using fake commands until it feels right.

Then I go seek out a design pattern that allows me to create the commands that will match the best example. Sometimes you execute everything in place and other times you collect everything at the parent function for processing.

* Part 4: [Writing a TypeExtension DSL](/2017-05-05-PowerShell-TypeExtension-DSL-part-4)
