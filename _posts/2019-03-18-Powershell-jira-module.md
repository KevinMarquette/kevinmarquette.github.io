---
layout: post
title: "Powershell: Jira module project"
date: 2019-03-18
tags: [PowerShell,Jira,Module]
share-img: "/img/share-img/2019-03-18-Powershell-jira-module.svg"
---

Let me tell you about a Jira module that I have been building over the last two weeks. I have been thinking about creating my own module for a while now. After talking about my idea after a recent PowerShell user group, I was given a lot of positive feedback on the idea. So I decided to jump in and write it.

To set the stage here, I work with the [JiraPS](https://atlassianps.org/docs/JiraPS/) quite a bit. Our development cycle has deeply integrated Jira into the workflow so we have quite a bit of automation around Jira tickets. There are times that we push JiraPS harder than it was intended to be pushed. 

<!--more-->

# Index

* TOC
{:toc}

# Why not JiraPS

JiraPS is a wonderful module that is great at a lot of things. There several great people that have put a lot of time into it for it to have such good feature coverage. It was designed to be approachable and do a lot of validation for you. JiraPS does not have a good user story around bulk operations with its issue commands and thats what I need from it the most.

It also has a large user base with hundreds of thousands of downloads and is used in a lot of organizations. Every change made to that module at this point needs to pay very close attention to backwards compatibility.

## Clean start

By building my own module, I get to start clean. I have no user-base yet, so backwards compatibility is not something that I have to deal with. I get the opportunity to make very different design decisions. Ultimately, I am building this module for myself but I feel that other will find some value in it. 

# Bulk Scenario

Our software development lifecycle and workflow is very dependent on Jira. We have a unique Jira issue for every code merge into a main branch. We have automated scripts that update the tickets when the code gets built and again for every release into a new environment. Our largest releases have more than 800 tickets that are updated as part of the production deployment.

It is those larger releases where we are waiting on a hundred tickets at a time to be transitioned and updated with a release data by JiraPS. In our environment, it takes JiraPS about 2 seconds for every action on a ticket. So each Jira ticket associated with a release ends up adding 3-4 seconds to the release. Every hundred tickets add 5-6 minutes to the release time.

I wanted to see if I could do something to speed that up.

## Requirements

My primary requirement was to build something as fast as possible. PowerShell is good at a lot of things, but speed is often not one of those things. I decided to build this as a binary module in C#. If I was going to create my own module in the name of speed, I may as well go all the way.

My initial plan was to hit the rest API directly. I mocked up a proof of concept in PowerShell to make sure I could manage the authentication and basic requests. After I ported that over to C#, I discovered a Jira SDK with a client library. It turned out to be really easy to work with. After a little refactoring, I am glad I made the switch to the SDK.

My secondary plan is for this module to complement JiraPS. There is no way I can compete with the feature coverage that the other module already has. I also have no plans at this point to try and replicate all those other features. I'll let JiraPS do what it is good at. My hope is that if I can focus on error handling from the beginning that I can provide a better experience when things go wrong.

# Current status

I already have a good start on this module. I have 5 Cmdlets fleshed out and working with a good set of integration tests. These commands should cover most of my use cases that I am looking at. 

It would be best to consider this project an early alpha. It works, but I have not settled on the name of anything yet. So it's best to expect breaking changes until I get closer to an official release. Feel free to check it out. I have it published as a pre-release version on the PSGallery.

``` posh
    Find-Module jira -AllowPrerelease
    Install-Module -Scope CurrentUser -Name Jira -AllowPrerelease
    Open-JiraSession -Credential (Get-Credential) -Uri "https://youjiraserver" -Save
    Get-Issue -ID "Test-Issue"
```

All the source is posted on github [kevinmarquette/jira](https://github.com/KevinMarquette/jira) if you want to have a closer look.

## Requirements and dependencies 

This module depends on two other community modules. `CredentialManager` and `PSFramework`. These should install for you if you use `Install-Module`. Too soon to tell if I will still depend on these for the final release.

This is also only tested on PowerShell 5.1. I think older verisons of PowerShell will have issues, so 5.1 is my minimum compatibility for now. Becuase I am using credentials, I may have issues on PowerShell 6 because that is untested. I plan on supporting PowerShell 6 before work is done on this module. 

I am targeting .Net Standard 2.0. You may need to update your version of .Net if you have a downlevel version.

# Cmdlets

Let's take a look at the Cmdlets that I have implemented already. This is what you are all here for.

* Open-JiraSession
* Get-Issue
* Save-Issue
* Set-Issue
* Add-Comment
* Invoke-IssueTransition


## Jira session management

I often use the concept of creating a session for my modules where I want to persist common connectivity details without having to provide them to every command. 

``` posh
    $Credential = Get-Credential
    $Uri = 'https://jira.contoso.com'
    Open-JiraSession -Credential $Credential -Uri $uri -Save
```

I added a `-Save` switch to persist those values for future sessions. So once you save your session info, then you can just call `Open-JiraSession` with no parameters.

``` posh
    Open-JiraSession
```

When you call `Open-JiraSession`, a request is made to the Jira endpoint to verify that you can access the endpoint that you specified. It gives me a place to do some error handling before you need to use it for other commands.

## Getting issues

The whole point of this module is to get issues faster so I have to have a `Get-Issue` Cmdlet. Once you open your session, you can call `Get-Issue` to get the issue that you are looking for.

``` posh
    Get-Issue TEST-1
```

Running this will get us a rich object back from the Jira SDK that shows the common fields and grants you access to all your custom fields. Not only can you query for a single issue, we can query for an entire list of issues at once.

``` posh
    $issues = 1..30 | ForEach-Object {"Test-$_"}
    Get-Issue $issues
```

From what I can tell, the Jira SDK does a single request for all those issues. This is where we start to see the largest performance improvements. The last option is to provide your own custom JQL query to get the data. 

    Get-Issue -Query "Key = Test-1" -MaxResults 200 -StartAt 0

This offers you flexibility to get the same tickets that you are getting in your dashboards or whatever else that you need. I also added some basic paging features incase you may need it.

## Modifying issues

Once you have the issue, the next thing you need to do is make changes to it. There are two ways to update an Issue. The first is to modify the object and then save it.

``` posh
    $issue = Get-Issue -ID $Ticket
    $issue.Description = 'This is a test issues'
    $issue | Save-Issue
```

Modifying custom fields are also supported but they use a different syntax that is more like how you would update values in a hashtable.

``` posh
    $issue["CustomField"] = 'Test value'
    $issue | Save-Issue
```

The `Save-Issue` commits the changes that you made to the local object.

### Set-Issue

The other way to make changes is to use the `Set-Issue` command and it will auto save your changes.

``` posh
    Set-Issue -ID $Ticket -Description 'This is a test issue'

    Get-Issue -ID $Ticket | 
        Set-Issue -Description 'This is a test issue'
```

Custom fields are handled a little bit differently. For now, I accept a hashtable of values.

``` posh
    Get-Issue $Ticket |
        Set-Issue -CustomField @{
            CustomField = 'Test Value'
        } 
```

I am looking at ways to leverage dynamic parameters for custom fields but I don't have that working yet.

For all of the commands that modify an issue, you should be able to specify the issue ID or pass it an existing issue object to any of these commands. Some commands need to have the issue information to make the changes. The Set-Issue is one of those commands where if you specify an issue ID, then it will first fetch the issue and then make the change.

### Other common features

At the moment, I also support adding comments and transitioning tickets.

``` posh
    $issue = Get-Issue -ID $Ticket
    $issue | Add-Comment 'Oh, Man! adding Comments'
    $issue | Invoke-IssueTransition -TransitionTo "In Progress"
```

This is about all I have for standard issue updates. I started with these because they cover most of my use cases. I'm sure that I'll add a few other options like adding labels and attachments. I want to cover the feature that you may be doing in bulk and allow you to lean on JiraPS for the things that it does really well.

# Async Experiments

One experimental feature that I have in this project is the use of async logic for all my commands. There are two ways this will impact this module. The first is that you can run a long query, go run other powershell, then come back and collect the result.

``` posh
    $asyncResult = Get-Issue -Query $largeQuery -Async
    Do-SomethingElse
    $issues | Receive-AsyncResult
    $issues | Invoke-IssueTransition -TransitionTo "In Progress"
```

The idea is that the large query can go run on its own while I let other PowerShell run. When it is time to use the `$issues`, I can call `Receive-AsyncResult` to get them. If they are not ready yet, then we will wait for them to finish.

The other way this is impacting the module is that all the commands are using async logic internally. So when we pipe a large list of issues, each action is kicked off in a async way. Then I wait for all the results to finish before returning. Take a look at this example.

``` posh
    $issues = Get-Issue -Query $largeQuery
    $issues | Invoke-IssueTransition -TransitionTo "In Progress"
```

The `Invoke-IssueTransition` command will take a large list of issues and make an async call for each one of them to perform the transition. Those async calls are collected and `Invoke-IssueTransition` waits for them to finish before returning. My hope is that this will provide a noticeable performance difference when working with large sets of issues. 

# Closing thoughts

The async logic is what will make or break this module. I have tested this on a small scale and everything feels solid. I'll know more when I start doing testing at a larger scale. My target use-case is querying thousands of tickets and updating hundreds of tickets at once. Let me know if you can find value in this module.

