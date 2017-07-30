---
layout: post
title: "Powershell: Publishing plaster templates"
date: 2017-06-12
tags: [PowerShell,Plaster,Modules]
---

One of the cool things about Plaster is that you can package your templates into [PowerShell modules](http://kevinmarquette.github.io/2017-05-27-Powershell-module-building-basics/?utm_source=blog&utm_medium=blog&utm_content=plasterTemplatePublishing). This makes it easy to distribute and share them. You can publish them to an [internal repository](https://kevinmarquette.github.io/2017-05-30-Powershell-your-first-PSScript-repository/?utm_source=blog&utm_medium=blog&utm_content=plasterTemplatePublishing) or even share them on the [PowerShell Gallery](https://www.powershellgallery.com/).
<!--more-->

# Index

* TOC
{:toc}

# Our Plaster template

For this example, I am going to take a fun Plaster template that I built in a [previous post called GetPlastered](https://kevinmarquette.github.io/2017-05-14-Powershell-Plaster-GetPlastered-template/?utm_source=blog&utm_medium=blog&utm_content=recent). It allows you to take a project folder and turn it into a Plaster template. While that template may be a little complex, the structure to is is very simple.

Right now we only have 2 files inside this template.

    Get-ChildItem -Recurse

    Mode          LastWriteTime Length Name
    ----          ------------- ------ ----
    -a----  5/14/2017  11:22 PM    893 PlasterManifest.xml
    -a----  5/28/2017  12:47 PM   1086 PlasterTemplate.aps1

## Packaging decisions

We need to decide if we are going to have a module of Plaster templates or a module that is a Plaster template. We can do it either way. I feel like this template kind of stands alone so I am going to package it as a single template module.

If I decide to publish all my other templates, I may do it as a collection.

# Module manifest



# Putting it all together


# What's next?


