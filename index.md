---
layout: page
title: PowerShell Explained
subtitle: With Kevin Marquette
---

# Popular reference pages

* [Installing MSIs](/2016-10-21-powershell-installing-msi-files/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Reading and writing to files](/2017-03-18-Powershell-reading-and-saving-data-to-files/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Variable substitution](/2017-01-13-powershell-variable-substitution-in-strings/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Hashtables](/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [PSCustomObject](/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Switch Statement](/2018-01-12-Powershell-switch-statement/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Exceptions](/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [Regex](/2017-07-31-Powershell-regex-regular-expression/?utm_source=blog&utm_medium=blog&utm_content=popref)
* [More](/tags/?utm_source=blog&utm_medium=blog&utm_content=popref)

# About Kevin Marquette

I am a Sr. DevOps Engineer for loanDepot in Irvine, CA, Microsoft MVP, 2018 PowerShell Hero, and SoCal PowerShell User Group Organizer. I have been passionate about PowerShell for a very long time. I enjoy learning about PowerShell and sharing the things that I discover.

# Projects

## Blog\Research

The primary focus of my [blog](/blog/?utm_source=blog&utm_medium=blog&utm_content=index) is on PowerShell. I love to learn and research ideas in PowerShell. When I find something interesting or new, I write about those discoveries.

When I cover fundamentals, my intention is that everyone walks away learning something. My coverage on [hashtables](/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog&utm_content=index) gently introduces hashtables and continues on to take the topic to the most advanced details.

### Recent posts

{% include recent-posts.md %}
* [More](/tags/?utm_source=blog&utm_medium=blog&utm_content=recent)

## PowerShell Modules

### DependsOn

[DependsOn](https://github.com/loanDepot/DependsOn) is a PowerShell Module that allows you to define dependencies in your data and order the data based on those dependencies.

### PSGraph

[PSGraph](/2017-01-30-Powershell-PSGraph//?utm_source=blog&utm_medium=blog&utm_content=projects) is a Powershell Module that allows you to script the generation of graphs using the GraphViz engine. It makes it easy to produce data driven visualizations.

### PSGraphPlus

[PSGraphPlus](https://github.com/KevinMarquette/PSGraphPlus) is a Powershell Module generates graphs using PSGraph. It has commands that will generate graphs of git repos and local network connections. Most of my best demos are captured as functions in this module. It saves you the work of crafting those graphs yourself.

### Chronometer

[Chronometer](/2017-02-05-Powershell-Chronometer-line-by-line-script-execution-times/?utm_source=blog&utm_medium=blog&utm_content=projects) analyzes a script or module during execution and reports line by line execution times. It allows you to see your code coverage and where most of your execution time is spent.

### GetPlastered
[GetPlastered](/2017-05-14-Powershell-Plaster-GetPlastered-template/?utm_source=blog&utm_medium=blog&utm_content=recent) is a Plaster template that will turn a folder into a Plaster template that can deploy that folder. The idea is to use this as a starting point to create the Plaster manifest when you know it will contain a lot of files.

### Select-Ast
[SelectAst](https://github.com/KevinMarquette/Select-Ast) is a helper command for working with the AST. It takes care of the delegate logic for you so you can select what you want with simpler syntax.