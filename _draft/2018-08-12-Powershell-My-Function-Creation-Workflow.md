---
layout: post
title: "Powershell: My Function Creation Workflow"
date: 2018-08-12
tags: [PowerShell]
---
I just saw a post over at [po(sh)land](http://powershell.damiangarbus.pl/prepare-final-version-powershell-script/) talking about some of the final steps he does when creating a script. It made me reflect a little bit on my workflow. Most people only ever see the final results and the miss all the work that goes into it.
<!--more-->
Today, I am going to write a function for working with a shortcut. But I am going to start from the very beginning.

# Index

* TOC
{:toc}

# Finding the key command

Quite often, I start just hacking away on the console trying to figure out the core commands and objects that I need to work with. The first thing I do is check to see what commands are already available to work with.

``` posh
    Get-Command *shortcut*
```

I'm kind of surprised that I didn't find one on my system already. This feels like it should already exist. Off to do a few searches online for `create shortcut powershell`.

After doing that search, I see several hundred thousand results. I look at a few and they are all based around calling `CreateShortcut` on a `WScript.Shell` COM object.

# From the console

Let's get a good look at the `WScript.Shell` object. I'm sure it is well documented online, but PowerShell can give us some quick information.

    $obj = New-Object -ComObject 'WScript.Shell'
    $obj | Get-Member

    TypeName: System.__ComObject#{41904400-be18-11d3-a28b-00104bd35090}

    Name                     MemberType            Definition
    ----                     ----------            ----------
    AppActivate              Method                bool AppActivate (Variant, Variant)
    CreateShortcut           Method                IDispatch CreateShortcut (string)
    Exec                     Method                IWshExec Exec (string)
    ExpandEnvironmentStrings Method                string ExpandEnvironmentStrings (string)
    LogEvent                 Method                bool LogEvent (Variant, string, string)
    Popup                    Method                int Popup (string, Variant, Variant, Va...
    RegDelete                Method                void RegDelete (string)
    RegRead                  Method                Variant RegRead (string)
    RegWrite                 Method                void RegWrite (string, Variant, Variant)
    Run                      Method                int Run (string, Variant, Variant)
    SendKeys                 Method                void SendKeys (string, Variant)
    Environment              ParameterizedProperty IWshEnvironment Environment (Variant) {...
    CurrentDirectory         Property              string CurrentDirectory () {get} {set}
    SpecialFolders           Property              IWshCollection SpecialFolders () {get}

From this `Get-Member` output, I can see that `CreateShortcut` takes a single string. I think the best way to figure out what it does is to call it.

I'm going to go do this from a safe place in my temp directory.

    $folder = "$env:temp\shortcut"
    New-Item -Path $folder -ItemType Directory
    Set-Location $folder

Now to call our command:

    PS> $obj.CreateShortcut('test')

    The shortcut pathname must end with .lnk or .url.
    At line:1 char:1
    + $obj.CreateShortcut('test')
    + ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : OperationStopped: (:) [], COMException
        + FullyQualifiedErrorId : System.Runtime.InteropServices.COMException

And we got an error message. This is where we take the time to read the error message. You would be surprised at how many people skip this step. `The shortcut pathname must end with .lnk or .url.`. That looks like something we can do.

    $obj.CreateShortcut('test.lnk')

    FullName         : C:\workspace\kevinmarquette.github.io\test.lnk
    Arguments        :
    Description      :
    Hotkey           :
    IconLocation     : ,0
    RelativePath     :
    TargetPath       :
    WindowStyle      : 1
    WorkingDirectory :

It looks like it did something. But I see two issues. The first is that the full name used the wrong folder name. I think that is the folder I was in when I created my object. I'll solve this by just using the full path every time. The second is that the file was not actually created when I look in that location.

    PS> $shortcut = $obj.CreateShortcut("$pwd\test.lnk")
    PS> $shortcut.FullName

    C:\Users\kevmar\AppData\Local\Temp\shortcut\test.lnk

Now that we have an object, let's take a look at it.

    PS> $shortcut | Get-Member

    TypeName: System.__ComObject#{f935dc23-1cf0-11d0-adb9-00c04fd58a0b}

    Name             MemberType Definition
    ----             ---------- ----------
    Load             Method     void Load (string)
    Save             Method     void Save ()
    Arguments        Property   string Arguments () {get} {set}
    Description      Property   string Description () {get} {set}
    FullName         Property   string FullName () {get}
    Hotkey           Property   string Hotkey () {get} {set}
    IconLocation     Property   string IconLocation () {get} {set}
    RelativePath     Property   string RelativePath () {set}
    TargetPath       Property   string TargetPath () {get} {set}
    WindowStyle      Property   int WindowStyle () {get} {set}
    WorkingDirectory Property   string WorkingDirectory () {get} {set}

The items that most interest me are the `Load`,`Save`, and `TargetPath` members of that object.

    $shortcut.Save()
    Get-ChildItem

        Directory: C:\Users\kevmar\AppData\Local\Temp\shortcut

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----        8/12/2018  12:25 PM             80 test.lnk

The file was actually created this time.

# The scratch file

This is the point where I create a scratch file to work from. I can tell this is can turn into something. I gram some lines from my history and place it into a new VSCode tab. I often call it a `debug.ps1` or `ShortcutScratch.ps1`.

``` posh
    Get-History |
        Select-Object -ExpandProperty commandline |
        Set-Clipboard
```

The first thing I do is identify the important variables and place them at the top of my script. Then I clean up the commands and swap out the variables as needed. I have something like this before I continue you experimenting.

``` posh
    $Path = "$pwd\test.lnk"
    $Target = "C:\Windows\System32\calc.exe"

    $obj = New-Object -ComObject 'WScript.Shell'
    $shortcut = $obj.CreateShortcut($Path)
    $shortcut.Save()
```

This script still does not do much at this point. But now I start typing my ideas out in the script and execute them by pressing F5 or F8.

We have a shortcut file, but it does not point to anything. Lets try setting the `TargetPath` property of our shortcut and saving it.

``` posh
    $shortcut.TagetPath = $Target
    $shortcut.Save()
```

After running this, I now have a working shortcut. I want to start the process over to see if I can read a shortcut too.

```
    $obj.CreateShortcut($Path)

    FullName         : C:\Users\kevma\AppData\Local\Temp\shortcut\test.lnk
    Arguments        :
    Description      :
    Hotkey           :
    IconLocation     : ,0
    RelativePath     :
    TargetPath       : C:\Windows\System32\calc.exe
    WindowStyle      : 1
    WorkingDirectory :
```

That worked out really well. From what I have in front of me, I think I can crate 2 functions. The first is a basic `Get-Shortcut` function and the second is a `Set-Shortcut` function. I'm going to focus on the `Set-Shortcut` for the rest of this post, but I would prabbably create the two of them at the same time.

# Function snippet

This is where I create a new file for each function in whatever module that I am going to put it in. This one would end up in a utility module. If I was going to publish it, I would consider creating a new module for it.

Once I have a file, I start with a VSCode snippet that generates this template function:

``` posh
    function Set-Shortcut
    {
        <#
        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
        Set-Shortcut -Path $path

        .NOTES

        #>
        [cmdletbinding()]
        param(
            # Path
            [parameter(
                Mandatory,
                Position = 0,
                ValueFromPipeline
            )]
            [ValidateNotNullOrEmpty()]
            [string[]]
            $Path
        )

        process
        {
            try
            {
                foreach ( $node in $Path )
                {

                }
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError($PSItem)
            }
        }
    }
```

I like this template because I just have to add a few details to the help and then add my logic in body. The template has a parameter that is easy to modify for my needs.

## Comment based help examples

This is the point where I fill out the help information and create the example. The example above is the default one in my template so it usually needs a little touch-up. Working on the examples here helps me think about the way I want the user to interact with the function.

The default example needs to be adjusted becuase we will need a 2nd parameter for the `TargetPath`. This is what I am thinking:

``` posh
    .Example
    Set-Shortcut -Path $path -TargetPath `C:\Windows\System32\calc.exe`

    .Example
    Get-ChildItem -Path C:\Windows\System32\calc.exe |
        Set-Shortcut -Path $Path
```

I like the way that looks. I'll use those same examples in my tests when I create them.

## TargetPath

I already know that I need to add a 2nd parameter. So lets go ahead and add that. It will look a lot like this:

``` posh
    # Target path for the shortcut to link to
    [parameter(
        Mandatory,
        Position = 1,
        ValueFromPipelineByPropertyName
    )]
    [alias('FullName')
    [ValidateNotNullOrEmpty()]
    [string[]]
    $TargetPath
```     

I actually copied and pasted the `$Path` parameter to start with. Yeh, I could have typed that out but I knew it would be mostly the same. This is why I like having that one first parameter in my template.

One other change that I need to make is that my original parameter `$Path` should be a single string instead of an array of strings. So I changed `[string[]] $Path` to `[string] $Path`. 

## Process

Take a look at the `foreach` loop in the middle of the function template. This is where we are going to place our code. The `process` block adds pipeline support and the `foreach` allows the user to provide a list of locations in the `$path`.

``` posh
    process
    {
        try
        {
            foreach ( $node in $Path )
            {
                # Our code will go here
            }
```

So at this point I have a `$Path` and I want to create a shortcut. I'm thinking we need to first validate the user input to ensure the file exists. We also need to make sure we have the full path to the file.

``` posh
    if ( Test-Path -Path $node )
    {
        $fullPath = Resolve-Path -Path $node
        Write-Verbose "Loading shortcut [$fullPath]"

        $wscript = New-Object -ComObject 'WScript.Shell'
        $wscript.CreateShortcut($fullPath)
    }
```

I am happy with returning the raw shortcut object here. I think the only other thing I would change from here is move the `New-Object` out of the `process` block and into a `begin` block. Doing that will ensure it only gets created once even if the user is using the pipeline.

# Testing

While I am working on the main function, I continue to use that original scratch file to test it. I'll add a line to import the function at the top and then a call to the new function.

    . c:\workspace\utility\Get-Shortcut.ps1

    $Path = "$pwd\test.lnk"
    $Target = "C:\Windows\System32\calc.exe"

    Get-Shortcut -Path $path

