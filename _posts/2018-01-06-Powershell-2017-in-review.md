---
layout: post
title: "What have you done with PowerShell this year?"
date: 2018-01-06
tags: [Review]
---

Over on [/r/PowerShell](https://www.reddit.com/r/PowerShell/comments/7nfms9/2017_retrospection_what_have_you_done_with/), we share with each other things that we have done with PowerShell every month and reflect on that at the end of the year. As I look back on my year in PowerShell, I see that I have accomplished quite a bit. Not only have I done great work in a professional setting but I have also done a lot for the PowerShell community this year.

<!--more-->

# Index

* TOC
{:toc}

# DevOps Engineer, Sr.

I started the year out by joining loanDepot. I became part of an amazing team that was already doing a lot of great things with PowerShell and DSC. It was an opportunity for me to leverage everything I already knew and loved about PowerShell. I was able to step in and start contributing right away. Here are some of the more fun PowerShell things that I was responsible for.

## DSC resources

One of the first DSC resources that I created at loanDepot was a service config watcher that would monitor for config file changes and then restart the needed service when that happened. I wrote a few others, but are the more noteworthy resources that I created.

* ServiceConfigWatcher
* HttpAcl
* HttpCert
* PSRepository

## F5 LTM load-balancer configuration automation

I built the first version of our F5 configuration tools that would leverage metadata that stored about each service and use that to generate our production configurations. This cut out a lot of manual work done by another team.

## Post-release validation

I put a framework in place that allows us to describe testable endpoints for all our services. Then I added the tooling to hit those endpoints every release to verify they were working. I created standalone tooling that allows me to easily test those endpoints on demand.

I had a coworker take what I started with the F5 LTM automation and added GTM (global traffic management) support. I think it was a total rewrite of my work, but he did extend it to use my post-release validation framework for the load-balancer fail-over checks. This allows us to define in one spot how to determine if the service is healthy and everything else builds off of that.

## The LDX Project

I plan on delivering on this one into production early next month. We have what we call a metadata database. It describes everything about every service, component, website, server, role, DNS name, firewall rule, load-balancer config, and environments that we manage. We add everything to metadata and that drives everything our automation does. Our DSC configs, for example, are generated on the fly based on that metadata.

We have pushed the current engine as far as we can push it. I have built the replacement engine that will manage this going forward. It is a new processing engine and a new build/release pipeline. Shifting from file system based datasets to storing it into Elastic Search that we can reach with a Rest API. Reworking existing modules and created several new ones to support it. A defined JSON schema to allow VS Code to validate, support autocomplete, and offer in-line property descriptions.

I don't have enough room to dive into it here, but it is a really cool project.

## PSGraph integration

I introduced my team to the PSGraph module that I wrote and they have integrated into several of our other modules and processes. We generate charts that show load balancer configurations that span multiple datacenters, firewall rules, and general component to component relationships. This has gained a lot of visibility for PSGraph and other teams are looking to leverage it this year.

# Community efforts

I did a lot of work this year on my community efforts and did what I could to make them more visible.

## /r/powershell

My largest are of contribution to the PowerShell community is guiding people looking for help in [/r/powershell](https://www.reddit.com/r/PowerShell). I have been active in that sub for a long time now and I continue to do what I can for that group. We have a lot of good contributors now so I don't have to be in every thread like I use to, but I still try to step in and add context or alternate approaches where applicable. It was the work that I was doing in this sub that drove me to start blogging more.

## Blogging

I first started a blog [back in 2004](http://kevinmarquette.blogspot.com/2004/10/opening-comments.html). But in late 2016 and continuing into 2017, I started to treat my blog like a real project. I focused on creating quality content that would be valuable to the community. I published 35 posts last year. A lot of the inspiration for my content comes from helping people in /r/powershell.

![2017 blog stats](/img/2017blogstats.png)

Taking a quick look at my stats for the year and it shows that my blog is doing quite well. I have close to 138,000 unique visitors and almost 249,000 page views in the last 12 months. My stats also show good month over month growth.

## Open source projects

I created several modules and open source projects this year.

* [PSGraph](https://github.com/KevinMarquette/PSGraph)
* [PSGraphPlus](https://github.com/KevinMarquette/PSGraphPlus)
* [Chronometer](https://github.com/KevinMarquette/chronometer)
* [PSHonolulu](https://github.com/KevinMarquette/PSHonolulu)
* [PlasterTemplates](https://github.com/KevinMarquette/PlasterTemplates)

I fleshed my modules out to include tests, a build process and auto-publishing to the [PSGallery](https://www.powershellgallery.com/). I have over 1300 downloads from the PSGallery across all my projects.

![2017 psgallery stats](/img/2017psgallerystats.png)

## SoCal PowerShell user group

I was putting in a lot of time helping the ATX PowerShell user group when I was in Austin and I was disappointed to find out that there was not a user group out in this area. I began working on getting the [SoCal PowerShell group](https://www.meetup.com/SoCal-PowerShell-user-group/) started around May and we had our first official meeting Aug 1st, 2017. Our roster on [MeetUp.com](https://www.meetup.com/SoCal-PowerShell-user-group/) lists 54 members.

I am hoping to grow our attendance numbers this year and I already have speakers lined up for the next few months.

## Public speaking

David Christian (from [OverPoweredShell.com](http://overpoweredshell.com)) and I host a SoCal PowerShell user group meeting every month. I was the presenter for two of those meetings where I covered Hashtables and PSGraph. I also did remote presentations for the [Austin](https://www.meetup.com/Austin-PowerShell/events/244271778/), [Dallas](https://sites.google.com/site/powershellsig/), and [Mississippi](http://mspsug.com/2017/09/07/mspsug-september-2017-virtual-meeting-psgraph-a-hierarchical-graph-module/) user groups in 2017.

I submitted a topic for the [2018 PowerShell + DevOps Global Summit](https://powershelldevopsglobalsummit2018.sched.com/) and it was accepted this year. I will be presenting on [Writing a DSL (Domain Specific Language) for PowerShell](https://powershelldevopsglobalsummit2018.sched.com/event/CrVQ) at the next summit. Feel free to stop me and say hello.

All my [presentation slides, scripts and demos](https://github.com/kevinmarquette) are posted on GitHub.

## Video sessions

I try to record and publish my presentations when I can. Both my talks on [PowerShell Hashtables](https://www.youtube.com/watch?v=EtHxfTfZD3I) and [Working with PSGraph](https://www.youtube.com/watch?v=pR_xzZh9qoI) made it onto YouTube.

# Reflections

Looking back, I have done a lot more than I expected in this last yet. I only hope that I am as productive going forward.