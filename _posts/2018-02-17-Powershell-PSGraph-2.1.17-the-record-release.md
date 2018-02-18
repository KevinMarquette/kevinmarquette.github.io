---
date: 2018-02-17
layout: post
title: "Powershell: PSGraph 2.1.17 the record release"
tags: [PSGraph]
share-img: "http://kevinmarquette.github.io/img/datamodel.png"
---

I just released another major update to PSGraph. This release includes new keywords and helps unlock more features of Graphviz. These features will make it easier to build entity and data model diagrams.

![sample data model diagram showing products and orders tables](/img/datamodel.png)
<!--more-->
# Index

* TOC
{:toc}

# Release notes

    2.1.17 20180217
    * add Record command
    * add Row command
    * add Entity command
    * add Show-PSGraph command
    * add key name case correction
    * throws error when there are Graphviz parse errors

# Record

A record is a column of values in a single node.

    Graph {
        Record -Name Table1 -Rows @(
            'Row1'
            'Row2'
            'Row3'
        )
    } | Show-PSGraph

This will produce a node that looks like this:

![single node record object](/img/record.png)

Under the covers, this is a node object. The command takes care of all the attributes and HTML label formating for you. Because this is a `Node`, you can created edges to it like you would any other node.

    Graph {
        Record -Name Table1 -Rows @(
            'Row1'
            'Row2'
            'Row3'
        )

        Node Other
        Edge Other -To Table1
    }

I offer a lot of flexible ways to work with the `Record` command. Here is the minimal DSL style syntax:

    Graph {
        Record Table1 @(
            'Row1'
            'Row2'
            'Row3'
        )
    }

Just knowing that the 2nd default parameter is an array opens up many options.

    $list = @(
        'Row1'
        'Row2'
        'Row3'
    )

    Record Table1 $list

    $list | Record -Name Table2

## -ScriptBlock

Having an array for the second parameter of a PowerShell DSL is not that common. So I also added support for using a `scriptblock`. It works the same as the array in many cases.

    Graph {
        Record Table1 {
            'Row1'
            'Row2'
            'Row3'
        }
    }

We will make better use of that scriptblock when I introduce the `Row` command.

# Row

The Row command is used with the Record to make a much richer object.

    Graph {
        Record Table1 {
            Row 'Row1'
            Row 'Row2'
            Row 'Row3'
        }
    }

If you take a close look at the `Row` command, it has 3 parameters.

    Row -Label 'MY row' -Name 'Port1' -EncodeHTML

The `-Label` is the text that you see in the record. The `-Lable` is the default parameter when no parameter is specified. The label supports simple HTML.

    Row 'My Row' -Name 'Port1'
    Row -Label 'First: <B>Kevin</B>'

Because the label is rendered as HTML, I added `-EncodeHTML` for when you data includes characters like `<>&` that can mess with the HTML syntax.

    Row -Label 'Mom & Dad' -EncodeHTML

## -Name

You can name a row like you name a node. By giving a row a name, we can target it with an edge.

    Graph {
        Record Table1 {
            Row 'Row1' -Name Row1
            Row 'Row2' -Name Row2
            Row 'Row3' -Name Row3
        }

        Record Table2 {
            Row 'Row1' -Name Row1
            Row 'Row2' -Name Row2
            Row 'Row3' -Name Row3
        }

        Edge Table1:Row1 -to Table2:Row1
        Edge Table1:Row3 -to Table2:Row2
    } | Show-PSGraph

![Two nodes with cross edges to rows](/img/recordedge.png)

If the label is a simple word with no spaces or symbols, the row will use that as the default row name. If you start injecting custom HTML into your row, then there will not be a default row name.

The Graphviz documentation refers to those row names as ports on the node.

# Entity

The `Entity` command takes an object and maps it into a `Record`. This turned out to be a common pattern in how I was trying to use the `Record`.

    $object = [PSCustomObject]@{
        First = 'Kevin'
        Last = 'Marquette'
        Age = 37
    }

    Graph {
        Entity $object
    } | Show-PSGraph

![An entity showing a PSCustomObject](/img/entitytypename.png)

I provide 3 different views of the object with the `-Show` parameter. Here are the possible options.

* `Name` - Property name
* `TypeName` - Name and value type
* `Value` - Name and value

Here is the same object showing the values.

    Graph {
        Entity $object -Name 'Person' -Show Value
    } | Show-PSGraph

![An entity showing the object values](/img/entityvalue.png)

The entity will automatically name each row with the property name. This will allow you to draw edges directly to them. I have a more complex example at the end of this article that shows this in action.

## -Name

If you have a small collection of objects that you want to place on a graph, make sure you give each one a custom name.

    $servers = Import-CSV .\myservers.csv

    Graph {
        $servers | ForEach-Object {
            Entity $PSItem -Name $PSItem.ComputerName
        }
    }

## -Property

The `-Property` parameter allows for easy filtering of the properties that you want to display.

    Entity $Server -Property ComputerName, CPU, Memory, IP, Location

# Show-PSGraph

The `Export-PSGraph` command has a parameter called `-ShowGraph` that will show the graph after generating it. This release added `Show-PSGraph` that does the same thing with one command.

    Graph {
        Node test
    } | Show-PSGraph

# Pulling it together

I opened the article with this simple 4 table diagram.

    $product = [ordered]@{
        ProductName = 'Sandbox'
        ProductID = 'P4576'
        CategoryID = 'C728'
        Description = 'Tractor tire with sand'
    }

    $Category = [ordered]@{
        CategoryID = 'C728'
        CategoryName = 'Backyard'
    }

    $OrderDetail = [ordered]@{
        OrderID = 'O3294'
        ProductID = 'P4576'
        UnitPrice = 280.00
        Quantity = 1
    }

    $Order = [ordered]@{
        OrderID = 'O3294'
        CustomerID = 'C1034'
        Address = '123 Street, Irvine CA'
    }

    Graph @{rankdir='LR'} {

        Entity $Product -Name Product
        Entity $Category -Name Category
        Entity $OrderDetail -Name OrderDetail
        Entity $Order -Name Order

        Edge Product:CategoryID -to Category:CategoryID
        Edge OrderDetail:OrderID -to Order:OrderID
        Edge OrderDetail:ProductID -to Product:ProductID
    } | Show-PSGraph

![sample data model diagram showing products and orders tables](/img/datamodel.png)

Here is that same diagram with `-Show Value` specified for each entity:

![same sample data model diagram showing values instead of types](/img/datamodelvalue.png)

# Closing remarks

For people coming from Graphviz, the `Record` is not a true record object as defined by the DOT language specification. I am using the HTML markup options to create this node. The base commands will continue to align closely with the Graphviz DOT language. As I add new commands, they will start to abstract away the underlying complexity.

I don't offer a lot of customization on these new objects yet. The look and style is a little rigid for now. I have not decided on the best way to expose and implement the styling options yet.

I have already found the use of `Record` and `Row` to be useful in my graphs. I should have added them a long time ago. If you find any bugs or unexpected behavior, feel free to open an issue on the [GitHub project page](https://github.com/KevinMarquette/PSGraph).

The 2.1.17 release is already live on the PSGallery.

    Find-Module PSGraph | Install-Module
