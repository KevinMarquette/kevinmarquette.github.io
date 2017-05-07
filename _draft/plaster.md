I was about to create a new module and decided that I was going to script out the process this time. Most of my stuff is very cookie cutter between modules. A lot of my standard stuff is duplicated across my modules.

David just covered the use of Plaster and it is exactly what I need for this. I am going to build on his post so you really should go read it first.

This also builds on my previous post about building a CI/CD pipeline. I am mostly automating the work done in that post.

# Index

* TOC
{:toc}

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
    ├──yModule
    │   │   Module.psd1
    │   │   Module.psm1
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

I don't know that we will capture all of that into a Plaster template. But we can see what we are trying to create.


# Getting started

The first thing I did was create a new repository for my Plaster templates. I plan on this being the first of many Plater templates that I create.

## My first Plaster manifest

The first one is going to be called `FullModuleTemplate`.


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

        <file source='\root\module.psm1' destination='\${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psm1'/>

        <newModuleManifest 
            destination='\${PLASTER_PARAM_ModuleName}\${PLASTER_PARAM_ModuleName}.psd1'
            moduleVersion='$PLASTER_PARAM_Version'
            rootModule='${PLASTER_PARAM_ModuleName}.psm1'
            author='$PLASTER_PARAM_FullName'
            description='$PLASTER_PARAM_ModuleDesc'
            encoding='UTF8-NoBOM'/>

    </content>

This should cover everything I specified above. I added variables where I felt like I needed them as I went. I will go back and define them here in a bit. I also made note of some files that may need to be modified or converted to a template.