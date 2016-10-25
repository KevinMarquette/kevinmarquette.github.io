---
layout: post
title: "Powershell: Remoting"
date: 2016-11-04
tags: [PowerShell]
---

When I talk about native filters, I am referring to filtering options that get passed down to the underlying system or api calls and the filtering is done before the object gets to the shell. Most of the time you will find this to perform signifigantly faster.

## Native filters: Get-ChildItem
This is a common one that everyone can use. First take a look at the help text for the `-Filter` parameter.

    Get-Help Get-ChildItem -Parameter Filter 
 
    -Filter <String>
        Specifies a filter in the provider's format 
        or language. The value of this parameter 
        qualifies the Path parameter. The syntax of 
        the filter, including the use of wildcards, 
        depends on the provider. Filters are more efficient 
        than other parameters, because the provider applies 
        them when retrieving the objects, rather than 
        having Windows PowerShell filter the objects after 
        they are retrieved.

So instead of piping the results and filtering them like this:

    Get-ChildItem -Recurse | where-Object{$_.name -like '*.ps1'}

Use the native -Filter parameter instead.

     Get-ChildItem -Filter *.ps1 -Recurse 

## Native filters: Get-WinEvent
 
You may not see a large performance gain with `Get-ChildItem` but the performance difference is much greater for some of these other commands like `Get-WinEvent`. This command greatly benifits because it often reads the entire eventlog without the use of the `-filterHashtable` parameter.  


    Get-WinEvent -FilterHashtable @{
        logname='System','Application'
        Level=1,2
    } 

You can specify multiple properties or values in the hashtable. [Use FilterHashTable to Filter Event Log with PowerShell](https://blogs.technet.microsoft.com/heyscriptingguy/2014/06/03/use-filterhashtable-to-filter-event-log-with-powershell/) 

## Native filters: Get-ADUser

Another command that makes good use of a native filter is `Get-AdUser`. I do have to say that this one can get complicated very quickly, expecially if you have not worked with AD queries like this before. The get-help details offers lots of examples and the syntax.

    Get-Help Get-ADUser -Parameter Filter 
    
Here are a few quick examples:

    Get-ADUser -Filter {EmailAddress -like "*"} 
    Get-ADUser -Filter {mail -like "*"} 
    Get-ADUser -Filter {(EmailAddress -like "*") -and (Surname  -eq "smith")}  

    $logonDate = New-Object System.DateTime(2016, 3, 1)
    Get-ADUser  -Filter { lastLogon -le $logonDate  } 
     

Syntax: 
The following syntax uses Backus-Naur form to show how to use the PowerShell Expression Language for this 
    parameter.
        
    <filter>  ::= "{" <FilterComponentList> "}"
    <FilterComponentList> ::= <FilterComponent> | <FilterComponent> <JoinOperator> <FilterComponent> | <NotOperator>  
    <FilterComponent>
    <FilterComponent> ::= <attr> <FilterOperator> <value> | "(" <FilterComponent> ")" 
    <FilterOperator> ::= "-eq" | "-le" | "-ge" | "-ne" | "-lt" | "-gt"| "-approx" | "-bor" | "-band" | 
    "-recursivematch" | "-like" | "-notlike"
    <JoinOperator> ::= "-and" | "-or" 
    <NotOperator> ::= "-not" 
    <attr> ::= <PropertyName> | <LDAPDisplayName of the attribute> 
    <value>::= <compare this value with an <attr> by using the specified <FilterOperator>>
    
For a list of supported types for <value>, see about_ActiveDirectory_ObjectModel. 
