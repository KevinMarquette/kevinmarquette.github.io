[cmdletbinding()]
param(
    $path = 'C:\workspace\kevinmarquette.github.io\_posts\*.md' 
)
$path = (LS $path | sort name -Descending | select -First 8).fullname
$lineTemplate = '* {0} [{1}](http://kevinmarquette.github.io/{2}/?utm_source=blog&utm_medium=blog&utm_content=recent)'
$template = @'
---
layout: post
title: "{Title:Powershell: PSGraph, A graph module built on GraphViz}"
date: {Date:2017-01-30}
tags: [{Tags:PowerShell,PSGraph,GraphViz}]
---
'@ 

$output = foreach ($node in $path)
{

   

    $parsedValues = Get-Content $node -raw | ConvertFrom-String -TemplateContent $template
    $tags = $parsedValues | where Tags | % {$_.Tags -split ','} | % {$_.trim()}

    $postInfo = [pscustomobject]@{
        Post  = (Split-Path $node -Leaf).Replace('.md','')
        Title = $parsedValues | where Title | % Title 
        Tags  = $tags
        Date  = $parsedValues | where Date | % Date
    }
    $lineTemplate -f $postInfo.Date,$postInfo.Title,$postInfo.Post
}

$output | Set-Content -Path 'C:\workspace\kevinmarquette.github.io\_includes\recent-posts.md'
