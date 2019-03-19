[cmdletbinding()]
param(
    $width = 230,
    $path = (LS 'C:\workspace\kevinmarquette.github.io\_posts\*.md' | select -last 1).fullname,
    #$path = 'C:\workspace\kevinmarquette.github.io\_posts\2017-01-13-powershell-variable-substitution-in-strings.md',
    [ValidateSet('Heading', 'WordCloud')]
    $Type = 'WordCloud',
    $FocusWord = $null
)
$path = Resolve-Path $path
foreach ($node in $path)
{
    Write-Verbose $node -Verbose
    $imgRoot = 'C:\workspace\kevinmarquette.github.io\img\share-img\'
    $filename = Join-Path $imgRoot (Split-Path $node -leaf).replace('.md', '.svg')

    switch ($Type)
    {
        "Heading"
        {
            $headdingHeight = 30
            $lineHeight = 20
            
            
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
        
            #$width = 500 # (headdingHeight + 31 * $lines.count)*2
            $bmp = new-object System.Drawing.Bitmap ($width, ($headdingHeight + $lineHeight * $lines.count))
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
                $graphics.DrawString($line, $font, $brushFg, 10, ($headdingHeight + $lineNumber * $lineHeight)) 
                $lineNumber += 1
            }
        
            $graphics.Dispose()
        
            $bmp.Save($filename) 
        }
        "WordCloud"
        {
            $templatePath = '{0}.png' -f (New-TemporaryFile).FullName

            $image = [System.Drawing.Bitmap]::new(600,314)
            #$image = [System.Drawing.Image]::FromFile($tempfile)
            
            $font = new-object System.Drawing.Font 'Lucida Console', 14
            $brushBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(1, 36, 86))
            $brushFg = [System.Drawing.Brushes]::White 
            $brushBlack = [System.Drawing.Brushes]::Black 
            
            $graphics = [System.Drawing.Graphics]::FromImage($image) 
            $graphics.FillRectangle($brushBlack,0,0,$image.Width,$image.Height)
            $graphics.FillRectangle($brushBg, 0, 0, $image.Width, 30) 
            $graphics.DrawString('PowerShellExplained.com with @KevinMarquette', $font, $brushFg, 35, 5) 
            $graphics.Dispose()
            $image.Save($templatePath)

            $content = Get-Content -Path $node 
        
            #$tempfile = '{0}.svg' -f (New-TemporaryFile).FullName
            $exclude = @(
                'utm_medium'
                'utm_source'
                'utm_content'
                'http'
                'will'
                'value'
                'popref'
            )
            $content = $content -replace 'powershell', 'PowerShell'
            $content = $content -replace 'posh', 'PowerShell'
            #$content = $content -replace '$null','null'
           

            $newWordCloudSplat = @{
                FontFamily   = 'Lucida Console'
                ExcludeWord  = $exclude
                path         = $filename
                BackgroundImage = $templatePath
                #ImageSize    = $size
            }
            if($FocusWord)
            {
                $newWordCloudSplat['FocusWord'] = $FocusWord
            }
            $content | New-WordCloud @newWordCloudSplat -Verbose
            # Add branding
            #$size = [System.Drawing.size]::new(600, 314)
            
        
        }
    }
    $filename 
    'share-img: "/img/share-img/{0}"' -f (Split-Path $filename -Leaf)
    #https://cards-dev.twitter.com/validator
}
