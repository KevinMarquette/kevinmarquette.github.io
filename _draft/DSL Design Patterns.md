---
layout: post
title: "Powershell: DSL Design Patterns"
date: 2017-03-04
tags: [PowerShell, DSL, Design Patterns, Advanced]
---


# passthu pattern

This is a command for the sake of creating a DSL. You may want to have a command with a specific name to fit your DSL but all it does it pass on the values that are given to it. DSLs are often just shorthand for more complex commands.

    function Set-State 
    {
        param($value)
        return $value
    }

This could just as easily be done by creating an alias on `Write-Output`.

# simple template pattern

This is one of the simplest DSL commands to implement. The idea is that you accept basic parameters, pass them into a template and return the resulting text. Our RdcServer command from the last post is a good example.

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

# nested template pattern

This pattern generally involves using a template for the headder and footer of the content. Then allowing the user to specify a script block to be invoked for the body of the content. Our RdcGroup command from the last post is a good example for this one.

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

# Hashtable passthru pattern

One way to use a DSL to collect information for use in the module is to have it build and return a `[hashtable]`. If I was building a state machine, I may want use a DSL to define the states and pass them off to an engine to process.

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

Here is how it may look in a full state machine:

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

This is great when you want to specify all the values as parameters to your function. This is also a good example of how you can pass a `scriptblock` up to a parent function to be executed later.

# hahstable builder pattern

A true hashtable builder will allow the user to specify key value pairs and properly convert them to a `hashtable` or `pscustomobject`. It could be implemented like this.

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

# hashtable collector pattern

If you have a hashtable passthru or hashtable builder, then you need to also have a collector. This pattern uses a script block to hold the hashtable passthrus. The scriptblock is invoked and the return values are captured. We can use this to complete our statemachine idea.

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

This example captures all the hashtables that are created when the `$StateScript` is invoked. Performs some processing and then returns the resulting statemachine. 

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

# restricted DSL pattern

When using a scriptblock, you leave your DSL open to allow any Powershell commands to be ran. You can restrict this to just the DSL commands you specify with the data command.

    
    $newScript = "DATA -SupportedCommand Get-State,Set-State {$($ScriptBlock.ToString())}"
    $newScriptBlock = [scriptblock]::Create($newScript)
    $newScriptBlock.invoke()

This is most valuable when you are defining your DSL to be used in files that are to be executed by Powershell. This allows you to treat your DSL based files more like plain text configs and less like scripts that execute code.

# Internal command pattern

You may have a command that you don't want to export or to be usable outside your DSL implementation. You can do this by defining them inside your container commands. The commands will be valid inside the script block when it is executed.  

# Focus on the user experience

No matter what pattern you use, make sure you focus on how the user will interact with your DSL. When I write a DSL, I often mock up several ways to describe something using fake commands until it feels right. 

Then I go seek out a design pattern that allows me to create the commands that will match the best example. Sometimes you execute everything in place and other times you collect everything at the parent function for processing.

