---
layout: post
title: "Powershell: Advanced Gherkin features in Pester 4.0"
date: 2017-04-30
tags: [PowerShell, DSL, Gherkin, Pester, Advanced]
---

In the last post, I covered the bare basics of how to use Gherkin. I had a conversation with [Joel Bennett](https://twitter.com/Jaykul) on twitter about Gherkin and he pointed out some more examples from his [Configuration module](https://github.com/PoshCode/Configuration/tree/master/Specs). Now that I have been playing with them for a few days, I decided it was time to share my findings.

This is the 2nd post in a 3 part series on Gherkin where I cover the advanced features. These features are the building blocks that give Gherkin a lot of power.<!--more-->

* Part 1: [Basic Gherkin introduction](../2017-03-17-Powershell-Gherkin-specification-validation)
* Part 2: Advanced Gherkin Features (This post)
* Part 3: Working with Gherkin (Planned but not posted)

# Index

* TOC
{:toc}

# Quick review

Take a moment to read the [previous post](../2017-03-17-Powershell-Gherkin-specification-validation). The idea is that you write a specification in common business speak consisting of several sentences. Each sentence is on its own line and starts with a keywords like `Given`,`When`,`Then`,`But` or`And`. This would be the `.\copyitem.feature` file.

    Feature: You can copy one file

    Scenario: The file exists, and the target folder exists
        Given we have a source file
        And we have a destination folder
        When we call Copy-Item
        Then we have a new file in the destination
        And the new file is the same as the original file

Then those are matched to the steps that validate the specification. The sentences are paired with a matching test. This would be the `copyitem.Steps.ps1` file.

    Given 'we have a source file' {
        mkdir testdrive:\source -ErrorAction SilentlyContinue
        Set-Content 'testdrive:\source\something.txt' -Value 'Data'
        'testdrive:\source\something.txt' | Should Exist
    }

    Given 'we have a destination folder' {
        mkdir testdrive:\target -ErrorAction SilentlyContinue
        'testdrive:\target' | Should Exist
    }

    When 'we call Copy-Item' {
        { Copy-Item testdrive:\source\something.txt testdrive:\target } | Should Not Throw
    }

    Then 'we have a new file in the destination' {
        'testdrive:\target\something.txt' | Should Exist
    }

    Then 'the new file is the same as the original file' {
        $primary = Get-FileHash testdrive:\target\something.txt
        $secondary = Get-FileHash testdrive:\source\something.txt
        $secondary.Hash | Should Be $primary.Hash
    }

Then we run Invoke-Gherkin to execute the specification.

    Invoke-Gherkin

The idea is simple but there is much more to it.

# Tags

Gherkin has tag support at the feature and scenario level. You place them at the line above the scenario or feature on one line and prefix them with the `@` sign.

    @Functions @Milestone
    Scenario: basic feature support
        Given we have public functions
        And we have a New-Node function

Then we can run those the scenarios that have the tag `@Functions` like this.

    Invoke-Gherkin -Tag Functions

And we can exclude by tags.

    Invoke-Gherkin -ExcludeTag Milestone

This is like the tag support that Peter uses.

# Background scenario

You can add a `Background` scenario to a `Feature` and it will get executed once before all the other scenarios in that `Feature`.

    Feature: You can copy one file

    Background: The file exists, and the target folder exists
        Given we have a source file
        And we have a destination folder

    Scenario: Copy a single file
        When we call Copy-Item
        Then we have a new file in the destination
        And the new file is the same as the original file

It is just like any of the other scenarios but the intent is to identify pre-requirements or do some common pre-work for the rest of the scenarios in that feature.

## BeforeEachScenario

In your script containing all your tests, you can specify a `BeforeEachScenario` script to run before each scenario.

    BeforeEachScenario { 
        Set-Location TestDrive: 
    }

This will change the working directory to the test drive before each scenario in case something changes it. We can also use tags to limit what scenario the `BeforeEachScenario` runs before.

    BeforeEachScenario -Tags DataProcessing  {
        Set-Location TestDrive: 
    }

By specifying a tag, this `BeforeEachScenario` script will only run for each scenario that has this same tag.

We also have `AfterEachScenario`, `BeforeEachFeature` and `AfterEachFeature` commands that work the same way. This lets you set up and tear down if the `Background` scenario just isn't appropriate.


# Many to one

Each specification is matched to a test and you can have the same specification in multiple scenarios.

    Scenario: basic node support
        Given we have public functions
        And we have a New-Node function

    Scenario: basic edge support
        Given we have public functions
        And we have a New-Edge function

In this example, the `Given we have public functions` in both scenarios would match the following test.

    Given 'we have public functions' {
        "$psscriptroot\..\myModule\public\*.ps1" | Should Exist
    }

This allows you have common requirements or statements for multiple scenarios without having to create more tests.

# Regular expressions

I didn't point this out before but the test descriptions are regular expressions (regex). This makes it much easier to reuse a test for different specification descriptions.

Lets say we use this specification in a few different locations.

    Given we have public functions
    Given there are public functions

Then we would need a test for each one.

    Given 'we have public functions' {
        "$psscriptroot\..\MyModule\public\*.ps1" | Should Exist
    }

    Given 'there are public function' {
        "$psscriptroot\..\MyModule\public\*.ps1" | Should Exist
    }

Instead of writing two tests, we can write one with a regex to match both.

    Given '(we have|there are) public functions' {
        "$psscriptroot\..\MyModule\public\*.ps1" | Should Exist
    }

This is a really handy way to get one test to match up to multiple features where you are talking about the same thing but are saying it differently.

## Regex match parameters

One powerful feature of Gherkin is that we can use named matches in our strings and automatically pass them in as parameters. A named match is part of the regex specification. It allows you to have sub matches with an identifying name. Here is a quick example of using a named regex pattern.

    If("My Name is Kevin." -match 'My Name is (?<name>\S*).' )
    {
        $matches.name
    }

Let's revisit a specification from the first example for this one.

    And the new file is the same as the original file

And rewrite it like this to get the files listed in the specification.

    And the file .\target\something.txt is the same as .\source\something.txt

We also want to parameterize those file paths.

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
        And we have a New-Node function
        And we have a New-Edge function
        And we have a New-Graph function
        And we have a New-Subgraph function

We already have a test for public functions in general. But now we need a test to cover each individual function.

    Given 'we have a (?<name>\S*) function' {
        param($name)
        "$psscriptroot\..\MyModule\*\$name.ps1" | Should Exist
    }

This is dynamically pulling the value from the specification text. This gives us a lot of flexibility.

## Regex positional parameters

I really stressed the named parameters in the last section, but this also works with positional parameters. The order of the expression matches up with the order of the parameter. So this would have worked just as well for that last example

    Then 'we have a (\S*) function' {
        param($functionName)
        "$psscriptroot\..\MyModule\*\$functionName.ps1" | Should Exist
    }

I would still recommend the named matches.

# Table support

We can define a table inside the specification and that will get passed to our tests.

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
            "$psscriptroot\..\MyModule\$($row.type)\$($row.name).ps1" | Should Exist
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

In that example, the `We have these functions` would be run twice. Once with each table.

I called my parameter `$table` in that example, but I could have called it anything.


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

The catch-all scenario is that we convert that text parameter to a `ScriptBlock`. If you would much rather put in PowerShell hashtable then we can do that.

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

You can place any PowerShell ScriptBlock into a text parameter. Should you do that? Prabably not. Your code really should be in the tests and not in the specifications.

I do have to warn you that by using `Invoke-Expression` or even creating a `ScriptBlock` that you are turning a specification file into an executable file. You could consider limiting the commands that could be used in your specification. If you are interested in that, I have a better write up about [Domain Specific Languages](https://kevinmarquette.github.io/2017-02-26-Powershell-DSL-intro-to-domain-specific-languages-part-1/?utm_source=blog&utm_medium=blog&utm_content=Gherkin2#data-sections) that covers that in more detail. 
 
# Running scenarios multiple times

I want to revisit a scenario we used in the table example. One problem with that specific example is if the test fails, it fails as a whole. We don't know what row caused the issue. It would be nice if we could run a single test for each one.

We can do that by using a `Scenario Outline` and adding an `Examples` table. This will make the the whole scenario run once for each example.

    Scenario Outline: functions are well made
        Given we have a <Function> function
        Then the <Function> should have comment based help

        Examples: public functions
        | Function |
        | New-Node |
        | New-Edge |

The `<Function>` gets replaced by the current value in the examples table. We would then match that with a regex in the test.

We can call that table `Scenarios` and it will work the same way as the `Examples` table. We can also specify more than one table for a given `Scenario Outline`.

    Scenario Outline: functions are well made
        Given we have a <Function> function
        Then the <Function> should have comment based help

        Scenarios: public functions
        | Function |
        | New-Node |
        | New-Edge |

        Scenarios: private functions
        | Function   |
        | Get-Indent |

# What is coming in part 3?

I covered a lot of advanced features that gives Gherkin an amazing amount of flexibility. In my next post on the topic, I plan on showing you how to make all of this work together. So far we have seen each test work in isolation but we can string these tests together. We can use values collected in one test to be used in later tests. This is where we will see everything come together.

* Part 3: Working with Gherkin (Planned but not posted)

