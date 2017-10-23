---
layout: post
title: "Powershell: PSGraph 1.2, The SubGraph Release"
date: 2017-10-22
tags: [PSGraph]
---

When I set out to write PSGraph, it started as a way to just write GraphViz instructions in PowerShell. The structure and syntax of GraphViz heavily influenced how I build the commands in PSGraph. This release polishes some of those commands and starts to work on doing more than just translating command. My focus of 1.2 was to make subgraphs easier to work with.

<!--more-->

# Index

* TOC
{:toc}

# Anonymous graphs

The first change worth mentioning is that PSGraph now supports anonymous or un-named graphs and subgraphs. When I was teaching others how to use PSGraph, I would have an example like this:

    Graph g {
        Edge Home,Work1,Lunch,Work2,Home

        SubGraph 0 {
            Node Lunch
            Node Work1,Work2 @{label='Work'}
            Rank Work1,Work2
        }
    } | Export-PSGraph -ShowGraph

I would always have to explain a few thing because I was exposing GraphViz requirements in my DSL. Why do I have to name the graph? `Graph g` Why do I have to name my SubGraph? `SubGraph 0`. I was also under the misunderstanding that the subgraph name needed to be numeric. Well, Just because GraphViz requires these to be named, PSGraph does not need to have the same requirement.

Starting with this release, you do not have to name your graphs. And if you do name them, strings are supported. This is now a valid PSGraph:

    Graph {
        Edge Home,Work1,Lunch,Work2,Home

        SubGraph {
            Node Lunch
            Node Work1,Work2 @{label='Work'}
            Rank Work1,Work2
        }
    }

So you do not have to name them anymore. PSGraph will go ahead and give them a name for you.

# Edges to SubGraphs

This was more challenging because it isn't really supported the way you would expect in the DOT language. I decided that I wanted a simple and intuitive syntax for this. We already give our subgraphs names. Why not just allow `Edge` to create edges to subgraphs instead of just nodes. This is what I ended up with.

    Graph {
        SubGraph Source {
            Node Inside
        }
        Node Outside
        Edge -From Source -To Outside
    }

I'm most excited about this change even though it's hard to tell that I even did anything. I was able to just drop it into the PSGraph DSL as if it was there from the beginning. Here is the old way you had to do it:

    Graph g @{compound='true'} {
        SubGraph 0 {
            Node Inside
            Source @{label="";style="invis";shape="point";}
        }
        Node Outside
        Edge -From Source -To Outside @{ltail='cluster_0'}
    }

You had to drop in a hidden node into the subgraph and then make your edge to that instead. Then you had to add all those other attributes to make sure it looked the way you wanted. I am still doing all of that, but now it happens under the covers so you don't have to think about it.

# Node -Ranked

The other change that made it into this release was the addition of a `-Ranked` switch on the `Node` command. A common pattern that I had was to add a set of nodes and then rank them on the next line. 

   Graph {
       Node -Ranked A,B,C
   }

The `Rank` command still exists so none of your old graphs should break.

# In closing

I'm working on a 2nd module that makes use of PSGraph and I am already making use of these new features. If you are using PSGraph and like these changes, drop me a tweet to let me know.
