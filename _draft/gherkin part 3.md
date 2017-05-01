


# notes

## Clever use of match for should operations

    When "the settings file should (\w+)\s*(.*)?" {
        param($operator, $data)
        # I have to normalize line endings:

        $data = [regex]::escape(($data -replace "\r?\n","`n"))
        if($operator -eq "Contain"){ $operator = "ContainMultiline"}
        Get-Item ${Script:SettingsFile} | Should $operator $data

    }


## Passing variables to future tests

Use script scope to set variables and future tests will be able to see them

Use BeforeEachScenario to clear any variables that you plan on using so they don't leak data from scenarios.

## dynamically add and call specifications at runtime

    Given 'we have a (?<name>.+?) function' {
        param($name)
        "$psscriptroot\..\psgraph\*\$name.ps1" | Should Exist
    }

    Given 'We have these functions' {
        param($table)
        foreach ($row in $table)
        {
            $step = @{
                text = ('we have a {0} function' -f $row.Name)
                keyword = 'Given'           
            }
        
            Invoke-GherkinStep $step -Pester $pester -Verbose
        }    
    }

## Guidance

Feature: Returns go to stock
As a   store owner
In order to   keep track of stock
I want to   add items back to stock when they're returned.

Use one Given, should be past tense
When in present tense
Then in future tense