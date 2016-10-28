---
layout: post
title: "Powershell: Everything you wanted to know about PSCustomObject"
date: 2016-10-28
tags: [PowerShell]
---

`PSCustomObject`s are a great tool to add into your Powershell toolbelt. Let's start with the basics and work our way into the more advanced features. The idea behind using a `PSCustomObject` is to have a very simple way to create structured data. Take a look at the first example and you will have a better idea what that means.

## Creating objects

I love using `[PSCustomObject]` in Powershell. Creating a usable object has never been easier. Becaus of that, I am going to skip over all the other ways you can create an object.

    $myObject = [PSCustomObject]@{
        Name     = 'Kevin'
        Language = 'Powershell'
        State    = 'Texas'
    }

This works well for me because I use hashtables for just about everything. But there are times when I would like Powershell to treat hashtables more like an object and this does it. The first place you notice the difference is when you want to use `Format-Table` or `Export-CSV` and you realize that a hashtable is just a collection of key/value pairs.

You can then access and use the values like you would a normal object.

    $myObject.Name 

## Converting a hashtable

While I am on the topic, did you know you could do this:

    $myHashtable = @{
        Name     = 'Kevin'
        Language = 'Powershell'
        State    = 'Texas'
    }
    $myObject = [pscustomobject]$myHashtable

I do prefer to create the object from the start but there are times you have to work with a hashtable first. This works because the constructor takes a hastable for the object properties. One important note is that while this works, it is not an exact equivelent. The bigest difference is that the order of the properties is not preserved.

## PSTypeName for custom object types

Now that we have an object, there are a few more things we can do with it that may not be nearly as obvious. First thing we need to do is give it a `PSTypeName`. This is the most common way I see people do it:

    $myObject.PSObject.TypeNames.Insert(0,"My.Object")

I recently discovered another way to do this from this [post by /u/markekraus](https://www.reddit.com/r/PowerShell/comments/590awc/is_it_possible_to_initialize_a_pscustoobject_with/). I did a little digging and more posts about the idea from [Adam Bertram](http://www.adamtheautomator.com/building-custom-object-types-powershell-pstypename/) and [Mike Shepard](https://powershellstation.com/2016/05/22/custom-objects-and-pstypename/) where they talks about this approach that allows you to define it inline.

    $myObject = [PSCustomObject]@{
        PSTypeName = 'My.Object'
        Name       = 'Kevin'
        Language   = 'Powershell'
        State      = 'Texas'
    }

I love how nicely this just fits into the language. Now that we have an object with a proper type name, we can do some more things.

## Using DefaultPropertySet (the long way)

Powershell decides for us what properties to display by default. A lot of the native commands have a `.ps1xml` [formating file](https://mcpmag.com/articles/2014/05/13/powershell-properties-part-3.aspx) that does all the heavy lifting. From this [post by Boe Prox](https://learn-powershell.net/2013/08/03/quick-hits-set-the-default-property-display-in-powershell-on-custom-objects/), there is another way for us to do this on our custom object using just Powershell. We can give it a `MemberSet` for it to use.

    $defaultDisplaySet = 'Name','Language'
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $MyObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers

Now when my object just falls to the shell, it will only show those properties by default. 

## Update-TypeData with DefaultPropertySet

This is really nice but I recently saw a better way when watching [PowerShell unplugged 2016 with Jeffrey Snover & Don Jones](https://www.youtube.com/watch?v=Ab46gHXNm8Q). He was using [Update-TypeData](https://technet.microsoft.com/en-us/library/hh849908.aspx) to specify the default properties. 

    $TypeData = @{
        TypeName = 'My.Object'
        DefaultDisplayPropertySet = 'Name','Language'
    }
    Update-TypeData @TypeData

That is simple enough that I could almost remember it if I didn't have this post as a quick reference. Now I can easily create objects with lots of properties and still give it a nice clean view when looking at it from the shell. If I need to access or see those other properties, they are still there.

    $myObject | Format-List *

## Update-TypeData with ScriptProperty

Something else that I got out of that video was creating script properties for your objects. This would be a good time to point out that this works for existing objects too.

    $TypeData = @{
        TypeName = 'My.Object'
        MemberType = 'ScriptProperty'
        MemberName = 'UpperCaseName'
        Value = {$this.Name.toUpper()}
    }
    Update-TypeData @TypeData

You can do this before your object is created or after and it will still work.

## Function parameters

You can now use these custom types for parameters in your functions and scripts. You can  have one function create these custom objects and then pass them into other functions.

    param( [PSTypeName('My.Object')]$Data )

Powershell will then require that the object be of the type you specified. It will throw a validation error if the type does not match automatically to save you the step of testing for it in your code. A great example of letting Powershell do what it does best.

## Function OutputType

You can also define an `OutputType` for your advanced functions.

    function Get-MyObject
    {
        [OutputType('My.Object')] 
        [CmdletBinding()]
            param
            (
                ...

The [OutputType](https://technet.microsoft.com/en-us/library/hh847785.aspx) attribute value is only a documentation note. It is not derived from the function code or compared to the actual function output.

The main reason you would use an output type is so that meta information about your function reflects your intentions. Things like `Get-Command`,`Get-Help` and your development environment can take advantage of that.  If you want more information then take a look at the help for it: [about_Functions_OutputTypeAttribute](https://technet.microsoft.com/en-us/library/hh847785.aspx)

With that said, if you are utilizing Pester to unit test your functions then it would be a good idea to validate the output objects match your `OutputType`. This could catch variables that just fall to the pipe when they shouldn't.

## Closing thoughts

I have seen most of these features in passing before but never saw them presented as a collection of information on `PSCustomObject`. Just this last week I stumbled upon another one and was surprised that I had not seen it before. I wanted to pull all these ideas together so you can hopefully see the bigger picture and be aware of them when you have an opportunity to use them. I hope you learned something and can find a way to work this into your scripts. 
 