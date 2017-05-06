


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

### one step deeper

I think we could make a gernic step test that takes a text block. That text block is executed and foreach to a invoke-GherkinStep that is built off of the current step text.

Would have to have a keyword or some way to inject the result back into the text.

Here is a clever example

    Then 'all public functions (?<Action>.*)' {
        Param($Action)
        $step = @{keyword = 'Then'}
        $AllPassed = $true
        foreach($command in (Get-Command -Module $ModuleName  ))
        {
            $step.text = ('function {0} {1}' -f $command.Name, $Action )

            Invoke-GherkinStep $step -Pester $Pester -Visible
            If( -Not $Pester.TestResult[-1].Passed )
            {
                $AllPassed = $false
            } 

            $step.keyword = 'And'
        }
        $AllPassed | Should be $true
    }

## pester version

Was added in 4.0 but refactored in 4.0.3. Pay attention to versions.

## Guidance

Feature: Returns go to stock
As a   store owner
In order to   keep track of stock
I want to   add items back to stock when they're returned.

Use one Given, should be past tense
When in present tense
Then in future tense

## it commands in given steps

Can call IT inside a given script to add lines to the output


    Then 'all script files pass PSScriptAnalyzer rules' {
    
    $Rules = Get-ScriptAnalyzerRule
    $scripts = Get-ChildItem $BaseFolder -Include *.ps1, *.psm1, *.psd1 -Recurse | where fullname -notmatch 'classes'
    
   
    $AllPassed = $true

    foreach ($Script in $scripts )
    {      
        $file = $script.fullname.replace($BaseFolder, '$')
        foreach ( $rule in $rules )
        {
            It " [$file] Rule [$rule]" {

                (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
            }
        }

        If ( -Not $Pester.TestResult[-1].Passed )
        {
            $AllPassed = $false
        } 
    }
    $AllPassed | Should be $true
}


## also supports context and describe

* should create an alias for context to scenario
* should create an alias for describe to feature