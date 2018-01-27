---
layout: post
title: "Powershell: My thoughts on the future of DSC"
date: 2018-01-26
tags: [PowerShell,DSC,Thoughts]
---

I just saw the PowerShell team post an update on [the future of Desired State Configuration (DSC)](https://blogs.msdn.microsoft.com/powershell/2018/01/26/dsc-planning-update-january-2018/). This is the first real update after the release of PowerShell Core 6.0. Without DSC support in PowerShell Core, there have been a lot of questions in the community. I want to take a moment to share my thoughts on what the PowerShell Team had to say.

<!--more-->

# A full rewrite

The first big take away is that they are rewriting DSC from the ground up. This does not surprise me at all. As far as I know, DSC is very tightly integrated into the WMI subsystem in Windows server.

DSC was designed at a time where everything Microsoft was building was integrating with WMI. I think Jeffrey Snover's vision at the time was to allow the teams to build DSC Resources in WMI. The teams were already invested in that platform and should be able to leverage a lot of the work they already had done.

This is also why `Get-WmiObject` was one of the first CmdLets that we ever saw.

# The project is written in C++

The PowerShell team went out of their way to make this point. I expect there was a lot of internal debate and that the community will also have a lot of opinions on this. So what value does C++ bring to this project?

This is a process that will be executing constantly all over Azure. The performance of the LCM in Azure is very important to Microsoft. The LCM needs to be small, quick, and not use any unneeded resources. At the end of the day, when Microsoft optimizes performance for Azure, we all win.

The use of C++ also fits into a larger vision that Jeffrey Snover had for DSC. There is a future where our networking and storage equipment could be running DSC. Instead of waiting for vendors to write their own LCM, open sourcing one in C++ can accelerate that effort. I can see this running on IoT devices and other places where it just isn't feasible to be running .Net Core just to have an LCM.

# DSC is not a PowerShell thing

The biggest take away for me is that DSC is not a feature of PowerShell. It is very clear that these are two different products. PowerShell has been the face of DSC but the vision for the future of DSC is not one tied to PowerShell. I think we need to remember that as DSC grows and evolves over time.

PowerShell may be the optimal way to generate a configuration. But once that configuration is generated, it is all up to an LCM that doesn't really need PowerShell. I think that future is a long ways off, but I won't discount it.

# Closing comments

I do look forward to having an open source LCM. My C++ days are way behind me so I don't expect to have many pull requests submitted. As long as the future of DSC is one where it is not only a feature of Azure, then I'll be happy. Tanking this open source is a step in the right direction.

With that said, this is how I think the pieces could fit together. I am just speculating here so take it for what it is.