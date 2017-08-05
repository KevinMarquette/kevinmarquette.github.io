[cmdletbinding()]
param(
    $width = 500,
    $path = (LS 'C:\workspace\kevinmarquette.github.io\_posts\*.md' | select -last 1).fullname
)
$path = Resolve-Path $path

foreach ($node in $path)
{

    $template = @'
---
layout: post
title: "{Title:Powershell: PSGraph, A graph module built on GraphViz}"
date: {Date:2017-01-30}
tags: [{Tags:PowerShell,PSGraph,GraphViz}]
---
'@

    $parsedValues = Get-Content $node -raw | ConvertFrom-String -TemplateContent $template
    $tags = $parsedValues | where Tags | % {$_.Tags -split ','} | % {$_.trim()}

    $postInfo = [pscustomobject]@{
        Post  = Split-Path $node -Leaf
        Title = $parsedValues | where Title | % Title 
        Tags  = $tags
        Date  = $parsedValues | where Date | % Date
    }

    $outline = Get-Content $node | where {$_ -match '^#{1,2}[^#]'}


    $lines = @()
    $lines += ($outline -replace '#', '    ') | Where {$_ -notmatch 'index'}
    if ($postInfo.Tags)
    {
        $lines += '$Tags = @("{0}")' -f ($postInfo.Tags -join '", "')
    }
    $lines += '  @KevinMarquette'
    Add-Type -AssemblyName System.Drawing
 
    #$width = 500 # (50 + 31 * $lines.count)*2
    $bmp = new-object System.Drawing.Bitmap ($width, (50 + 31 * $lines.count))
    $font = new-object System.Drawing.Font 'Lucida Console ', 12 
    $brushBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(1, 36, 86))
    $brushFg = [System.Drawing.Brushes]::White 
    $graphics = [System.Drawing.Graphics]::FromImage($bmp) 
    $graphics.FillRectangle($brushBg, 0, 0, $bmp.Width, $bmp.Height) 

    $graphics.DrawString($postInfo.Title.Replace('Powershell: ', ''), $font, $brushFg, 10, 10) 

    $font = new-object System.Drawing.Font 'Lucida Console ', 10 

    $lineNumber = 0
    foreach ($line in $lines)
    {
        $graphics.DrawString($line, $font, $brushFg, 10, (50 + $lineNumber * 30)) 
        $lineNumber += 1
    }

    $graphics.Dispose()

    $imgRoot = 'C:\workspace\kevinmarquette.github.io\img\share-img\'
    $filename = Join-Path $imgRoot (Split-Path $node -leaf).replace('.md', '.png')

    $bmp.Save($filename) 
    $filename 
    #https://cards-dev.twitter.com/validator
}