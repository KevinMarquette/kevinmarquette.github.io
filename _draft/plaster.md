---
layout: post
title: "Powershell: Adventures in Plaster"
date: 2017-05-08
tags: [PowerShell,Plaster,Modules]
---

I was about to create a new module and decided that I was going to script out the process this time. Most of my stuff is very cookie cutter between modules. A lot of my standard stuff is duplicated across my modules.

David just covered the use of Plaster and it is exactly what I need for this. I am going to build on his post so you really should go read it first.

This also builds on my previous post about building a CI/CD pipeline. I am mostly automating the work done in that post.

# Index

* TOC
{:toc}

# Copy/Paste warning

This was my first attempt and building a Plaster template so I am walking the process I used to figure it out. I made mistakes a long way and captured them in this post. Before you copy and paste examples, make sure you double check the context of the example.

# My Common module structure

First we need to know what we are building. Here is a structure that I modeled after my PSGraph module.

    MyModule
    │   appveyor.yml
    │   build.ps1
    │   LICENSE
    │   mkdocs.yml
    │   PITCHME.md
    │   psake.ps1
    │   readme.md
    │
    ├───docs
    │   │   about.md
    │   │   acknowledgements.md
    │   │   index.md
    │   │
    │   └───images
    │
    ├───Examples
    ├──ModuleName
    │   │   ModuleName.psd1
    │   │   ModuleName.psm1
    │   │
    │   ├───Classes
    │   │
    │   ├───Data
    │   │
    │   ├───Private
    │   │
    │   └───Public
    │
    ├───spec
    │       module.feature
    │       module.Steps.ps1
    │
    └───Tests
            Feature.Tests.ps1
            Help.Tests.ps1
            Project.Tests.ps1
            Regression.Tests.ps1
            Unit.Tests.ps1

I don't know that we will capture all of that into a Plaster template. But you can see what we are trying to create.

# Getting started

The first thing I did was create a new repository for my Plaster templates. I plan on this being the first of many Plater templates that I create.

## My first Plaster manifest

This first one is going to be called `FullModuleTemplate`.


    $manifestProperties = @{
        Path = ".\FullModuleTemplate\PlasterManifest.xml"
        Title = "Full Module Template"
        TemplateName = 'FullModuleTemplate'
        TemplateVersion = '0.0.1'
        Author = 'Kevin Marquette'
    }

    New-Item -Path FullModuleTemplate -ItemType Directory
    New-PlasterManifest @manifestProperties

## Template folder and file structure

I am making a design decision to create a root folder inside this template that will mirror the structure of my desired module. I will place all the folders and files inside there and work back from there.

    New-Item -Path FullModuleTemplate\root -ItemType Directory

 Most of the files in my module are very generic. My tests, build scripts and I can often copy them from one module to another. I will work these into the manifest first because they will be the easiest. I am also going to build my template with the idea that everything will be used. I can work in optional components later.

 I did a quick pass at copying files and then updated the `PlasterManifest.xml` with those entries. This is what my content section looks like after the first pass.

    <content>
        <message>
        Creating folder structure
        </message>
        <file source='' destination='\docs\images'/>
        <file source='' destination='\tests'/>
        <file source='' destination='\spec'/>
        <file source='' destination='\tests'/>
        <file source='' destination='\${PLASTER_PARAM_ModuleName}\public'/>
        <file source='' destination='\${PLASTER_PARAM_ModuleName}\private'/>
        <file source='' destination='\${PLASTER_PARAM_ModuleName}\classes'/>
        <file source='' destination='\${PLASTER_PARAM_ModuleName}\data'/>

        <message>
        Deploying common files
        </message>
        <file source='\root\appveyor.yml' destination='\'/>
        <file source='\root\build.ps1'    destination='\'/>
        <file source='\root\mkdocs.yml'   destination='\'/>
        <file source='\root\LICENSE.yml'  destination='\'/>
        <file source='\root\PITCHME.md'   destination='\'/>
        <file source='\root\psake.ps1'    destination='\'/>
        <file source='\root\readme.ps1'   destination='\'/>

        <file source='\root\docs\about.md' destination='\docs'/>
        <file source='\root\docs\acknowledgements.md' destination='\docs'/>
        <file source='\root\docs\index.md' destination='\docs'/>
        <file source='\root\docs\Quick-Start-Installation-and-Example.md' destination='\docs'/>

        <file source='\root\tests\Project.Tests.ps1' destination='\tests'/>
        <file source='\root\tests\Help.Tests.ps1' destination='\tests'/>
        <file source='\root\tests\Feature.Tests.ps1' destination='\tests'/>
        <file source='\root\tests\Regression.Tests.ps1' destination='\tests'/>
        <file source='\root\tests\Unit.Tests.ps1' destination='\tests'/>

        <file source='\root\spec\module.feature' destination='\spec'/>
        <file source='\root\spec\module.Steps.ps1' destination='\spec'/>

        <file source='\root\module\module.psm1' destination='\${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psm1'/>

        <newModuleManifest 
            destination='\${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psd1'
            moduleVersion='$PLASTER_PARAM_Version'
            rootModule='${PLASTER_PARAM_ModuleName}.psm1'
            author='$PLASTER_PARAM_FullName'
            description='$PLASTER_PARAM_ModuleDesc'
            encoding='UTF8-NoBOM'/>

    </content>

This should cover everything I specified above. I added variables where I felt like I needed them as I went. I will go back and define them here in a moment. I also made note of some files that may need to be modified or converted to a template.

## Adding parameters

At this stage, it is obvious that I am going to need to add some parameters so I can populate all the variables that I was using above. Once I add them in, I can start testing my template. Here is my first pass at the parameters section.

    <parameters>
        <parameter name="FullName" type="text" prompt="Module author's' name" />
        <parameter name="ModuleName" type="text" prompt="Name of your module" />
        <parameter name="ModuleDesc" type="text" prompt="Brief description on this module" />
        <parameter name="Version" type="text" prompt="Initial module version"  default="0.0.1"/>
    </parameters>

# First deploy

I have all my base files copied over, some parameter questions and the content section defined. I know I will need to turn some of those files into a Plaster `templateFile` but I want to see the basic template work first.

We are ready to run our template at this point.

    $plaster = @{
        TemplatePath = $manifestProperties.Path
        DestinationPath = "c:\temp\module"
    }

    New-Item -ItemType Directory -Path $plaster.DestinationPath

    Invoke-Plaster @plaster -Verbose

And I have an error right out of the gate.

    WARNING: Failed to create dynamic parameters from the template's manifest file.  Template-based dynamic parameters will not be available until the error is corrected.  The error was: The TemplatePath parameter value must refer to an existing directory. The specified path 'C:\workspace\PlasterTemplates\FullModuleTemplate\PlasterManifest.xml' does not.

It looks like it wants a directory instead of a full path to the xml file. That is easy enough to correct.

## Second deploy

Lets try that again.

    $plaster = @{
        TemplatePath = (Split-Path $manifestProperties.Path)
        DestinationPath = "c:\temp\module"
    }
    Invoke-Plaster @plaster -Verbose

We were prompted for our parameters this time:

    ____  _           _
    |  _ \| | __ _ ___| |_ ___ _ __
    | |_) | |/ _` / __| __/ _ \ '__|
    |  __/| | (_| \__ \ ||  __/ |
    |_|   |_|\__,_|___/\__\___|_|
                                                v1.0.1
    ==================================================
    Module author's' name: Kevin Marquette
    Name of your module: PSTest
    Brief description on this module: Test module for validating my template
    Initial module version (0.0.1):
    Destination path: C:\temp\module
        Creating folder structure

But I got a new error.

    The path '\docs\images' specified in the file directive in the template manifest cannot be an absolute path.
    Change the path to a relative path.

That looks like another easy one to correct. I am going to change all the locations to not have the leading backslash. This is the type of issue that using `Join-Path` would work around.

## Third deploy

So I updated all the paths from something like this:

    <file source='' destination='\docs\images'/>

To be like this:

    <file source='' destination='docs\images'/>

And I ran it again.

    PS:> Invoke-Plaster @plaster -Verbose
    ____  _           _
    |  _ \| | __ _ ___| |_ ___ _ __
    | |_) | |/ _` / __| __/ _ \ '__|
    |  __/| | (_| \__ \ ||  __/ |
    |_|   |_|\__,_|___/\__\___|_|
                                                v1.0.1
    ==================================================
    Module author's' name: Kevin Marquette
    Name of your module: PSTest
    Brief description on this module: template test
    Initial module version (0.0.1): 
    Destination path: C:\temp\module
        Creating folder structure    
    VERBOSE: Performing the operation "Create directory" on target "".
    Create docs\images\
    VERBOSE: Performing the operation "Create directory" on target "".
    Create tests\
    VERBOSE: Performing the operation "Create directory" on target "".
    Create spec\
    ...  

But we failed with another error:

    The path '\root\appveyor.yml' specified in the file directive in the template manifest cannot be an absolute path.  Change the path to a relative path.

## Next several deploys

So I had the same problem on my source paths. I made that correction and started experimenting with some of the values to try and get a clean run. I probably could have looked to the documentation at this point but I figure this part should be easy to work through.

In the process I learned another one of my assumptions was wrong. I am not sure why, but I assumed that an empty destination would place the files at the base of the new project. But something very different happened instead.

    <file source='root\appveyor.yml' destination='' />

This created a `root` folder with the `appveyor.yml` file inside of it. My clever idea to place everything in a root folder ended up working against me. I can either specify the full destination or re-base all my files to the root of the template folder. In this case, I am going to adjust the structure of my template. It now feels like that is the correct approach here.

Now that my files entries look like this:

    <file source='appveyor.yml' destination=''/>

I now get a clean Plaster run with this template.

    PS:> Invoke-Plaster @plaster -Verbose

    ____  _           _
    |  _ \| | __ _ ___| |_ ___ _ __
    | |_) | |/ _` / __| __/ _ \ '__|
    |  __/| | (_| \__ \ ||  __/ |
    |_|   |_|\__,_|___/\__\___|_|
                                                v1.0.1
    ==================================================
    Module author's' name: Kevin Marquette
    Name of your module: MyModule
    Brief description on this module: Testing Plaster Tempalte
    Initial module version (0.0.1): 
    Destination path: C:\temp\module
        Creating folder structure    
    VERBOSE: Performing the operation "Create directory" on target "".
    Create docs\images\
    VERBOSE: Performing the operation "Create directory" on target "".
    Create tests\
    ...
    VERBOSE: Performing the operation "Create new module manifest" on target "C:\temp\module\MyModule\MyModule.psd1".
    VERBOSE: Performing the operation "Create" on target "C:\temp\module\MyModule\MyModule.psd1".
    Create MyModule\MyModule.psd1

I trimmed the output above but this is what we just created.

    Module
    │   appveyor.yml
    │   build.ps1
    │   mkdocs.yml
    │   PITCHME.md
    │   psake.ps1
    │
    ├───docs
    │   │   about.md
    │   │   acknowledgements.md
    │   │   index.md
    │   │   Quick-Start-Installation-and-Example.md
    │   │
    │   └───images
    ├───MyModule
    │   │   MyModule.psd1
    │   │   MyModule.psm1
    │   │
    │   ├───classes
    │   ├───data
    │   ├───private
    │   └───public
    ├───spec
    │       module.feature
    │       module.Steps.ps1
    │
    └───tests
            Feature.Tests.ps1
            Help.Tests.ps1
            Project.Tests.ps1
            Regression.Tests.ps1
            Unit.Tests.ps1

# Checkpoint recap

Right now all we really have is a fancy `Copy-Item` script. But some of those files need to be customized and seeded with data. That is where Plater comes into play.

# First TemplateFile

I know my generic `module.feature` file requires one line to be updated with the module name. This would be a good one to start with.

My standard Gherkin `module.feature` file starts like this:

    Feature: A proper community module
        As a module owner
        In order to have a good community module
        I want to make sure everything works and the quality is high

    Background: we have a module
        Given the module was named ModuleName
        ...

I am going to update that last line like this:

     Given the module was named <%= $PLASTER_PARAM_ModuleName %>

And then update the `PlasterManifest.xml` to indicate `module.feature` is a `TemplateFile`.

    <templateFile  source='spec\module.feature' destination=''/>

Then re-run our template so we can see the results.

    Remove-Item -Path $plaster.DestinationPath -Recurse
    New-Item -ItemType Directory -Path $plaster.DestinationPath

    Invoke-Plaster @plaster -Verbose

And that worked amazingly well the first time.

    Background: we have a module
        Given the module was named MyModule

# More TemplateFiles

I have several other files to update like this.

## docs\about.md

The about page for the ReadTheDocs documentation:

    # What is <%= $PLASTER_PARAM_ModuleName %>

    <%= $PLASTER_PARAM_ModuleDesc %>

    Authored by <%= $PLASTER_PARAM_FullName %>

Generated this about page:

    # What is MyModule

    A module for testing my Plaster template

    Authored by Kevin Marquette

## docs\index.md

General index for the ReadTheDocs index:

    # <%= $PLASTER_PARAM_ModuleName %> Docs

    <%= $PLASTER_PARAM_ModuleName %> uses ReadTheDocs to host our documentation.  This allows us to keep our docs in the repository, without the various limitations that come with the built in GitHub repo wiki.

Generated this index page:

    # MyModule Docs

    MyModule uses ReadTheDocs to host our documentation.  This allows us to keep our docs in the repository, without the various limitations that come with the built in GitHub repo wiki.

## docs\Quick-Start-Installation-and-Example.md

The basic getting started guide for ReadTheDocs:

    # Installing <%= PLASTER_PARAM_ModuleName %>

        # Install <%= PLASTER_PARAM_ModuleName %> from the Powershell Gallery
        Find-Module <%= PLASTER_PARAM_ModuleName %> | Install-Module

Generated this page:

    # Installing MyModule

    # Install MyModule from the Powershell Gallery
    Find-Module MyModule | Install-Module

## mkdocs.yml

I already took care of a base set of ReadTheDocs files. Having them in place with minimal content makes it easier to update them in the future. We also need to update `mkdoc.yml` and as I do this, I see that we need new parameters. I am going to go ahead and add them to the template.

    site_name: <%= $PLASTER_PARAM_ModuleName %>
    repo_url: https://github.com/<%= $PLASTER_PARAM_GitHubUserName %>/<%= $PLASTER_PARAM_GitHubRepo %>
    theme: readthedocs
    pages:
    ...

And now I am going to create those parameters in my `PlasterManifest.xml`.

    <parameter name="GitHubUserName" 
      type="text" 
      prompt="GitHub username" 
      default="${PLASTER_PARAM_FullName}"
    />
    <parameter name="GitHubRepo" 
      type="text" 
      prompt="Github repo name for this module" 
      default="${PLASTER_PARAM_ModuleName}"
    />

I added these to the end of the parameters list and used default from earlier parameters. So if the module name and the GitHub repo name are the same, then the user can press enter to accept it.

    Module author's' name: Kevin Marquette
    Name of your module: MyModule
    Brief description on this module: Testing Plaster templates
    Initial module version (0.0.1): 
    GitHub username (Kevin Marquette): kevinmarquette
    Github repo name for this module (MyModule): 

And this is my end result:

    site_name: MyModule
    repo_url: https://github.com/kevinmarquette/MyModule
    theme: readthedocs
    pages:
    ...

# Wrapping it all up

I do have more work to do but I think you have the general idea now. This was very easy for me because many of my files are very generic already. My `module.psd1`, `psake.ps1`, `build.ps1` and most of those tests are the same for all of my modules (most of the time). I didn't have to add much logic to my template files because they are simple and I am including everything. 

I could have made several things optional and prompted for them. In my case, I want to do all these things all the time. I can always delete something if it is not fitting. 

## Resulting manifest

Here is the final PlasterManifest.xml with all of our changes in this post.

    <?xml version="1.0" encoding="utf-8"?>
    <plasterManifest schemaVersion="1.0" 
    xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>FullModuleTemplate</name>
        <id>abe7c8b0-2b42-4db8-8bfc-f4a61487d29c</id>
        <version>0.0.1</version>
        <title>Full Module Template</title>
        <description></description>
        <author>Kevin Marquette</author>
        <tags></tags>
    </metadata>
    <parameters>
        <parameter name="FullName" type="text" prompt="Module author's' name" />
        <parameter name="ModuleName" type="text" prompt="Name of your module" />
        <parameter name="ModuleDesc" type="text" prompt="Brief description on this module" />
        <parameter name="Version" type="text" prompt="Initial module version" default="0.0.1" />
        <parameter name="GitHubUserName" type="text" prompt="GitHub username" default="${PLASTER_PARAM_FullName}"/>
        <parameter name="GitHubRepo" type="text" prompt="Github repo name for this module" default="${PLASTER_PARAM_ModuleName}"/>
    </parameters>
    <content>
        <message>      Creating folder structure    </message>
        <file source='' destination='docs\images'/>
        <file source='' destination='tests'/>
        <file source='' destination='spec'/>
        <file source='' destination='tests'/>
        <file source='' destination='${PLASTER_PARAM_ModuleName}\public'/>
        <file source='' destination='${PLASTER_PARAM_ModuleName}\private'/>
        <file source='' destination='${PLASTER_PARAM_ModuleName}\classes'/>
        <file source='' destination='${PLASTER_PARAM_ModuleName}\data'/>
        <message>      Deploying common files    </message>
        <file source='appveyor.yml' destination=''/>
        <file source='build.ps1' destination=''/>
        <templateFile source='mkdocs.yml' destination=''/>
        <file source='PITCHME.md' destination=''/>
        <file source='psake.ps1' destination=''/>
        <templateFile source='docs\about.md' destination=''/>
        <file source='docs\acknowledgements.md' destination=''/>
        <templateFile source='docs\index.md' destination=''/>
        <templateFile source='docs\Quick-Start-Installation-and-Example.md' destination=''/>
        <file source='tests\Project.Tests.ps1' destination=''/>
        <file source='tests\Help.Tests.ps1' destination=''/>
        <file source='tests\Feature.Tests.ps1' destination=''/>
        <file source='tests\Regression.Tests.ps1' destination=''/>
        <file source='tests\Unit.Tests.ps1' destination=''/>
        <templateFile source='spec\module.feature' destination=''/>
        <file source='spec\module.Steps.ps1' destination=''/>
        <file source='module\module.psm1' destination='${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psm1'/>
        <newModuleManifest destination='${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psd1' moduleVersion='$PLASTER_PARAM_Version' rootModule='${PLASTER_PARAM_ModuleName}.psm1' author='$PLASTER_PARAM_FullName' description='$PLASTER_PARAM_ModuleDesc' encoding='UTF8-NoBOM'/>
    </content>
    </plasterManifest>

# More to come

I will continue to work on this Plaster template and I will share it out on GitHub.

Most of the examples out there are for creating functions or modules. I just want to remind you that you can use this to create any type of file. This is not limited to just PowerShell files. There are a lot more features than the ones I covered. Plaster has a lot of flexibility.

If I find any creative uses for it, I'll let you know.