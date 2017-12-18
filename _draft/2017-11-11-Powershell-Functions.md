---
layout: post
title: "Powershell: Exploring Functions"
date: 2017-11-11
tags: [PowerShell]
---

Functions are very important in most languages. PowerShell is no exception. I want to break down what it means to be a function in PowerShell to see if we can discover anything interesting along the way. 
<!--more-->

# Index

* TOC
{:toc}

# To the beginner

I know many of my posts start with a conversation for the beginner and end with me sharing everything I know about the topic.  

# Getting Started



In it's simplest form, a function is a script block with a friendly name. Let me show you what that looks like.

Lets say we have a statement like this for looking at a shortcut:

    $shortcut = Get-ChildItem '~\desktop\*.lnk' | Select -First 1
    $WScriptShell = New-Object -ComObject WScript.Shell
    $WScriptShell.CreateShortcut( $shortcut.fullname )

I picked a random shortcut off my desktop and looked at where it pointed to. My output looks like this:

    FullName         : C:\Users\kevmar\desktop\Docker for Windows.lnk
    Arguments        :
    Description      : Docker for Windows
    Hotkey           :
    IconLocation     : C:\Program Files\Docker\Docker\Docker for Windows.exe,0
    RelativePath     :
    TargetPath       : C:\Program Files\Docker\Docker\Docker for Windows.exe
    WindowStyle      : 1
    WorkingDirectory :



# Putting it all together


# What's next?


