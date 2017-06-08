---
layout: post
title: "Powershell: PSGraphing the Abstract Syntax Tree"
date: 2017-06-06
tags: [PowerShell,AST,PSGraph]
---

I just saw this post by Prateek Singh talking about the Abstract Syntax Tree and it had a graph showing a sample AST.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">PowerShell: Tokenization and Abstract Syntax Tree <a href="https://t.co/eLKX6Tg9IN">https://t.co/eLKX6Tg9IN</a> <a href="https://t.co/2mkgkxWUV1">pic.twitter.com/2mkgkxWUV1</a></p>&mdash; Prateek Singh (@SinghPrateik) <a href="https://twitter.com/SinghPrateik/status/872186276795076608">June 6, 2017</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

 I thought it would be cool to see if I could recreate that graph with PSGraph.

<!--more-->

# Index

* TOC
{:toc}

# Getting Started

I have already talked about PSGraph in a previous post. It is a module that I wrote to make it easier to generate directional graphs. If you have not used it before, I would suggest you start with that previous post. I'm just going to jump into it here.

# Crafting it by hand

The first thing I am going to do is craft this smaller tree by hand.

I pulled tree that directly from Prateek's post. I can see that some of the values are unique. For the values that are duplicated, I will have to assign them a unique ID so they appear in the graph multiple times.

The first thing I am going to do is create a new graph with the root element.

    graph ast {
        node @{shape='square';fontcolor='blue'}
        node root @{label=''}
    }

The first node is just setting the default shape and font color for all other nodes. The next thing I am going to do is define the nodes that need a unique ID to them.

    graph ast {
        node @{shape='square';fontcolor='blue'}
        node root @{label=''}

        node x1,x2 @{label='x'}
        node y1,y2 @{label='y'}
        node '=1','=2' @{label='='}
    }

The label is the value that will show up in the graph. You will see me use the unique ID when I draw the edges, but those node definitions will show the basic label.

Now we can draw some edges.

    edge root -to '=1','=2','*'
    edge '=1' -to 'x1',1
    edge '=2' -to y1,2
    edge '*' -to x,'+'
    edge '+' -to 'x2','y2'

I started from the top and worked my way down the tree. You will notice that I am drawing edges between nodes that I didn't define as a node. That is a feature of the engine. You can create new nodes by drawing an edge ot it.

Here is the final graph and the resulting script.

![PSGraph AST](/img/psgraphast.jpg)

    graph ast {
        node @{shape='square';fontcolor='blue'}
        node root @{label=''}

        node x1,x2 @{label='x'}
        node y1,y2 @{label='y'}
        node '=1','=2' @{label='='}

        edge root -to '=1','=2','*'
        edge '=1' -to 'x1',1
        edge '=2' -to y1,2
        edge '*' -to x,'+'
        edge '+' -to 'x2','y2'

    } | Export-PSGraph -ShowGraph

I think that was a fairly good replica of the original image.

# Scripted AST graph

As fun as that was, I don't think we really want to be hand crafting our AST. We should be able to generate something like that on the fly. I don't know how close a real AST will look like the example above but I bet we can get close.

Here is our sample script.

    $x = 1
    $y = 2
    3 * ($x + $y)

Now I just need to figure out how to parse that into an AST. 