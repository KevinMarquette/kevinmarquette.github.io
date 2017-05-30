---
layout: post
title: "Powershell: Remote install software"
date: 2017-04-22
tags: [PowerShell,Remoting,Basics]
---

I previously covered how to [silently install a MSI](/2016-10-21-powershell-installing-msi-files/?utm_source=blog&utm_medium=blog&utm_content=installingremotesoftware). The next thing an administrator wants to do is install it on a remote system. That is the logical next step. This isn't always the easiest task for someone new to PowerShell.<!--more-->

# Index

* TOC
{:toc}


# Introduction

 To keep these samples cleaner, I am going to use an imaginary installer that is not an MSI but the approach is the same. The main way to execute remote commands is with PowerShell remoting using the `Enter-PSSession` or `Invoke-Command` cmdlets. I am assuming that you already have PSRemoting working in your environment. If you need help with that, consult the [Secrets of PowerShell Remoting](https://www.gitbook.com/book/devopscollective/secrets-of-powershell-remoting/details) ebook.
 
 I am also using `Invoke-Command` in all my examples because that is what you would use in your scripts.

# Running installers remotely

If you already have the file on the remote system, we can run it with `Invoke-Command`.

    Invoke-Command -ComputerName server01 -ScriptBlock {
        c:\software\installer.exe /silent
    }

There are two important details to be aware of right away.

The first detail is that you need to maintain a remote session while the installer is running. If the installer does not block execution (it returns control back to the shell while it executes), your script may finish before the installer finishes. This will cancel the install as it closes the remote session.

You will need to call `Start-Process -Wait` if you are having that issue.

    Invoke-Command -ComputerName server01 -ScriptBlock { 
        Start-Process c:\windows\temp\installer.exe -ArgumentList '/silent' -Wait
    }

This brings us to our second important detail. The install needs to be truly silent. Remote sessions are non-interactive. That means that they cannot popup or show windows. This will either cause the program to fail because it cannot show the window or it will cause the installer to hang because it expects someone to click a button that you have no way to click.

# Installing from a remote location

Most of the time if you are running installers  on a remote system, you have the installer on a network share (UNC path). At first glance, this looks like it should work:

    # Incorrect approach
    Invoke-Command -ComputerName server01 -ScriptBlock {
        \\fileserver\share\installer.exe /silent
    }

This can be the source of a lot of headaches. Ideally you want to run the installer from a UNC path, but you discover that it does not work.

Trying to copy the file inside the remote command give you the same problem.

    
    # Incorrect approach
    Invoke-Command -ComputerName server01 -ScriptBlock {
        Copy-Item \\fileserver\share\installer.exe c:\windows\temp\
    }

    # Access denied or file does not exist

 Everything tells you that the file either does not exist or you have no permissions to the file. This is kind of a false message because it does exist and you have file access rights. The issue is that your remote session does not have those same rights.

## The double hop problem

This is the double hop problem. The credential used to authenticate with `server01` cannot be used by `server01` to authenticate to `fileserver`. Or any other network resources for that matter. That second hop is anything that requires authentication that is not on the first remote system.

We can either pre-copy the file or re-authenticate on the remote end.

I will use these place holder variables in the rest of the examples.

    $file = '\\fileserver\share\installer.exe'
    $computerName = 'server01'

## Pre-copy file using administrator share

The obvious first approach is to use the administrator share of the remote system to push content to a location we can access. Here I place it in the windows temp folder then remotely execute it.

    Copy-Item -Path $file -Destination "\\$computername\c$\windows\temp\installer.exe"
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        c:\windows\temp\installer.exe /silent
    }

## Pre-copy using PSSession (PS 5.0)

There is a new feature added in Powershell 5.0 that allows you to copy files using a PSSession. So create a PSSession and copy the file over it using the syntax below. A cool thing about this approach is that with Powershell 5.0, you can create a PSSession to a guest VM over the VM buss (instead of over the network) and you can still copy a file to it.

    $session = New-PSSession -ComputerName $computerName
    Copy-Item -Path $file -ToSession $session -Destination 'c:\windows\temp\installer.exe'

    Invoke-Command -Session $session -ScriptBlock {
        c:\windows\temp\installer.exe /silent
    }
    Remove-PSSession $session


While you can run `Invoke-Command` on multiple computers at once, be aware that `Copy-Item -ToSession` only works on a single session.

### PowerCLI Copy-VMGuest

You can use PowerCli to copy files to a vSphere guest with the [Copy-VMGuest](https://www.vmware.com/support/developer/PowerCLI/PowerCLI41U1/html/Copy-VMGuestFile.html) CmdLet.

    $VM = Get-VM $computername
    Copy-VMGuest -Source $file -Destination 'c:\windows\temp\installer.exe' -VM $VM

## Re-authenticate from the session

It actually is easy to re-authenticate in the remote session. Create a credential object and pass it into your `Invoke-Command`. Then use that credential to create a `New-PSDrive`. Even if you don't use that new drive mapping, it will establish authentication for your UNC path to work.

    $credential = Get-Credential
    $psdrive = @{
        Name = "PSDrive"
        PSProvider = "FileSystem"
        Root = "\\fileserver\share"
        Credential = $credential
    }

    Invoke-Command -ComputerName $computerName -ScriptBlock {
        New-PSDrive @using:psdrive
        \\fileserver\share\installer.exe /silent 
    } 

I used two tricks in that example that I need to point out if you have not seen them before. The first is [splatting](https://technet.microsoft.com/en-us/library/jj672955.aspx) where I place arguments into a hashtable and use the `@` operator to pass them to the CmdLet. The second is the `$using:` [scope](/2016-08-28-PowerShell-variables-to-remote-commands) to get a variable from my local session into that remote scriptblock. I combine both of them when I execute this command `New-PSDrive @using:psdrive`.

# Don’t use CredSSP

I can't talk about the double hop problem without mentioning CredSSP. The most common solution you will find on-line if you Google the double hop problem is to enable CredSSP. Even Jeffery Snover has an old article recommending it. The general community has moved away from that as a solution because it puts your environment at risk. The issue with CredSSP is that your administrator credential gets cached on the remote system in a way that gives attackers easy access to it.

For more details see this great write up: [Accidental Sabotage: Beware of CredSSP](http://www.powershellmagazine.com/2014/03/06/accidental-sabotage-beware-of-credssp/)


## Resource-based Kerberos constrained delegation

But there is a better solution called Resource-based Kerberos constrained delegation. constrained delegation in Server 2012 introduces the concept of controlling delegation of service tickets using a security descriptor rather than an allow list of SPNs. This change simplifies delegation by enabling the resource to determine which security principals are allowed to request tickets on behalf of another user. See [PowerShell Remoting Kerberos Double Hop Solved Securely](https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/) for the details.

Here is a quick snip of code showing how it works.

    # For ServerC in Contoso domain and ServerB in other domain
    $ServerB = Get-ADComputer -Identity ServerB -Server dc1.alpineskihouse.com
    $ServerC = Get-ADComputer -Identity ServerC
    Set-ADComputer -Identity $ServerC -PrincipalsAllowedToDelegateToAccount $ServerB

    #To undo the configuration, reset ServerC’s attribute to null.
    Set-ADComputer -Identity $ServerC -PrincipalsAllowedToDelegateToAccount $null

# Other approaches to consider

That covers the most common approaches that administrators take to solving this problem. I do have a few more ideas for you to take into consideration. These approaches are outside the scope of this post to go into the implementation details, but I wanted you to be aware of them.

## Desired State Configuration

You can use DSC to deploy and install your software. The easy stuff in DSC is very easy and you would learn a lot going down this path. You will need a pull server (that is easy to set up) for this one.

Deciding how to get the installer to the target system is the hard part with DSC. If you set up certificates, then you can provide credentials to a file share for straight file copy. Or you can create a custom DSC Resource and place the files in it. The target system would download it from the pull server like it would other resources.

You can combine it with one of these next ideas.

## Web download

You can pull the file off of an external or internal webserver before you install it.

    Invoke-WebRequest $url -OutFile 'c:\windows\temp\installer.exe' -UseBasicParsing

## Install with Package Management

Windows has introduced [pakage management](ttps://blogs.technet.microsoft.com/packagemanagement/2015/04/28/introducing-packagemanagement-in-windows-10/) into Windows that can be used to install packages from online repositories.

    Install-Package $PackageName

### Install with Chocholatey

Or you could use the [Chocholatey.org](https://chocolatey.org/) package manager. The Microsoft package manager supports Chocholatey as a source but I have found the occasional installer that needs to be ran with `choco install` instead.

    choco install $PackageName

### Internal repository

You can set up a nuget repository and use the new package management commands to deploy applications. If you have an internal dev team, this is something they may have already set up.

    Install-Package $PackageName -Source MyRepoName

# In closing

The first half of this post answers the immediate question as to why you may be struggling to get software to install remotely.

If your question was "how should I be installing software?" then your focus should shift to package management. It is still new to the Windows ecosystem, but this is the direction that Windows is headed.

You have plenty of options to choose from. Pick what works best for your current situation.