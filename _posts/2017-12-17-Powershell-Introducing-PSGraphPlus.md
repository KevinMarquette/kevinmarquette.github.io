---
layout: post
title: "Powershell: Introducing PSGraphPlus with Show-GitGraph"
date: 2017-12-17
tags: [PowerShell]
share-img: "/img/share-img/2017-12-17-Powershell-Introducing-PSGra
phPlus.png"
---

I have been presenting my [PSGraph](https://github.com/KevinMarquette/PSGraph) module to a few [Powershell user groups](https://www.youtube.com/watch?v=pR_xzZh9qoI). One thing I do in my demos is use local system information to generate graphs. Things like network connections and process relationships. Some of them have turned out to be quite useful. So I have started compiling them into a new module called [PSGraphPlus](https://github.com/KevinMarquette/PSGraphPlus).

One of the commands that I find myself running all the time from this module is `Show-GitGraph`. I spent today working on it and I would like to share my progress.

<!--more-->

#Index

* TOC
{:toc}

# Git as a directional graph

Git makes a great example for PSGraph because it is already a directional graph. Every commit has one or more parent commits. Each branch just points to a specific commit. We just have to map it out.

![Basic Sample](/img/basicgit.png)

This looks a lot like the diagrams that you see in git help guides. This one shows 2 branches and several commits.

# Show-GitGraph

If you want to generate graphs like that for your Git repository, you can use `Show-GitGraph` to do so. Let's take a look at an example from a real repository.

    Show-GitGraph -Depth 5

![PSGraph](/img/psgraphgit.png)

By specifying a depth of 5, it will only show the 5 most recent commits. The yellow box is a tag for my v1.2 release. The first green box is a remote feature branch that I merged into master but never cleaned up. The last two green boxes show my local and remote master branches are pointing to the same commit. The gray box indicates the current branch that I have checked out.

## Feature list

Here is a quick overview of the `Sho-GitGraph` parameters and features.

* `-Depth` to configure how much history to show
* `-Direction` to change the direction of the graph. `TopToBottom` or `LeftToRight`
* Tags are listed in yellow
* Local and remote branches in green
* Shows sister branches that are not in the current branches git log
* Current location in gray
* `-ShowCommitMessage` to show the commit message

# More examples

You can see many of those in action on the graph above. I also want to show you the same graph with a `TopToBottom` direction and the `-ShowCommitMessage`.

    Show-GitGraph -Depth 5 -ShowCommitMessage -Direction TopToBottom

![PSGraph2](/img/psgraphgit2.png)

I know there are a lot of tools out there that would do a much better job exploring the commit history, but I find it handy having this command at my fingertips.

Here is one last piece of eye candy to leave you with.

![Git Graph Example](/img/gitgraphexample.png)

# Installing PSGraphPlus

This module builds on my PSGraph module. So you will need both PSGraph and GraphViz installed first. Run these next commands from a PowerShell 5.0 admin prompt to install everything you need.

    # Install GraphViz from the Chocolatey repo
    Register-PackageSource -Name Chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/
    Find-Package graphviz | Install-Package -ForceBootstrap

    # Install from the Powershell Gallery
    Find-Module PSGraph -Repository PSGallery | Install-Module
    Find-Module PSGraphPlus -Repository PSGallery | Install-Module


I'll be continuing to add more commands to this module as I discover good things to graph. If you come up with a good idea that you feel should be included, let me know. I would love to hear it.
