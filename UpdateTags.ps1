$path = 'C:\workspace\kevinmarquette.github.io\_posts'
$tagFile = 'C:\workspace\kevinmarquette.github.io\tags.md'
$postList = LS $path -Filter *.md

$template = @'
---
layout: post
title: "{Title:Powershell: PSGraph, A graph module built on GraphViz}"
date: {Date:2017-01-30}
tags: [{Tags:PowerShell,PSGraph,GraphViz}]
---
'@

$tagList = @{}
foreach($file in $postList)
{
    $parsedValues = Get-Content $file.FullName -raw | ConvertFrom-String -TemplateContent $template
    $tags = $parsedValues | where Tags | %{$_.Tags -split ','}

    $post = [pscustomobject]@{
        Post = $file.basename
        Title = $parsedValues | where Title | % Title 
        Tags  = $tags
        Date = $parsedValues | where Date | % Date
    }

    foreach($tag in $tags)
    {
        $tag = $tag.Trim()
        If(-Not $tagList.ContainsKey($tag))
        {
            $tagList[$tag] = @{}
        }

        $tagList[$tag][$post.date] = $post
    }
}

$keyList = $tagList.Keys | Sort-Object

$taginfo = foreach($key in $keyList)
{
    Write-Output ''
    Write-Output "<a name='$key'></a>"
    Write-Output "# $key"
    Write-Output ''
    foreach($post in $tagList[$key].Values | Sort-Object Date)
    {
        Write-Output ("* {0} [{1}](/{2}/?utm_source=blog&utm_medium=blog&utm_content=tags)" -f $post.Date, $post.Title, $post.Post)
    }
}

Set-Content -Path $tagFile -Value @'
---
layout: page
title: Tags
---
This is a collection of all the tags I use in my blog and links back to the pages that use them.

# Index

* TOC
{:toc}
'@

Add-Content -Path $tagFile -Value $taginfo