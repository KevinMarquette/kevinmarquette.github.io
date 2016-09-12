---
layout: post
title: "PowerShell: Passing variables to remote commands"
date: 2016-08-28
tags: [PowerShell, Invoke-Command, Remoting]
---

If you have started using `Invoke-Command`, then you have ran into the issue of getting local variables into your remote commands. There is a lot of advice out there on how to do this and some approaches are more clunky than others. First let me show you the problem of scope.

    $local = Get-Date
    Invoke-Command -ComputerName server01 -ScriptBlock { 
        "Date = {0}" -f $local
    }

That script runs in a different scope on the remote system and it is not aware of the variables in the local session. In the example above, $local is actually `$null` in the remote session because it was never defined in that scope. The good news is that `Invoke-Command` has a `-ArgumentList` parameter that we can use.

    Invoke-Command -ComputerName server01 -ArgumentList $local -ScriptBlock { 
        "Date = {0}" -f $args[0] 
    }

While that works, we are using a legacy variable to access the parameter. I don't mind that as much but it isn't intuitive that `$args[0]` has the value of `$local`. Easy enough to figure out when you have one argument but that list can get quite large at times. We can address that problem by giving our ScriptBlock a param block.

    Invoke-Command -ComputerName server01 -ArgumentList $local -ScriptBlock { 
        param($local)
        "Date = {0}" -f $local
    }

Now our variables are a lot easier to work with and this easily scales to as many parameters as we need. There is one more option available to us that I like much better. Starting with Powershell 3.0, they added a `$using:` scope to the language to address this scenario in workflows. You can also use it with `Invoke-Command` and with the DSC script resource. It looks like this:

    Invoke-Command -ComputerName server01 -ScriptBlock { 
        "Date = {0}" -f $using:local
    }

It embeds the variable from the calling scope into the scriptblock. I like this because it is really close to how we started and it is very intuitive once you figure it out. You can do this with any number of variables.
