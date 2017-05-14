---
layout: post
title: "Powershell: Plaster template, GetPlastered"
date: 2016-10-28
tags: [PowerShell,Plaster]
---

I recently started working with Plaster. I covered my first template in my [Adventures in Plaster](https://kevinmarquette.github.io/2017-05-12-Powershell-Plaster-adventures-in/?utm_source=blog&utm_medium=blog&utm_content=titlelink) blog post. I have been pulling together ideas for more Plaster templates and I thought up a fun one to work on.

I am going to build a Plaster template that builds a Plaster template. I am calling this template `GetPlastered`.

This will also be a good example demonstrating the `templateFile` features of Plaster.

# Index

* TOC
{:toc}

# Project plan

My primary goal is to have a `Plaster` template that will turn an existing folder/project into a Plaster template. Our Plaster template will generate a `PlasterTemplate.xml` for that folder. 

This can be very confusing because we are also creating a `PlasterTemplate.xml` for this template that generates that template. It is like we are writing code that writes the same code that we are writing.

# Starting a new template

I already have a repository for my [Plaster templates](https://github.com/KevinMarquette/PlasterTemplates). I need to create the initial template manifest.

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

Because my intent is that this template will be used instead of the `New-PlasterManifest` Cmdlet, we need to capture that functionality. We will need to collect this information.

* Template Name
* Template Title
* Template Author

## Creating parameters

Now to turn those planned questions into parameters. The first few are very straight forward parameters to create. I added these to the parameters section of the `PlasterManifest.xml` file.

    <parameter name="TemplateName" 
               type="text" 
               prompt="Template Name" 
               default="${PLASTER_DestinationName}" />

    <parameter name="TemplateTitlee" 
               type="text" 
               prompt="Template Title" 
               default="${PLASTER_PARAM_TemplateName" />

    <parameter name="TemplateAuthor" 
               type="user-fullname" 
               prompt="Author" />

For the `TemplateName` default value, I use the name of the destination folder that you need to specify when you create run `Invoke-Plaster`.

For the `TemplateAuthor`, I used `user-fullname` for the `type`. That is a special type that pulls the value from the user's `.gitconfig` as a default.

# TemplateFile

Now we need to create a `TemplateFile` to generate the `PlasterTemplate.xml` file. The first half of the template will be basic value substitution.

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

All the magic happens in the second half. We walk the destination folder for both folders and files to create this section.

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

Then we save this into a template file and add a `templateFile` to our original `PlasterTemplate.xml` content section.