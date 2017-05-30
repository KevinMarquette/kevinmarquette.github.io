---
layout: post
title: "Powershell: Installing MSI files"
date: 2016-10-21
tags: [PowerShell,Basics]
---

The nice thing about Powershell is that you can run any command line application from the shell. That is a common way to install things. Calling the installer is often the same as double clicking on it. If you call an MSI, it will pop up and start the install.<!--more-->

    .\SQLIO.msi


You see that work but then you want it to run silently. Check for command line options with `/?` and see something promising. There is a `/quiet` option.

    .\SQLIO.msi /quiet


It looks like it works. You see msiexec flash up into taskmanager but it does not actually install anything. Eventually you go online and find out that you need to pass it to `msiexec.exe` as an argument with other flags.

    msiexec.exe /I .\SQLIO.msi /quiet 


We are starring at the first common problem that can cause a lot of headache. This command is actually throwing an error but the `/quiet` flag is suppressing it. The message would basically say that it could not find the specified MSI file. 
All we are missing is the full path to the MSI.

    msiexec.exe /I c:\installers\SQLIO.msi /quiet


The next common issue that you run into is needing to wait for the installer to finish. Executing msiexec directly starts the installer but returns control back to the Powershell Script. The way I like to solve this one is with `Start-Process -Wait`. It will wait until the process finishes before it lets your script continue. The second thing that `Start-Process` does is ensure that your parameters are processed correctly.

    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\installers\SQLIO.msi /quiet'


With that said, any time you are struggling with command line arguments for an executable, use `Start-Process -ArgumentList`.

Here is a full sample that I reuse in my scripts for installing MSI files. I use this so often that I wrap this in its own function.

    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $file.fullname,$DataStamp
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $file.fullname)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 

Not only does it do the silent install, it also captures a verbose log of the install.

Now that you know how to execute a MSI silently, the next step is to run that on a remote system. See my post on [Installing remote software](https://kevinmarquette.github.io/2017-04-22-Powershell-installing-remote-software/?utm_source=blog&utm_medium=blog&utm_content=installingmsifiles) on how to approach that.
