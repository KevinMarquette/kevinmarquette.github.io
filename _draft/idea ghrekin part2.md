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




# regex matches




    Feature: The module should provide support for 
        the common graphviz commands

        Scenario: basic feature support
            Given we have public functions
            Then we have a node function
            And we have a edge function
            And we have a graph function
            And we have a subgraph function

    Given 'we have a public functions' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

    Given 'we have a (?<name>.+?) function' {
        param($name)
        "$psscriptroot\..\psgraph\public\$name.ps1" | Should Exist
    }


In the last post, I covered the bare basics of how to use Ghrekin. I had a conversation with Joel Bennett on twitter about Ghrekin and he pointed out some more features. Now that I have been playing with them for a few days, I decided it was time to share my findings.

# Quick review

Take a moment to read the previous post. The idea is that you write a specification in common business speak consisting of several sentances. Each sentance is on its own line and starts with a key works like `Given`,`When`,`Then` or`And`.

Then those are matched to the steps that validate the specification. The sentances are used to pair them up. The idea is simple but there is much more to it.

# regex matches

The first interesting details is that you can use regex expressions in your tests to match up with specifications.

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

One very powerfull feature of Ghrekin is that we can use named matches in our strings and turn them into test variables. Lets say we have these two specifications.

    Given we have public functions
    Given we have private functions

And in our project, we have a `public` folder and a `private` folder for our functions. We could write these two tests.

    Given 'we have public functions' {
        "$psscriptroot\..\psgraph\public\*.ps1" | Should Exist
    }

    Given 'we have private functions' {
        "$psscriptroot\..\psgraph\private\*.ps1" | Should Exist
    }

Or we could use a named regex to create a parameterized test.

    Given 'we have (?<folder>(public|private)) functions' {
        param($folder)
        "$psscriptroot\..\psgraph\$folder\*.ps1" | Should Exist
    }

If we take a close look at that example; the named match `(?<folder>(public|private))` is passed in as `$folder`. My pattern matches on either `private` or `public`.  Here is a second example.

    Scenario: basic feature support
        Given we have public functions
        Then we have a node function
        And we have a edge function
        And we have a graph function
        And we have a subgraph function

We already have a test for public functions in general. But now we need a test to cover each individual function.

    Given 'we have a (?<name>.+?) function' {
        param($name)
        "$psscriptroot\..\psgraph\*\$name.ps1" | Should Exist
    }

Instead of hard coding a test for every function, we can just pull it from the specification.


