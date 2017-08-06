---
layout: post
title: "Powershell: The many ways to use regex"
date: 2017-07-31
tags: [PowerShell,Regex]
share-img: http://kevinmarquette.github.io/img/share-img/2017-07-31-Powershell-regex-regular-expression.png
---

Regular expressions (regex) match and parse text. The regex language is a powerful shorthand for describing patterns. Powershell makes use of regular expressions in several ways. Sometimes it is easy to forget that these commands are using regex becuase it is so tightly integrated. You may already be using some of these commands and not even realize it.

![xkcd.com](/img/xkcd-regex.jpg)
> Image from [xkcd.com](http://www.xkcd.com), slightly altered

<!--more-->

# Index

* TOC
{:toc}


# Scope of this article

Teaching the regex syntax and language is beyond the scope of this article. I will just cover what I need in order to focus on the PowerShell. My regex examples will intentionally be very basic.


## Regex quick start

You can use normal numbers and characters in your patterns for exact matches. This works when you know exactly what needs to match. Sometimes you need a pattern where any digit or letter should make the match valid. Here are some basic patterns that I may use in these examples.

    \d digit [0-9]
    \w alpha numeric [a-zA-Z0-9_]
    \s whitespace character
    .  any character except newline
    () sub-expression 
    \  escape the next character

So a pattern of `\d\d\d-\d\d-\d\d\d\d` will match a social security number. Three digits, then a dash, two digits, then a dash and then 4 digits. There are better and more compact ways to represent that same pattern. But this will work for our examples today.


## Regex resources

Here are some regular expression resources to help you find the right patterns for your task.

Interactive regex calculators:

* [regexr.com](http://regexr.com/)
* [regex101.com](http://regex101.com/)
* [www.debuggex.com](https://www.debuggex.com)
* [regexhero.net](http://regexhero.net/tester/)

Documentation and training:

* [learn regex the easy way](https://github.com/zeeshanu/learn-regex)
* [www.reddit.com/r/regex](https://www.reddit.com/r/regex/)
* [Wikipedia](https://en.wikipedia.org/wiki/Regular_expression)
* [Mastering Regular Expressions, O'Reilly](http://shop.oreilly.com/product/9780596528126.do)


# Select-String

This cmdlet is great for searching files or strings for a text pattern. 

    Get-ChildItem -Path $logFolder | Select-String -Pattern 'Error'

This example searches all the files in the `$logFolder` for lines that have the word `Error`. The pattern parameter is a regular expression and in this case, the word `Error` is valid regex. It will find any line that has the word error in it. 

    Get-ChildItem -Path $logFolder |
        Select-String -Pattern '\d\d\d-\d\d-\d\d\d\d'

This one would search text documents for numbers that look like a social security number.


# -match

The `-match` opperator takes a regular expression and returns `$true` if the pattern matches.

    $message = 'there is an error with your file'
    $message -match 'error'

    '123-45-6789' -match '\d\d\d-\d\d-\d\d\d\d'

If you apply a match to an array, you will get a list of all the items that match the pattern.

    PS> $data = @(
           "General text without meaning"
           "my ssn is 123-45-6789"
           "some other string"
           "another SSN 123-12-1234"
       )
    PS> $data -match '\d\d\d-\d\d-\d\d\d\d'

    my ssn is 123-45-6789
    another SSN 123-12-1234

## Variations

`-imatch` makes it explicit that you are doing a case insensitive operation (the default)

`-cmatch` makes the operation case sensitive.

`-notmatch` returns true when there is no match.

The `i` and `c` variants of an operator is available for all comparison operators.

## -like

The `-like` command is like `-match` except it does not use regex. It uses a simpler wildcard pattern where `?` is any character and `*` is multiple unknown characters.

    $message -like '*error*'

 One important difference is that the `-like` command expects an exact match unless you include the wildcards. So if you are looking for a pattern within a larger string, you will need to add the wildcards on both ends. `'*error*'`

Sometimes all you need is a basic wildcard and that is where `-like` comes in. 

This operator has `-ilike`, `-clike`, `-notlike` variants.

## String.Contains()

If all you want to do is test to see if your string has a substring, you can use the `string.contains($substring)` appraoch. 

    $message = 'there is an error with your file'
    $message.contains('error')

`string.contains()` is case sensitive. This will perform faster then using the other opperators for this substring scenario.

# -replace

The replace command uses regex for it's pattern matching.

    PS> $message = "Hi, my name is Dave."
    PS> $message -replace 'Dave','Kevin'
    Hi, my name is Kevin.

    PS> $message = "My SSN is 123-45-6789."
    PS> $message -replace '\d\d\d-\d\d-\d\d\d\d', '###-##-####'
    My SSN is ###-##-####.

The other variants of this command are `-creplace` and `-ireplace`.

## String.Replace()

The .Net `String.Replace($pattern,$replacement)` funciton does not use regex. I mention this because it performs faster than `-replace`.

    PS> $message = "Hi, my name is Dave."
    PS> $message.replace('Dave','Kevin')
    Hi, my name is Kevin.

This one is also case sensitive. Infact, all the string funtions are case sensitive.

# -split

This command is very often overlooked as one that uses a regex. We are often splitting on simple patterns that happen to be regex compatible that we never even notice.

    PS> 'CA,TX,NE' -split ','
    CA
    TX
    NE

Every once and a while, we will try to use some other character that means something else in regex. This will lead to very unexpected results. If we change our comma to a period, we get a bunch of blank lines.


    PS> 'CA.TX.NE' -split '.'








    PS>

The reason is that `.` will match any character, so in this case it matches every character. It ends up spliting at every character and giving us 9 empty values.

    PS> ('CA.TX.NE' -split '.').count
    9

This is why it is important to remember what commands use regex.

`-isplit` and `-csplit` are the variants on this command.


## String.Split()

Like with the replace command, there is a `String.Split()` function that does not use regex. It will be faster when splitting on a character (or substring) and give you the same results.


# Switch

By default, the `switch` statement does exact matches. But it does have an `-regex` option to use regex matches instead.

    switch -regex ($message)
    {
        '\d\d\d-\d\d-\d\d\d\d' {
            Write-Warning 'message may contain a SSN'
        }
        '\d\d\d\d-\d\d\d\d-\d\d\d\d-\d\d\d\d' {
            Write-Warning 'message may contain a credit card number'
        }
        '\d\d\d-\d\d\d-\d\d\d\d' {
            Write-Warning 'message may contain a phone number'
        }
    }

This feature of `switch` is often overlooked.

## Multiple switch matches

The interesting thing about using regex in a switch is that it will test each pattern so you can have several matches to one switch.

Run this example with the above switch statement:

    PS> $message = "Hey, call me at 123-456-1234, there is an issue with my 1234-5678-8765-4321 card"

    WARNING: message may contain a credit card number
    WARNING: message may contain a phone number

Even though we had one string in the `$message`, 2 of the switch statements executed.

# ValidatePattern

When creating an advanced function, you can add a `[ValidatePattern()]` to your parameter. This will validate the incomming value has the pattern that you expect. 

    function Get-Data
    {
        [cmdletbinding()]
        param(
            [ValidatePattern('\d\d\d-\d\d-\d\d\d\d')]
            [string]
            $SSN
        )

        # ... #
    }

This example requests a SSN from the user and it does the validation on the input. This will give the user an error message if not valid. My issue with this is that it does not give a good error message by default.

    PS> Get-Data 'Kevin'

    get-data : Cannot validate argument on parameter 'SSN'. The argument "Kevin" does not match 
    the "\d\d\d-\d\d-\d\d\d\d" pattern. Supply an argument that matches "\d\d\d-\d\d-\d\d\d\d" 
    and try the command again.

## ValidateScript

One way around that is to use a `[ValidateScript({...})]` instead that throws a custom error message.

    [ValidateScript({
        if( $_ -match '\d\d\d-\d\d-\d\d\d\d')
        {
            $true
        }
        else
        {
            throw 'Please provide a valid SSN (ex 123-45-5678)'
        }
    })]

Now we get this error message

    PS> get-data 'Kevin'

    get-data : Cannot validate argument on parameter 'SSN'.
    Please provide a valid SSN (ex 123-45-5678)

It may complicate our parameter, but it is much easier for our users to understand.

## Validators on variables

We mostly think of validators as part of an advanced function but the reality is that they apply to the variable and can be used outside of an advanced function.

    PS> [ValidatePattern('\d\d\d-\d\d-\d\d\d\d')]
    PS> [string]$SSN = '123-45-6789'

    PS> $SSN = "I don't know"

    The variable cannot be validated because the value `I don't know`
    is not a valid value for the SSN variable.

I can't say that I realy ever do this, but this would be a good trick to know. 

# $Matches

When you use the `-match` operator, an automatic variable called `$matches` contains the results of the match. If you have any sub expressions in your regex, those sub matches are also listed.

    $message = 'My SSN is 123-45-6789.'

    $message -match 'My SSN is (\d\d\d-\d\d-\d\d\d\d)\.'
    $Matches[0]
    $Matches[1]


## Named matches

This is one of my favorite features that most people don't know about.If you use a named regex match, then you can access that match by name on the matches.

    $message = 'My Name is Kevin and my SSN is 123-45-6789.'

    if($message -match 'My Name is (?<Name>.+) and my SSN is (?<SSN>\d\d\d-\d\d-\d\d\d\d)\.')
    {
        $Matches.Name
        $Matches.SSN
    }

In the example above, the `(?<Name>.+)` is a named sub expression. This value is then placed in the `$Matches.Name` property. Same goes for SSN.


# .Net Regex

Because this is PowerShell, we have full access to the .net regex object. Most of them are covered by the functionality above. If you are getting into more advanced regex where you need custom options, then take a second look at this object.

    [regex]::new($pattern) | Get-Member

All the .Net regex methods are case sensitive.

I'm going to touch on `[regex]::Escape()` because there is not a PowerShell equivalent.


## Escape regex

regex is a complex language with common symbols and a shorthand syntax. There are times where you may want to match a literal value instead of a pattern. The `[regex]::Escape()` will escape out all the regex syntax for you.

Take this string for example `(123)456-7890`. It contains regex syntax that may not be obvious to you. 

    $message -match '(123)456-7890'

You may think this is matching a specific phone number but the thing it would match is `123456-7890`. My point is that when you use a literal string where a regex is expected, that you will get unexpected results. This is where the `[regex]::Escape()` solves that issue.

    $message -match [regex]::Escape('(123)456-7890')

I don't want to talk on this too much because this is an anti-pattern. If you are needing to regex escape your entire pattern before you match it, then you should use the `String.Contains()` method instead.

The only time you should be escaping a regex is if you are placing that value inside a more complex regex. Even that is solved with a more complex regex pattern.

If you are using this in your code. Rethink why you need it because odds are, you are using the wrong operator or method.

# Should match

When using Pester tests, the `Should Match` uses a regular expression.

    It "contains a SSN"{
        $message = Get-Data
        $message | Should Match '\d\d\d-\d\d-\d\d\d\d'
    }

When with Pester is the exception to the rule of not using `[regex]::Escape()`. Pester does not have a substring match alternative.

    It "contains $subString"{
        $message = Get-Data
        $message | Should Match ([regex]::Escape($subString))
    }


# Putting it all together

As you can see, there are a lot of places where you can use regex or may already using regex and not even know it. PowerShell did a good job of integrating these into the language. But be wary of using them if performance is a concern and you are not actually using regex pattern.

Let me know if you discover any other common ways to use regex in PowerShell. I would love to hear about them and add them to my list.

