---
layout: post
title: "Powershell: How to Disable SMBv3 Compression"
date: 2020-03-10
tags: [PowerShell]
share-img: "/img/share-img/2020-03-10-Powershell-disable-smb3-compression.png"
---

If you are working on the [ADV200005 Security Advisory](https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/adv200005) for [CVE-2020-0796](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0796), the primary workaround is to disable SMB Compression on the host. Let's take a look at how to do that in the registry with PowerShell.
<!--more-->

# Index

* TOC
{:toc}

# Disabling SMBv3 Compression

SMB Compression is managed using the `HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\DisableCompression` key in the registry and does not require a reboot. Powershell makes this really simple.

``` powershell
#Requires -RunAsAdministrator
$parameters = @{
    Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Name  = 'DisableCompression'
    Type  = 'DWORD'
    Value = 1
    Force = $true
}
Set-ItemProperty @parameters
```

You do have to run this on every host. We can use `Invoke-Command` to do that (Assuming [PowerShell remoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting?view=powershell-7) is working in your environment). We place our original script inside its scriptblock.

``` powershell
$Session = New-PSSession -ComputerName 'ATX-FILE01','ATX-FILE02','LAX-SQL05'

Invoke-Command -Session $Session -ScriptBlock {
    $parameters = @{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        Name  = 'DisableCompression'
        Type  = 'DWORD'
        Value = 1
        Force = $true
    }
    Write-Verbose "Disabling [$env:computername]" -Verbose
    Set-ItemProperty @parameters
}
$Session | Remove-Session
```

# Enabling

We can enable SMBv3 Compression by using a value of 0 instead of 1.

``` powershell
#Requires -RunAsAdministrator
$parameters = @{
    Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Name  = 'DisableCompression'
    Type  = 'DWORD'
    Value = 0
    Force = $true
}
Set-ItemProperty @parameters
```

If we get a patch to fix the Security Advisory, make sure you go back and enable this.

# Current Status

I don't know about you, but when I am making bulk changes, I like to have a script that tells me the status of everything that I can run before and after I make the change. I start with something like this:

``` powershell
$parameters = @{
    Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
}
$properties = Get-ItemProperty @parameters
if (1 -eq $properties.DisableCompression){
    Write-Verbose "[$env:ComputerName] is Disabled" -Verbose
} else {
    Write-Verbose "[$env:ComputerName] is Enabled" -Verbose
}
```

I could have used Get-ItemProperty to get just the value of `DisableCompression`, but it will throw an error if that property does not exist. My logic above is very subtly working around that scenario.

We can also wrap this in an `Invoke-Command` to get the results from multiple hosts.

``` powershell
$Session = New-PSSession -ComputerName 'ATX-FILE01','ATX-FILE02','LAX-SQL05'

Invoke-Command -Session $Session -ScriptBlock {
    $parameters = @{
        Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
    }
    $properties = Get-ItemProperty @parameters
    if (1 -eq $properties.DisableCompression) {
        Write-Verbose "[$env:ComputerName] is Disabled" -Verbose
    } else {
        Write-Verbose "[$env:ComputerName] is Enabled" -Verbose
    }
}
$Session | Remove-Session
```

## PSSessions

You may have noticed that I used `New-PSSession` to create sessions instead of using `Invoke-Command -ComputerName`. I did this because I tend to run multiple commands back to back on a collection of hosts. I first run my script to get the current status. This gives me a clear picture of what I am about to change. I then run my change for a small set of hosts before running it on everything. When I am done, I run the status check again to verify everything is correct.

While I did include the creation and cleanup of sessions in both examples, I do reuse the sessions over and over when making my changes.

## Idempotent changes

It is important to make your change script safe to execute multiple times on the same host. This example is just setting a registry key and it is safe to set that over and over. If you are making other changes like deleting a file, make sure the script does not error out if the file does not exist on a second run.

You never know when you will be part of the way through changing a large group of hosts and have to start over for some reason. If you can safely rerun your script on the entire group, it saves you from having to go research what hosts got changed and exclude them from the next run.

# Configuration management

This is also a change we can make using DSC. We can do it by using a single [DSC registry resource](https://docs.microsoft.com/en-us/powershell/scripting/dsc/reference/resources/windows/registryresource?view=powershell-7).

``` powershell
Configuration DisableSMBv3CompressionConfig {
    Node localhost {
        Registry DisableSMBv3Compression {
            Ensure = 'Present'
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            ValueName = 'DisableCompression'
            ValueData = '1'
            ValueType = 'Dword'
        }
    }
}

DisableSMBv3CompressionConfig -Output c:\DSC
Start-DscConfiguration -Path C:\DSC -Wait -Force -Verbose
```

This example just configures `localhost` but you could specify your hosts instead. Ideally, you are already using DSC and can just add this to your existing configuration.

## Why configuration management

I just want to call out that even if you blast out a change like this to every sever, it is important to move this into your configuration management system. Making this change this way only gets the hosts that are online at this very moment. If a host is powered off, or reverted to a snapshot, or restored from backup, or a new host is deployed, they also need to have these changes made.

I am often quick to rush out a change, but the task isn't really done until its a managed setting. I don't care if thats Group Policy, SCCM, DSC, Puppet, Chef, or something else. Don't just fire and forget changes like this.

# Closing remarks

Hopefully you found some value in me explaining how to make a change like this with PowerShell. The original security advisory did include a single line script to make these same changes so I wanted to take some time and add a little more context. If you like content like this, share it on Twitter using the links below with your feedback. I always appreciate it when readers share my content with others.
