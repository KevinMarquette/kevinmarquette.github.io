
I am really quick to build a module out of my scripts. I like how it allows me to organize my functions and use them in other scripts. I also see that many PowerShell scripters are slow to take that step of building a module. We often learn how to build a module without really understanding why they are built that way.  

 In this post, we will turn a common script scenario into a full module one step at a time. We will take several microsteps to show all the subtle details of why common modules are built the way they are. Lets take the mystery out of building a module to see how simple they can be.

# Index

* Toc
{toc}

# Starting with functions

There is a natrual progression when working with PowerShell. You start with small script and work into making much larger ones. When your scripts get large, you start using more functions. These functions could be from someplace else or functions that you write yourself. These functions start collecting at the top of your script.

    function GetInfo{
        param($ComputerName)
        Get-WmiObject -ComputerName $ComputerName -Class Win32_BIOS
    }

    GetInfo -ComputerName localhost

You scripts are still long because all these functions are still taking up space in your script. This is the common scenario that we are going to build on. I have one function here but having several of them is common.

## Dot sourcing

From here, we would move the functions out into their own `.ps1` file. So if you saved that function into a file called `GetInfo.ps1`, then you could dot source it and call it like this.

    . .\GetInfo.ps1
    GetInfo -ComputerName localhost

Dot sourcing is a way to load a script into your current runspace. This function now becomes available to you or the calling script. Leaving out that period would run the script without leaving that defined function available in your script.

You can place multiple functions in that file and treat it like a library of functions.

# Import-Module

All it takes to turn your function script into a module is the use of `Import-Module` to import it. Here is how that works.

    Import-Module .\GetInfo.ps1
    GetInfo -ComputerName localhost

I like this so much more than dot sourcing. I really wish that this was the standard appraoch over dot sourcing for a two reasons. First is that it would be easier to understand and explain to people new to Powershell. And it moves the scripter down the path of making modules much sooner.

## .psm1

We can call `Import-Module` on a `.ps1`, but the convention is to use `.psm1` as a module designation. Rename that script to `GetInfo.psm1`.

    Import-Module .\GetInfo.psm1
    GetInfo -ComputerName localhost

Now we can say we have a module.

## Folder names

Then next thing I want to do is place our module into its own folder. The convention here is that the name of the folder matches the name of the `.psm1` file. Our file structure should look something like this now.

    Scripts
    │   myscript.ps1
    │
    └───GetInfo
            GetInfo.psm1

Then we update our `myscript.ps1` file to import that folder.

    Import-Module .\GetInfo
    GetInfo -ComputerName localhost

Import-Module will automatically find our `.psm1` file inside that folder. From here on out, that whole folder and all of it's contents will be our module.

## $ENV:PSModulePath

There is an environment variable called `$ENV:PSModulePath`. If we look at it, we will see all the locations where we can import a module (by module name instead of by path).

    PS:> $env:PSModulePath -split ';'

    C:\Users\username\Documents\WindowsPowerShell\Modules
    C:\Program Files\WindowsPowerShell\Modules

This is normally a single string but I split it up so we could read it. Sometimes you will install something that will add a path to that list. If we place our folder inside one of those two locations, we can import our module by name. 

So we need to move this module to `C:\Users\username\Documents\WindowsPowerShell\Modules`

    Move-Item .\GetInfo C:\Users\username\Documents\WindowsPowerShell\Modules\

Then our module should show up when we list available modules.

    Get-Module -ListAvailable

And we can import it by name in our script.

    Import-Module GetInfo
    GetInfo -ComputerName localhost

# Module manifest

We really should't call our module done until we add a module manifest. This adds metadata about your module. It includes author information and versioning. It also will enable PowerShell to autoload our module if we create it correctly.

The module manifest is just a hashtable saved as a `*.psd1` file. The name of the file should match the same of the folder. By creating this file, it will get loaded when you call `Import-Module`.

## New-ModuleManifest

The good news is that we have a `New-ModuleManifest` cmdlet that will create the manifest for us.

    $manifest = @{
        Path              = '.\GetInfo\GetInfo.psd1'
        RootModule        = 'GetInfo.psd1' 
        Author            = 'Kevin Marquette' 
        FunctionsToExport = 'GetInfo'
    }
    New-ModuleManifest @manifest

Because our manifest is loaded instead of the `*.psm1`, we need to use the `RootModule` parameter to indicate what Powershell module file should be ran. The functions to export indicates the functions in your module that should be available to anyone that imports the module. I'll talk about why this is important later.

Here is a clip of the manifest that we just generated.

    # Module manifest for module 'GetInfo'
    # Generated by: Kevin Marquette
    # Generated on: 5/21/2017

    @{

    # Script module or binary module file associated with this manifest.
    RootModule = 'GetInfo.psd1'

    # Version number of this module.
    ModuleVersion = '1.0'

    # ID used to uniquely identify this module
    GUID = 'dadea276-ae04-4c01-b901-06838167ec7c'

    # Author of this module
    Author = 'Kevin Marquette'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2017 Kevin Marquette. All rights reserved.'

    # Description of the functionality provided by this module
    # Description = ''

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'GetInfo'

    ...

    }

The `New-ModuleManifest` created all those keys and comments for us.

## Module autoloading

One nice feature of having a module manifest with `FunctionsToExport` defined, is that Powershell can auto import your module if you call one of the exported functions. Your module still has to be in the `$ENV:PSModulePath` variable for this to work.

This is why it is important to populate the `FunctionsToExport`. The default value for this is `*` to designate that it is exporting all functions defined in the module. This does work, but the auto import functionality depends on this value. This is often overlooked by a lot of module builders.

# $PSModuleAutoloadingPreference 

Module autoloading was introduced in PowerShell 3.0. We were also given `$PSModuleAutoloadingPreference` to control that behaviour. If you want to disable module autoloading for all modules, then set this value to `none`.

    $PSModuleAutoloadingPreference = 'none'

Unless your doing module development, you would generally leave this variable alone.

# #Reqires -Modules 

When you have a script that requires a module, you can add a requires statement to the top of your script. This will require that the specified module is loaded before your script runs. If the module is installe

Just because you can auto import a properly creafted module in your script just by calling functions from it, you really should import the module first. 





