---
layout: post
title: "Powershell: Writing a DSL for RDC Manager, DSLs part 2"
date: 2017-03-04
tags: [PowerShell, DSL, Advanced]
---

I am not sure how many times I have written a script to generate server lists for Microsoft's [Remote Desktop Connection Manager (RDCMan)]((https://www.microsoft.com/en-us/download/confirmation.aspx?id=44989)). I find that it is a very easy script to write many different ways. Writing a Domain-Specific Language (DSL) to generate RDCMan files may not be the best solution for this problem, but generating RDCMan files is a good project for a first DSL.<!--more-->

This is the second post in a series covering what a DSL is and how to write one.

* Part 1: [Intro to Domain-Specific Languages](/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1)
* Part 2: Writing a DSL for RDC Manager (This post)
* Part 3: [DSL design patterns](/2017-03-13-Powershell-DSL-design-patterns/)
* Part 4: [Writing a TypeExtension DSL](/2017-05-05-PowerShell-TypeExtension-DSL-part-4)
* Part 5: [Writing an alternate TypeExtension DSL](/2017-05-18-PowerShell-TypeExtension-DSL-part-5)

# Index

* TOC
{:toc}

# What are we building?

RDCMan allows you to group and organize your server connections. The configuration gets saved into a RDG file. If you open the file, you will find a fairly simple XML file. The hierarchy that you build in RDCMan is reflected in the XML structure.

## Sample RDG file

Here is the sample configuration that we will be working with.

![RdcMan Sample](/img/rdcman.png)

And here is the resulting configuraiton file.

    <?xml version="1.0" encoding="utf-8"?>
    <RDCMan programVersion="2.7" schemaVersion="3">
      <file>
        <credentialsProfiles />
        <properties>
          <expanded>True</expanded>
          <name>rdcman</name>
        </properties>
        <group>
          <properties>
            <expanded>True</expanded>
            <name>GroupATX</name>
          </properties>
          <group>
            <properties>
              <expanded>True</expanded>
              <name>GroupDMZ</name>
            </properties>
            <server>
              <properties>
                <name>ServerDMZ01</name>
              </properties>
            </server>
            <server>
              <properties>
                <name>ServerDMZ02</name>
              </properties>
            </server>
          </group>
          <group>
            <properties>
              <expanded>False</expanded>
              <name>GroupInternal</name>
            </properties>
          </group>
        </group>
      </file>
      <connected />
      <favorites />
      <recentlyUsed />
    </RDCMan>

I created this sample with some depth to it so we could see how the hierarchy and multiple elements were handled. We have a lot of good information in here. It looks like a group element can contain multiple group  or server elements. Each group or server element has a properties element for all the metadata about that item.

These are the key pieces of data that we will be generating today.

    <server>
      <properties>
        <name>ServerDMZ02</name>
      </properties>
    </server>

    <group>
      <properties>
        <expanded>True</expanded>
        <name>GroupATX</name>
      </properties>
      <!-- group or server elements -->
    </group>

There was a lot more stuff in that file, but I think we can abstract it away in a template another time. I feel that the rest of it is just scaffolding to hold these elements. Now that we know what we are creating, we can build some functions.

## Get-RdcServer

The `Server` element looks really easy. We just need a function that returns that chunk of XML with the correct server name.

    function Get-RdcServer
    {
        param($ComputerName)
        @"
        <server>
          <properties>
            <name>$ComputerName</name>
          </properties>
        </server>
    "@
    }

This would be a great start, but I want to spruce it up a bit to give us more flexibility. Here is a full advanced function that we will use going forward.

    function Get-RdcServer
    {
        [CmdletBinding()]
        param(
            [Parameter(
                ValueFromPipeline = $true,
                Mandatory = $true,
                Position = 0
            )]
            [string[]]
            $ComputerName
        )
        process
        {
            foreach($node in $ComputerName)
            {
                @"
          <server>
            <properties>
              <name>$node</name>
            </properties>
          </server>
    "@
            }
        }
    }

I added pipeline and multiple `$ComputerName` support. This will add a lot of value to this command. Right now, I would expect we could use it like this.

    Get-RdcServer -ComputerName Server1
    Get-RdcServer -ComputerName Server2

    Get-RdcServer -ComputerName Server3,Server4

    Get-Content -Path $path | Get-RdcServer

I'll show you how this plays into our DSL in a moment, but first we need one more command.

## Get-RdcGroup

The `Group` element will be more interesting because we need a way for it to contain other servers or groups. In our example, the child items will either be function calls to `Get-RdcServer` or calls to this new function `Get-RdcGroup`. We will use a `[ScriptBLock]` to hold these child items.

Here is our function for creating the group.

    function Get-RdcGroup
    {
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $true,
                Position = 0
            )]
            [string]
            $GroupName,

            [Parameter(
                Mandatory = $true,
                Position = 1
            )]
            [scriptblock]
            $ChildItem
        )
        process
        {
            @"
        <group>
          <properties>
            <name>$GroupName</name>
          </properties>
    "@
           $ChildItem.Invoke()

            '    </group>'
        }
    }

First I specified two parameters. The first one `$GroupName`, will be the name of the group and the `$ChildItem` will contain our child items. 

The body is really simple in this one. I have two strings that I let fall to the pipeline and I execute that `$ChildItem`. Executing the `[ScriptBlock]` will run any commands that we place in there.

Right now, this function could be used like this:

    Get-RdcGroup -GroupName 'ATX' -ChildItem {
        Get-RdcServer -ComputerName 'Server1'
    }

# Looking like a DSL

This is where we start to see this looking like a DSL. Because we used positional parameters, we can rewrite this command like this:

    Get-RdcGroup ATX {
        Get-RdcServer Server1,Server2
    }

There is one more little known trick we can use here. Any command that is defined with the `Get` verb will have an automatic weak alias that is just the noun. You can run `Service` and `Get-Service` will be called. We could just rename our commands or even create aliases, but I find this to be a handy shortcut.

    RdcGroup GroupATX {
        RdcServer Server1
        RDCServer Server2
    }

We can also place groups inside our script block. This should let us recreate the original example using our DSL.

    RdcGroup GroupATX {
        RdcGroup GroupDMZ {
            RdcServer ServerDMZ01
            RdcServer ServerDMZ02
        }
        RdcGroup GroupInternal {
        }
    }

When we execute that, it generates the inner XML that defines the groups and servers with the correct hierarchy.

# What is next for this module

We only have 1/2 a solution here at this point. The inner XML is valid for what we need even if the formatting is not done well. I did not indent child groups like you would normal XML but RDCMan does not care.

We also need to build the outer XML of the file. This would built like our `Get-RdgGroup` function.

RDGMan has a lot of settings and configuration option we could implement. I took the bare minimum setting to keep this example simple.

I have covered as much as I wanted to here for the DSL implementation but I may spin off another series where I build this out into a full featured module. 

# Where do we go from here

Now that we know what a DSL is and put together something simple, I will dive into some design patterns around building more complex DSL solutions in my next post.

* Part 3: [DSL design patterns](/2017-03-13-Powershell-DSL-design-patterns/)