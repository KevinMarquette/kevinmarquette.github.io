---
layout: post
title: "Powershell: Supressing output"
date: 2017-11-18
tags: [PowerShell, Performance]
---

<!--more-->

# Index

* TOC
{:toc}

# Getting Started


# Putting it all together


# What's next?


    $count = 10000
    $testList = [ordered]@{
        BaseLine = {
            foreach($i in 1..$count ) {
                'Was it a car or a cat I saw?'
            }
        }
        Null = {
            foreach($i in 1..$count ) {
                $null = 'Was it a car or a cat I saw?'
            }
        }
        Void = {
            foreach($i in 1..$count ) {
                [void] 'Was it a car or a cat I saw?'
            }
        }
        VoidSub = {
            foreach($i in 1..$count ) {
                [void] ('Was it a car or a cat I saw?')
            }
        }
        RedirectNull = {
            foreach($i in 1..$count ) {
                'Was it a car or a cat I saw?' > $null
            }
        }
        OutNull = {
            foreach($i in 1..$count ) {
                'Was it a car or a cat I saw?' | Out-Null
            }
        }
        OutNullCmd = {
            foreach($i in 1..$count ) {
                Out-Null -InputObject 'Was it a car or a cat I saw?'
            }
        }
    }

    '     Test        Milliseconds'
    Foreach($test in $testList.GetEnumerator())
    {
        $result = Measure-Command -Expression $test.value
        '[{0,12}] {1,9:f2}' -f $test.name, $result.TotalMilliseconds
    }