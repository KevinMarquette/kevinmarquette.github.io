---
layout: post
title: "Powershell: What is pwsh.exe"
date: 2017-12-29
tags: [PowerShell,pwsh]
share-img: "http://kevinmarquette.github.io/img/share-img/2017-12-29-Powershell-what-is-pwsh.png"
question: "What is pwsh.exe?"
answer: "The pwsh.exe process is the new name for PowerShell starting with version 6.0."
---
The `pwsh.exe` process is the new name for PowerShell starting with version 6.0. At the time of this writing, PowerShell 6.0 is only a release candidate. But it is already known that the executable is changing names from `powershell.exe` to `pwsh.exe`. Let's take a look at this executable.
<!--more-->

# Index

* TOC
{:toc}

# Installing PowerShell 6.0

The best place to start is over on the [Github.com page for PowerShell](https://github.com/PowerShell/PowerShell). Not only do they have installers for every supported operating system, they also have a good [getting started guide](https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell) for anyone new to PowerShell.

After the install, the folder for it is added to the `PATH` environment variable.

``` PowerShell
    PS:> $env:path -split ';'

    C:\windows\system32
    C:\windows
    C:\windows\System32\WindowsPowerShell\v1.0\
    C:\Program Files\PowerShell\6.0.0-rc.2\
    C:\Program Files\Microsoft VS Code\bin
```

You should be able to run `pwsh` from any run box or other shell window. You can even start it from a PowerShell 5.1 prompt.


# Side by side with PS 5.1

PowerShell 6.0 does not replace PowerShell 5.1 on your system. Instead, they install side by side and both can exist on the same system.

It is worth pointing out that not only did the name of the executable change, but several of the folder locations also changed. Let's take a look at some of those changes.

## exe location

First is the install location for the executable.

* PS 5.1: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
* PS 6.0: `C:\Program Files\PowerShell\6.0.0-rc.2\pwsh.exe`

The original PowerShell used a v1.0 folder but never changed it for future versions. You will also see that the install location moved out of the `C:\Windows\System32` folder and into `c:\Program Files`. You will also notice names that were `WindowsPowerShell` are now `PowerShell`. You will see this in other places too.

## Modules

A fresh install of PowerShell 6.0 will not have any of your modules loaded. This is because all the module install locations have also changed.

``` PowerShell
    # PowerShell 5.1
    PS:> $env:PSModulePath -Split ';'

    C:\Users\kevmar\Documents\WindowsPowerShell\Modules
    C:\Program Files\WindowsPowerShell\Modules
    C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules


    # PowerShell 6.0
    PS:> $env:PSModulePath -Split ';'

    C:\Users\kevmar\Documents\PowerShell\Modules
    C:\Program Files\PowerShell\Modules
    c:\program files\powershell\6.0.0-rc.2\Modules
```

In the list above, you can see all the module locations for my system for each version of PowerShell. Let's take a closer look at the new 6.0 locations.

The first one `C:\Users\$env:username\Documents\PowerShell\Modules` is in my local profile. The folder name changed. Generally when I install modules, I load them in my local profile.

``` PowerShell
    Install-Module -Name PSGraph -Scope CurrentUser
```

The second one `C:\Program Files\PowerShell\Modules` is for all users of the system. If you are installing a module for everyone to use, it should be in this location. DSC will also look here for modules when it is configuring a system. Again, we have a slight name change.

The third one `c:\program files\powershell\6.0.0-rc.2\Modules` is for modules that are core to PowerShell itself. Generally this is a folder that you would not manage. If you need to add or update a module on your system, you will place it in one of the previous folders.

## $PROFILE

PowerShell 6.0 has a new `$PROFILE` location for us to use.

* PS 5.1: `C:\Users\kevma\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
* PS 6.0: `C:\Users\kevma\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

This is mostly due to the renaming of folder. If you do have important stuff in your profile, you will need to add it to your new profile location. Most people use the profile to set a custom prompt or import often used modules.

# Command-line options

`pwsh.exe` is a standard console application and it has command line options available to us. I am going to list the important ones below, but you can run `pwsh -?` for the full list.

``` Plaintext
    PS:> pwsh -?

    Usage: pwsh[.exe] [[-File] <filePath> [args]]
                    [-Command { - | <script-block> [-args <arg-array>]
                                    | <string> [<CommandParameters>] } ]
                    [-ConfigurationName <string>] [-EncodedCommand <Base64EncodedCommand>]
                    [-ExecutionPolicy <ExecutionPolicy>] [-InputFormat {Text | XML}]
                    [-Interactive] [-NoExit] [-NoLogo] [-NonInteractive] [-NoProfile]
                    [-OutputFormat {Text | XML}] [-Version] [-WindowStyle <style>]

        pwsh[.exe] -h | -Help | -? | /?

    PowerShell Online Help https://aka.ms/pscore6-docs

    All parameters are case-insensitive.

    -Command | -c
        Executes the specified commands (and any parameters) as though they were typed
        at the PowerShell command prompt, and then exits, unless NoExit is specified.
        The value of Command can be "-", a string. or a script block.

        If the value of Command is "-", the command text is read from standard input.

        If the value of Command is a script block, the script block must be enclosed
        in braces ({}). You can specify a script block only when running 'pwsh'
        in a PowerShell session. The results of the script block are returned to the
        parent shell as deserialized XML objects, not live objects.

        If the value of Command is a string, Command must be the last parameter in the command,
        because any characters typed after the command are interpreted as the command arguments.

        To write a string that runs a PowerShell command, use the format:
        "& {<command>}"
        where the quotation marks indicate a string and the invoke operator (&)
        causes the command to be executed.

        Example:
            pwsh -Command {Get-WinEvent -LogName security}
            pwsh -command "& {Get-WinEvent -LogName security}"

    -EncodedCommand | -e | -ec
        Accepts a base64 encoded string version of a command. Use this parameter to submit
        commands to PowerShell that require complex quotation marks or curly braces.

        Example:
            $command = 'dir "c:\program files" '
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
            $encodedCommand = [Convert]::ToBase64String($bytes)
            pwsh -encodedcommand $encodedCommand

    -ExecutionPolicy | -ex | -ep
        Sets the default execution policy for the current session and saves it
        in the $env:PSExecutionPolicyPreference environment variable.
        This parameter does not change the PowerShell execution policy
        that is set in the registry.

        Example: pwsh -ExecutionPolicy RemoteSigned

    -File | -f
        Default parameter if no parameters is present but any values is present in the command line.
        Runs the specified script in the local scope ("dot-sourced"), so that the functions
        and variables that the script creates are available in the current session.
        Enter the script file path and any parameters. File must be the last parameter
        in the command, because all characters typed after the File parameter name are interpreted
        as the script file path followed by the script parameters.

        Example: pwsh HelloWorld.ps1

    -Help | -h | -? | /?
        Shows this help message.

    -NoExit | -noe
        Does not exit after running startup commands.

        Example: pwsh -NoExit -Command Get-Date

    -NoLogo | -nol
        Hides the copyright banner at startup.

    -NonInteractive | -noni
        Does not present an interactive prompt to the user. Inverse for Interactive parameter.

    -NoProfile | -nop
        Does not load the PowerShell profiles.

    -Version | -v
        Shows the version of PowerShell and exits. Additional arguments are ignored.

        Example: pwsh -v

    -WindowStyle | -w
        Sets the window style to Normal, Minimized, Maximized or Hidden.
```

# Why change the name to pwsh?

This is a valid question. [Mark Krause](https://get-powershellblog.blogspot.com/2016/11/about-mark-kraus.html) has a good [post summarizing the details](https://get-powershellblog.blogspot.sg/2017/10/why-pwsh-was-chosen-for-powershell-core.html) on his blog. You can also read the [discussion about the name change](https://github.com/PowerShell/PowerShell/issues/4214) on Github.

# Closing comments

I expect the name change will cause a little confusion for those that don't work with PowerShell very closely. Someone is going to see `pwsh.exe` in task manager one day and wonder what it is. When that day comes, I hope they find this article helpful.

{% include question.html %}
