---
layout: post
title: "Powershell: PSCustomObject"
date: 2016-11-04
tags: [PowerShell]
---

## Creating objects

I love using `[PSCustomObject]` in Powershell. Creating a usable object has never been easier.

    $myObject = [PSCustomObject]@{
        Name     = 'Kevin'
        Language = 'Powershell'
        State    = 'Texas'
    }

This works well for me because I use hashtables for just about everything. But there are times when I would like Powershell to treat them more like an object and this does it. the first place you notice the difference is when you want to use `Format-Table` or `Export-CSV` and you realize that a hashtable is not an object.

## Converting a hashtable

While I am on the topic, did you know you could do this:

    $myHashtable = @{
        Name     = 'Kevin'
        Language = 'Powershell'
        State    = 'Texas'
    }
    $myObject = [pscustomobject]$myHashtable

I do prefer to create the object from the start but there are times you have to work with a hashtable first. This works because the constructor takes a hastable for the properties. 

## PSTypeName for custom object types

Now that we have an object, there are a few more things we can do with it that may not be nearly as obvious. First thing we need to do is give it a `PSTypeName`. This is the most common way I see people do it:

    $myObject.PSObject.TypeNames.Insert(0,"My.Object")

I recently discovered another way to do this from this [post by /u/markekraus](https://www.reddit.com/r/PowerShell/comments/590awc/is_it_possible_to_initialize_a_pscustoobject_with/). I did a little digging and more posts about the idea from [Adam Bertram](http://www.adamtheautomator.com/building-custom-object-types-powershell-pstypename/) and [Mike Shepard](https://powershellstation.com/2016/05/22/custom-objects-and-pstypename/) where they talks about this approach where you can define it inline.

    $myObject = [PSCustomObject]@{
        PSTypeName = 'My.Object'
        Name       = 'Kevin'
        Language   = 'Powershell'
        State      = 'Texas'
    }

I love how nicely this just fits into the language. Now that we have an object with a proper type name, we can do some more things.

## Default dispaly set

Powershell decides for us what properties to display by default. A lot of the native commands have a `.ps1xml` formating file that does all the heavy lifting. From this [post by Boe Prox](https://learn-powershell.net/2013/08/03/quick-hits-set-the-default-property-display-in-powershell-on-custom-objects/), there is a much simpler way for us to do this on our custom object. We can give it a `MemberSet` for it to use.

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

## Parameter Validation and OutputType

One more thing that comes to mind is parameter validation for an advanced function (This was Adam's example too). You can also define an output type for your advanced functions.

    function Get-MyObject
    {
        [OutputType('My.Object')] 
        [CmdletBinding()]
            param
            (
                [Parameter()]
                [ValidateNotNullOrEmpty()]
                [PSTypeName('My.Object')]
                $MyObject
            )
        
            Write-Output $MyObject
    }

This works really well if you need your custom object as the property. It will throw a validation error if the type does not match. 

Defining the `OutputType` does not do any output validation like you may think it should. Right now it feels like a good practice but I think the only thing that may use is is the ISE.

 