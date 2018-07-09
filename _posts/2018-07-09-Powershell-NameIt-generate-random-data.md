---
layout: post
title: "Powershell: Generating random data with NameIT"
date: 2018-07-09
tags: [PowerShell,Modules]
share-img: "http://kevinmarquette.github.io/img/share-img/2018-07-09-Powershell-NameIt-generate-random-data.png"
---
I find that I often need random datasets for testing or as examples in my presentations. My favorite tool for that is [NameIt](https://github.com/dfinke/NameIT). This is a PowerShell module written by [Doug Finke](https://twitter.com/dfinke) that makes it super easy to create good looking but random data.

    PS:> Invoke-Generate '[person]' -Count 3
    Heather Rogers
    John Bailey
    Julia Perez

<!--more-->

# Index

* TOC
{:toc}

# Installing NameIt

This module is published to the PSGallery. All we have to do is install it.

``` posh
    Install-Module NameIT -Scope CurrentUser
```

# Invoke-Generate

`Invoke-Generate` is the workhorse of this module. By calling it without any parameters, we get a random text string.

    PS:> Invoke-Generate
    lhcqalmf

The real magic happens when we start to provide template strings with patterns in them. Quite often, we have a pattern in mind and NameIt lets us build on that. Here we use '?' for random characters and '#' for random numbers.

    PS:> Invoke-Generate "cafe###-???"
    cafe176-yhj

## Template functions

There is also support for in-line template functions for common patterns or random data. If we need a random name and an address for example:

    PS:> Invoke-Generate "[person], [address]"
    Sarah Garcia, 10096 Tililebuik Commons

The reason that I use NameIt is because it includes a good set of template functions that are easy to use.

    `[alpha]`: selects a random character (constrained by the -Alphabet parameter).
    `[numeric]`: selects a random numeric (constrained by the -Numbers parameter).
    `[vowel]`: selects a vowel from a, e, i, o or u.
    `[phoneticVowel]`: selects a vowel sound, for example ou.
    `[consonant]`: selects a consonant from the entire alphabet.
    `[syllable]`: generates (usually) a pronounceable single syllable.
    `[synonym word]`: finds a synonym to match the provided word.
    `[person]`: generate random name of female or male based on provided culture like <FirstName><Space><LastName>.
    `[person female]`: generate random name of female based on provided culture like <FirstName><Space><LastName>.
    `[person male]`: generate random name of male based on provided culture like <FirstName><Space><LastName>.
    `[address]`: generate a random street address. Formatting is biased to US currently.
    `[guid]`: generates a random GUID.
    `[randomdate]`: generates a random date.
    `[state]`: generates a random US state. supports specifying abbr, zip, capital.

## Syllable

The syllable template function will generate data that looks like words but are pronounceable and easier to remember than true random.

    PS:> Invoke-Generate '[syllable][syllable][syllable][numeric][numeric]' -Count 5
    ugderip87
    gedicwa11
    haermi85
    uksexpop29
    jursejcab72

## Person

Generating random names is one of the most common data elements in random datasets. This is the example from the start of the article.

    PS:> Invoke-Generate '[person]' -Count 3
    Heather Rogers
    John Bailey
    Julia Perez

Some of these template functions support parameters. The `[person]` template allows you to specify `female` or `male` names.

    PS:> Invoke-Generate '[person female]' -Count 3
    Natasha James
    Christine Jenkins
    Jennifer Nguyen

    PS:> Invoke-Generate '[person male]' -Count 3
    Joshua Richardson
    Joseph Diaz
    Luis Clark

# Custom datasets

NameIT has a basic set of built in datasets, but we can create our own. These custom datasets can be used like the other template functions. To do this, we have to craft a hashtable in a special way.

``` posh
    $CustomData = @{
        color   = @('Red','Green','Blue','Black','White')
        weekday = @('Monday','Tuesday','Wednesday','Thursday','Friday')
        team    = @('IT','Accounting','Marketing','Shipping','Administration','Sales')     
    }
```

Each key of the hashtable becomes a new template function. The values of the key are then randomly selected. In the above example, I have three sets of data called `color`,`weekday`, and `team`. We can then provide this value to `Invoke-Generate` to get a random value from that list.

    PS:> Invoke-Generate "[color] [weekday] [team]" -CustomData $CustomData
    Green Tuesday Marketing

# Random objects

One interesting feature is the ability for `Invoke-Generate -AsPSObject` to create `PSObjects` for you. It uses `ConvertFrom-StringData` internally to try and convert the string into an object. This generally expects you to create key value pairs for it to parse.

``` posh
    $template = @"
        name    = [person]
        address = [address]
    "@
    Invoke-Generate $Template -AsPSObject -Count 3
```

That will create these objects for us automatically.

    name              address      
    ----              -------      
    Christopher Scott 130 Buin Loop
    Jonathan Flores   110 Nehle Clb
    Jasmine Evans     68 Yegeh Blvd

## JSON

If you find the use of flat key value pairs too limiting, then we can always generate JSON that can be converted into an object.

``` posh
    $template = @"
    {
        "name" : "[person]",
        "address" : {
            "street":"[address]",
            "state":"[state abbr]"
        }
    }
    "@
    Invoke-Generate $Template -Count 3 | 
        ForEach-Object {ConvertFrom-Json $_}
```

I removed the `-AsPSObject` this time because I want the raw string output. 

``` JSON
    {
        "name" : "Travis Turner",
        "address" : {
            "street":"489 Juhalpipreduq Sta",
            "state":"AL"
        }
    }
```

I can then pass this JSON to `ConvertFrom-JSON` to get my desired object.

```
    name          address                                  
    ----          -------                                  
    Travis Turner @{street=489 Juhalpipreduq Sta; state=AL}
    Jesse Johnson @{street=44283 Zano Lane; state=PA}      
    Anthony Baker @{street=38215 Zulujjalga Port; state=MO}
```

## Keep it simple

There is also nothing wrong with creating an object with random properties. 

``` posh
    [pscustomobject]@{
        name = Invoke-Generate '[person]'
        address = @{
            street = Invoke-Generate '[address]'
            state  = Invoke-Generate '[state abbr]'
        }
    }
```

This is exactly how I create my test objects.

# NameIT in action

With the basics out of the way, Let's take a look at some more examples that I used for other projects.

## Example server info

This first one is a fake server report. Something that shows system owners and some generic audit information.

    [pscustomobject]@{
        ComputerName = Invoke-Generate "Server-[state abbr]##"
        Owner        = Invoke-Generate "[person]"
        Phone        = Invoke-Generate "###-###-####"
        LastUpdate   = Invoke-Generate "[randomdate]"
        Status       = Invoke-Generate '[status]' -CustomData @{
            status = @('Secure','Unpatched','Unsecure')
        }
    }

I do get a little clever with generating the status by using custom data inline. This may have been easier to just use a `Get-Random`. It would have done the same thing.

    @('Secure','Unpatched','Unsecure') | Get-Random

Here is what the final result looked like:

    ComputerName Owner          Phone        LastUpdate Status   
    ------------ -----          -----        ---------- ------   
    Server-AK22  Amy Hill       968-954-5675 01/15/2007 Unsecure 
    Server-MN43  Kelly Price    934-790-4090 11/14/1994 Secure   
    Server-NE01  Shane Robinson 337-859-7009 03/25/1973 Unpatched
    Server-MS06  Evan Parker    792-245-5228 07/31/2009 Secure   
    Server-AZ26  Krystal Parker 643-391-6774 10/26/2014 Unsecure 

## AD group names

I had a demo that used Active Directory to generate a PSGraph based on group membership. For that, I generated several AD group names using the `[synonym]` template function.

```
    PS:> Invoke-Generate "[synonym opinion]_[synonym committee]" -Count 7

    message_commission
    subjectmatter_citizenscommittee
    idea_nongovernmentalorganization
    legaldocument_citizenscommittee
    substance_administrativebody
    subjectmatter_citizenscommittee
    legalinstrument_administrativeunit
```

This worked out better than using random characters.

# Final words

Many of the above examples were taken from the [project's github page](https://github.com/dfinke/NameIT). I have found NameIT to be very usefull. I know my random data looks a lot better because of it.
