---
layout: post
title: "Powershell: DSL Design Patterns"
date: 2017-03-04
tags: [PowerShell, DSL, Design Patterns, Advanced]
---

When I was working on my DSL, I found that I had to be more creative with my implementations that I do with normal advanced functions. When it comes to writing a CmdLet, there are lots of community standards and expected behaviors already defined. 

When creating a DSL, you may be bending a lot of those best practices to create the best user experience. When optimizing for the user, you may find yourself collecting and processing data in different ways.

The goal of this post is to show you different approaches you can take in crafting a DSL. 

This is the third post in a series on writing DSLs in PowerShell.

* Part 1: [Intro to Domain-Specific Languages](/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1)
* Part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)
* Part 3: CmdLet based DSL design patterns


# Index

* TOC
{:toc}

# Value passthu

You may want to have a command with a specific name to fit your DSL but all it does it pass on the values that is given to it. DSLs are often shorthand for more complex commands and that is all you are doing here.

    function Set-State 
    {
        param($State)
        return $State
    }

This could alias be done by creating an alias on `Write-Output`.

# Hashtable passthru

You can also use a DSL to collect more information for use in the module. You can have it build and return a `[hashtable]` of your values. 

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

# Simple template

TThe idea behind a template is that you accept basic parameters, pass them into a template and return the resulting text. Our RdcServer command from the last post is a good example of that.

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

I mostly think of returning strings to build a document when using this approach. You can also build more complicated objects to return. This could be a true XML object or any other type of object.

# Nested template

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

This command can be nested with itself and joined with the simple template pattern.

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

This is an example where you execute the `scriptblock` inline as the command is running.

# Hahstable builder

A true `[hashtable]` builder will allow the user to specify key value pairs and properly convert them to a `hashtable` or `pscustomobject`. It could be implemented like this.

    function Get-ServerDetails
    {
        param([scriptblock]$ScriptBlock)

        $newScript = "@{[ordered]$($ScriptBlock.ToString())}"
        $newScriptBlock = [scriptblock]::Create($newScript)
        $newScriptBlock.invoke()
    }

Then you could have a DSL command in place that looks like this.

    ServerDetails {
        Name = 'test'
        IP = '10.0.0.1'
    }

The `scriptblock` is still a key component in the way the command is used. The key value pairs are provided in the `scriptblock` and then we reformat the input to become a valid `hashtable` before executing it. 

This is a great time to point out that you can modify the contents of the script before you run it.

# hashtable collector

If you have a hashtable passthru or hashtable builder, then you need to also have a collector. This pattern uses a script block to hold the hashtable passthrus. The `[scriptblock]` is invoked and the return values are captured. We can use this to complete our statemachine idea.

    function Get-StateMachine
    {
        [cmdletbinding()]
        param(
            [scriptblock]
            $StateScript
        )
    
        $userScripts = $StateScript.Invoke()    
        [hashtable]$stateEngine = @{}
        $userScripts | ForEach-Object {$stateEngine[$_.State] = $_}

        return $stateEngine        
    }

This example captures all the hashtables that are created when the `$StateScript` is invoked. It performs some processing and then returns the resulting statemachine. 

    StateMachine "Start" {

        State Start {
            Write-Verbose "Start"
            Set-State "Monitor"
        }  

        State Monitor {
            Write-Verbose "Monitor"
            Set-State "End"
        }  
    }

# Restricted DSL

When using a scriptblock, you leave your DSL open to allow any Powershell commands to be ran. You can restrict this to just the DSL commands you specify with the data command.

    
    $newScript = "DATA -SupportedCommand Get-State,Set-State {$($ScriptBlock.ToString())}"
    $newScriptBlock = [scriptblock]::Create($newScript)
    $newScriptBlock.invoke()

This is most valuable when you are defining your DSL to be used in files that are to be executed by Powershell. This allows you to treat your DSL based files more like plain text configs and less like scripts that execute code.

# Internal or private command

You may have a command that you don't want to export or to be usable outside your DSL implementation. You can do this by defining them inside your container commands. The commands will be valid inside the script block when it is executed.  

# Focus on the user experience

No matter what pattern you use, make sure you focus on how the user will interact with your DSL. When I write a DSL, I often mock up several ways to describe something using fake commands until it feels right. 

Then I go seek out a design pattern that allows me to create the commands that will match the best example. Sometimes you execute everything in place and other times you collect everything at the parent function for processing.

