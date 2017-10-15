---
layout: post
title: "PowerShell: Automatic Module Semantic Versioning"
date: 2017-10-14
tags: [PowerShell,Build,Module]
---

I am just getting started on a new module [PSGraphPlus](https://github.com/KevinMarquette/PSGraphPlus) and if you know me, this is when I take a look at how I build modules. I fleshed out a lot of little bugs with my [Full Module Plaster Template](https://github.com/KevinMarquette/PlasterTemplates) and I spent a little time working on my [module build script](https://github.com/KevinMarquette/PSGraphPlus/blob/master/module.build.ps1). I may talk about that build process in another post but for the sake of this conversation, it is just a script that I run that performs several actions on my module. It runs tests, bumps the version and publishes to the [PSGallery](https://www.powershellgallery.com/).

Today, I am going to walk you through how I bump that version based on changes in my module.

<!--more-->

# Index

* TOC
{:toc}

# What is a Semantic version number?

When it comes down to it, a version number is just a few numbers separated by periods (ex `2.13.87.2342`). Semantic versioning is one popular way to manage the version number. If we call the parts of the version `Major`, `Minor`, `Patch`, `Build` in that order;

* `Major` is updated when there are breaking changes
* `Minor` is updated when there are feature additions (that don't have breaking changes)
* `Path` is updated when you fix or change something
* `Build` is optional and changes every build if you include it

This is greatly simplified but will cover what we need for today. Check out [semver.org](http://semver.org/) if you would like more information.

# Updating the version of a module manifest

I leverage the [BuildHelper](https://github.com/RamblingCookieMonster/BuildHelpers) community module to help me update the version on my manifest. It has a lot of great little tools in there. We are going to work with `Step-ModuleVersion` today.

If you open your module manifest, you will see a version property that looks something like this:

    # Version number of this module.
    ModuleVersion = '2.13.87'

If we want to bump it from `2.13.87` to `2.13.88`, we can use `Step-ModuleVersion` to do so.

     $ManifestPath = '.\MyModule.psd1'
     Step-ModuleVersion -Path $ManifestPath -By Patch

That command makes it easy to bump the version every time, but I want Semantic versioning.

# Detecting changes in the module

I decided to monitor the function names and their parameters to detect breaking changes. My theory is that if I ever remove or rename a function or its parameter, I should consider that a breaking change and update the major version number. I can use that same logic to detect the addition of functions or parameters as a feature addition.

## The fingerprint

First, we need to build our fingerprint. Here is my plan:

* Import the module
* Get the functions
* Enumerate the parameters for each
* Create a fingerprint like this "function:parameter"

Here is the code that does that.

    Import-Module ".\$ModuleName"
    $commandList = Get-Command -Module $ModuleName
    Remove-Module $ModuleName

    Write-Output 'Calculating fingerprint'
    $fingerprint = foreach ( $command in $commandList )
    {
        foreach ( $parameter in $command.parameters.keys )
        {
            '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
            $command.parameters[$parameter].aliases | 
                Foreach-Object { '{0}:{1}' -f $command.name, $_}
        }
    }

We will then save that fingerprint to a file in the project.

## Checking the fingerprint

Each build we will load the existing fingerprint, compare it to the current one and update it. Comparing each line between the two fingerprints will let us know if we added or deleted something.

    if ( Test-Path .\fingerprint )
    {
        $oldFingerprint = Get-Content .\fingerprint
    }

    $bumpVersionType = 'Patch'
    'Detecting new features'
    $fingerprint | Where {$_ -notin $oldFingerprint } | 
        ForEach-Object {$bumpVersionType = 'Minor'; "  $_"}
    'Detecting breaking changes'
    $oldFingerprint | Where {$_ -notin $fingerprint } | 
        ForEach-Object {$bumpVersionType = 'Major'; "  $_"}

    Set-Content -Path .\fingerprint -Value $fingerprint

In this example, if there were no changes then we would bump the `Patch` version. If I have something in the new fingerprint that is not in the old one, then we bump the `Minor` version. Finally, we move onto detecting when a fingerprint that was there before but was removed in order to bump the `Major` version.

Now that we know what to bump, we return to `Step-ModuleVersion` to take care of it.

    $ManifestPath = '.\MyModule.psd1'
    Step-ModuleVersion -Path $ManifestPath -By $bumpVersionType

# End result

Having this as part of my module build script will allow me to automatically indicate if a release has a breaking change. This only does so much. I can still update my version by hand when needed if there are other changes that would not be detected by this.

# Closing details

The one issue with this approach is the extra file added to the project. This means that if you use a build system to run this, you would have to have it check the file in after the build. I currently run it locally so the fingerprint becomes part of my check-in.

I had an earlier version of this that would use the `FunctionsToExport` in the module manifest to detect changes. It only handled new and removed functions.

I'll see how it works on this project before I go add it to all my other projects. If you want to see this in my build script, you can see it here: [module.build.ps1](https://github.com/KevinMarquette/PSGraphPlus/blob/master/module.build.ps1).
