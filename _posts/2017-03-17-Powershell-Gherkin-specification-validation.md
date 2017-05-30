---
layout: post
title: "Powershell: Gherkin specification validation introduction"
date: 2017-03-17
tags: [PowerShell, DSL, Gherkin, Pester, Advanced]
---

Pester has a interesting secret feature that we need to talk about. It supports Gherkin-style feature specifications. I had no idea this was even a thing until I was looking at one of Joel Bennett's modules and saw something I had not seen before.

This feature allows you to define your features and specifications in a simple business readable syntax. Then you crate a validation script that gets executed with that specification. It will give you pass/fail results on each item like Pester. I think this is awesome and more people need to know about it. I am not exactly sure when this feature was introduced, so you may need to update Pester to get it.<!--more-->

This is the first post in a 3 part series on Gherkin.

* Part 1: Basic Gherkin introduction (This post)
* Part 2: [Advanced Gherkin Features](../2017-04-30-Powershell-Gherkin-advanced-features)
* Part 3: Working with Gherkin (Planned but not posted)

# Index

* TOC
{:toc}

# What is Gherkin?

Gherkin is the specific business readable Domain Specific Language used to create a specification. I honestly don't know much more about it, but I found these references on the topic.

* [Cucumber Wiki/Gherkin](https://github.com/cucumber/cucumber/wiki/Gherkin)
* [Cucumber (software) - Wikipedia](https://en.wikipedia.org/wiki/Cucumber_(software)#Gherkin_.28Language.29 )
* [The Truth about BDD](https://sites.google.com/site/unclebobconsultingllc/the-truth-about-bdd)
* [Writing Great Specifications](https://www.manning.com/books/writing-great-specifications)

Even though I don't know about its origins, I can still show you how it works in Pester/Gherkin.

# Our first specification

We need to start by creating a specification. These plain text files need to be saved with a `.feature` extension for them to get automatically processed. 

    Feature: You can copy one file

    Scenario: The file exists, and the target folder exists
        Given we have a source file
        And we have a destination folder
        When we call Copy-Item
        Then we have a new file in the destination
        And the new file is the same as the original file

Save this as `.\copyfile.feature` and now we have a Gherkin-style specification. If this was part of a module, I would save it into a `spec` folder.

## Invoke-Gherkin

Now we need to execute `Invoke-Gherkin` like we would `Invoke-Pester`. Here is the output from our sample.

![Gherkin feature only](/img/gherkin-firstrun.png)

Because those colors can be hard to read, here is the raw text.

    PS > Invoke-Gherkin
    Testing all features in '.\spec'

    Feature: You can copy one file

    Scenario: The file exists, and the target folder exists
        [!] Given we have a source file 15ms
        [!] And we have a destination folder 2ms
        [!] When we call Copy-Item 3ms
        [!] Then we have a new file in the destination 8ms
        [!] And the new file is the same as the original file 5ms

    Testing completed in 483ms
    Scenarios Passed: 0 Failed: 0
    Steps Passed: 0 Failed: 0 Skipped: 5 Pending: 0 Inconclusive: 0

That will enumerate all the feature specifications we have. And run any corresponding tests. We have not created any tests yet so none of them passed.

# Adding test steps

The set of tests for a Gherkin feature are called steps. Because of that they need saved in a file with a name ending in `.Steps.ps1`. Add these steps to a new file and save it as `CopyItem.Steps.ps1`.

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
 
You will notice that I created a Pester-style test for several lines in the specification. Each one starts with a keyword of `Given`, `And`, `When` or`Then`. (`But` is also a valid keyword). The description is pulled directly from the specification. The `Invoke-Gherkin` uses that description to make the match.

I also want to point out that the step keywords (`Given`, `And`, `When`, `Then`, `But`) are interchangeable within the code. Use `Given` to set up for or prep for an action, `When` for the actions, and `Then` for validation. The `And` and `But` keywords are there to make the specification flow better and will match to any `Given`,`When` or `Then` test.

## Running the test steps

Now when we run the `Invoke-Gherkin`, we get this output.

![Gherkin feature passing](/img/gherkin-pass.png)

    PS> Invoke-Gherkin
    Testing all features in '.\spec'

    Feature: You can copy one file

    Scenario: The file exists, and the target folder exists
        [+] Given we have a source file 15ms
        [+] And we have a destination folder 2ms
        [+] When we call Copy-Item 3ms
        [+] Then we have a new file in the destination 8ms
        [+] And the new file is the same as the original file 5ms
    Testing completed in 35ms
    Scenarios Passed: 0 Failed: 0
    Steps Passed: 5 Failed: 0 Skipped: 0 Pending: 0 Inconclusive: 0

Here we see all the tests passing because we have all these features implemented.

## Other details

You can have multiple scenarios for a feature in the same file. I only used a single scenario to keep the example simple.

You also don't have to have a 1 to 1 mapping between step files and feature files. I did that in this example to make this post easier to write. You could have multiple feature files and one step file if that was easier to work with. The important thing is that the strings inside them map to each other.

Different specifications can have lines map to the same test as long as the text is an exact match. This is good when you have scenarios that have the same dependencies or a lot of overlapping steps.

# Why not use Invoke-Pester?

Pester is good at a lot of things but it is built around one school of thought. Gherkin approaches the problem from a different prospective. This is just another tool for us to use. 

# Whats next?

We just looked at the most basic of examples. We have only scratched the surface. In the next post on Gherkin, I am going to cover the rest of the features.

* Part 2: [Advanced Gherkin Features](../2017-04-30-Powershell-Gherkin-advanced-features)
