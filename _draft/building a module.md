---
layout: post
title: "Powershell: Creating a module"
date: 2017-1-11
tags: [PowerShell,Module]
---

I have not built a module from scratch in a long time. My process has evolved and I have incorperated a lot of ideas into my process. Most of the time, I copy an existing module and just gut out all the funtions. This has worked becuase each module grows a little more from the last time I built one. 

I also realize that I may have some older ideas baked into my process. I have seen a lot of good work in the community that I have not formally adopted because what I had just worked. It was quick and easy to run with. 

I am working on a new module and I want to rethink a lot of the things I have done when setting up a new module. To help get a fresh perspective on this, I am going to build it based on the work done by [RamblingCookieMonster](http://ramblingcookiemonster.github.io/) and I am going to use his [PSDepend](https://github.com/RamblingCookieMonster/PSDepend) project as my reference. He has built quite a few modules for the community and already has a lot of the things I would like to implement. It also helps that he has written many of the things I want to use and has several great blog posts on how to use them.

# Getting Started

I have been working with [GraphViz](http://graphviz.org/) recently and I really like it. It gives me the ability to generate graphs or diagrams in script. With the proper helper functions, it would make it very easy to generate graphs on the fly. 

So, lets get started. The first thing is to create a new repository on github called PSGraphViz. If we are going to use source control, we may as well start with it. Once that is created, I clone it to my local system to work on.

    git clone https://github.com/KevinMarquette/PSGraphViz.git

## Folder Structure

I created a folder structure much like PSDepend for everything to live in. 

    PSGraphViz
    ├───Examples
    ├───PSGraphViz
    │   ├───Classes
    │   ├───Private
    │   └───Public
    └───Tests

I am going to take a moment to talk about what we have here as a way to understand it better. This already breaks from my appraoch and I think it does so in a good way. First off, the module is not the entire git repo. It will be contained in the sub `PSGraphViz` folder. The `Private` and `Public` folders will contain the functions for the module. I added Classes because I plan on using them for this project. 

By moving the Module out of the root of the repository, it allows us to have the Examples, Tests, build and publish components outside the module. I like this because they don't need to be a part of the module and my require additional dependencies that the module should not need when deployed. 

# Additional files

There are a lot of additional files I need to point out. I may start with some empty files and build them as I work through each one.

## \build.ps1
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

In this script, we are defaulting to the 'default' task. The psake.ps1 script will have more tasks and the $Task will allow us to run specified build steps if needed. Then it installs and loads all the required modules for the build. I like what I see here, so I'll reuse this script as it is. `Set-BuildEnvironment` is new to me, so I'll to loop back and figure out what that is doing later.

## psake.ps1

This is the [psake](https://github.com/psake/psake) script that runs all the build tasks. I am going to leave this blank for the moment because I want to take my time walking this file. A lot of the magic is happening here. I do see that it has 4 tasks defined. init, test, build, deploy.

As I walk the [psake.ps1](https://github.com/RamblingCookieMonster/PSDeploy/blob/master/psake.ps1) script from PSDeploy, it looks very approachable. There are some hooks in there to account for running in a build system and publishing test results from pester to that build. I may be able to barrow this as it is without changing anything.

It is too long to post here so check it out on the repo.

## appvoyer.yml

This is used for automated builds. Again, this is something that I want to implement. The RamblingCookieMonster already has a Guide up talking about how he set it up in [Fun with Github, Pester, and AppVeyor](http://ramblingcookiemonster.github.io/GitHub-Pester-AppVeyor/). 

I went over to [AppVoyer.com](https://ci.appveyor.com) and created an account. In almost no effort, I had it looking at my projects on GitHub. I ceated a new project in AppVoyer and selected the GraphViz project of mine. Just like that, I have a build system ready to build my module and I have not even checked anything in yet. 

This is the file.

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

This yaml file looks fairly basic with one exception. I'll mention how to get a NewgetApiKey in a moment, but that is something that needs to be secured. I pinged the RamblingCookieMonster on how he handled it and he told me it was encrypted. AppVoyer has a way to [encrypt strings](https://www.appveyor.com/docs/build-configuration/#secure-variables) that you can use this way. 

I used everything else as it was. 

## mkdocs.yml

Up until this point, I have actually worked with or have a general understanding of everything. This file was new to me. At first glance, it looks like it builds documentation out of markdown files. I like that idea of that. I think I have enough pieces on my plate, but this does intrest me. I'll loop back on this one in the future.

## deploy.GraphViz.ps1

After a bit of review, this looks like it allows the build system to deploy the module to the PS Gallery. It needs to be checked into master with a commit message containing `!deploy`. 

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

I don't think I need to even change anything in this file. I like the way it looks and what it does. That `$ENV:NugetApiKey` is actually my API key for the PS Gallery. That was securly created and added to the appvoyer.yml.

# Powershell Gallery

I did need to get an API key for the [Powershell Gallery](https://www.powershellgallery.com/account). Just had to register on the website and the key was right there. Very quick and simple.

# Module Manifest

After all of that, I still don't have a module manifest. I could have started with the manifest, but dropping in all these other files was fairly quick and I figured there is a lot of general module information available already.

I am going to create a quick module manifest.

    $module = @{
        Author = 'Kevin Marquette' 
        Description = 'GraphViz helper module for generating graph images' 
        RootModule = 'PSGraphViz.psm1'
        Path = 'PSGraphViz.psd1'
    }
    New-ModuleManifest @module

# pam1 module
Now we need to create the psm1 file for the module. Normally, you would place all your module code inside the .spm1 file. Technicaly, all you need is a .psm1 file to have a module. Because I like to break out my code into smaller files, the psm1 will be used to load those other files at runtime.

This is something I have done for a long time and alreayd have a good module loader. 

    Write-Verbose "Importing Functions"

    # Import everything in sub folders folder
    foreach($folder in @('private', 'public', 'classes'))
    {
        $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
        if(Test-Path -Path $root)
        {
            $files = Get-ChildItem -Path $root -Filter *.ps1 -Exclude *.tests.ps1

            # dot source each file
            $files | ForEach-Object{Write-Verbose $_.name; . $_.FullName}
        }
    }

    Export-Modulemember -function (Get-ChildItem -Path "$PSScriptRoot\public\*.ps1").basename

# Functions

Now that we have a loader, we can add a few functions. I'll start with a function to install GraphViz and another to wrap around the dot.exe. Once I get those two created, then I have a minimally viable module where I can add tests. I an also test and validate all the things I did up until this point. 

# In closing

I'll pick create those two functions and add more details in a future post. This all came together quite nicely. 

