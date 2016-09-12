---
layout: post
title: "Powershell: Working with scheduled tasks"
date: 2016-08-27
tags: [PowerShell, Scheduled Task]
---
We all have things that we would like to run on a schedule. Windows Task Scheduler does exactly that. Before we script this, there are a few things to be aware of.

The important thing to remember when setting up a scheduled task is that the application is powershell.exe. You script needs to be set as a `-file` argument to the script. You need to use the full path and include double quotes if there are spaces in the path or name.

    Program/Script: Powershell.exe
    Add arguments (optional): -file "c:\my scripts\script.ps1" 

If you make any changes to the script after you create the task, you may need to open and save the task again. It should prompt you for credentials any time it detects changes on save. This is generally more of an issue with batch files but is still something to keep in mind when troubleshooting scheduled task issues. 

Remember that your script also needs to be non-interactive. So don’t have any GUI elements in these scripts. This includes prompts for input using `Read-Host` or having a `Pause` statement. 