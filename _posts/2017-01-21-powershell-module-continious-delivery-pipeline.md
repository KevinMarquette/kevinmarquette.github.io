---
layout: post
title: "Powershell: Let's build the CI/CD pipeline for a new module"
date: 2017-01-21
tags: [PowerShell,Modules]
---

A fresh start to building a module.

I have not built a module from scratch in a long time. My process has evolved and I have incorporated a lot of ideas into my process. Most of the time, I copy an existing module and just gut out all the functions. This has worked because each module grows a little more from the last time I built one. 

I also realize that I may have some older ideas baked into my process. I have seen a lot of good work in the community that I have not formally adopted because what I had just worked. It was quick and easy to run with. 

I am working on a new module and I want to rethink a lot of the things I have done when setting up a new module. I especially want to incorporate CI/CD (Continious Integration and Continious Delivery) ideas into my pipeline. To help get a fresh perspective on this, I am going to build it based on the work done by Warren Frame ([RamblingCookieMonster](http://ramblingcookiemonster.github.io/)) and I am going to use his [PSDepend](https://github.com/RamblingCookieMonster/PSDepend) project as my reference. He has built quite a few modules for the community. It also helps that he has written many of the modules that I am planning on using and has several great blog posts covering those modules.<!--more-->

[Index](#index)

# Quick overview
At a high level, we are going to build a new module and put in place several components that make up the CI/CD pipeline. 

* Source control with [Git](https://git-scm.com/) and [GitHub](https://github.com/)
* Build scripts with [psake](https://github.com/psake/psake)
* Tests with [Pester](https://github.com/pester/Pester)
* Publishing to the [Powershell Gallery](https://www.powershellgallery.com/) with [PSDeploy](https://github.com/RamblingCookieMonster/PSDeploy)
* Automated with [AppVeyor.com](https://www.appveyor.com/)

## Dependencies
The build script will handle most dependencies and we will create accounts with [AppVeyor.com](https://www.appveyor.com/) and [Powershell Gallery](https://www.powershellgallery.com/) along the way.

The only local component you really need in order to follow along is Git, Powershell 5.0 and Pester. If you run the build script, it will pull down all the other required modules to run the pipeline locally. 

# Getting started building my module
I have been working with [GraphViz](http://graphviz.org/) recently and I really like it. It gives me the ability to generate graphs or diagrams with text. With the proper helper functions, it would make it very easy to generate these graphs on the fly. 

So, let's get started. The first thing is to create a new repository on github called [PSGraph](https://github.com/KevinMarquette/PSGraph). If we are going to use source control, we may as well start with it. Once that is created, I clone it to my local system.

    git clone https://github.com/KevinMarquette/PSGraph.git

## Folder structure

I created a folder structure much like PSDepend. 

    PSGraph
    ├───Examples
    ├───PSGraph
    │   ├───Classes
    │   ├───Private
    │   └───Public
    └───Tests

This already breaks from my approach and I think it does so in a good way. Let's take a moment to talk about what we have here as a way to understand it better. First off, the module is not the entire git repo. It will be contained in the sub `PSGraph` folder. The `Private` and `Public` folders will contain the functions for the module. 

By moving the Module out of the root of the repository, it allows us to have the examples, tests, build and publish components outside the module. I like this because they don't need to be a part of the module and require additional dependencies that the module should not need when deployed. I plan on adopting it going forward.

# Additional files and components

There are a lot of additional files I need to walk through. 

## build.ps1
Having this file makes it very easy to figure out where to build from. I have used [psake](https://github.com/psake/psake) before and the common pattern is to have a build.ps1 file as a starting point that then calls the psake.ps1 file. 

    param ($Task = 'Default')

    # Grab nuget bits, install modules, set build variables, start build.
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

    Install-Module Psake, PSDeploy, BuildHelpers -force
    Install-Module Pester -Force -SkipPublisherCheck
    Import-Module Psake, BuildHelpers

    Set-BuildEnvironment

    Invoke-psake -buildFile .\psake.ps1 -taskList $Task -nologo
    exit ( [int]( -not $psake.build_success ) )

In this script, we are defaulting to the 'default' task. The psake.ps1 script will have more tasks and the `$Task` will allow us to run specified build steps if needed. Then it installs and loads all the required modules for the build. I like what I see here, so I'll reuse this script as it is. `Set-BuildEnvironment` is new to me, so I'll to loop back and figure out what that is doing later.

## psake.ps1

This is the psake script that runs all the build tasks. A lot of the magic is happening here. It has 4 tasks defined. `init`, `test`, `build` and `deploy`.

As I walk the [psake.ps1](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/psake.ps1) script from PSDeploy, it looks very approachable. There are some hooks in there to account for running in a build system and publishing test results from pester to that build. I can borrow this as it is without changing anything. It is a little long to post here so check it out on the repo.

## Powershell Gallery

I did need to get an API key for the [Powershell Gallery](https://www.powershellgallery.com/account). Just had to register on the website and the key was right there. Very quick and simple. I'll show you where to use it in the next section.

## appveyor.yml

This is used for automated builds. Again, this is something that I want to implement. Warren already has a Guide up talking about how he set it up in [Fun with Github, Pester, and AppVeyor](http://ramblingcookiemonster.github.io/GitHub-Pester-AppVeyor/). 

I went over to [AppVeyor.com](https://ci.appveyor.com) and created an account. With almost no effort, I had it looking at my projects on GitHub. I created a new project in AppVeyor and selected the GraphViz project of mine. Just like that, I have a build system ready to build my module and I have not even checked anything in yet. 

This is the file I need to place in my local project.

    # See http://www.appveyor.com/docs/appveyor-yml for many more options

    environment:
      NugetApiKey:
        secure: sqj8QGRYue5Vq3vZm2GdcCttqyOkt7NOheKlnmIUq1UcgVrmDezFArp/2Z1+G3oT

    # Allow WMF5 (i.e. PowerShellGallery functionality)
    os: WMF 5

    # Skip on updates to the readme.
    # We can force this by adding [skip ci] or [ci skip] anywhere in commit message 
    skip_commits:
    message: /updated readme.*|update readme.*s/

    build: false

    #Kick off the CI/CD pipeline
    test_script:
    - ps: . .\build.ps1

This yaml file looks fairly basic with one exception, the NewgetApiKey (PSGallery API key). I pinged Warren on how he handled it and he told me it was encrypted. AppVoyer has a way to [encrypt strings](https://www.appveyor.com/docs/build-configuration/#secure-variables) that you can use in your files. So just to be clear, this is not your plain text PSGallery api key. That would be very bad. This is encrypted with a private key stored in your AppVeyor account.

I used everything else as it was (Just had to provide my secured NugetApiKey).

## Build status in readme.md

One cool thing that I almost overlooked is that Warren has a realtime buid status icon in his project `readme.md`. It looks like this ![Build status](https://ci.appveyor.com/api/projects/status/cgo827o4f74lmf9w/branch/master?svg=true)

To get that, I had to add this line to the top of my `readme.md`.

    ![Build status](https://ci.appveyor.com/api/projects/status/cgo827o4f74lmf9w/branch/master?svg=true)

There is a project ID embedded in that first URL. `cgo827o4f74lmf9w`. I found that in AppVeyor.com under project settings in the Webhook URL field. This will be unique for each project.

He also wrapped that in a link to the build status page.

    https://ci.appveyor.com/project/kevinmarquette/PSGraph/branch/master


## mkdocs.yml

Up until this point, I have worked with or have a general understanding of these components already. This file was new to me. At first glance, it looks like it builds documentation out of markdown files. I like that idea of that. I think I have enough pieces on my plate, but this does interest me. I'll loop back on this one in the future.

## deploy.PSDeploy.ps1
After a bit of review, this looks like it allows the build system to deploy the module to the PS Gallery. PSDeploy when it runs, looks for this file for instructions on what to deploy and how. 

    if($ENV:BHProjectName -and $ENV:BHProjectName.Count -eq 1)
    {
        Deploy Module {
            By PSGalleryModule {
                FromSource $ENV:BHProjectName
                To PSGallery
                WithOptions @{
                    ApiKey = $ENV:NugetApiKey
                }
            }
        }
    }

I don't think I need to even change anything in this file. I like the way it looks and what it does. That `$ENV:NugetApiKey` is my API key for the PS Gallery. That was securely created and added to the appvoyer.yml.

## Pester test
I also need my first Pester test. When I run the build script, it dpends on me having passing tests. I'll do something simple like validate that the powershell is mostly valid code. This is my starter `tests\Project.Tests.ps1`

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psm1")
    $moduleName = Split-Path $moduleRoot -Leaf

    Describe "General project validation: $moduleName" {

        $scripts = Get-ChildItem $projectRoot -Include *.ps1,*.psm1,*.psd1 -Recurse

        # TestCases are splatted to the script so we need hashtables
        $testCase = $scripts | Foreach-Object{@{file=$_}}         
        It "Script <file> should be valid powershell" -TestCases $testCase {
            param($file)

            $file.fullname | Should Exist

            $contents = Get-Content -Path $file.fullname -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $errors.Count | Should Be 0
        }

        It "Module '$moduleName' can import cleanly" {
            {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force } | Should Not Throw
        }
    }

I defined several variables at the start that I feel like I may need. I am trying really hard to not hardcode paths or project names. I do this so I can easily reuse it in other projects.

The rest of it looks more complicated than it is. It first walks every Powershell file in the project and tries to tokenize it. If that fails, then there is a syntax error someplace. It then performs an import of the module. This is just a quick safety net for some typos and a good starter test for any project.

If we run this right now, only the module import should fail because we have not built that part yet.

## Module manifest

After all of that, I still don't have a module manifest. I could have started with the manifest, but dropping in all these other files was fairly quick. I figured there is a lot of general module information available already.

Here is a quick module manifest.

    $module = @{
        Author = 'Kevin Marquette' 
        Description = 'GraphViz helper module for generating graph images' 
        RootModule = 'PSGraph.psm1'
        Path = 'PSGraph.psd1'
        ModuleVersion = '0.0.1'
    }
    New-ModuleManifest @module

I ran this from the module root folder to build the actual manifest. I am considering moving this into the build process later.

## psm1 module
Now we need to create the psm1 file for the module. Normally, you would place all your module code inside the .psm1 file. Technically, all you need is a .psm1 file to have a module. Because I like to break out my code into smaller files, the psm1 will be used to load those other files at runtime.

This is something I have done for a long time and already have a good module loader. 

    Write-Verbose "Importing Functions"

    # Import everything in these folders
    foreach($folder in @('private', 'public', 'classes'))
    {
        
        $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
        if(Test-Path -Path $root)
        {
            Write-Verbose "processing folder $root"
            $files = Get-ChildItem -Path $root -Filter *.ps1

            # dot source each file
            $files | where-Object{ $_.name -NotLike '*.Tests.ps1'} | 
                ForEach-Object{Write-Verbose $_.name; . $_.FullName}
        }
    }

    Export-ModuleMember -function (Get-ChildItem -Path "$PSScriptRoot\public\*.ps1").basename


Because I have a build process, I may end up adding a build step to pull all these external files into the psm1 file at publish time. The module would load faster if it did that. 

## Functions

Now that we have a loader, we need to add a few functions. I created a wrapper for the primary executable in GraphViz. Go check out the project if you want to see how I did that one. I called it `Invoke-GraphViz` for now and placed it into the public folder `PSGraph\public\invoke-graphviz.ps1`.

Normally I would add this to the `FunctionsToExport` in the module manifest by hand. After everything is up and running, the build script should take care of that. That is one of the advantages of having a build process.

## Source control 
I have been saving into source locally this whole time. This is already part of my workflow.

    #Add all new files
    git add -A

    #Commit changes
    git commit -a -m 'updated project tests'

Sometimes I am already on the shell and just commit on the commandline. I also do a lot of work in [VSCode](https://code.visualstudio.com/) and it has great git integration. I do easily 95% of my git commits from within VSCode.

I also use some basic branching in my projects but that is not something we need to dive into at the moment.

# Testing and publishing
With all of our components in place and having a function we can actually use, I need to see all the pieces working.

## Pester tests
May as well start with our Pester tests. If I run the `Tests\Project.Tests.ps1` that we created earlier, we should see everything pass. We just have basic test coverage at this point.

    PS:> Invoke-Pester

    Describing General project validation: PSGraph
    [+] Script C:\workspace\PSGraph\PSGraph\Public\Install-GraphViz.ps1 should be valid powershell 112ms
    [+] Script C:\workspace\PSGraph\PSGraph\Public\Invoke-GraphViz.ps1 should be valid powershell 66ms
    [+] Script C:\workspace\PSGraph\PSGraph\PSGraph.psd1 should be valid powershell 69ms
    [+] Script C:\workspace\PSGraph\PSGraph\PSGraph.psm1 should be valid powershell 51ms
    [+] Script C:\workspace\PSGraph\Tests\Project.Tests.ps1 should be valid powershell 53ms
    [+] Script C:\workspace\PSGraph\build.ps1 should be valid powershell 55ms
    [+] Script C:\workspace\PSGraph\psake.ps1 should be valid powershell 58ms
    [+] Script C:\workspace\PSGraph\PSGraph.PSDeploy.ps1 should be valid powershell 54ms
    [+] Script C:\workspace\PSGraph\requirements.psd1 should be valid powershell 51ms
    [+] Module 'PSGraph' can import cleanly 88ms
    Tests completed in 662ms
    Passed: 10 Failed: 0 Skipped: 0 Pending: 0 Inconclusive: 0

Everything ran as expected.

## First local build
Now we run the build. It should first install all the build related dependencies from the PSGallery. The build runs but does not publish. I get this message:

    PS:> .\build.ps1

    Executing Build
    ----------------------------------------------------------------------
    Executing Deploy
    ----------------------------------------------------------------------
    Skipping deployment: To deploy, ensure that...
            * You are in a known build system (Current: Unknown)
            * You are committing to the master branch (Current: master)
            * Your commit message includes !deploy (Current: Working on the AppVeyor text upload component )

    Build Succeeded!

    ----------------------------------------------------------------------
    Build Time Report
    ----------------------------------------------------------------------
    Name   Duration
    ----   --------
    Init   00:00:00.0640305
    Test   00:00:01.6234376
    Build  00:00:04.3823107
    Deploy 00:00:00.0711113
    Total: 00:00:06.2215688

I get a clean build but nothing published to the PSGallery. I am good with that default behavior.

## First AppVeyor build

I am ready to see the AppVeyor system in action. I need a commit that contains `!deploy`. Then we need to push it to github.

    PS:> git commit -m '!deploy'
    PS:> git push

    Counting objects: 23, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (21/21), done.
    Writing objects: 100% (23/23), 5.62 KiB | 0 bytes/s, done.
    Total 23 (delta 8), reused 0 (delta 0)
    remote: Resolving deltas: 100% (8/8), completed with 2 local objects.
    To https://github.com/KevinMarquette/PSGraph.git
    af9aaba..e959142  master -> master

Give it a few minutes and we should see the build queued at appveyor.com when we log in. Once it starts, we can click on it to see the build output. 

The only thing left to do after it finishes is check the PSGallery for the module.

    PS:> Find-Module PSGraph

    Version Name       Repository Description
    ------- ----       ---------- -----------
    0.0.1   PSGraph PSGallery  GraphViz helper module

I guess everything worked. I love when that happens.

# In closing
This is really exciting that everything came together so well. Let's take a second and reflect on this. I took a project from the very start and it was published to the PSGallery automatically by the end of this post. I know I covered a lot of ground and skimmed over a lot of details of how these things worked. I more wanted to show you my workflow and approach to figuring this out.

This is the first time I touched several of these components and it all turned out to be a lot easier than I expected. What you don't see are the mistakes I made along the way. I had things named wrong or pieces missing at various times. At the end of the day, they were fairly easy to sort out. 

I do have to give a big thanks to the [RamblingCookieMonster](http://ramblingcookiemonster.github.io/) for sharing all his work. The code he has in [github](https://github.com/RamblingCookieMonster) and various blog posts is what allowed me to do this so easily.

I have a module, but now I need to do the real work. Me publishing a working function was only just the beginning.   

# Index

* TOC
{:toc}
