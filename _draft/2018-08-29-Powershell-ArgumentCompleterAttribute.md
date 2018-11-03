---
layout: post
title: "Powershell: ArgumentCompleterAttribute"
date: 2018-08-29
tags: [PowerShell]
---

<!--more-->

# Index

* TOC
{:toc}

# Getting Started


# Putting it all together


# What's next?

A fairly commonly-requested functionality for custom functions is to be able to perform custom tab completion.

In simple scenarios, this can be accomplished with [ValidateSet()], which takes an array of values that it will cycle through for tab completion. Enums can also be used for this functionality.

Another, more advanced option is Register-ArgumentCompleter. However, this has the distinct disadvantage that it must be invoked from outside the function after the function has been parsed and read into memory.

There's a third option that we don't really see mentioned much: [ArgumentCompleter()]

This is quite a simple parameter attribute, and is used something like this:

function Test-ArgumentCompleter {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [ArgumentCompleter({ Get-ChildItem -Path 'C:\' -Directory | Select-Object -ExpandProperty Name })]
        [ValidateScript({$_ -in (Get-ChildItem -Path 'C:\' -Directory | Select-Object -ExpandProperty Name })]
        [string]
        $FolderName
    )
    Write-Warning "You have selected the folder $FolderName"
    Remove-Item "C:\$FolderName" -WhatIf
}
Now, note that here I have also paired it with a ValidateScript. ValidateSet doesn't allow arbitrary script block input, but it does both tab complete and validate the parameter value.

ArgumentCompleter unfortunately does not do validation, but it is perfectly capable of providing impromptu values for you to work with. For example, when building a custom function you may want it to be able to query the domain for possible values for a -ComputerName parameter.

It's important to note that the attribute script block is not invoked in the local scope. It's invoked in the global scope. As such, in order to utilise outside variables inside the completion, they must be globally scoped. This is likely a bug, and is one possible reason you might still want to use Register-ArgumentCompleter.

https://www.reddit.com/user/Ta11ow/comments/9b23yx/argumentcompleterattribute/?utm_content=full_comments&utm_medium=message&utm_source=reddit&utm_name=frontpage

A few of us on the PS Slack were stumbling over Romero's issue where he was basically trying to reinvent this (not knowing it already exists).

/u/SeeminglyScience pointed this one out, I think, and since I had never seen in written down literally anywhere I figured may as well write something down about it. :D
