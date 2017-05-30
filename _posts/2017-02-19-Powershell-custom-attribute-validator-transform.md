---
layout: post
title: "Powershell: Creating and using custom attributes"
date: 2017-02-19
tags: [PowerShell,Classes,Attribute,Validator,Advanced]
---

Every once and a while I stumble onto something in Powershell that I find interesting and I can't help but dive deep into it. I saw a tweet by [Brandon Olin](https://twitter.com/devblackops) recently that showed that you can create your own custom attributes in Powershell. 

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Custom attributes work on <a href="https://twitter.com/hashtag/PowerShell?src=hash">#PowerShell</a> class methods. This will be useful. <a href="https://t.co/8AeopiWH8T">pic.twitter.com/8AeopiWH8T</a></p>&mdash; Brandon Olin (@devblackops) <a href="https://twitter.com/devblackops/status/815747777221099520">January 2, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

We can have a lot of fun with that.<!--more-->

This was originaly one post but I broke it into two sections because of the length.

* Part 1: Creating and using custom attributes
* [Part 2: Creating parameter validators and transforms](/2017-02-20-Powershell-creating-parameter-validators-and-transforms)

Before you begin, understand that this is a very advanced technique and we are about to dive very deep into it.

# Index

* TOC
{:toc}

# What is an attribute?
They allow you to attach additional information to classes, functions and properties. It's metadata for your code. Let me show you some examples.

## Examples in advanced functions
Powershell already makes use of them in advanced functions. You can specify the `[Property(Mandatory=$true)]` attribute for a property to make it required. You can add the `[ValidateNotNullOrEmpty]` attribute to make sure it has a value. 

    function Do-Something 
    {
        [cmdletbinding()]
        param(
            [Property(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $Path
        )
        ...
    }

## PSScriptAnalyzer hints
The [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) has a lot of good best practices that it will check. Sometimes you need to do something a little different and you don't want PSScriptAnalyzer complaining. You could exclude that one rule for everything or use an attribute like `[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression","")]` to [suppress](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/README.md#suppressing-rules) the one occurrence in your script. 

# Create your own attribute
You can also create your own by inheriting from [Attribute](https://msdn.microsoft.com/en-us/library/system.attribute(v=vs.113).aspx).

     Class MyCommand : Attribute {}

If we create a default constructor, we can pass values into our attribute and access them later.

    Class MyCommand : Attribute {
        [string]$Name

        MyCommand([string]$Name)
        {
            $this.Name = $Name
        }
    }

## Attaching our custom attribute
Then we can attach it to our class, properties and functions like this.

    [MyCommand('MyClass')]
    class Test {

        [MyCommand('MyClassProperty')]
        $Name = 'TestName'

        [MyCommand('myFunction')]
        [string] SayHello(
            [string]
            $Name = "Kevin"
        )
        {
            return "Hello $name"
        }
    }

I attached our attribute in three locations and gave each one a custom value that we can then discover with reflection. Here is an example for an advanced function.

    function Do-Something
    {
        [MyCommand('MyAdvancedFunction')]
        [cmdletbinding()]
        param()
        return $true
    }

## Accessing our attribute
Now that we have an attribute and attached it to something, we can use `GetCustomAttributes('MyCommand')` to read our values.

    # on our class
    [Test].GetCustomAttributes('MyCommand')

    # on our class property named Name
    [Test].GetMember('Name').GetCustomAttributes('MyCommand')
    [Test].GetProperty('Name').GetCustomAttributes('MyCommand')

    # on our method named SayHello
    [Test].GetMember('SayHello').GetCustomAttributes('MyCommand')
    [Test].GetMethod('SayHello').GetCustomAttributes('MyCommand')

Advanced functions are a little different but the information is still there.

    $command = Get-Command Do-Something
    $command.ScriptBlock.Attributes | Where-object {$_.TypeID.Name -eq 'MyCommand'}

I had to filter on the `TypeID.Name` because we will also get the `[CmdLetBinding()]` attribute too if we don't use a filter. 

## It's on the class and not the object

Remember that attributes are metadata for our code. So it is the class that has the attribute attached to it. Every object of that class will have the same attribute with identical values.

    $object = [Test]::new()
    $object.GetType().GetCustomAttributes('MyCommand')

The only way to get our attribute from an object is to pull it off of the object type. If you find that this is an issue for you, reconsider the use of an attribute. A class property or function parameter could be a better option for whatever it is you are trying to do.

# What can we do with this?
The most obvious use to me is giving hints to our testing framework like in my `PSScriptAnalyzer` example above. A lot of tests we make in Pester are specific to the functions we are testing, but I often have tests that walk everything.

Here is a quick example of all the pieces to make that work.

## SkipTest attribute
Here is a new attribute for this example.

    Class SkipTest : Attribute {
        [string]$TestName

        MyCommand([string]$Name)
        {
            $this.TestName = $Name
        }
    }

## Sample function
The we attach it to an advanced function.

    function Do-Something
    {
        [SkipTest('HelpDescription')]
        [cmdletbinding()]
        param()
        return $true
    }

## Helper function
I decided to create a helper function to make this easier to work with. 

    function ShouldRunTest
    {
        [cmdletbinding()]
        param(
            [System.Management.Automation.CommandInfo]
            $Command,

            [string]
            $TestName
        )
        $SkipTest = $Command.ScriptBlock.Attributes | Where-object { $_.TypeID.Name -eq 'SkipTest' }
        
        if( ( $SkipTest -ne $null ) -and ( $SkipTest.TestName -eq $TestName ) )
        {
            return $false
        }

        return $true
    }

This will make our test look a lot cleaner

## Pester test
Then we update our test to check for the attribute. Assume this is a full module where we have lots of functions that we are testing but want to exclude just the one above.

    Describe "Help tests for $moduleName" -Tags Build {

        $functionList = Get-Command -Module $moduleName
        
        foreach($function in $functionList)
        {         
            if(ShouldRunTest $function -TestName 'HelpDescription')
            {
                It "has a help description" {
                    $help = $function | %{Get-Help $_.name}
                    $help.description | Should Not BeNullOrEmpty
                }
            }
        }
    }

## Limited applications
I am definitely writing this up as an advanced feature with limited applications. I am sure you can get very creative with this feature. I could stop here but I want to see how far we can push this.

What if we found a way to create new attributes that Powershell already understand how to use? 

 * [Part 2: Creating parameter validators and transforms](/2017-02-20-Powershell-creating-parameter-validators-and-transforms)

## Let me know
If you find a good way to put this information to use, let me know. I would love to see some practical implementations. 
