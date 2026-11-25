<#
.SYNOPSIS
Creates the social media share image for a post.

.DESCRIPTION
Builds a 1200x630 PNG in img\share-img\ and prints the share-img line to paste into
the post's front matter. The WordCloud type renders an SVG with PSWordCloud and then
converts it to PNG with a headless Edge or Chrome, because social media cards don't
display SVG.

.EXAMPLE
.\CreateTitleImage.ps1

Creates a word cloud image for the newest post.

.EXAMPLE
.\CreateTitleImage.ps1 -FocusWord 'Developers'

Puts 'Developers' in the center of the cloud. Use this when a post is broad enough
that the most common words don't give it an identity of its own.
#>
[CmdletBinding()]
param(
    # The post to create an image for. Defaults to the newest post in _posts.
    [string[]]$Path,

    # Image width for the Heading type.
    [int]$Width = 230,

    [ValidateSet('Heading', 'WordCloud')]
    [string]$Type = 'WordCloud',

    # Word drawn large in the center of the word cloud. It doesn't need to appear in the post.
    [string]$FocusWord,

    # Seed for the word cloud layout. Use the same seed to get the same layout again.
    [int]$RandomSeed
)

# 1.91:1 is the large link card shape for Facebook, LinkedIn, and X.
# 1200x630 stays sharp on high DPI screens.
$shareWidth = 1200
$shareHeight = 630

# Windows PowerShell 5.1 doesn't populate $PSScriptRoot in param defaults
$imgRoot = Join-Path -Path $PSScriptRoot -ChildPath 'img\share-img'
if (-not $Path) {
    $Path = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '_posts\*.md') |
        Sort-Object -Property Name |
        Select-Object -Last 1 -ExpandProperty FullName
}

function Get-PostFrontMatter {
    param([string]$Path)

    $values = @{}
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    if ($lines[0].Trim() -eq '---') {
        foreach ($line in $lines | Select-Object -Skip 1) {
            if ($line.Trim() -eq '---') { break }
            if ($line -match '^(?<key>[\w-]+):\s*(?<value>.*?)\s*$') {
                $values[$Matches.key] = $Matches.value
            }
        }
    }

    $tags = @()
    if ($values['tags']) {
        $tags = $values['tags'].Trim('[', ']') -split ',' |
            ForEach-Object { $_.Trim().Trim('"', "'") } |
            Where-Object { $_ }
    }

    [pscustomobject]@{
        Title = $values['title'] -replace '^(["''])(.*)\1$', '$2'
        Date  = $values['date']
        Tags  = $tags
    }
}

function Find-Browser {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}

function Convert-SvgToPng {
    param(
        [string]$SvgPath,
        [string]$PngPath,
        [int]$Width = 1200,
        [int]$Height = 630
    )

    $browser = Find-Browser
    if (-not $browser) {
        throw "Could not find Edge or Chrome to convert [$SvgPath] to PNG"
    }

    # A separate profile keeps headless mode from handing off to a browser that is already open
    $profileDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([guid]::NewGuid())
    $svgUri = ([System.Uri]$SvgPath).AbsoluteUri

    $browserArgs = @(
        '--headless'
        '--disable-gpu'
        '--hide-scrollbars'
        "--user-data-dir=`"$profileDir`""
        "--window-size=$Width,$Height"
        "--screenshot=`"$PngPath`""
        $svgUri
    )

    if (Test-Path -LiteralPath $PngPath) {
        Remove-Item -LiteralPath $PngPath
    }

    $processParam = @{
        FilePath     = $browser
        ArgumentList = $browserArgs
        Wait         = $true
        WindowStyle  = 'Hidden'
    }
    Start-Process @processParam
    Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path -LiteralPath $PngPath)) {
        throw "Browser did not create [$PngPath]"
    }
}

Add-Type -AssemblyName System.Drawing

foreach ($node in Resolve-Path -Path $Path)
{
    $node = $node.ProviderPath
    Write-Verbose "Creating share image for [$node]" -Verbose
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($node)
    $pngPath = Join-Path -Path $imgRoot -ChildPath "$baseName.png"

    switch ($Type)
    {
        'Heading'
        {
            $headingHeight = 30
            $lineHeight = 20

            $postInfo = Get-PostFrontMatter -Path $node
            $outline = Get-Content -LiteralPath $node | Where-Object { $_ -match '^#{1,2}[^#]' }

            $lines = @()
            $lines += ($outline -replace '#', '    ') | Where-Object { $_ -notmatch 'index' }
            if ($postInfo.Tags)
            {
                $lines += '$Tags = @("{0}")' -f ($postInfo.Tags -join '", "')
            }
            $lines += '  @KevinMarquette'

            $bmp = New-Object System.Drawing.Bitmap ($Width, ($headingHeight + $lineHeight * $lines.Count))
            $font = New-Object System.Drawing.Font 'Lucida Console', 12
            $brushBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(1, 36, 86))
            $brushFg = [System.Drawing.Brushes]::White
            $graphics = [System.Drawing.Graphics]::FromImage($bmp)
            $graphics.FillRectangle($brushBg, 0, 0, $bmp.Width, $bmp.Height)

            $graphics.DrawString(($postInfo.Title -replace '^Powershell: ', ''), $font, $brushFg, 10, 10)

            $font = New-Object System.Drawing.Font 'Lucida Console', 10

            $lineNumber = 0
            foreach ($line in $lines)
            {
                $graphics.DrawString($line, $font, $brushFg, 10, ($headingHeight + $lineNumber * $lineHeight))
                $lineNumber += 1
            }

            $graphics.Dispose()
            $bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
        }
        'WordCloud'
        {
            $svgPath = Join-Path -Path $imgRoot -ChildPath "$baseName.svg"
            $backgroundPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "$([guid]::NewGuid()).png"

            # Black background with the site banner across the top.
            # The word cloud takes its size from this background image.
            $image = [System.Drawing.Bitmap]::new($shareWidth, $shareHeight)
            $font = New-Object System.Drawing.Font 'Lucida Console', 28
            $brushBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(1, 36, 86))
            $brushFg = [System.Drawing.Brushes]::White
            $brushBlack = [System.Drawing.Brushes]::Black

            $graphics = [System.Drawing.Graphics]::FromImage($image)
            $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
            $graphics.FillRectangle($brushBlack, 0, 0, $image.Width, $image.Height)
            $graphics.FillRectangle($brushBg, 0, 0, $image.Width, 60)
            $graphics.DrawString('PowerShellExplained.com with @KevinMarquette', $font, $brushFg, 70, 10)
            $graphics.Dispose()
            $image.Save($backgroundPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $image.Dispose()

            $content = Get-Content -LiteralPath $node -Encoding UTF8

            # Drop link targets and URLs so they don't fill the cloud with utm, https, and domain names
            $content = $content -replace '\]\([^)]*\)', ']'
            $content = $content -replace 'https?://\S+', ''
            # Drop code fences and console prompts like 'PS>' and 'PS C:\Temp>'
            $content = $content -notmatch '^\s*```'
            $content = $content -replace '^\s*PS(\s+[^>]*)?>\s*', ''
            $content = $content -replace 'powershell', 'PowerShell'
            $content = $content -replace '\bposh\b', 'PowerShell'

            $exclude = @(
                'utm_medium'
                'utm_source'
                'utm_content'
                'http'
                'https'
                'will'
                'value'
                'popref'
            )

            $wordCloudParam = @{
                FontFamily      = 'Lucida Console'
                ExcludeWord     = $exclude
                Path            = $svgPath
                BackgroundImage = $backgroundPath
            }
            if ($FocusWord)
            {
                $wordCloudParam['FocusWord'] = $FocusWord
                # Keep the focus word horizontal so it reads at a glance
                $wordCloudParam['RotateFocusWord'] = 0
            }
            if ($PSBoundParameters.ContainsKey('RandomSeed'))
            {
                $wordCloudParam['RandomSeed'] = $RandomSeed
            }

            try
            {
                $content | New-WordCloud @wordCloudParam
            }
            finally
            {
                Remove-Item -LiteralPath $backgroundPath -ErrorAction SilentlyContinue
            }

            Convert-SvgToPng -SvgPath $svgPath -PngPath $pngPath -Width $shareWidth -Height $shareHeight
        }
    }

    $pngPath
    'share-img: "/img/share-img/{0}"' -f (Split-Path -Path $pngPath -Leaf)
}
