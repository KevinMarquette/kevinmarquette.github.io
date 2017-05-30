---
layout: post
title: "Powershell: GetPlastered, a Plaster template to create a Plaster template"
date: 2017-05-14
tags: [PowerShell,Plaster]
---

I recently started working with [Plaster](https://github.com/PowerShell/Plaster) and I really like this module. I covered my first template in my [Adventures in Plaster](/2017-05-12-Powershell-Plaster-adventures-in/?utm_source=blog&utm_medium=blog&utm_content=getplastered) blog post last week. I have been pulling together ideas for more Plaster templates and I thought up a fun one to work on.

I am going to build a Plaster template that builds a Plaster template. I am calling this new template `GetPlastered`.

This will be a good example demonstrating the TemplateFile features of Plaster.<!--more-->

# Index

* TOC
{:toc}

# Project plan

My primary goal is to have a Plaster template that will turn an existing folder/project into a Plaster template. Our Plaster template will generate a `PlasterTemplate.xml` for that folder.

This can be confusing because we are also creating a `PlasterTemplate.xml` to make this template that generates a `PlasterTemplate.xml` for a new template. It is like we are writing code that writes the same code that we are writing.

# Starting a new template

I already have a repository for my [Plaster templates](https://github.com/KevinMarquette/PlasterTemplates), so all I need to do is create the initial template manifest.

    $templateName = 'GetPlastered'
    $manifestProperties = @{
        Path = ".\$templateName\PlasterManifest.xml"
        Title = "Generate Plaster Maifest"
        TemplateName = $templateName
        TemplateVersion = '0.0.1'
        Author = 'Kevin Marquette'
    }

    New-Item -Path $templateName -ItemType Directory
    New-PlasterManifest @manifestProperties

# Planning the questions

Because my intent is that this template will be used instead of the `New-PlasterManifest` Cmdlet, we need to capture that functionality. 

* Template Name
* Template Title
* Template Author

That should sum up the information we need to collect.

## Creating parameters

Now we can turn those planned questions into parameters. These questions are straightforward parameters to create.

    <parameter name="TemplateName" 
               type="text" 
               prompt="Template Name" 
               default="${PLASTER_DestinationName}" />

    <parameter name="TemplateTitle" 
               type="text" 
               prompt="Template Title" 
               default="${PLASTER_PARAM_TemplateName" />

    <parameter name="TemplateAuthor" 
               type="user-fullname" 
               prompt="Author" />

I added these parameters to the parameters section of the `PlasterManifest.xml` file.

For the `TemplateName` default value, I use the name of the destination folder that is specified when `Invoke-Plaster` is invoked.

For the `TemplateAuthor`, I used `user-fullname` for the `type`. That is a special type that pulls the value from the user's `.gitconfig` as a default.

# TemplateFile

Now we need to create a TemplateFile to generate the `PlasterTemplate.xml` file. The first half of the TemplateFile will be basic value substitution.

    <?xml version="1.0" encoding="utf-8"?>
    <plasterManifest schemaVersion="1.0" 
    xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name><%= $PLASTER_PARAM_TemplateName %></name>
        <id><%= $PLASTER_GUID1 %></id>
        <version>0.0.1</version>
        <title><%= $PLASTER_PARAM_TemplateTitle %></title>
        <description></description>
        <author><%= $PLASTER_PARAM_TemplateAuthor %></author>
        <tags></tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    ...

All the magic happens in the second half of this TemplateFile. We walk the destination folder for both folders and files to create the content section.

    ...
      <content>
    <%
    $path = $PLASTER_DestinationPath

    $folders = Get-ChildItem -Path $path -Directory -Recurse
    $files = Get-ChildItem -Path $path -File -Recurse

    $path += '\'  

    foreach($node in $folders.fullname)
    {
        $destination = $node.replace($path,'')
    "    <file source='' destination='$destination'/>" 
    }

    foreach($node in $files.fullname)
    {
        $source = $node.replace($path,'')
    "    <file source='$source' destination=''/>" 
    }

    %>
      </content>
    </plasterManifest>

Then we save this into a template file called `PlasterTemplate.aps1` and add a `templateFile` entry to our original `PlasterTemplate.xml` content section.

    <content>
        <templateFile source="PlasterTemplate.aps1" 
                      destination="PlasterManifest.xml" />
    </content>

I can call that template file anything I want and could easily have left the file extension as xml. I am currently using `.aps1` as that designation.

# GetPlastered in action

Now we can take any folder and turn that into a Plaster template. The idea is that I would build out the folder first with all the files that should be included. Then instead of running `New-PlasterManifest`, I would use `Invoke-Plaster` with this template.

## Example

Here is a quick example to see this working. Lets say I have two folders of common tests that I drop into modules. I first move all of these to a new folder called MyTests.

    MyTests
    ├───spec
    │       module.feature
    │       module.Steps.ps1
    │
    └───tests
            Export-PSGraph.Tests.ps1
            Feature.Tests.ps1
            Help.Tests.ps1
            Project.Tests.ps1
            Regression.Tests.ps1
            Unit.Tests.ps1

Now we run the `GetPlastered` template.

    PS:> Invoke-Plaster -DestinationPath .\MyTests -TemplatePath .\GetPlastered
    ____  _           _
    |  _ \| | __ _ ___| |_ ___ _ __
    | |_) | |/ _` / __| __/ _ \ '__|
    |  __/| | (_| \__ \ ||  __/ |
    |_|   |_|\__,_|___/\__\___|_|
                                                v1.0.1
    ==================================================
    Template  Name (MyTests):
    Template Title (MyTests):
    Author (KevinMarquette):
    Destination path: .\MyTests
    Create PlasterManifest.xml

I just accepted all the defaults and my `.\MyTests\PlasterManifest.xml` was created. Here is the contents of that file showing every file in the `content` section.

    <?xml version="1.0" encoding="utf-8"?>
    <plasterManifest schemaVersion="1.0" 
    xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>MyTests</name>
        <id>3c3480d8-c2fa-4777-bb0c-a2453c8147c3</id>
        <version>0.0.1</version>
        <title></title>
        <description></description>
        <author>KevinMarquette</author>
        <tags>GetPlastered</tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
        <file source='' destination='spec'/>
        <file source='' destination='tests'/>
        <file source='spec\module.feature' destination=''/>
        <file source='spec\module.Steps.ps1' destination=''/>
        <file source='tests\Feature.Tests.ps1' destination=''/>
        <file source='tests\Help.Tests.ps1' destination=''/>
        <file source='tests\Project.Tests.ps1' destination=''/>
        <file source='tests\Regression.Tests.ps1' destination=''/>
        <file source='tests\Unit.Tests.ps1' destination=''/>
    </content>
    </plasterManifest>

We can now use this new template to deploy our tests.

    PS:> Invoke-Plaster -DestinationPath .\TestFolder -TemplatePath .\MyTests
    ____  _           _
    |  _ \| | __ _ ___| |_ ___ _ __
    | |_) | |/ _` / __| __/ _ \ '__|
    |  __/| | (_| \__ \ ||  __/ |
    |_|   |_|\__,_|___/\__\___|_|
                                                v1.0.1
    ==================================================
    Destination path: .\TestFolder
    Create spec\
    Create tests\
    Create spec\module.feature
    Create spec\module.Steps.ps1
    Create tests\Feature.Tests.ps1
    Create tests\Help.Tests.ps1
    Create tests\Project.Tests.ps1
    Create tests\Regression.Tests.ps1
    Create tests\Unit.Tests.ps1

    PS:> cd .\TestFolder
    PS:> tree /f

    TestFolder
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

# Wrapping it up

Other than the layers of inception going on, this really was an easy template to create. This was a fun project and I have it published with my other [Plaster templates](/2017-05-12-Powershell-Plaster-adventures-in/?utm_source=blog&utm_medium=blog&utm_content=getplastered). 

I am working on setting this up to be published to the PSGallery. I'll update this post when that happens. I hope you enjoy it.

