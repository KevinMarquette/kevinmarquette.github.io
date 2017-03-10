---
layout: post
title: "Powershell: Gherkin specification validation"
date: 2017-03-10
tags: [PowerShell, DSL, Gherkin, Pester, Advanced]
---

Pester has a interesting secret feature that we need to talk about. It support Gherkin style feature specifications. I had no idea this was even a thing until I was looking at one of Joel Bennett's modules and saw something I had not seen before. 

This feature allows you to define your features and specifications in a simple business readable syntax. Then you crate a validation script that gets executed with that specification. It will give you Pester like pass/fail on each item. I think this is awesome and more people need to know about it. I am not exactly sure when this feature was added so you may need to update Pester to get it.

# Index

* TOC
{:toc}

# What is Gherkin?

Gherkin is the specific business readable Domain Specific Language used to create a specification. I honestly don't know much more about it, but I found these references on the topic.

* [Cucumber Wiki/Gherkin](https://github.com/cucumber/cucumber/wiki/Gherkin)
* [The Truth about BDD](https://sites.google.com/site/unclebobconsultingllc/the-truth-about-bdd)
* [Writing Great Specifications](https://www.manning.com/books/writing-great-specifications)

Even though I don't know about its origins, I can still show you how it works in Pester.

# Our first specification
We need to start by creating a specification. These plain text files need to be saved with a `.feature` extension for them to get automatically processed. Here is a simple one we can add to a module.

    Feature: We need to distribute our module to the public
        It should be published someplace that is easy to find

      Scenario: A user needs to be able to find our module in the PSGallery
        Given We have functions to publish
          And We have a module
        When The user searches for our module
        Then They can install the module

Save this as `.\distribution.feature` and now we have a Gherkin style specification. I am going to save this into a `Spec` folder inside my already existing [Chronometer](https://kevinmarquette.github.io/2017-02-05-Powershell-Chronometer-line-by-line-script-execution-times/) module.

## Invoke-Gherkin

Now we need to execute `Invoke-Gherkin` like we would `Invoke-Pester`. Here is the output from our sample.

![Gherkin feature only](/img/gherkin-firstrun.png)

Because those colors can be hard to read, here is the raw text.

    PS > Invoke-Gherkin
    Testing all features in 'C:\workspace\Chronometer'

    Feature: We need to distribute our module to the public
        It should be published someplace that is easy to find

      Scenario: A user needs to be able to find our module in the PSGallery
            Given We have functions to publish
                And We have a module
            When The user searches for our module
            Then They can install the module
    Testing completed in 0ms
    Scenarios Passed: 0 Failed: 0
    Steps Passed: 0 Failed: 0 Skipped: 0 Pending: 0 Inconclusive: 0

That will enumerate all the feature specifications we have. And run any corresponding tests. We just did not have any tests for it to run.

# Adding test steps

The set of tests for a Gherkin feature are called steps. Because of that they need saved in a file with a name ending in `.Steps.ps1`. Now we can start adding some steps into a file.

    Given 'We have functions to publish' {
        "$psscriptroot\..\chronometer\public\*.ps1" | Should Exist
    }
    And 'We have a module' {
        "$psscriptroot\..\chronometer\chronometer.psd1" | Should Exist
        "$psscriptroot\..\chronometer\chronometer.psm1" | Should Exist
    }
    When 'The user searches for our module' {
        Find-Module chronometer | Should Not BeNullOrEmpty
    }
    Then 'They can install the module' {
        { Install-Module chronometer -Scope CurrentUser -WhatIf } | Should Not Throw
    }
 
You will notice that I created a Pester style test for several lines in the specification. Each one starts with a keyword of `Given`, `And`, `When` or`Then`. (`But` is also a valid keyword). The description is pulled directly from the specification. The `Invoke-Gherkin` uses that description to make that match.

This is what my module looks like now that I added both the feature specification and the step tests.

    Chronometer
    ├───Spec
    │       distribution.feature
    │       distribution.Steps.ps1
    │
    ├───Chronometer
    │   │   chronometer.psd1
    │   │   Chronometer.psm1
    │   │
    │   └───Public
    │           Format-Chronometer.ps1
    │           Get-Chronometer.ps1
    |
    └───Tests


## Running the test steps

Now when we run the `Invoke-Gherkin`, we get this output.

![Gherkin feature passing](/img/gherkin-pass.png)

    PS> Invoke-Gherkin
    Testing all features in 'C:\workspace\Chronometer'

    Feature: We need to distribute our module to the public
           It should be published someplace that is easy to find

      Scenario: A user needs to be able to find our module in the PSGallery
        [+] Given We have functions to publish 4ms
        [+] And We have a module 3ms
        [+] When The user searches for our module 3.12s
    What if: Performing the operation "Install-Module" on target "Version '0.5.3.51' of module 'chronometer'".
        [+] Then They can install the module 1.84s
    Testing completed in 4.97s
    Scenarios Passed: 0 Failed: 0
    Steps Passed: 4 Failed: 0 Skipped: 0 Pending: 0 Inconclusive: 0

Here we see all the tests passing because I already have all these features implemented. If I added this to a new module, they would fail until that feature was put in place.

## Other details

You can have multiple scenarios for a feature in the same file. I only used a single scenario to keep the example simple.

You also don't have to have a 1 to 1 mapping between step files and feature files. I did that in this example to make this post easier to write. You could have multiple feature files and one step file if that was easier to work with. The important thing is that the strings inside them map to each other.

Different specifications can have lines map to the same test as long as the text is an exact match. This is good when you have scenarios that have the same dependencies or a lot of overlapping steps.


# Why not use Invoke-Pester?

Pester is good at a lot of things but it is built around one school of thought. Gherkin approaches the problem from a different prospective. This is just another tool for us to use. I feel like I have only scratched the surface on this but I wanted to shed some light on this feature that is fairly unknown.
