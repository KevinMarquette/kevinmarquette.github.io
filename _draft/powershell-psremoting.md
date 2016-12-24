---
layout: post
title: "Powershell: Everything you wanted to know about PSRemoting"
date: 2016-11-04
tags: [PowerShell, Remoting]
---

Knowing how to setup and work with PSRemoting is an important skill for every Powershell admin. It is realy easy to get started with but there are some things to watch out for along the way. I am going to give a rundown on how to work with it and then dive into all the quirks that I am aware of. 

# The basiscs of remoting

Remoting is all about running commands on remote systems. Many commands that you can run on your local system can be executted in sessions that are running on the target system.

## Commands with -ComputerName
Before you dive into remoting, check to see if the command you want to run suppots the `-ComputerName` parameter. 

    Get-CimInstance Win32_BIOS -ComputerName $ComputerName

There are a good number of cmdlets that support specifying a target system already without using remoting.

## Quickly enabling PSRemoting
On Server 2012, remoting should already be enabled by default. For anything older, we still have to enable it with this command (as an administrator). 

    Enable-PSRemoting

It will perform the needed configuration steps to get PSRemoting enabled. There are lots of scenarios where it isn't this simple and you may need to troubleshoot some things. I have an entire section bellow dedicated to working out connectivity issues below.

## Quick first conneciton
The first command we are going to work with is `Enter-PSSession`. This creates a remote session with the target system. 

    $computername = 'TargetSystemName'
    Enter-PSSession -ComputerName $computername

If this connects then you will have a session where you can run commands and see the results. 

Run `Exit` to end your session. 

## Invoke-Command
The `Enter-PSSession` command allows you to interact with the session. The other importing remoting command is `Invoke-Command`. This one just executes commands on the remote session.

    Invoke-Command -ComputerName $computername -ScriptBlock { Get-Date } 

Everything in the script block gets executed in the remote session.

## Invoke-Command vs Enter-PSSession
The important thing to realize is that `Invoke-Command` is what you should be using in your scripts and `Enter-PSsession` is what you use when you are on the shell and want to interact with the target system. They both run the commands on the remote system.

If your `Invoke-Command` scripts are not working, use `Enter-PSSession` to troubleshoot your code. This is important to remember because remote sessions do not act 100% the same as your local shell. Sometimes you need to interact with things a bit to get a feel for where the prolem is.

## 

# Variables in remote sessions
Working with variables in remote sessions are a little different that you would expect when you first start woking with remote sessions. variables



## Scope


# the double hop problem

# Just enough admin

# Troubleshooting connections


Getting started with Powershell [remoting](https://technet.microsoft.com/en-us/library/hh847900.aspx) can be very easy. If you are running an older OS then you may need to enable it.

    Enable-PSRemoting

One quick tip. Non-Domain joined machines may fail if the network type is public. This is common when a system first comes up. One of these commands should work depending on your operating system.

    Enable-PSRemoting -SkipNetworkProfileCheck -Force

    Set-NetConnectionProfile -NetworkCategory Private

Connecting cross domain or to workgroup machines requires you to add that system to the [trusted hosts](http://winintro.ru/windowspowershell2corehelp.en/html/f23b65e2-c608-485d-95f5-a8c20e00f1fc.htm) (on the client machine)

    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "Server1,Server2"
    Set-Item wsman:\localhost\Client\TrustedHosts -Value "*.contoso.com,10.*"

If you would like to see the current configuration then you can query it like this:

    Get-ChildItem wsman:\localhost\Client\TrustedHosts

If you are still having troubles, then use `Test-WSMan` for [diagnotic testing](https://technet.microsoft.com/en-us/library/hh849873.aspx). It's like a ping but checks common WSMan remoting issues.

    Test-WSMan localhost

Make sure that the WinRM service is enabled and running on the target system.

    Get-Service winrm

Double check you firewall ports if you have a one in the way. For WinRM 2.0, the default HTTP port is 5985, and the default HTTPS port is 5986.
[Installation and Configuration for Windows Remote Management](https://msdn.microsoft.com/en-us/library/aa384372%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396)


## Using PSRemoting

Here is a quick [command](https://technet.microsoft.com/en-us/library/hh849707.aspx) to start a new remote session.

    Enter-PSSession -ComputerName localhost
    Enter-PSSession -ComputerName localhost -Credential (Get-Credential)


You can invoke just a command on computer(s) without using an interactive session.

    Invoke-Command -ComputerName localhost -ScriptBlock {hostname}
    Invoke-Command -ComputerName localhost,localhost -ScriptBlock {hostname}

    'localhost','localhost'  | %{Invoke-Command -computername $_ -ScriptBlock {hostname} }

I covered a lot of things very quickly but those are all the things that I consider and look at when I am dealing with PSRemoting issues. Most of the time everything just work. I figured I would take the time to spell out all these other details incase you were having issues and needed to dive in a little deeper. 
