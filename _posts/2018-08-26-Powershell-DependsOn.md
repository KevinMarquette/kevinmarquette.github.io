---
layout: post
title: "Powershell: DependsOn Module"
date: 2018-08-26
tags: [PowerShell,loanDepot]
share-img: "http://kevinmarquette.github.io/img/share-img/2018-08-26-Powershell-DependsOn.png"
---

One nice feature of a DSC configuration is that all resources support specifying a `DependsOn` property that ensures that the resources that it depends on are ran first. Every once in a while, I find myself wanting to use that feature in other scripts. I created a module called [DependsOn](https://github.com/loanDepot/DependsOn) to do that for me.

<!--more-->
# Index

* TOC
{:toc}

# Basic Scenario

Let's say I am creating some user groups from a datafile. Each item specifys the group name and the members of the group. Here is basic sample of what that json may look like.

``` json
    [
        {
            "Name":"Group1"
        },
        {
            "Name":"Group2",
            "Members":"Group1"
        }
    ]
```

If I process this list in order, I would create `Group1` first and then create `Group2` with `Group1` as a member. You can see how processing this in order is important. 

What if if we flipped the order?

``` json
    [
        {
            "Name":"Group2",
            "Members":"Group1"
        },
        {
            "Name":"Group1"
        }
    ]
```

When we go to create `Group2` with `Group1` as a member before creating `Group1` then I would expect our script to have an error.

We could manually keep our list in order. But this list could grow to be quite large or even data driven where we don't have a way to contol it.

# Resolve-DependencyOrder

This is where [DependsOn](https://github.com/loanDepot/DependsOn) offers a solution. It will take a list of items, allow you to define how they depend on each other, and then sort the items in order of that dependency.

I'm going to add a few more records and save them into `$groups`.

``` posh
    $groups = @'
    [
        {
            "Name":"Group4",
            "Members":["Group3","Group2"]
        },
        {
            "Name":"Group3",
            "Members":"Group1"
        },
        {
            "Name":"Group2",
            "Members":"Group1"
        },
        {
            "Name":"Group1"
        }
    ]
    '@ | ConvertFrom-Json
```

Now we get to sort it with `Resolve-DependencyOrder`.

``` posh
    PS\> $groups | Resolve-DependencyOrder -Key {$_.Name} -DependsOn {$_.Members} |
                   Select-Object Name, Members

    Name   Members
    ----   -------
    Group1
    Group3 Group1
    Group2 Group1
    Group4 {Group3, Group2}
```

It processed the groups from top to bottom. When it identified that `Group4` depended on `Group3` and `Group2`, it made sure they were in the list ahead of `Group4`. It then checked `Group3` to see that it depended on `Group1`. So it made sure that `Group1` was in the list ahead of `Group3`. By the time it got to `Group2`, `Group1` was already in the list so it was not added a 2nd time.

You may have noticed that `Group3` and `Group2` could have been processed in any order as long as `Group1` was processed first. The secondary sort is based on order of discovery. Either by walking dependencies or processing the list. I just happened to discover `Group3` before `Group2`.

# Parameters

Taking a closer look at the `Resolve-DependencyOrder`, we will see 2 important parameters. The `Key` defines how to to identify the object. The `DependsOn` then defines how to to identify what your object depends on. So it needs to be able to match the `DependsOn` values to the `Key` values. Both of these parameters are scriptblocks for maximum flexibility.

Here is a second example that use and array of hashtables instead of objects:

``` posh
    $familyTree = [ordered]@(
        @{Name='Girl';    DependsOn='Dad','Mom'}
        @{Name='Mom';     DependsOn='Dad'}
        @{Name='Dad';     DependsOn='Grandpa','Grandma'}
        @{Name='Grandpa'; DependsOn=$null}
        @{Name='Grandma'; DependsOn='Grandpa'}
        @{Name='Boy';     DependsOn='Dad','Mom'}
    )

    $familyTree |
        Resolve-DependencyOrder -Key {$_.name} -DependsOn {$_.DependsOn} |
        ForEach-Object {$_.name}
```

This will produce this list:

```
    Grandpa
    Grandma
    Dad
    Mom
    Girl
    Boy
```


# DependsOn alias

The alias for `Resolve-DependencyOrder` is `DependsOn`. I thing the name is a little long so I personally prefer the alias for this one.

``` posh
    $familyTree |
        DependsOn -Key {$_.name} -DependsOn {$_.DependsOn} 
```

# Value maps

My first 2 examples expect that the data has enough information to deterine what it's own dependencies are. We are also able to reference other sets of data or call other commands as part of that mapping process.

Here is an example where I have a list of strings that I want to order by using an external dependency map in a hashtable.

``` posh
    $list = @(
        'Girl'
        'Mom'
        'Grandpa'
        'Dad'
        'Grandma'
        'Boy'
    )

    $map = [ordered]@{
        'Girl'='Dad','Mom'
        'Mom'='Dad'
        'Grandpa' = $null
        'Dad'='Grandpa','Grandma'
        'Grandma'='Grandpa'
        'Boy'='Dad','Mom'
    }

    $list | Resolve-DependencyOrder -DependsOn {$map[$_]}
```

If you don't specify a key then it takes each object at it's value. When you have a list of strings then that is the value that gets used.

I used a hashtable here, but it easily could have been a call to a database or a reset endpoint for dependency information.

# Installing DependsOn

This module is published to the PSGallery.

``` posh
    Install-Module DependsOn -Scope CurrentUser
```

# About DependsOn

This is a hybrid module that support PowerShell Core and was built using the [PowerShell Standard Library](/2018-08-04-Powershell-Standard-Library-Binary-Module/?utm_source=blog&utm_medium=blog&utm_content=dependson). This is also the first open source module from [loandDepot](https://github.com/loandepot). I hope to see more of our modules and DSC resources like this opened up soon.

Let me know if you find a good use for this module.
