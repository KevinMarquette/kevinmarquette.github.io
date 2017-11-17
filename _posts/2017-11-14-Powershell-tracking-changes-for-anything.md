---
layout: post
title: "Powershell: Tracking changes"
date: 2017-11-14
tags: [PowerShell]
---

Every once in a while, I see someone ask for a way to track changes to something. It reminds me of a script I wrote once to track changes made in Active Directory. Twice a day, my team was emailed with a report showing all the user account, group membership, and group policies that were changed. It turned out to be a valuable tool in giving everyone visibility to the changes that were recently made.

I'm reminded of that script because I handled that scenario in a very generic way that could be applied to many other things that you would want to monitor.

<!--more-->

# High level plan

This is a great project for all skill levels because the core idea is simple to build on.

* Capture the state of a command
* Compare the state to the last time you checked
* Report on the results
* Save the current state for the next comparison

Then set it up as a scheduled task and let it run.

# Index

* TOC
{:toc}

# Capturing state

For this example, I am going to track the state of services on my system. This way I can start and stop services to simulate changes. I said we were capturing state, but it was just a fancy way of saying to save it into a variable.

    $currentState = Get-Service

When capturing the state for what we are doing here, we want one object or line for each item we want to compare. Services are flat objects so they will be easy to compare.

If your main object has a large list of values in a property that you care about, you will want to flatten them out. This will simplify our comparison and give us a more meaningful comparison. A good example of this is active directory groups and their members. Walk the list and create a new object with the group name and member name. Create something that would look good if it was exported to CSV.

# Compare with previous state

There is a chicken and egg situation to deal with. The first time we run this, we don't have a previous state. We are going to end up saving the current state to a file later. So for now, we need to load the previous state from a file if it exists.

    if( Test-Path $path )
    {
        $previousState = Import-CliXml $path
        # ...
    }

If we have a previous state, we need to compare the two states. We could do a full object compare, but we usually only care about specific values. I have found it best to keep the number of properties tracked to a minimum. Be sure to exclude noisy properties that may flag changes that we don't want to see.

For our services, we will use these properties.

    $properties = @( 'DisplayName','Status','StartType' )

Compare the previous and current state using `Compare-Object`.

    $compare = @{
        ReferenceObject  = $previousState
        DifferenceObject = $currentState
        Property         = $properties
        SyncWindow       = 1000
    }

    $results = Compare-Object @compare | Sort -Property $properties

# Report on the results

My output looks something like this after a few changes.

    DisplayName              Status StartType SideIndicator
    -----------              ------ --------- -------------
    Group Policy Client     Stopped Automatic <=
    Group Policy Client     Running Automatic =>
    Print Spooler           Stopped Automatic =>
    Print Spooler           Running Automatic <=
    Tile Data model server  Stopped    Manual <=
    Tile Data model server  Running    Manual =>
    Windows Insider Service Stopped    Manual =>
    Windows Insider Service Running    Manual <=

Our results are a typical compare object result. We can email this output as is or add a little processing to make it more meaningful. If the results are `$null`, then there are no changes to report on.

# Save the current state

The last step is to save the current state.

    $currentState | Export-CliXml $path

This puts us in a good place for the next time this executes.

# Putting it all together

I used a simple example for the comparison, but this could be anything. I have used this trick for these types of monitoring tasks.

* AD users created, disabled or home folder changes
* Groups created or members changed
* Group policy objects created or modified
* Computers joined or removed from AD, or description changed
* New VMs created, deleted or configs changed
* Databases added or removed from SQL servers

I know there are often audit logs that can tell you what changes are taking place and who is making the changes. But using this approach makes for a great daily or weekly summary report of changes in your environment.

Use your imagination and if you find a creative way to use this, let me know. I would love to hear about it.