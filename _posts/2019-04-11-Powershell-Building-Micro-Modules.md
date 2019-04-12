---
layout: post
title: "Powershell: Building Micro Modules"
date: 2019-04-11
tags: [PowerShell,Module]
share-img: "/img/share-img/2019-04-11-Powershell-Building-Micro-Modules.svg"
---

I am a big fan of modules as a way to package and distribute PowerShell functions. I create modules all the time and I tend to use a fairly robust set of build and release scripts. More recently, I have wanted to release an individual advanced function as a module but I felt that my existing process was a bit much. So I started building micro modules instead.

<!--more-->

# Index

* TOC
{:toc}

# What is a micro module?

A micro module is very small in scope and often has a single function. Building a micro module is about getting back to the basics and keeping everything as simple as possible. 

There is a lot of good advice out there on how to build a module. That guidance is there to assist you as your module grows in size. If we know that our module will not grow and we will not add any functions, we can take a different approach even though it may not conform fully to the community best practices.

## Single function

The whole idea behind the micro module is that there is only one function. Because there is one function, we place it directly into the `.psm1` file in source. This is important because when you have multiple functions, you should have them in their own files.

I love having multiple files for my dev work but that requires that I add a build script to combine them into the `.psm1` for publishing. By having the single function in the `.psm1` file already, I can skip that build step. I can just publish the module as it sits in source control. 

# A closer look

Let's take a look at the structure of my `Watch-Command` module. `Watch-Command` is a micro module that I published last week. I see 7 files in this project.

```
Watch-Command
│   azure-pipelines.yml
│   publish.ps1
│   readme.md
│
├───.vscode
│       settings.json
│
└───Watch-Command
        LICENSE
        Watch-Command.psd1
        Watch-Command.psm1
```

## Module files

The `Watch-Command` folder is the actual module with 3 files. The `.psm1` file has 90 lines of PowerShell for the 1 function (named the same as my module). The `.psd1` is still important and is required to publish to the PSGallery. I also have a `LICSNSE` file in this folder so it gets delivered with the module.

# Continuous Delivery

Even though it is a simple module, I still leverage a continuous delivery pipeline to publish the module.

### publish.ps1

At the heart of the pipeline is the `publish.ps1` that will publish my module to the PSGallery. Here is a look at the `publish.ps1` file in the project.

``` posh
$publishModuleSplat = @{
    Path        = ".\Watch-Command"
    NuGetApiKey = $ENV:nugetapikey
    Verbose     = $true
    Force       = $true
    Repository  = "PSGallery"
    ErrorAction = 'Stop'
}

"Files in module output:"
Get-ChildItem $Destination -Recurse -File |
    Select-Object -Expand FullName

"Publishing [$Destination] to [$PSRepository]"

Publish-Module @publishModuleSplat
```

It is basically a call to `Publish-Module` with a little verbosity. The important detail here is that the `nugetapikey` is pulled from an environment variable. 

### azure-pipelines.yml

I am using azure devops pipelines to manage the deployment. I define the whole build in the `azure-pipelines.yml` file. This allows me to just point the pipleine at my source and the build will just work.

``` yaml
trigger:
  batch: true
  branches:
    include:
      - master

pool:
  vmImage: 'windows-2019'

steps:
- script: pwsh -Command {Install-Module PowerShellGet -Force}
  displayName: 'Update powershellget'
- script: pwsh -File publish.ps1
  displayName: 'Build and Publish Module'
  env:
    nugetapikey: $(nugetapikey)
```

The first thing I do is update `PowerShellGet` in its own build step. This way when the next PowerShell step executes, I know that it is running with a current verison of `PowerShellGet`.

For the second step, I call the `publish.ps1` script to publish the module. I also need to map the environment `nugetapikey` to the build step or it will be `null` in my script for the publish.

## Setting up the pipeline

I set up a single DevOps Pipeline for all my micro modules, but each one will get a unique build in that pipeline. When you create the build, you will have to point it at your source repository. Then specify the `azure-pipelines.yml` for the build definition.

### nugetapikey

I generate a new PSGallery api key each project and add it to the build as an environment vaiable. Make sure you click the little lock to protect the value.

## publish

At this point, I am able to merge into master and the module will get published. 

# Closing comments

If you get a chance, you should check out my `Watch-Command` module. It lets you specify a command to be ran every 15 seconds. It will then clear the screen and show you the results of that command (over and over until you kill it). 

Here is an example of it showing the local process list sorted by cpu time.

``` posh
Watch-Command {Get-Process | Sort cpu -desc}
```

This micro module pattern was fast to set up. I was able to write my `Watch-Command` module and have the pipleine publishing it the same day. This allowed me to focus on my ideas and quickly get it out the door.
