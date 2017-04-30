# notes

examples

https://github.com/PoshCode/Configuration/tree/master/Specs 


I need to explain wildcards in steps, parameterized examples, the way before/after works better, and why g-w-t makes you write better tests

It's worth pointing out there's a Find-GherkinStep you can use to figure out which step definition will match step text ;-)

Some <examples> in my Configuration module.
https://github.com/PoshCode/Configuration/blob/master/Specs/LocalStoragePath.feature#L40-L49 … 
It's also regex! E.g. line 43 matches here:

Gherkin has Before/After each Feature/Scenario in steps
They apply across a whole test run
Pester Before/After apply to "IT" within context

# start of post


In the last post, I covered the bare basics of how to use Gherkin. I had a conversation with Joel Bennett on twitter about Gherkin and he pointed out some more examples from his Configuration module. Now that I have been playing with them for a few days, I decided it was time to share my findings.

This is the 2nd post in a 3 part series on Gherkin where I cover the advanced features. These features are the building blocks that give Gherkin a lot of power.

* Part 1: Basic introduction
* Part 2: Advanced Features (This post)
* Part 3: Working with Gherkin (Planned but not posted)


# Quick review

Take a moment to read the previous post. The idea is that you write a specification in common business speak consisting of several sentences. Each sentence is on its own line and starts with a key works like `Given`,`When`,`Then`,`But` or`And`.

    Feature: You can copy one file

    Scenario: The file exists, and the target folder exists
        Given we have a file: .\source\something.txt
        And we have a folder: .\target
        When we call Copy-Item .\source\something.txt .\target
        Then we have a file .\target\something.txt
        And the file .\target\something.txt is the same as .\source\something.txt

Then those are matched to the steps that validate the specification. The sentences are parried with a matching test.

    Given 'we have a file: .\source\something.txt' {
        .\source\something.txt | Should Exist
    }

    And 'we have a folder: .\target' {
        .\target | Should Exist
    }

    When 'we call Copy-Item .\source\something.txt .\target' {
        { Copy-Item .\source\something.txt .\target } | Should Not Throw
    }

    Then 'we have a file .\target\something.txt' {
        .\target\something.txt | Should Exist
    }

    And 'the file .\target\something.txt is the same as .\source\something.txt' {
        $primary = Get-FileHash .\target\something.txt
        $secondary = Get-FileHash .\source\something.txt
        $secondary.Hash | Should Be $primary.Hash
    }

The idea is simple but there is much more to it.

# Tags

Gherkin has tag support at the feature and scenario level. You place them at the line above the scenario or feature on one line and prefix them with the `@` sign.

    @Functions @Milestone
    Scenario: basic feature support
        Given we have public functions
        Then we have a New-Node function

Then we can run those the scenarios that have the tag `@Functions` like this.

    Invoke-Gherkin -Tag Functions

And we can exclude by tags.

    Invoke-Gherkin -ExcludeTag Milestone

This is like the tag support that Peter uses.

# BeforeEachScenario

In your script containing all your tests, you can specify a `BeforeEachScenario` script to run before each scenario.

    BeforeEachScenario { 
        Set-Location TestDrive: 
    }

This will stage the sample file with sample data between each scenario. We can also use tags to limit what scenario the `BeforeEachScenario` runs before.

    BeforeEachScenario -Tags DataProcessing  {
        Set-Location TestDrive: 
    }

By specifying a tag, this script will only run for each scenario that has this same tag.

We have `AfterEachScenario`, `BeforeEachFeature` and `AfterEachFeature` commands that work the same way.

# Manny to one

Each specification is matched a test and you can have the same specification in multiple scenarios.

    Scenario: basic node support
        Given we have public functions
        Then we have a New-Node function

    Scenario: basic edge support
        Given we have public functions
        Then we have a New-Edge function

In this example, the `Given we have public functions` in both scenarios would match the following test.

    Given 'we have public functions' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

This allows you have common requirements or statements for multiple scenarios without having to create more tests.

# Table support

We can define a table inside the specification and that will get passed into our tests.

    Scenario: basic feature support
        Given we have these functions
        | Name       | Type    |
        | New-Node   | Public  |
        | New-Edge   | Public  |
        | Get-Indent | Private |

Then create a corresponding test to use that table.

    Given 'We have these functions' {
        param($table)
        foreach($row in $table)
        {
            "$psscriptroot\..\psgraph\$($row.type)\$($row.name).ps1" | Should Exist
        }
    }

Using a table also allows you to reuse that test in other specifications but with different datasets.

    Scenario: basic public functions
        Given we have these functions
        | Name       | Type    |
        | New-Node   | Public  |
        | New-Edge   | Public  |

    Scenario: basic private functions
        Given we have these functions
        | Name       | Type    |
        | Get-Indent | Private |

In that example, the `We have these functions` would be ran twice. Once with each table.

I called my parameter `$table` in that example, but I could have called it anything.

# Regex matches

You can use regex expressions in your tests to match up with specifications.

Lets say we use this specification in a few different locations.

    Given we have public functions
    Given there are public functions

Then we would need a test for each one.

    Given 'we have public functions' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

    Given 'there are public function' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

Instead of writing two tests, we can write one with a regex to match both.

    Given '(we have|there are) public functions' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

This is a really handy way to get one test to match up to multiple features where you are talking about the same thing but are saying it differently.

## Regex Parameters

One powerful feature of Gherkin is that we can use named matches in our strings and automatically pass them in as parameters. A named match is part of the regex specification. It allows you to have sub matches with an identifying name. Here is a quick example of using a named regex pattern.

    If("My Name is Kevin." -match 'My Name is (?<name>\S*).' )
    {
        $matches.name
    }

Let's revisit a specification from the first example for this one.

    And the file .\target\something.txt is the same as .\source\something.txt

We want to parameterize those file paths.

    And 'the file (?<target>\S*) is the same as (?<source>\S*)' {
        param($Target,$Source)

        $primary = Get-FileHash $Target
        $secondary = Get-FileHash $Source
        $secondary.Hash | Should Be $primary.Hash
    }


If we take a close look at that example; the named match `(?<target>\S*)` is passed in as `$Target`. My pattern of `\S*` is for consecutive characters that are not whitespace. We did the same thing for the second value. This would let us reuse that test for different files or in different specifications.

Here is a second example.

    Scenario: basic feature support
        Given we have public functions
        Then we have a New-Node function
        And we have a New-Edge function
        And we have a New-Graph function
        And we have a New-Subgraph function

We already have a test for public functions in general. But now we need a test to cover each individual function.

    Given 'we have a (?<name>\S*) function' {
        param($name)
        "$psscriptroot\..\psgraph\*\$name.ps1" | Should Exist
    }

This is dynamically pulling the value from the specification text.

One last example

This gives us a lot of flexibility.

### Regex positional parameters

I really stressed the named parameters in the last section, but this also works with positional parameters. The order of the expression matches up with the order of the parameter. So this would have worked just as well for that last example

    Given 'we have a (\S*) function' {
        param($functionName)
        "$psscriptroot\..\psgraph\*\$functionName.ps1" | Should Exist
    }

I would still recommend the named parameters. 

# Multi-line text parameter

Those previous approaches are flexible and easy for the person writing the specification. We have one more option that enables advanced functionality.

This is a multi-line text parameter.

    Scenario: multi-line text example
        Given we have a multi-line parameter
            """
            first
            second
            third
            """

Like the table example above, this is passed in to the test as if it was a single multi-line just like a here string. At face value this may not feel like it offers much.

## Hashtable parameters

We can use that multi-line parameter to hold a hashtable.

    Scenario: Hashtable example
        Given we have a Hastable name key
            """
            Name  = "Kevin Marquette"
            State = "California"
            """

We then have to convert the text to a hashtable in our test.

    Given "we have a Hastable name key" {
        param($Data)

        $hashtable = $Data | ConvertFrom-StringData
        $hashtable['Name'] | Should Not BeNullOrEmpty
    }

### Using splatting

I want to point out that we can take these hashtables and splat them to our functions.

   Scenario: Splat function
        Given we have these values for New-Person
            """
            Name  = "Kevin Marquette"
            State = "California"
            """

Then use it in the test like this:

    Given "we have these values" {
        param($Data)
        $hashtable = $Data | ConvertFrom-StringData
        New-Person @hashtable
    }

This can be a powerful way to provide varied input from the specification that gets passed directly into your tests.

## JSON parameters

We can take that multi-line text parameter and treat it like JSON.

    Scenario: JSON example
        Given we have a JSON name property
            """
            {
                "Name":"Kevin Marquette"
            }
            """

Then we do the JSON conversion in the test.

    Given "we have a JSON name property" {
        param($Data)

        $json = $Data | ConvertFrom-Json
        $json.Name | Should Not BeNullOrEmpty
    }

This will allow us to get structured data into our tests from the specification. 

## Scriptblocks

The catch all scenario is that we convert that text parameter to a `ScriptBlock`. If you would much rather put in PowerShell hashtable then we can do that.

    Scenario: Splat function with script block
        Given we have these values for New-Person
            """
            @{
                Name  = "Kevin Marquette" 
                UserName = $env:UserName   
            }      
            """

Then use it in the test like this:

    Given "we have these values" {
        param($Data)

        $hashtable = Invoke-Expression $Data 
        New-Person @hashtable
    }

You can place any PowerShell into a text parameter. Should you do that? Prabably not. Your code really should be in the tests and not in the specifications.

I do have to warn you that by using `Invoke-Expression` or even creating a `ScriptBlock` that you are turning a specification file into an executable file. You could consider limiting the commands that could be used in your specification. If you are interested in that, I have a better write up about [Domain Specific Languages](https://kevinmarquette.github.io/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1/?utm_source=blog&utm_medium=blog&utm_content=Gherkin2#data-sections) that covers that in more detail. 
 
# Running scenarios multiple times

I want to revisit a scenario we used in the table example. One problem with that specific example is that the test fails as a whole. We don't know what row caused the issue. It would be nice if we could run a single test for each one.

We can do that by using a `Scenario Outline` and adding an example table. This will make the the whole scenario run once for each example.

    Scenario Outline: functions are well made
        Given we have a <Function> function
        Then the <Function> should have comment based help

        Examples:
            | Function |
            | Node     |
            | Edge     |

The `<Function>` gets repalced by the current value in the examples table. We would then match that with a regex in the test.

# What is comming in part 3?

I covered a lot of advanced feautres that gives Gherkin an amazing amount of flexibility. In my next post on the topic, I plan on showing you how to make all of this work togehter. So far we have only seen each test work in isolation but we can string these tests together. We can use values collected in one test to be used in later tests. This is where we will see everything come togheter. 
