---
layout: post
title: "Powershell: Writing a TypeExtension DSL, DSLs part 4"
date: 2017-05-05
tags: [PowerShell, DSL, Advanced]
excerpt_separator: <!--more-->
---

Steffen Stranger pointed the [PowerShell-RFC RFC0017-Domain-Specific-Language-Specifications](https://github.com/PowerShell/PowerShell-RFC/blob/48f23e86b836dfe25ff3dd76733fc1dfb32e0e1f/3-Experimental/RFC0017-Domain-Specific-Language-Specifications.md) out to me recently.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr"><a href="https://twitter.com/hashtag/psconfeu?src=hash">#psconfeu</a> RFC proposes a C#-based mechanism for defining DSLs in <a href="https://twitter.com/hashtag/PowerShell?src=hash">#PowerShell</a>. <a href="https://t.co/YF850s8Q01">https://t.co/YF850s8Q01</a> cc <a href="https://twitter.com/KevinMarquette">@KevinMarquette</a> <a href="https://twitter.com/mcnabbmh">@mcnabbmh</a></p>&mdash; Stefan Stranger (@sstranger) <a href="https://twitter.com/sstranger/status/860154016604594179">May 4, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>


The [RFC](https://github.com/PowerShell/PowerShell-RFC/blob/48f23e86b836dfe25ff3dd76733fc1dfb32e0e1f/3-Experimental/RFC0017-Domain-Specific-Language-Specifications.md) is about making it easier to implement a DSL in Powershell with C#. They have an example of a DSL to replace `types.ps1xml`. It is a nice clear example of a DSL.<!--more-->

This is my fourth post in this series covering DSLs.

* Part 1: [Intro to Domain-Specific Languages](/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1)
* Part 2: [Writing a DSL for RDC Manager](/2017-03-04-Powershell-DSL-example-RDCMan)
* Part 3: [DSL design patterns](/2017-03-13-Powershell-DSL-design-patterns/)
* Part 4: Writing a TypeExtension DSL (This post)
* Part 5: [Writing an alternate TypeExtension DSL](/2017-05-18-PowerShell-TypeExtension-DSL-part-5)

# Index

* TOC
{:toc}

# The Example

Here is a partial example from the RFC:

    # Extend the System.Array type
    TypeExtension [System.Array] {
        # Add a new Sum method (from Bruce Payette's "Windows PowerShell in Action", p. 435)
        Method Sum {
            $acc = $null
            foreach ($e in $this)
            {
                $acc += $e
            }
            $acc
        }

        # Add an alias property
        Property Count -Alias Length
    }

    # Add a DateTime property to the System.DateTime class
    TypeExtension [System.DateTime] {
        Property DateTime {
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

The RFC is about more than just allowing us to create that DSL. The main goal was to add better support into the AST and open up access to other features. Features that DSC has access to that are internal to PowerShell.

I say that because as I was looking at the example, I felt like it would be a good example for us to work through.

# What I need to figure out

I see three thing that I need to figure out how to do. How to add a method, an alias property and a calculated property to a type.

In my post about [PSCustomObjects](https://kevinmarquette.github.io/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/?utm_source=blog&utm_medium=blog&utm_content=PSTypeExtension), I quickly mention the use of [Update-TypeData](https://kevinmarquette.github.io/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/?utm_source=blog&utm_medium=blog&utm_content=PSTypeExtension#update-typedata-with-defaultpropertyset). I think I can use that as a starting point.

The first thing I am going to do is walk that example DSL and do each of those by hand. I need to know how to do it in PowerShell before I get clever with it.

## Add script method

The first example is a script method.

    # Extend the System.Array type
    TypeExtension [System.Array] {
        # Add a new Sum method (from Bruce Payette's "Windows PowerShell in Action", p. 435)
        Method Sum {
            $acc = $null
            foreach ($e in $this)
            {
                $acc += $e
            }
            $acc
        }
    }

Let's rework that using `Update-TypeData`.

    $TypeData = @{
        TypeName = 'System.Array'
        MemberType = 'ScriptMethod'
        MemberName = 'Sum'
        Value = {
            $acc = $null
            foreach ($e in $this)
            {
                $acc += $e
            }
            $acc
        }
    }
    Update-TypeData @TypeData

Now if we create that object, we get a sum method.

    PS:> [system.array]$object = @(1,2)
    PS:> $object.Sum()
    3

## Add alias property

The next one in the list was an alias property

    Property Count -Alias Length

Would be this:

    $TypeData = @{
        TypeName = 'System.Array'
        MemberType = 'AliasProperty'
        MemberName = 'Lenght'
        Value = 'Count'
    }
    Update-TypeData @TypeData


## Add script property

Now for the script property example.

    Property DateTime {
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

Here is the current equivalent command in PowerShell.

    $TypeData = @{
        TypeName = 'System.DateTime'
        MemberType = 'ScriptProperty'
        MemberName = 'DateTime'
        Value = {
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
    Update-TypeData @TypeData

A quick check of the results:

    $date = get-date
    $date.DateTime

# DSL game plan

So after reviewing those examples, this looks like the base syntax that I am looking to implement.

    TypeExtension <Type> {
        Method <Name> <ScriptBlock>
        Property <Name> -Alias <PropertName>
        Property <Name> <ScriptBlock>
    }

I don't see any keywords that will conflict with PowerShell. The `TypeExtension` will be an advanced function that uses a `ScriptBlock` to collect the child keywords. `Method` and `Property` will be implemented as advanced functions. I will end up executing the `TypeExtension` `ScriptBlock` to run the `Method` and `Property` functions. And I will make the first positional parameter for `Method` and `Property` the `MemberName`.

There are two approaches that I can take with the implementation of `Method` and `Property`.

## Option 1

I can make the `Method` and `Property` keywords functions that take the parameters and executes `Update-TypeData`. I would need to get the type data into the function and would end up doing it with a script scoped variable.

## Option 2

I can make the `Method` and `Property` keywords functions return hashtables. I could then add the typedata to the `TypeName` key of each hashtable and just splat it into `Update-TypeData`.

# Implementation

I decided to use option 2 for this implementation. It just felt very clean and elegant to me. I think it will make it easier to extend in the long run. This should come together quickly for us.

## TypeExtension function

For the `TypeExtension`, I want the user to be able to provide a type for the first parameter. I would be fine if it is just a `string`. The second positional parameter will be a `ScriptBlock` that gets executed. We expect the results from the `ScriptBlock` to be one or more `Hashtables`.

We will walk each `Hashtable`, add the `TypeName` key and then spat it to `Update-TypeData`. Now that we defined it so simply, it will be a very easy function to write.

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
                $results = & $TypeData

                If( $type -match '^\[(?<Type>.*)\]$' )
                {
                    $type = $matches.Type
                }

                foreach($options in $results)
                {
                    if($options -is [hashtable])
                    {
                        $options.TypeName = $type.ToString()
                        Update-TypeData @options -Force
                    }
                    else
                    {
                        Write-Error "TypeData has unexpected value [$options]"
                    }
                }
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }

I added basic error and exception handling here because this will be the the public function that is called by the end user.

## Method function

This function will allow us to create script methods for a given type. The first parameter will be the name and the second will be the method script. We will use those parameters to create a `Hashtable`.


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
            [string]
            $Name,

            [Parameter(Mandatory,Position=1)]
            [ValidateNotNullOrEmpty()]
            [scriptblock]
            $ScriptBlock
        )
        process
        {
            @{
                MemberType = 'ScriptMethod'
                MemberName = $Name
                Value = $ScriptBlock
            }
        }
    }

We return the `Hashtable` to `TypeExtension` for processing.

## Property function

When we consider the script property, then this is almost identical to the previous function. But we need to support an alternate syntax with this one for the alias property. I will solve this one with a `ParameterSet` to handle the two use-cases.

    function Property
    {
        <#
            .Description
            Allows you to add an alias or script property to a type
        #>
        [cmdletbinding(DefaultParameterSetName='ScriptProperty')]
        param(
            [Parameter(Mandatory,Position=0)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Name,

            [Parameter(
                Mandatory,
                Position=1,
                ParameterSetName='ScriptProperty'
            )]
            [ValidateNotNullOrEmpty()]
            [scriptblock]
            $ScriptBlock,

            [Parameter(
                Mandatory,
                Position=1,
                ParameterSetName='AliasProperty'
            )]
            [ValidateNotNullOrEmpty()]
            [string]
            $Alias
        )

        process
        {
            $typeData = @{
                MemberName = $Name
            }

            If($PSCmdlet.ParameterSetName -eq 'ScriptProperty')
            {
                $typeData.MemberType = 'ScriptProperty'
                $typeData.Value = $ScriptBlock
            }
            else
            {
                $typeData.MemberType = 'AliasProperty'
                $typeData.Value = $Alias
            }

            $typeData
        }
    }

Now if we run the original DSL example, then our implementation will just work.

# Wrapping it all together

I saw this as a good follow up example to my previous coverage of DSLs. I hope that by writing this so quickly that I don't take anything away from that original RFC. It addressed more than just creating DSLs and this was only an example of how it could be implemented.

I can't wait to see some of the work that comes out of that RFC. But until then, we have our own DSL implementations to play with. It should be very easy to extend this approach to support the other `Update-TypeData` options.

On my next post, I will take a different approach to this same scenario.

* Part 5: [Writing an alternate TypeExtension DSL](/2017-05-18-Powershell-TypeExtension-DSL-part-5)