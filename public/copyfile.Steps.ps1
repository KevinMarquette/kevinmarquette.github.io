Given 'we have a source file' {
    mkdir source -ErrorAction SilentlyContinue
    Set-Content '.\source\something.txt' -Value 'Data'
    '.\source\something.txt' | Should Exist
}

And 'we have a destination folder' {
    mkdir target -ErrorAction SilentlyContinue
    '.\target' | Should Exist
}

When 'we call Copy-Item' {
    { Copy-Item .\source\something.txt .\target } | Should Not Throw
}

Then 'we have a new file in the destination' {
    '.\target\something.txt' | Should Exist
}

And 'the new file is the same as the original file' {
    $primary = Get-FileHash .\target\something.txt
    $secondary = Get-FileHash .\source\something.txt
    $secondary.Hash | Should Be $primary.Hash
}