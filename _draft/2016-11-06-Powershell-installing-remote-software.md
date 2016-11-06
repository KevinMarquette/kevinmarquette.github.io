---
layout: post
title: "Powershell: Remote install software"
date: 2016-11-06
tags: [PowerShell,Remoting]
---

Last month I covered [silently installing a MSI](/2016-10-21-powershell-installing-msi-files/). The next thing an admin 
wants to do is install it on a remote system. That is the logical 
next step. To keep these samples cleaner, I am going to use 
a different imaginary installer that is not an MSI. Using `Enter-PSSession` or 
`Invoke-Command` allows us to run commands on the remote system 
so that is what we will use.

    Invoke-Command -ComputerName server01 -ScriptBlock { 
        \\fileserver\share\installer.exe /silent 
    }

At first glance, this looks like it should work and it can be 
the source of a lot of headaches. Ideally you want to run the 
installer from the network, but you find that does not work. 
Then you try to work in a `Copy-Item` command in and get an 
access denied message. 

## The double hop problem 

This is the double hop problem. The credential used to authenticate 
with server01 cannot be used by server01 to authenticate to fileserver. 
Or any other network resources for that matter. That second hop is 
anything that requires authentication that is not on the remote system. 

We can either pre-copy the file or re-authenticate on the remote end. 
First a few common variables to reuse in the rest of the examples.

    $file = '\\fileserver\share\installer.exe'
    $computerName = 'server01'

## Pre-copy file using admin share
The obvious first approach is to use the admin share of the remote system 
to push content to a location we can access. Here I just place it 
in the windows temp folder then remotely execute it.
    
    Copy-Item -Path $file -Destination "\\$computername\c$\windows\temp\installer.exe"
    Invoke-Command -ComputerName $computerName -ScriptBlock { 	
        c:\windows\temp\installer.exe /silent 
    } 

## Pre-copy using PSSession (PS 5.0)
There is a new feature added in Powershell 5.0 that allows you to copy 
files using a PSSession. So create a PSSession and just copy the file 
over it using the syntax below. A cool thing about this approach is that 
with Powershell 5.0, you can create a PSSession to a guest VM over the 
VM buss (instead of over the network) and you can still copy a file to it. 

    $session = New-PSSession -ComputerName $computerName
    Copy-Item -Path $file -ToSession $session -Destination 'c:\windows\temp\installer.exe' 

    Invoke-Command -Session $session -ScriptBlock { 	
        c:\windows\temp\installer.exe /silent 
    }
    Remove-PSSession $session 

## Re-authenticate from the session
It actually is really easy to re-authenticate if that 
is what is needed. Just create a credential object and 
pass it into your Invoke-Command. Then use that credential 
to create a New-PSDrive. Even if you don't use the 
new drive mapping, it will establish authentication. 

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

I used two tricks in that example that I need to point out incase you have not seen them before. The first is [splatting](https://technet.microsoft.com/en-us/library/jj672955.aspx) and the second is the `$using:` [scope](/2016-08-28-PowerShell-variables-to-remote-commands). I combine both of them when I execute this command `New-PSDrive @using:psdrive`. Those tricks took the hashable from my local session and splatted to the command in the remote session.

## Don’t use CredSSP

I can't talk about the double hop problem without mentioning 
CredSSP. The most common solution you will find online 
if you google the double hop problem is to enable CredSSP. 
The general community has moved away from that as a solution 
because it puts your environment at risk. The issue with 
CredSSP is that your admin credential gets cached on the 
remote system in a way that gives attackers easy access 
to it. [Accidental Sabotage: Beware of CredSSP](http://www.powershellmagazine.com/2014/03/06/accidental-sabotage-beware-of-credssp/)


## Resource-Based Kerberos Constrained Delegation.

But there is a better solution called Resource-Based Kerberos Constrained Delegation. Constrained delegation in Server 2012 introduces the concept of controlling delegation of service tickets using a security descriptor rather than an allow list of SPNs. This change simplifies delegation by enabling the resource to determine which security principals are allowed to request tickets on behalf of another user. [PowerShell Remoting Kerberos Double Hop Solved Securely](https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/)

Here is a quick snip of code showing how it works.

    # For ServerC in Contoso domain and ServerB in other domain            
    $ServerB = Get-ADComputer -Identity ServerB -Server dc1.alpineskihouse.com            
    $ServerC = Get-ADComputer -Identity ServerC            
    Set-ADComputer -Identity $ServerC -PrincipalsAllowedToDelegateToAccount $ServerB

    #To undo the configuration, simply reset ServerC’s attribute to null.
    Set-ADComputer -Identity $ServerC -PrincipalsAllowedToDelegateToAccount $null 

# Other ideas for the more ambitious

That covers the most common approaches that admins take to solving this problem. I do have a few more ideas for you if you are willing to think outside the box. I am not going to get into any details on these. So you are on your own to figure out how to implement them.

## Web download

We could just as easily placed the file you need on a internal web server and downloaded them to the target system before running them.

    Invoke-WebRequest $url -OutFile 'c:\windows\temp\installer.exe'

## Internal repository

The first is to set up a repository and use the new package management commands to deploy applications. `Find-Package` and `Install-Package`. I have not worked with setting up package repository for this purpose so I can't give you any more direction than that.

## Desired State Configuration

The other is to use DSC to deploy and install your software. The easy stuff in DSC is very easy and you would learn a lot going down this path. I don't have enough space here to get into the details of how something like that would work. But you would need a pull server but that is easy to set up. 

Deciding how to get the installer to the target system is the hard part with DSC. You could use the same download from URL or pull from repository idea that I just mentioned. If you set up certificates, then you can provide credentials to a file share for straight file copy. Or you can create a custom DSC Resource and place the files in it. The target system would download it from the pull server like it would other resources.

# In closing
You have plenty of options to choose from. I would recommend focusing on the ones in the first half of this post. That is what most people start with and there is a lot more help out there if you need it. 

