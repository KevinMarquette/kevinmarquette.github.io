---
layout: post
title: "Powershell: Windows Eventlog"
date: 2016-11-04
tags: [PowerShell]
---

Another common activiy that a system administrator performs is querying the event log. We have two options to work with. I like the second one better but I will show you both.

## Get-EventLog 

Here is a quick sample to jump into it.

    Get-EventLog Application | Select-Object -First 4


I'll talk about native filtering in a bit but you will find this to be way slower than it should be. It pulls all events and then filters it down tothe first 4. We can tell this command to only read the front of the eventlog like this.

    Get-EventLog Application -Newest 4

## Get-WinEvent

We do have a better command for pulling the eventlog that supports processing of the advanced logs.

    Get-WinEvent -LogName Application -MaxEvents 4
    Get-WinEvent -LogName 'Microsoft-Windows-Dhcp-Client/Admin' -MaxEvents 4


We can also list all the available logs to find the exact name we need.

    Get-WinEvent -ListLog * | Out-GridView -PassThru


Get-WinEvent can also read binary or archived logs.

    $path = 'C:\Windows\System32\winevt\Logs\system.evtx'
    Get-WinEvent -Path $Path -MaxEvents 4 

The native filtering engine for `Get-WinEvent` is very flexible and offers great performance gains over filtering on the pipleine. Using the `-FilterHashtable`, we can specify all kinds of things to search for. Most of the values support multiple values for when that is needd.

    Get-WinEvent -FilterHashtable @{
        logname='application'
        providername='.Net Runtime' 
    } 