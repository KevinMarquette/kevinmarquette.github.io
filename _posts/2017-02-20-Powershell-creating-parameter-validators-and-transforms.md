---
layout: post
title: "Powershell: Creating parameter validators and transforms"
date: 2017-02-20
tags: [PowerShell,Classes,Attribute,Validator,Advanced]
---
I was in the [Powershell Slack](https://powershell.slack.com/messages/irc-bridge/) channel and [Joel Bennett](https://twitter.com/Jaykul) mentioned inheriting from `System.Management.Automation.ValidateArgumentsAttribute` to create a custom validator. This builds directly on my last post because you are creating a custom attribute to do this.<!--more-->

This is the second part in a two part post about attributes. 

* [Part 1: Creating and using custom attributes](/2017-02-19-Powershell-custom-attribute-validator-transform)
* Part 2: Creating parameter validators and transforms (This post)

Before you begin, understand that this is a very advanced technique and we are about to dive very deep into it.

# Index

* TOC
{:toc}

# What is a validator?
 Just to make sure we are on the same page. A validator is an attribute that you can attach to a parameter in your advanced functions. They will validate your arguments for you so you don't have to do it on your own.

     function Verb-Noun
     {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("sun", "moon", "earth")]
            $Param1
            ...

There is a long list of built in validators and today we are going to cover how to make our own custom validator.

# Custom ValidatePathExistsAttribute
One thing that I find myself doing quite often is using a `[ValidateScript({Test-Path -Path $_})]` on path parameters. This checks they are valid, except the error message is worthless. So instead of just using a script block, we can  implement our own validator.

    class ValidatePathExistsAttribute : System.Management.Automation.ValidateArgumentsAttribute
    {
        [void]  Validate([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)
        {
            $path = $arguments
            if([string]::IsNullOrWhiteSpace($path))
            {
                Throw [System.ArgumentNullException]::new()
            }
            if(-not (Test-Path -Path $path))
            {
                Throw [System.IO.FileNotFoundException]::new()
            }        
        }
    }

The first thing to point out is that I postfix my name with the `Attribute` keyword. When we attach that to our property, we can call it `[ValidatePathExists()]`.

I inherit the `ValidateArgumentsAttribute` and I override the `[void] Validate ([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)` function. I figured this out by looking at the Powershell source for an [example](https://github.com/PowerShell/PowerShell/blob/02b5f357a20e6dee9f8e60e3adb9025be3c94490/src/System.Management.Automation/engine/Attributes.cs#L1222). 

The `$Arguments` contains the value of the property. I have no idea what the `$engineIntrinsics` is, so I ignore it for now.

I decided to use standard exceptions in this case so the error message is localized. I could `throw` a custom message if needed.

## Use the validator
Now that we have a custom validator, we can attach it to our property and let Powershell do the rest.

    function Do-Something
    {
        [cmdletbinding()]
        param(
            [ValidatePathExists()]
            $Path
        )
        return $Path
    }	 

Then we run our testcases to see the results

    PS:> Do-Something -Path 'C:\Windows'
    C:\Windows

    PS:> Do-Something -Path 'testvalue'
    do-something : Cannot validate argument on parameter 'Path'. Unable to find the specified file.

    PS:> Do-Something -Path $null
    do-something : Cannot validate argument on parameter 'Path'. Value cannot be null.

## Other reasons to use custom validators
I use the script and match validators quite often but I do not like the cryptic error messages. If you truly need a better validator error message, it is worth considering this option.

# ArgumentTransformationAttribute
A lesser known attribute built into Powershell is the `ArgumentTransformationAttribute`.  This is also one that I discovered when looking at the Powershell source. There are only two (that are publicly accessible) instances that I know of.

### Type Accelerators
I need to pause for a second and mention [Type Accelerators](https://blogs.technet.microsoft.com/heyscriptingguy/2013/07/08/use-powershell-to-find-powershell-type-accelerators/). These transforms are just like those except with a Type Accelerator, your value becomes that type. A transform can do anything and return any type (as long as it is an `[Object]`). 

## [System.Management.Automation.Credential()]
I ran across this one a while back. You can attach this attribute to a parameter. If you pass in a string, then you will be prompted for the password. If you give it a `[PSCredential]`, it will use that credential. 

    function Do-Something
    {
        [cmdletbinding()]
        param(
            [System.Management.Automation.Credential()]
            $Credential
        )
        return $Credential
    }

    Do-Something -Credential 'username'

So this attribute transforms a string into something else. Starting with Powershell 5.0, you get this same functionality by specifying the type as `[PSCredential]`.

## [ArgumentToConfigurationDataTransformationAttribute()] 
I went hunting for another example and I discovered this [gem](https://github.com/PowerShell/PowerShell/blob/02b5f357a20e6dee9f8e60e3adb9025be3c94490/src/System.Management.Automation/DscSupport/CimDSCParser.cs#L278). If you attach this to an attribute, it will allow you to specify a file path. If it discovers a psd1 file, It will transform your parameter into the contents of that psd1 as a hashtable. So it auto imports the hashtable for you. 


    function Get-HashtableFromFile
    {
        [cmdletbinding()]
        param(
            [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
            $Path
        )
        return $Path
    }

    $path = 'C:\workspace\PSGraph\PSGraph\PSGraph.psd1'
    Get-HashtableFromFile -Path $path

I don't think this was ever intended for us to use this way, but it is a good example of what is possible.

## Custom PathTransformAttribute
We can take everything we learned here and build our own transform. For a simple example, lets create a transform that gives the full path to a file.

    class PathTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)
        {
            if ( $inputData -is [string] )
            {
                if ( -NOT [string]::IsNullOrWhiteSpace( $inputData ) )
                {
                    $fullPath = Resolve-Path -Path $inputData -ErrorAction SilentlyContinue
                    if ( ( $fullPath.count -gt 0 ) -and ( -Not [string]::IsNullOrWhiteSpace( $fullPath ) ) 
                    {
                        return $fullPath.Path
                    }                
                }
            }
            $fullName = $inputData.Fullname
            if($fullName.count -gt 0)
            {
                return $fullName
            }

            throw [System.IO.FileNotFoundException]::new()
        }
    }

For this attribute, we inherit from `System.Management.Automation.ArgumentTransformationAttribute` and override the `[object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object] $inputData)` function.

The inner logic checks for a `[string]` and does a `Resolve-Path` on it. Then if it can find a `FullName` property (assuming a file or directory), then it returns the `FullPath`. I decided to throw an error if there was no match but I could have returned the original object. 

## Using the transform
Now we use it like our validator attribute.

    function Get-Path
    {
        [cmdletbinding()]
        param(
            [PathTransform()]
            $Path
        )
        return $Path
    }

    Get-Path -Path '\Windows'
    Get-Path -Path (Get-ChildItem $ENV:temp)

# The big picture
These custom validators and transforms truly are advanced features. But if you find yourself doing the same validation and transformations on certain sets of data across your module, it is worth considering this option. 

I could see creating a validator to validate the format of a customer ID over and over (instead of a regex match).

Another validator that I am considering building already is one that verifies that a `[Hashtable]` or a `[PSCustomObject]` has a specific key (or keys). I often pass in a hashtable that I assume has a set structure to it and this would let be validate those assumptions.
