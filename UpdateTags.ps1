[CmdletBinding()]
param(
    [string]$Path,
    [string]$TagFile
)

# Windows PowerShell 5.1 doesn't populate $PSScriptRoot in param defaults
if (-not $Path) { $Path = Join-Path -Path $PSScriptRoot -ChildPath '_posts' }
if (-not $TagFile) { $TagFile = Join-Path -Path $PSScriptRoot -ChildPath 'tags.md' }

function Get-PostFrontMatter {
    param([System.IO.FileInfo]$File)

    $lines = Get-Content -LiteralPath $File.FullName -Encoding UTF8
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') {
        Write-Warning "No front matter found in [$($File.Name)]"
        return
    }

    $values = @{}
    foreach ($line in $lines | Select-Object -Skip 1) {
        if ($line.Trim() -eq '---') { break }
        if ($line -match '^(?<key>[\w-]+):\s*(?<value>.*?)\s*$') {
            $values[$Matches.key] = $Matches.value
        }
    }

    $title = $values['title'] -replace '^(["''])(.*)\1$', '$2'
    $tags = @()
    if ($values['tags']) {
        $tags = $values['tags'].Trim('[', ']') -split ',' |
            ForEach-Object { $_.Trim().Trim('"', "'") } |
            Where-Object { $_ }
    }

    [pscustomobject]@{
        Post  = $File.BaseName
        Title = $title
        Date  = $values['date']
        Tags  = $tags
    }
}

$tagList = @{}
foreach ($file in Get-ChildItem -LiteralPath $Path -Filter *.md) {
    $post = Get-PostFrontMatter -File $file
    if ($null -eq $post) { continue }

    if (-not $post.Tags) {
        Write-Verbose "No tags in [$($file.Name)]"
    }

    foreach ($tag in $post.Tags) {
        if (-not $tagList.ContainsKey($tag)) {
            $tagList[$tag] = [System.Collections.Generic.List[object]]::new()
        }
        $tagList[$tag].Add($post)
    }
}

$output = [System.Collections.Generic.List[string]]::new()
$header = @'
---
layout: page
title: Tags
---
This is a collection of all the tags I use in my blog and links back to the pages that use them.

# Index

* TOC
{:toc}
'@
# Split so the here-string's line endings don't depend on how this file was saved
$output.AddRange([string[]]($header -split '\r?\n'))

foreach ($key in $tagList.Keys | Sort-Object) {
    $output.Add('')
    $output.Add("<a name='$key'></a>")
    $output.Add("# $key")
    $output.Add('')
    foreach ($post in $tagList[$key] | Sort-Object -Property Date, Post) {
        $output.Add(("* {0} [{1}](/{2}/?utm_source=blog&utm_medium=blog&utm_content=tags)" -f $post.Date, $post.Title, $post.Post))
    }
}

# WriteAllLines writes UTF-8 without a BOM in both Windows PowerShell 5.1 and PowerShell 7
$fullTagPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TagFile)
[System.IO.File]::WriteAllLines($fullTagPath, $output)
