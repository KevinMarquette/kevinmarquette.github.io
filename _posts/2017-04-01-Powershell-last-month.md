---
layout: post
title: "Powershell: What have you done this month? March 2017"
date: 2017-04-01
tags: [Monthly]
---

I did a lot more this month than I expected. Here is a breakdown of all the posts and other Powershell projects that I worked on.

# Personal/Community efforts

These are the projects and idea that I do on my own time for the community. Most of my personal projects are published on this blog or as a contribution on GitHub.<!--more-->

* Blog post on [Writing a DSL for RDC Manager, DSLs part 2](https://kevinmarquette.github.io/2017-03-04-Powershell-DSL-example-RDCMan/?utm_source=blog&utm_medium=blog&utm_content=monthly)
* Blog post on [DSL design patterns, DSLs part 3](https://kevinmarquette.github.io/2017-03-13-Powershell-DSL-design-patterns/?utm_source=blog&utm_medium=blog&utm_content=monthly)
* Blog post on [Gherkin specification validation](https://kevinmarquette.github.io/2017-03-17-Powershell-Gherkin-specification-validation/?utm_source=blog&utm_medium=blog&utm_content=monthly)
* Blog post on [The many ways to read and write to files](https://kevinmarquette.github.io/2017-03-18-Powershell-reading-and-saving-data-to-files/?utm_source=blog&utm_medium=blog&utm_content=monthly)
* Blog post on a [Mnemonic wordlist](https://kevinmarquette.github.io/2017-03-25-mnemonic-wordlist/?utm_source=blog&utm_medium=blog&utm_content=monthly)
* Spent some time experimenting with Newtonsoft JSON.net library.
* I got two very minor contributions merged into Powershell to get my contributer tag.
* I reworked the landing page and reorganized my blog with [tag support](https://kevinmarquette.github.io/tags/#DSL).
* I wrote a script to parse all my posts and re-generate my tags page. [UpdateTags.ps1](https://github.com/KevinMarquette/kevinmarquette.github.io/blob/master/UpdateTags.ps1)

# Work/Consulting efforts

I also put a lot of time into Powershell projects outside of my published community efforts.

* Automated our F5 configuration for load balanced virtual IPs (VIP). Can now add target nodes, create load balancing pool, create ssl offloading VIPs and http to https redirection VIPs by updating our project metadata.
* Auto deployed 30 VIPs using the new automation.
* Re-worked our metadata referential lookup logic to be more generic. Hard to explain out of context but it is really cool.
* Started on-boarding .Net Core projects into our build/release system.

# What have you done?

I was inspired to write this post because every month the [/r/Powershell](https://www.reddit.com/r/PowerShell) community has this discussion. Please stop by and join us to share your projects. [What have you done with PowerShell this month? March 2017](https://www.reddit.com/r/PowerShell/comments/62tuch/what_have_you_done_with_powershell_this_month/)
