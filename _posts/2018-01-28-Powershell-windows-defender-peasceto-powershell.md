---
layout: post
title: "Powershell: Windows Defender vs PowerShell Modules, Peasecto.A"
date: 2018-01-28
tags: [PowerShell]
---

For a period of time, Windows Defender was flagging several important PowerShell modules as infected with `Peasecto.A`. This would prevent users from running or installing those modules. Some of the impacted modules included `PackageManagement`, `MSOnline`, `PSScriptAnalyzer`, and `VMware.PowerCLI`. Even [VSCode](https://github.com/Microsoft/vscode/issues/42284) was feeling the pain. The good news is that the issue is resolved for some modules now.

<!--more-->

    PS:> Get-MpComputerStatus | Select AntivirusSignature*

    AntivirusSignatureLastUpdated   : 1/28/2018 8:28:37 PM
    AntivirusSignatureVersion       : 1.261.424.0

These are the definition version that I confirmed fix these modules:

* `PackageManagement` 1.261.424.0
* `PSScriptAnalyzer` 1.261.441.0
* `MSOnline` 1.261.441.0
* `VMWare.PowerCLI`  Pending

Last tested on 1.261.441.0 (KB2267602).

It looks like these module issues will need to be fixed one at a time.

There was not a lot of options other than disable defender or disable PowerShell AMSI while we waited for the definitions to get updated. I was pulling together what information that I could and posting it here as it came up. Now that the issue is resolved, I rewrote the into so the important information is easy to discover.

There are lingering issues for some users with broken modules that will need to be re-installed. The `PackageManagement` module will take some special steps that I outlined below.

# Reinstall PowerShellGet and PackageManagement

Because `PowerShellGet` depends on `PackageManagement`, issues with `PackageManagement` can prevent `PowerShellGet` from working. How do you install modules when `Install-Module` has issues?

If Windows Defender did clean up files out of the `PackageManagement` module, you can import the old version of `PowerShellGet` in a fresh shell to use `Install-Module` again.

    Get-Module PowerShellGet -ListAvailable |
        Where Version -eq 1.0.0.1 |
        Import-Module

    Install-Module PackageManagement -Force
    Install-Module PowerShellGet -Force

PowerShell 5.1 should have the 1.0.0.1 version of both of these modules. So you should have a old version of the module to import. Also note that only users that updated to the new modules will have this issue.

PowerShell Core ships with the newer module by default and is [not as easy to repair](https://github.com/PowerShell/PowerShell/issues/6056).

## Indications that you are in a bad state

These are the error messages you get when in this bad state. If you call `Find-Module` or `Install-Module` you should see something like this:

    find-module : The 'find-module' command was found in the module 'PowerShellGet', but the module
    could not be loaded. For more information, run 'Import-Module PowerShellGet'.

    install-module : The 'install-module' command was found in the module 'PowerShellGet', but the
    module could not be loaded. For more information, run 'Import-Module PowerShellGet'.

If you try and import the `PowerShellGet` module, then you will see this error message:

    PS:> Import-Module PowerShellGet

    import-module : The required module 'PackageManagement' is not loaded. Load the module or remove
    the module from 'RequiredModules' in the file 'C:\Program
    Files\WindowsPowerShell\Modules\powershellget\1.6.0\powershellget.psd1'.

# Early reporting on the issue

The details below contain all the information that was available to us before a fix was made available.

## Twitter

These are the first tweets talking about the issue:

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">What&#39;s this?<br>Defender real-time protection removing files from my <a href="https://twitter.com/hashtag/PowerShell?src=hash&amp;ref_src=twsrc%5Etfw">#PowerShell</a>  modules!</p>&mdash; Luc Dekens (@LucD22) <a href="https://twitter.com/LucD22/status/957732708741992448?ref_src=twsrc%5Etfw">January 28, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">FYI: Windows Defender is detecting Legit PowerShell Modules and PowerShell Core itself as PowerShell/PeaSecto.a <a href="https://t.co/i7DZEo3Pgn">https://t.co/i7DZEo3Pgn</a></p>&mdash; Mark Kraus MVP (@markekraus) <a href="https://twitter.com/markekraus/status/957743213749686272?ref_src=twsrc%5Etfw">January 28, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-cards="hidden" data-lang="en"><p lang="en" dir="ltr">That awkward moment when Windows Defender declares that your <a href="https://twitter.com/hashtag/PowerShell?src=hash&amp;ref_src=twsrc%5Etfw">#PowerShell</a> module is a threat. <a href="https://t.co/DJxvBYenJi">pic.twitter.com/DJxvBYenJi</a></p>&mdash; Boe Prox (@proxb) <a href="https://twitter.com/proxb/status/957723701071568897?ref_src=twsrc%5Etfw">January 28, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Might have overlooked this, but is there any guidance on dealing with <a href="https://twitter.com/hashtag/PowerShell?src=hash&amp;ref_src=twsrc%5Etfw">#PowerShell</a> AMSI false positives in Defender outside of DisableIOAVProtection?  Some innocuous automation being flagged, would prefer not to turn this off...</p>&mdash; Warren F. (@psCookieMonster) <a href="https://twitter.com/psCookieMonster/status/956995840006152192?ref_src=twsrc%5Etfw">January 26, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


## TechNet

Mark was talking about this thread: [Latest updates indicated Peasecto.A infection](https://social.technet.microsoft.com/Forums/en-US/40fa56dd-b73f-456a-9d97-cdb4500bc7ed/latest-updates-indicated-peasectoa-infection-?forum=WindowsDefenderATPPreview). This thread indicates that MSOnline and the Azure modules are impacted. Lots of good information is collecting here even as I post this.

## Reddit

Reddit was also noticing the issue.

* [Windows Defender reporting Peasecto.A malware in some Microsoft PSD1 files](https://www.reddit.com/r/PowerShell/comments/7to5dy/windows_defender_reporting_peasectoa_malware_in)
* [System Center Endpoint protection flagging the MSOnline.psd1 file with Peasecto.A trojan](https://www.reddit.com/r/sysadmin/comments/7tnukh/system_center_endpoint_protection_flagging_the)

## Github Issues

Issues started to pop up on GitHub projects.

* [VSCode](https://github.com/Microsoft/vscode/issues/42284)
* [PowerShell Core](https://github.com/PowerShell/PowerShell/issues/6056)
* [oneget](https://github.com/OneGet/oneget/issues/335)
* [PSSciptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer/issues/860)

## Other links

* [VMWare.PowerCLI](https://blogs.vmware.com/PowerCLI/2018/01/windows-defender-reports-false-positive-powershell-modules.html)

# For next time

Lee Holmes pointed out that Microsoft does have a process for submitting false positives.

<blockquote class="twitter-tweet" data-conversation="none" data-lang="en"><p lang="en" dir="ltr">Here&#39;s where to report false positives: <a href="https://t.co/NsQ34giE3e">https://t.co/NsQ34giE3e</a> - it has nothing to do with AMSI. If the content triggers a signature, it would do it through basic scanning as well.</p>&mdash; Lee Holmes (@Lee_Holmes) <a href="https://twitter.com/Lee_Holmes/status/957692055957880832?ref_src=twsrc%5Etfw">January 28, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

The next time you find Defender attacking the wrong files, you can [submit a file for analysis](https://www.microsoft.com/en-us/wdsi/filesubmission).
