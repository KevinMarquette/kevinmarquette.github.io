---
layout: post
title: "Powershell: How to copy a Hashtable"
date: 2017-08-11
tags: [hashtable]
---

Last week I was making some updates to my article on Hashtables and I added a section on how to make a copy of a Hashtable. As I was adding that part, I felt like there was a lot more depth to the topic than I could devote to it in that article. This is because the idea of making a copy of a Hashtable is a simple one but there are all kinds of scenarios that you may have to account for that can greatly complicate it.

<!--more-->

# Index

* TOC
{:toc}

# The Reddit challenge

The first think I did was post it as PowerShell challenge to the [http://www.reddit.com/r/powershell](/r/PowerShell) community.

> [PowerShell Challenge: create a copy of a hashtable](https://www.reddit.com/r/PowerShell/comments/6rq03i/powershell_challenge_create_a_copy_of_a_hashtable/)
> This is one that comes up from time to time. You have one hashtable and you want a clone or copy of it. Either post your own solution, add small features to someone else's or optimize a solution that someone already posted. If you have written this before, hang back a bit and see how the solutions develop.

> Today's lesson: there be icebergs

We had a lot of people get involved in providing solutions and providing counter examples. I'm going to start with some basic approaches to the problem and then highlight the scenarios they strugle with.

# Copying value types

To set the stage, I need to talk about value types. Basic values like numbers, strings, and booleans are what we call value types. When you assign them to a variable, the variable holds that value.

    $value = 1

If you assign one variable to another variable, the second variable gets a copy of the first value.

    $primary = 1
    $secondary = $primary
    
But these variables are not connected. You can assign a new value one of them without the other changing.

    PS> $secondary = 2
    PS> "primary:   $primary"
    PS> "secondary: $secondary"

    primary:   1
    secondary: 2

You can never modify a value type. You can only ever assign a new value to a value type variable.

# Assigning reference types

A `Hashtable` is a reference type. With a reference type, the variable only points to (or references) the target object. The actual value of the variable is a location in memory but this is hidden from you. The reason that I point this out is that when you have a variable that is a reference type and assign it to a second variable, they are both pointing to the same thing.

    PS> $primary = @{name='Kevin'}
    PS> $secondary = $primary
    PS> "primary:   {0}" -f $primary.name
    PS> "secondary: {0}" -f $secondary.name

    primary:   Kevin
    secondary: Kevin

At first glance, this looks like what you expect. We see the issue when we start to make changes.

    PS> $secondary.name = 'Alex'
    PS> "primary:   {0}" -f $primary.name
    PS> "secondary: {0}" -f $secondary.name

    primary:   Alex
    secondary: Alex

Instead of having a copy of the `Hashtable`, we have 2 variables that reference the same `Hashtable`.

# Shallow clones

Our hashtable has a `clone()` method that looks promising. This will make a quick copy of our object.

This does a good job of copying all the base level properties to the new object. And if our object is flat or has no depth to it, then this works perfectly. 

If our object contains other reference types, we have the same variable assignment issues on those properties that we saw above. This is why we call it a shallow copy. Only the first level of the object is truly copied. All of the child objects

# Deep copies with recursion

# Seralization



# Putting it all together


# What's next?


