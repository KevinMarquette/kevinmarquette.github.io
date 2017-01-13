---
layout: post
title: "Powershell: Creating a module"
date: 2017-1-11
tags: [PowerShell,Module]
---

I have not built a module from scratch in a long time. My process has evolved and I have incorperated a lot of ideas into my process. Most of the time, I copy an existing module and just gut out all the funtions. This has worked becuase each module grows a little more from the last time I built one. 

I also realize that I may have some older ideas baked into my process. I have seen a lot of good work in the community that I have not formally adopted because what I had just worked. It was quick and easy to run with. 

I am working on a new module and I want to rethink a lot of the things I have done when setting up a new module. To help get a fresh perspective on this, I am going to build it based on the work done by [RamblingCookieMonster](http://ramblingcookiemonster.github.io/) and I am going to use his [PSDepend](https://github.com/RamblingCookieMonster/PSDepend) project as my reference. He has built quite a few modules for the community and already has a lot of the things I would like to implement. It also helps that he has written many of the things I want to use and has several great blog posts on how to use them.

h3. Getting Started

I have been working with [GraphViz](http://graphviz.org/) recently and I really like it. It gives me the ability to generate graphs or diagrams in script. With the proper helper functions, it would make it very easy to generate graphs on the fly. 

So, lets get started. The first thing is to create a new repository on github called PSGraphViz. If we are going to use source control, we may as well start with it. Once that is created, I clone it to my local system to work on.

    git clone https://github.com/KevinMarquette/PSGraphViz.git

h3. Folder Structure

I am going to create a folder structure much like PSDepend for everything to live in. 

    PSGraphViz
    ├───Examples
    ├───PSGraphViz
    │   ├───Classes
    │   ├───Private
    │   └───Public
    └───Tests

I am going to take a moment to talk about what we have here as a way to understand it better. This already breaks from my appraoch and I think it does so in a good way. First off, the module is not the entire git repo. It will be contained in the sub `PSGraphViz` folder. The `Private` and `Public` folders will contain the functions for the module. I added Classes because I plan on using them for this project. 

By moving the Module out of the root of the repository, it allows us to have the Examples, Tests, build and publish components outside the module. I like this because they don't need to be a part of the module and my require additional dependencies that the module should not need when deployed. 

h3. Additional files

There are a lot of additional files I need to point out. I may start with some empty files and build them as I work through each one.

h4. \build.ps1
Having this file makes it very easy to figure out where to build from. I have used psake before and the common pattern is to have a build.ps1 file as a starting point that then calls the psake.ps1 file. 

    param ($Task = 'Default')

    # Grab nuget bits, install modules, set build variables, start build.
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

    Install-Module Psake, PSDeploy, BuildHelpers -force
    Install-Module Pester -RequiredVersion 3.4.2 -Force
    Import-Module Psake, BuildHelpers

    Set-BuildEnvironment

    Invoke-psake -buildFile .\psake.ps1 -taskList $Task -nologo
    exit ( [int]( -not $psake.build_success ) )

In this script, we are defaulting to the 'default' task. The psake.ps1 script will have more tasks and the $Task will allow us to run specified build steps if needed. Then it installs and loads all the required modules for the build. I like what I see where so I'll reuse this script as it is. `Set-BuildEnvironment` is new to me, so I need to loop back and figure out what that is doing.

h4. psake.ps1

This is the psake script that runs all the build tasks. I am going to leave this blank for the moment because I want to take my time walking this file. A lot of the magic is happening here. I do see that it has 4 tasks defined. init, test, build, deploy.

h4. appvoyer.yml

This is used for automated builds and module deployment. Again, this is something that I want to implement but I plan on looping back to.



Now I have a folder with a readme.md file in it. I am going to create a quick module manifest.

    $module = @{
        Author = 'Kevin Marquette' 
        Description = 'GraphViz helper module' 
        RootModule = 'PSGraphViz.psm1'
        Path = 'PSGraphViz.psd1'
    }
    New-ModuleManifest @module
    Set-Content -Value '' -Path $module.RootModule

Now I have an empty module with nothing in it. 

h3. Next steps
I already have an idea of some of the modules that I want to incorporate into this one. Here is the list of things that I am looking to incorporate into this module. 

* Pester
* PSDepends
* psake
* BuildHelper
* PSDeploy

Some of those I have never worked with before so this feels like a great time to learn them. I have worked with others on my own, but I want to investigate how the community is using them for ideas that I have overlooked. And Pester is an old friend of mine.

    
    