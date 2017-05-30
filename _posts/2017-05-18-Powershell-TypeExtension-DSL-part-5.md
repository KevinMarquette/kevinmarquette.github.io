---
layout: post
title: "Powershell: Writing an alternate TypeExtension DSL, DSLs part 5"
date: 2017-05-18
tags: [PowerShell, DSL, Advanced]
---

In my last post on DSLs, I broke down a proposed DSL that someone else had described. It was drafted specifically as an example DSL for a RFC. Today, I am going to propose an alternate DSL syntax and I am going to break down the implementation just like I did last time.

My real motivation for this is to break away from the way most DSLs are implemented. There is a strong tenancy to see every keyword as an advanced function that takes a string and a script block. I want to show that we have other options.<!--more-->

This is the fifth post in my series on DSLs.

* Part 1: [Intro to Domain-Specific Languages](/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1)
* Part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)
* Part 3: [DSL design patterns](/2017-03-13-Powershell-DSL-design-patterns/)
* Part 4: [Writing a TypeExtension DSL](/2017-05-05-PowerShell-TypeExtension-DSL-part-4)
* Part 5: Writing an alternate TypeExtension DSL (This post)

# Index

* TOC
{:toc}

# The example DSL

Here is my draft example of how that DSL could look for creating `TypeExtension` properties for a class.

    # Extend the System.Array type
    TypeExtension [System.Array] {

        # Add an alias property
        Count = Property Length

        # Add a new Sum method (from Bruce Payette's "Windows PowerShell in Action", p. 435)
        Sum = Method {
            $acc = $null
            foreach ($e in $this)
            {
                $acc += $e
            }
            $acc
        }
    }

    # Add a DateTime property to the System.DateTime class
    TypeExtension [System.DateTime] {
        DateTime = Property {
            if ((& {Set-StrictMode -Version 1; $this.DisplayHint}) -ieq "Date")
            {
                "{0}" -f $this.ToLongDateString()
            }
            elseif ((& {Set-StrictMode -Version 1; $this.DisplayHint }) -ieq "Time")
            {
                "{0}" -f $this.ToLongTimeString()
            }
            else
            {
                "{0} {1}" -f $this.ToLongDateString(), $this.ToLongTimeString()
            }
        }
    }

This is almost the same example from the last post. I made a small adjustment so it looks like you are creating properties. Here is a simpler view of the syntax.

    TypeExtension <Type> {
        <name> = Method <ScriptBlock>
        <name> = Property <PropertName>
        <name> = Property <ScriptBlock>
    }

I think this would feel natural to work with even if the implementation is not obvious.

# Implementation

We will start with the `Method` and `Property` keywords. They will be the easiest to implement and look the most like our implementations from the last post.

## Method keyword

This will be an advanced function that takes a single parameter. I will place that parameter into a `Hashtable` and return it.

    function Method
    {
        <#
            .Description
            Allows you to add a script method to a type
        #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory,Position=0)]
            [ValidateNotNullOrEmpty()]
            [scriptblock]
            $ScriptBlock
        )
        process
        {
            @{
                MemberType = 'ScriptMethod'
                Value = $ScriptBlock
            }
        }
    }

I am also adding the `MemberType` as part of the return value. This will be very important later.

## Property keyword

This will be just like the `Method` keyword except I am going to check the type on the input value to decide the `MemberType`.


    function Property 
    {
        <#
            .Description
            Allows you to add an alias or script property to a type
        #>
        [cmdletbinding()]
        param(
            [Parameter(
                Mandatory,
                Position=0
            )]
            [ValidateNotNullOrEmpty()]
            $Value
        )

        process
        {
            $typeData = @{
                Value = $Value
            }

            If($Value -is [ScriptBlock])
            {
                $typeData.MemberType = 'ScriptProperty'
            }
            else
            {
                $typeData.MemberType = 'AliasProperty'
            }

            $typeData
        }
    }

## TypeExtension keyword

The `TypeExtension` function will be the most complicated part of this. I have to be a little clever here because I am letting the design drive the implementation. In general it is best to stay away from clever code because it is hard to understand and maintain.

Our keywords are returning hashtables with two properties. The `MemberType` and the `Value`. Those are both parameters for `Update-TypeData`. If you want to see the examples for how to use `Update-TypeData`, please see my previous post where I showed how to do these things by hand.

If I looked at the `ScriptBlock` as if it was a `Hashtable`, then the keys would be the `MemberName`.

    TypeExtension <Type> {
        <MemberName> = Method <ScriptBlock>
        <MemberName> = Property <PropertName>
        <MemberName> = Property <ScriptBlock>
    }

So I am going to turn that `ScriptBlock` into a `Hashtable` using the method described in my [DSL Design Patterns](/2017-03-13-Powershell-DSL-design-patterns/#hashtable-builder) post.

In that post, I convert the `ScriptBlock` to a string, add the syntax needed to transform it into a valid looking hashtable, and I execute it to get an actual `Hashtable`.

Then we walk the keys for the values that I need. Each key is the name of a property and the value has the `TypeExtension` data for that property.


    function TypeExtension 
    {
        <#
            .Description
            Allows you to update type information
        #>
        [cmdletbinding()]
        param(
            [Parameter(Mandatory,Position=0)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Type,

            [Parameter(Mandatory,Position=1)]
            [ValidateNotNullOrEmpty()]
            [scriptblock]
            $TypeData
        )
        process
        {
            try
            {
                $newScript = "[ordered]@{$($TypeData.ToString())}"
                $newScriptBlock = [scriptblock]::Create($newScript)
                [hashtable]$PropertyList = & $newScriptBlock
                
                If( $type -match '^\[(?<Type>.*)\]$' )
                {
                    $type = $matches.Type
                }

                foreach( $property in $PropertyList.GetEnumerator() )
                {                    
                    If( $property.Value -is [hashtable] )
                    {
                        $options = $property.Value
                    }
                    elseIf( $property.Value -is [scriptblock] )
                    {
                        $options = @{
                            MemberType = 'ScriptProperty'
                            Value = $property.Value
                        }
                    }
                    else
                    {
                        $options = @{
                            MemberType = 'AliasProperty'
                            Value = $property.Value
                        }
                    }
                    
                    $options.MemberName = $property.key
                    $options.TypeName = $type.ToString()

                    Update-TypeData @options -Force                    
                }
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }

# Recap

I ended up adding a little more validation that allows for more flexibility for the user. That validation makes the `Property` keyword optional. So my new DSL syntax tree looks like this:

    TypeExtension <Type> {
        <MemberName> = Method <ScriptBlock>
        <MemberName> = [Property] <PropertName>
        <MemberName> = [Property] <ScriptBlock>
    }

This approach has a nice feel for the end user for these specific options. The down side of this implementation is that it has a single focus on properties. If that is all we wanted to support, then this would be perfect.

# Just an example

Remember that this is an alternate example. For this specific example, I like previous approach better.

If you have worked with `Update-TypeData` before then you know that is modifies a lot more than properties. You can modify what shows when `format-list` is executed or how  `group-object` uses for grouping. The approach we used in the previous post would be much easier to extend to support these other options.