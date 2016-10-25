---
layout: post
title: "Powershell: Operational Validation Framework"
date: 2016-10-25
tags: [PowerShell,Pester,OVF,DSC]
---

If you know me, then you know I have been a fan of [Pester](https://github.com/pester/Pester/wiki) for a long time. I found it to be a great tool and found novel uses for it. I put together a talk on [Pester in Action](https://github.com/KevinMarquette/PesterInAction) a year ago to show how I used it in my environment. The big thing I wanted to get across to people was that it was amazing at validating system configuration and validating a system before you release it. I have seen a lot of community efforts along these same lines. One of these tools deserves a closer look.

## The [Operational Validation Framework](https://github.com/PowerShell/Operation-Validation-Framework)

It took me a long time to wrap my head around this project at first. I'll admit that I looked at it a few times without really seeing the value of it. At face value, all I saw was a few commands that would find Pester tests and run them. `Invoke-Pester` already does that if you execute it from the root of your tests folder. I went and did my own thing without really digging into it. 

Recently, I saw a post about [Continuously Testing your Infrastructure with OVF and Microsoft Operations Management Suite](https://dscottraynsford.wordpress.com/2016/10/23/continuously-testing-your-infrastructure-with-ovf-and-microsoft-operations-management-suite/) that did a very nice walk through of using OVF. I was able to see it in action and that was a good thing. 

## The Operational Validation Framework explained

This is a very light framework that executes Pester tests that are intended to validate the system. You package your tests into modules for OVF to find them. OVF allows for simple and comprehensive diagnostic tests. You can package both types into the same module. This feels like a good standard that you will see many in the community use for managing operational validation.

Ideally you could run the simple tests on a schedule and feed that into your alerting system. Then save the diagnostic tests for troubleshooting. That is the post above was highlighting. 

Other things to mention before I move on is that OVF produces output that is easier to consume by other systems (but the Pester output is still there if you want it). It also has functions to enumerate all the tests without having to run them. 

## Put my tests in a module?

This is where the OVF starts to show its hidden potential. Powershell now has a module based packaged management system that is very easy to set up and use. I want to build on the example in [this post](https://dscottraynsford.wordpress.com/2016/10/23/continuously-testing-your-infrastructure-with-ovf-and-microsoft-operations-management-suite/) that creates a `ValidateDNS` module. I now want to distribute that module (and others). 

I need to ceate a repository and publish my `ValidateDNS` module to it.

    $path = '\\server\share\PSRepository'
    $repository = @{
        Name               = 'MyModules'
        SourceLocation     = $path
        PublishLocation    = $path
        InstallationPolicy = 'Trusted'
    }
    Register-PSRepository @repository

    Publish-Module -Name validateDNS -Repository MyModules

You never knew it was that easy to create your own repository and publish a module did you. I know I was surprised the first time I discovered that. You will also need to run the `Register-PSRepository` command on your target system. Once you have that, Install the module.

    Install-Module -Name ValidateDNS -Repository MyModules

Now you have a very easy way to distribute your tests to your systems. As an added bonus, this makes it very easy to update a central location and update those tests on your servers.

## What about DSC?

The comparison to DSC often comes up when talking about using Pester for operational validation. DSC already tests all the settings that get configured, right? First, it is good to have something other than the configuration system validating what it is configuring. But there is a bigger point to make here.

DSC tests and validates that things are configured like you expect. But it does not really do a good job of checking the state of the system. Is IIS accepting connections on port 80? Does the system disk have 20% free space? Are these specific errors in the eventlog? Are any of the certs expired? Can I reach the database server? Pester can step in to go the last mile and let DSC do what it does best. 

## Pester, OVF and DSC. Better Together 

This is where things start to get really good and the whole reason I wrote this post. Because OVF will look at all modules for validation tests, you can place your validation tests inside your custom DSC resource modules. Let that sink in for just a moment. 

The module based approach and structure that OVF is looking for compliments the structure of a DSC resource module. You can combine them so your system validation tests for custom DSC resources get distributed automatically with the resource from the DSC pull server. 

I just thought it was really clever how all of this ties together. This last little trick only works if you are creating custom DSC resource and not everyone is doing that. It may be an opportunity for some community projects to build in some additional functionality more than anything.

## Wrapping things up

I have a new found appreciation of this project and the potential it offers. It solved one of the largest problems I had with my current approach of distributing tests and keeping them updated across systems. I already started moving over to this new approach.