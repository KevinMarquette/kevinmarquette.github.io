---
layout: post
title: "Powershell: Creating custom attributes and practical applications"
date: 2017-02-19
tags: [PowerShell,Classes,Attribute,Validator,Transform]
---

Every once and a while I stumble onto something in Powershell that I find interesting and I can't help but dive deep into it. I saw a tweet by [Brandon Olin](https://twitter.com/devblackops) recently that showed that you can create your own custom attributes in Powershell.


<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Custom attributes work on <a href="https://twitter.com/hashtag/PowerShell?src=hash">#PowerShell</a> class methods. This will be useful. <a href="https://t.co/8AeopiWH8T">pic.twitter.com/8AeopiWH8T</a></p>&mdash; Brandon Olin (@devblackops) <a href="https://twitter.com/devblackops/status/815747777221099520">January 2, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

We can have a lot of fun with that.

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

Remember that attributes are metadata for our code. So it is the class that has the attribute attached to it. Every object of that class will have the same attribute.

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
        $SkipTest = $Command.ScriptBlock.Attributes | Where-object {$_.TypeID.Name -eq 'SkipTest'}
        
        if($SkipTest -ne $null -and $SkipTest.TestName -eq $TestName)
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

# Custom parameter validator
I was in the [Powershell Slack](https://powershell.slack.com/messages/irc-bridge/) channel and [Joel Bennett](https://twitter.com/Jaykul) mentioned inheriting from `System.Management.Automation.ValidateArgumentsAttribute` to create a custom validator. As is turns out, there are two attributes that Powershell automatically processes that we can implement ourselves.

## Custom ValidatePathExistsAttribute
One thing that I find myself doing quite often is using a `[ValidateScript({Test-Path -Path $_})]` on path parameters. This checks they are valid, except the error message is worthless. So instead of using a script block, we can  implement our own validator.

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

The first thing to point out is that I postfix my name with the `Attribute` keyword. When we attach that to our property, we can call it `[ValidatePathExists]`.

I inherit the `ValidateArgumentsAttribute` and I override the `[void] Validate ([object]$arguments, [System.Management.Automation.EngineIntrinsics]$engineIntrinsics)` function. I figured this out by looking at the Powershell source for an [example](https://github.com/PowerShell/PowerShell/blob/02b5f357a20e6dee9f8e60e3adb9025be3c94490/src/System.Management.Automation/engine/Attributes.cs#L1222). 

The `$Arguments` contains the value of the property. I have no idea what the `$engineIntrinsics` is, so I ignore it for now.

I decided to use standard exceptions in this case so the error message is localized. I could `throw` a custom message needed.

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
I use the script and match validators quite often but I do not like the cryptic message. If you truly need a better validator error message, it is worth considering this option.

# ArgumentTransformationAttribute
A lesser known attribute built into Powershell is the `ArgumentTransformationAttribute`.  This is also one that I discovered when looking at the Powershell source. There are only two (that are publicly accessible) that I know of.

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
            if($inputData -is [string])
            {
                if( -NOT [string]::IsNullOrWhiteSpace($inputData))
                {
                    $fullPath = Resolve-Path -Path $inputData -ErrorAction SilentlyContinue
                    if($fullPath -and -Not [string]::IsNullOrWhiteSpace($inputData))
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

The inner logic checks for a `[string]` and does a `Resolve-Path` on it. The if it can find a `FullName` property (assuming a file or directory), then it returns the `FullPath`. I decided to throw an error if there was no match but I could have returned the original object. 

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

## Let me know
If you find a good way to put this information to use, let me know. I would love to see some practical implementations. 
