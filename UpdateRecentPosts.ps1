[CmdletBinding()]
param(
    [string]$Path,
    [string]$OutputPath,
    [int]$Count = 8
)

# Windows PowerShell 5.1 doesn't populate $PSScriptRoot in param defaults
if (-not $Path) { $Path = Join-Path -Path $PSScriptRoot -ChildPath '_posts\*.md' }
if (-not $OutputPath) { $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath '_includes\recent-posts.md' }

$lineTemplate = '* {0} [{1}](/{2}/?utm_source=blog&utm_medium=blog&utm_content=recent)'

$postList = Get-ChildItem -Path $Path |
    Sort-Object -Property Name -Descending |
    Select-Object -First $Count

$output = foreach ($file in $postList)
{
    $values = @{}
    $lines = Get-Content -LiteralPath $file.FullName -Encoding UTF8
    if ($lines[0].Trim() -eq '---') {
        foreach ($line in $lines | Select-Object -Skip 1) {
            if ($line.Trim() -eq '---') { break }
            if ($line -match '^(?<key>[\w-]+):\s*(?<value>.*?)\s*$') {
                $values[$Matches.key] = $Matches.value
            }
        }
    }

    $title = $values['title'] -replace '^(["''])(.*)\1$', '$2'
    $lineTemplate -f $values['date'], $title, $file.BaseName
}

# WriteAllLines writes UTF-8 without a BOM in both Windows PowerShell 5.1 and PowerShell 7
$fullOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
[System.IO.File]::WriteAllLines($fullOutputPath, [string[]]$output)
