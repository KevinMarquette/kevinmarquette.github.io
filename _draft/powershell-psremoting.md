---
layout: post
title: "Powershell: Remoting"
date: 2016-11-04
tags: [PowerShell, Remoting]
---

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