---
layout: post
title: "Powershell: the many ways to use regex"
date: 2017-07-31
tags: [PowerShell,Regex]
---

Regular expressions (regex) are used to match and parse text. The regex languae is very powerfull shorthand for describing patterns. Powershell makes use of regular expressions in several ways. Sometimes it is easy to forget that these commands are using regex becuase it is so tightly integrated. You may already be using some of these and not even realize that they are using regex patterns.

<!--more-->

# Index

* TOC
{:toc}

# Scope of this article

Teaching the regex syntax and language is beyond the scope of this article. I will just cover what I need in order to focus on the PowerShell. These regex examples will be very basic.

## regex quick start

You can use normal numbers and characters in your patterns for exact matches. This works when you know exactly what needs to be matched. Sometimes you need a pattern where any digit or letter should make the match valid. Here are some basic patterns that I will use in these examples.

    \d digit [0-9]
    \w alpha numeric [a-zA-Z0-9_]
    \s whitespace character
    .  any character except newline
    () sub-expression 
    \  escape the next character

So a pattern of `\d\d\d-\d\d-\d\d\d\d` would match a social security number. Three digits, then a dash. Two digits, then a dash. And then 4 digits. There are better and more compact ways to represent that same pattern. But this will work for our examples today.

## Regex resources

Here are some regular expression resources to help you with find the right patterns for your task.

* [regexr.com](http://regexr.com/)
* [learn regex the easy way](https://github.com/zeeshanu/learn-regex)
* [www.reddit.com/r/regex](https://www.reddit.com/r/regex/)
* [Wikipedia](https://en.wikipedia.org/wiki/Regular_expression)
* [Mastering Regular Expressions, O'Reilly](http://shop.oreilly.com/product/9780596528126.do)


# Select-String

This cmdlet is great for searching files for a text pattern. 

   Get-ChildItem -Path $logFolder | Select-String -Pattern 'Error'

This example searches all the files in the `$logFolder` for lines that have the word `Error`. The pattern parameter is a regular expression and in this case, the word `Error` is valid regex. It will find any line that has the word error in it. 

    Get-ChildItem -Path $logFolder | Select-String -Pattern '\d\d\d-\d\d-\d\d\d\d'

This one would search text documents for numbers that look like a social security number.

# -match

The `-match` opperator takes a regular expression. 

    $message = 'there is an error with your file'
    $message -match 'error'

    '123-45-6789' -match '\d\d\d-\d\d-\d\d\d\d'

When the pattern is matched, then `-match` will evaulate to true. 

## -like

The -like command is very much like -match except it does not use regex. It uses a simpler wildcard pattern where `?` is any character and `*` is multiple unknown characters. 

    $message -like '*error*'

Sometimes all you need is a basic wildcard and that is where `-like` comes in.

# -replace

The replace command uses regex for it's pattern matching.

    PS> $message = "Hi, my name is Dave."
    PS> $message -replace 'Dave','Kevin'
    Hi, my name is Kevin.

    PS> $message = "My SSN is 123-45-6789."
    PS> $message -replace '\d\d\d-\d\d-\d\d\d\d', '###-##-####'
    My SSN is ###-##-####.

## String.Replace()

The .Net `String.Replace($pattern,$replacement)` funciton does not use regex. 

# -split

This command is very often overlooked as one that uses a regex. We are often splitting on simple patterns that just so happen to be regex compatible that we never even notice.

    PS> 'CA,TX,NE' -split ','
    CA
    TX
    NE

Every once and a while, we will try to use some other character that means something else in regex. This will lead to very unexpected results. If we chance our coma to a period, we get a bunch of blank lines.

    
    PS> 'CA.TX.NE' -split '.'








    PS>

The reason is that `.` will match any character so in this case it matches every character. It ends up spliting at every character and giving us 9 empty values.

    PS> ('CA.TX.NE' -split '.').count
    9

This is why it is important to remember what commands do use regex.

# switch

By default, the `switch` statement does exact matches. But it does have an option to use regex.

    switch -regex ($message)

# topics
    
    switch
    validatepattern
    
    regex escaping
    $matches

# Putting it all together


# What's next?


