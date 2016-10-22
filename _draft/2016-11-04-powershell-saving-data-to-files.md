---
layout: post
title: "Powershell: Saving data to files"
date: 2016-11-04
tags: [PowerShell]
---

Saving data to files is a very common task when working with Powershell. There may be more options that you realize. Lets start from the top and work our way down.

## Basic redirection with Out-File

    Get-Help Out-File
    <#
    SYNOPSIS
        Sends output to a file.
    DESCRIPTION
        The Out-File cmdlet sends output to a file. You can use this 
        cmdlet instead of the redirection operator (>) when you need 
        to use its parameters.
    #> 
 
 
Get-ChildItem | Select-Object Name, Length, LastWriteTime, Fullname | Out-File tests.txt 

<#
 Name                                         Length  LastWriteTime          FullName               
----                                         ------  -------------          --------               
3A1BFD5A-88A6-487E-A790-93C661B9B904                 9/6/2016 10:38:54 AM   C:\Users\kevin.marqu...
acrord32_sbx                                         9/4/2016 10:18:18 AM   C:\Users\kevin.marqu...
TCD789A.tmp                                          9/8/2016 12:27:29 AM   C:\Users\kevin.marqu...
TCD78AB.tmp                                          9/8/2016 12:27:29 AM   C:\Users\kevin.marqu...
TCD7919.tmp                                          9/8/2016 12:27:30 AM   C:\Users\kevin.marqu...
TCD7998.tmp                                          9/8/2016 12:27:30 AM   C:\Users\kevin.marqu...
TCD7A74.tmp                                          9/8/2016 12:27:30 AM   C:\Users\kevin.marqu...
TCD7AA5.tmp                                          9/8/2016 12:27:30 AM   C:\Users\kevin.marqu...
TCD7CD9.tmp                                          9/8/2016 12:27:31 AM   C:\Users\kevin.marqu...
TCD85C0.tmp                                          9/8/2016 12:27:33 AM   C:\Users\kevin.marqu...
TCDC366.tmp                                          9/8/2016 12:40:55 AM   C:\Users\kevin.marqu...
TCDC377.tmp                                          9/8/2016 12:40:55 AM   C:\Users\kevin.marqu... 
#>


# The Add-Content cmdlet appends content to a specified item or file.
$data | Add-Content -Path $Path 
Get-Content -Path $Path 


# Converts objects into a series of comma-separated (CSV) 
# strings and saves the strings in a CSV file.
$data | Export-CSV -Path $Path 
Import-CSV -Path $Path 


# Converts an object to a JSON-formatted string
$data | ConvertTo-JSON | Add-Content  -Path $Path 
Get-Content -Path $Path -Raw | ConvertFrom-JSON 


# Creates an XML-based representation of an object or 
# objects and stores it in a file.
$data | Export-Clixml -Path $Path 



# ProTip: Create default values for any parameter 
$PSDefaultParameterValues["Function:Parameter"]  = $value 

# Set the default file encoding
$PSDefaultParameterValues["Out-File:Encoding"]    = "UTF8"
$PSDefaultParameterValues["Set-Content:Encoding"] = "UTF8"
$PSDefaultParameterValues["Add-Content:Encoding"] = "UTF8"
$PSDefaultParameterValues["Export-CSV:Encoding"]  = "UTF8" 


# Transcripts.
# Starting with PS 5.0, all data streams are captured to the transcript 
Start-Transcript
Stop-Transcript 

# Ways to output data:
Write-Host    'Write-Host'
Write-Output  'Write-Output'
Write-Verbose 'Write-Verbose'
Write-Warning 'Write-Warning'
Write-Error   'Write-Error'
Write-Debug   'Write-Debug'
Write-Information 'Write-Information' # New in PS 5.0
Throw 'Throw'

# Each ends up in its own data stream, if you 
# need to collect those streams you can redirect them
# https://blogs.technet.microsoft.com/heyscriptingguy/2014/03/30/understanding-streams-redirection-and-write-host-in-powershell/

.\streams.ps1 -Verbose *>> streamsScript.log
psEdit .\streamsScript.log

# END
