---
layout: post
title: "Powershell: Reading and writing to files"
date: 2017-03-18
tags: [PowerShell,Basic]
---

Saving data to files is a very common task when working with PowerShell. There may be more options than you realize. Let's start with the basics and work into the more advanced options.

# Index

* TOC
{:toc}

# Working with file paths

We are going to start this off by showing you the commands for working with file paths.

## Test-Path

`Test-Path` is one of the more well known commands when you start working with files. It allows you to test for a folder or a file before you try to use it.

    If( Test-Path -Path $Path )
    {
        ...
    }

## Split-Path

`Split-Path` will take a full path to a file and gives you the parent folder path.

    PS:> Split-Path -Path 'c:\users\kevin.marquette\documents'
    c:\users\kevin.marquette

If you need the file or folder at the end of the path, you can use the `-Leaf` argument to get it.

    PS:> Split-Path -Path 'c:\users\kevin.marquette\documents' -Leaf
    documents

## Join-Path

`Join-Path` can join folder and file paths together.

    PS:> Join-Path -Path $env:temp -ChildPath testing
    C:\Users\kevin.marquete\AppData\Local\Temp\testing

I use this anytime that I am joining locations that are stored in variables. You don't have to worry about how to handle the backslash becuse this takes care of it for you. If you variables both have backspashes in them, it sorts that out too.

## Resolve-Path

`Resolve-Path` will give you the full path to a location. The important thing is that it will expand wildcard lookups for you. You will get an array of values if there are more than one matches.

    Resolve-Path -Path 'c:\users\*\documents'

    Path
    ----
    C:\users\kevin.marquette\Documents
    C:\users\Public\Documents


That will enumerate all the local users document folders.

I commonly use this on any path value that I get as user input into my functions that accept multiple files. I find it as an easy way to add wildcard support to parameters.

# Saving and reading data

Now that we have all those helper functions out of the way, we need to walk the options we have for saving and reading data.

## Basic redirection with Out-File

PowerShell was introduced with `Out-File` as the way to save data to files. Here is what the help on that looks like.

    Get-Help Out-File
    <#
    SYNOPSIS
        Sends output to a file.
    DESCRIPTION
        The Out-File cmdlet sends output to a file. You can use this cmdlet instead of the redirection operator (>) when you need to use its parameters.
    #>
 
For anyone comming from batch file, `Out-File` is the basic replacement for the redirection operator `>`. Here is a sample of how to use it.

    'This is some text' | Out-File -FilePath $Path

It is a basic command and we have had it for a long time. Here is a second example that shows some of the limitations.

     Get-ChildItem | Select-Object Name, Length, LastWriteTime, Fullname | Out-File -FilePath $Path

The resulting file looks like this when ran from my temp folder:


    Name
    Length  LastWriteTime          FullName
    ----
    ------  -------------          --------
    3A1BFD5A-88A6-487E-A790-93C661B9B904                 9/6/2016 10:38:54 AM   C:\Users\kevin.marqu...
    acrord32_sbx                                         9/4/2016 10:18:18 AM   C:\Users\kevin.marqu...
    TCD789A.tmp                                          9/8/2016 12:27:29 AM   C:\Users\kevin.marqu...

You can see that the last column of values is cut short. `Out-File` is processing objects for the console but redirects the output to a file. All the issues you have getting something to format in the console will show up in your output file. The good news is that we have lots of other options for this that I will cover below.

## Save text data with Add-Content

I personally don't use `Out-File` and prefer to use the `Add-Content` and `Set-Content` commands. There is also a `Get-Content` command that goes with them to read file data.

    $data | Add-Content -Path $Path
    Get-Content -Path $Path

These are good all-purpose command as long as performance is no a critical factor in your script. These are great for individual or small content requests. For large sets of data where performance matters more then readability, we can turn to the .Net framework. I will come back to this one.

## Save column based data with Export-CSV

If you ever need to save data for Excel, `Export-CSV` is your starting point. This is good for storing an object or basic structured data that can be imported later. The CSV format is comma separated values in a text file. Excel is often the default viewer for CSV files.

If you want to import Excel data in PowerShell, save it as a CSV and then you can use `Import-CSV`. There are other ways to do it but this is by far the easiest.

    $data | Export-CSV -Path $Path
    Import-CSV -Path $Path

### -NoTypeInformation

`Export-CSV` will insert type information into the first line of the CSV. If you don't want that, then you can specify the `-NoTypeInformation` parameter.

    $data | Export-CSV -Path $Path -NoTypeInformation

## Save rich object data with Export-CliXml

The `Export-CliXml` command is used to save full objects to a file and then import them again with `Import-CliXml`. This is for objects with nested values or complex datatypes. The raw data will be a verbose serialized object as XML. The nice thing is that you can save a an object to the file and when you import it, you will get that object back.

    Get-Date | Export-Clixml date.clicml
    $date = Import-Clixml .\date.clicml
    $date.GetType()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     DateTime                                 System.ValueType

You would never need to look at or edit the resulting output file. Here is what the `date.clixml` file looks like:

    <Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
        <Obj RefId="0">
            <DT>2017-03-17T00:00:00.3522798-07:00</DT>
            <MS>
                <Obj N="DisplayHint" RefId="1">
                    <TN RefId="0">
                        <T>Microsoft.PowerShell.Commands.DisplayHintType</T>
                        <T>System.Enum</T>
                        <T>System.ValueType</T>
                        <T>System.Object</T>
                    </TN>
                    <ToString>DateTime</ToString>
                    <I32>2</I32>
                </Obj>
            </MS>
        </Obj>
    </Objs>

Don't worry about trying to understand it. You are not intended to be digging into it.

This is another command that I don't find myself using often. If I have a nested or hierarchical dataset, then JSON is my goto way to save that information.

## Save JSON with ConvertTo-Json

When my data is nested, then I use `ConvertTo-Json` to convert it to JSON. `ConvertFrom-Json` will convert it back into an object. These commands do not save or read from files on their own. You will have to turn to `Get-Content` and `Set-Content` for that.

    $Data = @{
        Address = @{
            Street = '123 Elm'
            State  = 'California'
        }
    }

    $Data | ConvertTo-Json | Add-Content  -Path $Path
    $NewData = Get-Content -Path $Path -Raw | ConvertFrom-Json
    $NewData.Address.State

There are two things to note. The first is that I used a `[hashtable]` for my `$Data` but `ConvertFrom-Json` returns a `[PSCustomObject]` instead. The other is that I use `Get-Content -Raw` to get the data as a single string instead of an array of strings.

Here is the contents of the JSON file from above:

    {
        "Address":  {
            "State":  "California",
            "Street":  "123 Elm"
        }
    }

You will notice that this is similar the original hashtable. This is why JSON is a popular format. It is easy to read and understand. I use this all the time in my own projects.

# Other options and details

All of those CmdLets are easy to work with. We also have access to .Net for more options.

## Faster reads with System.IO

 That ease of use that the CmdLets provide can come at a small cost in raw performance. It is small enough that you will not notice it for most of the scripting that you do. When that day comes that you need more speed, you will find yourself turning to the native .Net commands. Thankfully they are easy to work with.

    [System.IO.File]::ReadAllLines($Path)
    
This is just like `Get-Content -Path $Path` in that you will end up with a collection full of strings. You can also read the data as a multi-line string.
    
    [System.IO.File]::ReadAllText($Path)

## Saving XML

If you are working with XML files, you can call the `Save()` method on the XML object.

    $Xml = [xml]"<r><data/></r>"
    $Path = (join-path $pwd 'File.xml')
    $Xml.Save($Path)

The important thing to remember about this function is that it requires a full path. It will try to save the file to your `C:\Windows\System32` folder if you forget it.


## Quick note on encoding

The file encoding is the way the data is transformed into binary when saved to disk. Most of the time it just works unless you do a lot of cross platform work.

If you are running into issues with encoding, most of the CmdLets support specifying the encoding. If you want to default the encoding for each command, you can use the `$PSDefaultParameterValues` hashtable like this:

    # Create default values for any parameter
    # $PSDefaultParameterValues["Function:Parameter"]  = $value

    # Set the default file encoding
    $PSDefaultParameterValues["Out-File:Encoding"]    = "UTF8"
    $PSDefaultParameterValues["Set-Content:Encoding"] = "UTF8"
    $PSDefaultParameterValues["Add-Content:Encoding"] = "UTF8"
    $PSDefaultParameterValues["Export-CSV:Encoding"]  = "UTF8"


# Wrapping up

Working with files is such a common task that you should take the time to get to know these options. Hopefully you saw something new and can put this to use in your own scripts.
