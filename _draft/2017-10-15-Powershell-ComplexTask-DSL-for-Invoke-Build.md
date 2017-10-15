---
layout: post
title: "Powershell: Creating ComplexTask DSL for Invoke-Build"
date: 2017-10-15
tags: [DSL,Build]
---

<!--more-->

# Index

* TOC
{:toc}

# Getting Started


# Putting it all together


# What's next?



    $packageHelp = @{
        inputs  = (Get-ChildItem $HelpRoot -Recurse -File)
        Outputs = "$Destination\en-us\$ModuleName-help.xml"
    }
    Task PackageHelp @packageHelp {
        
        New-ExternalHelp -Path $HelpRoot -OutputPath "$Destination\en-us" -force | % fullname
    }

    Task  @{
        Name    = 'PackageHelp2'
        inputs  = (Get-ChildItem $HelpRoot -Recurse -File)
        Outputs = "$Destination\en-us\$ModuleName-help.xml"
        Action  = {
            New-ExternalHelp -Path $HelpRoot -OutputPath "$Destination\en-us" -force | % fullname
        }
    }
    $Tasks = @{
        PackageHelp3 = @{
            Inputs  = (Get-ChildItem $HelpRoot -Recurse -File)
            Outputs = "$Destination\en-us\$ModuleName-help.xml"
            Jobs    = {
                New-ExternalHelp -Path $HelpRoot -OutputPath "$Destination\en-us" -force | % fullname
            }
        }
    }

    
    Foreach ($key in $Tasks.keys)
    {
        $options = $Tasks[$key]
        Task $key @options
    }



    function ComplexTask
    {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, Mandatory = 1)]
            [string]
            $Name,
            [Parameter(Position = 1, Mandatory = 1)]
            [hashtable]
            $Options
        )
        if ( $null -ne $Options.Action)
        {
            $Options.Jobs = $Options.Action
            $Options.Remove('Action')
        }
        Task $Name @Options
    }

    ComplexTask PackageHelp4  @{
        Inputs  = (Get-ChildItem $HelpRoot -Recurse -File)
        Outputs = "$Destination\en-us\$ModuleName-help.xml"
        Action  = {
            New-ExternalHelp -Path $HelpRoot -OutputPath "$Destination\en-us" -force | % fullname
        }
    }

