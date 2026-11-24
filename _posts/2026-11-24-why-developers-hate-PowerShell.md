---
layout: post
title: "Why developers hate PowerShell"
date: 2026-11-24
tags: [PowerShell, DeveloperExperience]
---

Using and learning PowerShell is a very different experience if you already have a background in programming. You bring intuitions and assumptions with you from other languages, and PowerShell breaks a lot of them in your first few scripts because it wasn't written for you. PowerShell was built for admins managing systems and learning to automate. You might also notice that AI coding assistants make the same mistakes for the same reasons.

I am going to walk through the things I have seen developers struggle with from their perspective. I'll show you what the developer sees first, then what's really happening, because I want to recreate some of the experience that developers have when they first run into them. Some of these issues get advanced really quickly, but it's hard to avoid that.

<!--more-->
At the time of writing this, PowerShell 7.6 is the most recent version. I will call out a few places where 7.x behaves differently than 5.1, but the vast majority of this post applies to both.

# Index

* TOC
{:toc}

# Calling functions

Writing a [function](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions) is one of the most natural things for a developer to do. This is an early function a developer might write in PowerShell, written the way they think it should be.

```powershell
function writeWelcome([string]$FirstName, [string]$LastName) {
    return "Hello $FirstName $LastName."
}
function writeIntro([string]$FirstName, [string]$LastName) {
    return "Dear $LastName, $FirstName"
}
```

Those are perfectly valid functions. The syntax is a little different than what we might be used to, but they are still functions. Now let's call them and see what happens:

```powershell
PS> writeWelcome("Kevin", "Marquette")
Hello Kevin Marquette .
PS> writeIntro("Kevin", "Marquette")
Dear , Kevin Marquette
```

I want you to pause for a moment and think through the output of both calls. This is valid PowerShell that a developer would intuitively expect to work. It's especially frustrating because the first one almost worked and the second one is obviously wrong.

Let's add some debug output to see what is happening. I'm going to use `echo` instead of a better alternative to set the stage for another issue later on.

```powershell
function writeIntro([string]$FirstName, [string]$LastName) {
    echo "FirstName [$FirstName]"
    echo "LastName [$LastName]"
    return "Dear $LastName, $FirstName"
}
```

The new output shows us the problem. The argument values are not landing in the parameters the way we expected.

```powershell
PS> writeIntro("Kevin", "Marquette")
FirstName [Kevin Marquette]
LastName []
Dear , Kevin Marquette
```

Both values ended up in `$FirstName` so `$LastName` is empty. This is the point where a developer either switches to named parameters or searches for how to call a function in PowerShell. An admin would never think to use parentheses there.

## What really happened

PowerShell binds unnamed arguments to parameters by position, and `("Kevin", "Marquette")` happens to be valid syntax for an array of two strings. So we passed one argument, an array, to the first parameter. Then `$LastName` was never given a value. When an array is placed inside a string, PowerShell joins the elements with a space. That is how `$FirstName` became `Kevin Marquette`.

This is how the call should look:

```powershell
PS> writeIntro "Kevin" "Marquette"
Dear Marquette, Kevin
PS> writeIntro -FirstName "Kevin" -LastName "Marquette"
Dear Marquette, Kevin
PS> writeIntro -FirstName Kevin -LastName Marquette
Dear Marquette, Kevin
```

To make things more confusing, methods use the syntax developers expect. Commas and parentheses are required when you call a method on an object.

```powershell
PS> "Kevin Marquette".Split(" ")
Kevin
Marquette
```

So a developer sees `.Split(" ")` work and reasonably assumes functions work the same way when they don't. Commands use shell syntax and methods use programming syntax, and you will see both in the same script.

# Return values

I can't tell you how many times I have seen developers get frustrated with that first example in their first hour of PowerShell. But it doesn't stop there. Let's use the return value from `writeIntro`, the version with the debug output still in it.

```powershell
PS> $intro = writeIntro -FirstName "Kevin" -LastName "Marquette"
PS> $email = "$intro. I am writing to you about..."
PS> $email
FirstName [Kevin] LastName [Marquette] Dear Marquette, Kevin. I am writing to you about...
```

Our debug messages ended up in the email. The function returned three values when we only expected one.

The whole point of `return` in other languages is to return the specified value and exit. In PowerShell, [`return`](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_return) exits the function, and the value you give it is added to the output. It doesn't stop anything else from being output. Everything a function outputs goes into the pipeline, which is how PowerShell passes values from one command to the next, one item at a time. Every value that is not captured or redirected is sent to the pipeline, and the caller gets all of it.

If you want debug messages that stay out of the return value, my preference is `Write-Verbose`. It writes to the verbose stream, which stays hidden until you ask for it with `-Verbose`.

Let's switch to the modern PowerShell style for functions with a `param` block and add `[CmdletBinding()]` to the function (consider it boilerplate for now). That gives us the `-Verbose` switch automatically. I'll also adopt the Verb-Noun naming standard going forward. More on that at the end.

```powershell
function Get-Intro {
    [CmdletBinding()]
    param([string]$FirstName, [string]$LastName)
    Write-Verbose "FirstName [$FirstName]"
    Write-Verbose "LastName [$LastName]"
    return "Dear $LastName, $FirstName"
}
```

```powershell
PS> $intro = Get-Intro -FirstName "Kevin" -LastName "Marquette" -Verbose
VERBOSE: FirstName [Kevin]
VERBOSE: LastName [Marquette]
PS> $intro
Dear Marquette, Kevin
```

You'll see a lot of `Write-Host` used for this in other people's code. It also stays out of the return value, but it shows up every time the function runs. I code everything with `Write-Verbose` messages so the caller gets to decide when they want to see the output.

## Output you didn't know about

`echo` is an alias for `Write-Output` and that might be too obvious, so let's try a different example that will often catch a regular PowerShell scripter off guard:

```powershell
function New-Folder {
    param([string]$path)
    New-Item -Path $path -ItemType Directory
    return "Created folder at $path"
}
```

This function creates a folder and returns a string to say that it worked. Let's call it:

```powershell
PS> $result = New-Folder -path "C:\Temp\TestFolder"
PS> $result.Count
2
PS> $result
    Directory: C:\Temp


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        11/21/2026   2:00 PM                TestFolder
Created folder at C:\Temp\TestFolder
```

We got two values. The first is the folder object from `New-Item` and the second is our string. The real challenge is that this isn't always obvious. We don't always know which commands output something. Any value we don't capture ends up in the return value.

Here are the common ways to discard output values you don't want:

```powershell
$null = New-Item -Path $path -ItemType Directory
[void](New-Item -Path $path -ItemType Directory)
New-Item -Path $path -ItemType Directory | Out-Null
```

I tend to use `$null =` because it's obvious what it's doing and it's fast. If you want more detail on these, I cover them in [Everything you wanted to know about $null](/2018-12-23-Powershell-null-everything-you-wanted-to-know/?utm_source=blog&utm_medium=blog).

## ArrayList.Add()

PowerShell is built on top of dotnet, and developers often reach into dotnet to use types that they are familiar with. The most common dotnet type that pollutes the pipeline is `[System.Collections.ArrayList]`. Its `Add()` method returns the index of the item that was added.

```powershell
PS> $list = [System.Collections.ArrayList]@()
PS> $list.Add("Kevin")
0
PS> $list.Add("Marquette")
1
```

Put that inside a function and those index values become part of your return value. My preferred alternative is the generic `List[T]`. Its `Add()` method doesn't return anything.

```powershell
PS> $list = [System.Collections.Generic.List[string]]::new()
PS> $list.Add("Kevin")
PS> $list.Add("Marquette")
PS> $list
Kevin
Marquette
```

## Arrays that change shape

Now that we know everything gets sent to the pipeline, here is a nasty surprise. Let's write a function that returns an array with one item in it:

```powershell
function Get-Names {
    $names = @('Kevin')
    return $names
}
```

```powershell
PS> $result = Get-Names
PS> $result[0]
K
PS> $result.GetType().FullName
System.String
```

We asked for the first name and got the first letter. Checking the type shows that we got a string back instead of an array. This is because PowerShell unrolls collections and sends each item down the pipeline one at a time. An empty array would have given us a `$null` (technically its an `AutomationNull`). Most of the time, PowerShell doesn't care what the type is and does the right thing. But a developer expecting strongly typed objects will always be surprised by that behavior.

If you absolutely have to preserve the collection, then you can use the unary comma operator to wrap the collection in another array or use `Write-Output -NoEnumerate`.

```powershell
# unary comma operator
function Get-Names {
    $names = @('Kevin')
    return ,$names
}

# Write-Output -NoEnumerate
function Get-Names {
    $names = @('Kevin')
    Write-Output -NoEnumerate $names
}
```

That comma operator is easy to miss and looks like a typo to anyone who doesn't know the trick. In practice, this is most commonly resolved on the caller's side by wrapping the results in an array.

```powershell
$names = @(Get-Names)
```

I cover unrolling, `@()`, and the other collection types in [Everything you wanted to know about arrays](/2018-10-15-Powershell-arrays-Everything-you-wanted-to-know/?utm_source=blog&utm_medium=blog).

# Comparison operators

This is a fun one because it doesn't throw an error:

```powershell
PS> $count = 10
PS> if ($count > 5) { "big" } else { "small" }
small
```

Ten is not bigger than five? Let's look at the current folder:

```powershell
PS> Get-ChildItem
    Directory: C:\Temp

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        11/21/2026  11:36 PM             10 5
```

There is now a file named `5` with `10` in it. In a shell, `>` [redirects output to a file](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_redirection). That is what it has meant in shells for decades, and admins expect it. The redirection produced no output, so the `if` statement saw nothing and treated it as `$False`.

PowerShell uses these named [comparison operators](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_comparison_operators) instead:

| Other languages | PowerShell |
| --- | --- |
| `==` | `-eq` |
| `!=` | `-ne` |
| `>` | `-gt` |
| `>=` | `-ge` |
| `<` | `-lt` |
| `<=` | `-le` |
| `&&` | `-and` |
| `\|\|` | `-or` |
| `!` | `-not` or `!` |

## Case doesn't matter

Developers expect `==` on two strings to be case-sensitive. PowerShell ignores case by default.

```powershell
PS> 'Kevin' -eq 'kevin'
True
PS> 'Kevin' -ceq 'kevin'
False
```

Every string operator has a `c` version when you need case to matter: `-ceq`, `-clike`, `-cmatch`, `-creplace`, `-ccontains`. The same rule applies to hashtable keys, and to variable and command names. `$FirstName` and `$firstname` are the same variable.

Here is the part that catches people. Methods come from dotnet, and they follow dotnet rules.

```powershell
PS> 'Kevin' -like '*kevin*'
True
PS> 'Kevin'.Contains('kevin')
False
```

Operators ignore case and methods don't. It's the same split we saw with calling functions, and you will see both in the same script.

## The left side wins

Now that we are using the correct operators, let's look at what they do with different types:

```powershell
PS> "1" + 1
11
PS> 1 + "1"
2
```

PowerShell converts the value on the right to match the type on the left. A string on the left means string concatenation. A number on the left means addition. The same thing happens with comparisons.

```powershell
PS> 1 -eq "01"
True
PS> "01" -eq 1
False
```

The first one converted `"01"` to a number. The second converted `1` to a string, and `"01"` is not `"1"`.

## Arrays on the left

When the left side is an array, the comparison operators turn into filters. They return every item that matches instead of `$True` or `$False`.

```powershell
PS> @(1,2,3,2) -eq 2
2
2
```

That's a handy feature once you know about it. It's also the reason `$null` should always go on the left side of a comparison. Look at what happens when we check this array for `$null` both ways.

```powershell
$value = @($null, $null)

if ($value -eq $null) { 'right: is null' } else { 'right: not null' }
if ($null -eq $value) { 'left: is null' } else { 'left: not null' }
```

```powershell
right: is null
left: not null
```

`$value` is an array, so it is not `$null`. With `$null` on the right, the comparison filtered the array and returned two `$null` values, and the `if` statement treated that as `$True`. With `$null` on the left, we get a real comparison and the right answer.

If you want to check whether an array contains a value and get back `$True` or `$False`, use `-contains` instead.

```powershell
PS> $names = @('Kevin','Alex')
PS> $names -contains 'Kevin'
True
```

## What is $True?

So what counts as `$True`?

```powershell
PS> [bool]"False"
True
PS> [bool]"0"
True
PS> [bool]""
False
PS> [bool]@()
False
PS> [bool]@(0)
False
PS> [bool]@(0,0)
True
```

Any string that isn't empty is `$True`, even `"False"`. An empty array is `$False`. An array with one item is `$True` or `$False` based on that one item. An array with two or more items is `$True` no matter what is in it.

That `"False"` case comes up when you read values from a config file or a CSV and expect them to act like booleans. Convert them on purpose with something like `$value -eq 'true'`. There is a lot more on this in the [about_Booleans](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_booleans) docs.

# Variables

We have been putting variables in strings this whole time. That works great until you use a property for the first time.

```powershell
PS> $user = @{ Name = 'Kevin' }
PS> "Hello $user.Name"
Hello System.Collections.Hashtable.Name
```

PowerShell only expands the variable `$user`. The `.Name` is left as text. To use a property or any other expression in a string, wrap it in a `$()` subexpression.

```powershell
PS> "Hello $($user.Name)"
Hello Kevin
```

A few other [quoting rules](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_quoting_rules) catch developers:

* The escape character is the backtick, not the backslash. A tab is `` "`t" `` and a new line is `` "`n" ``.
* Single quotes don't expand anything. `'Hello $user'` is exactly that text.
* Because `\` isn't an escape character, `"C:\temp\new"` is the path you meant. In C#, that `\n` would have been a new line.

## Typos are $null

Here is where my poor spelling haunts me the most:

```powershell
PS> $FirstName = 'Kevin'
PS> "Hello [$FristName]"
Hello []
```

I misspelled the variable and PowerShell gave me an empty value. A variable that was never set is `$null`, and there is no compiler to catch it. This is also why I wrap variables in brackets when I write them out. It makes it easy to see when a variable is empty vs the message getting truncated.

This is a good place to call out `Set-StrictMode -Version Latest`. It turns a reference to a variable that was never set into an error. I don't see it used very often, but it would have caught this one with this error:

```text
InvalidOperation: The variable '$FristName' cannot be retrieved because it has not been set.
```

## [string] is never $null

So a variable that was never set is `$null`. Unless we gave it a type that can't be `$null`. Let's go back to our very first function and handle the `$LastName` being optional. We'll check it explicitly for `$null`.

```powershell
function Get-Welcome {
    param([string]$FirstName, [string]$LastName)
    if ($null -eq $LastName) {
        return "Hey $FirstName!"
    }
    "Hello $FirstName $LastName."
}
```

```powershell
PS> Get-Welcome -FirstName "Kevin"
Hello Kevin .
```

Our `$null` check never matched. `[string]` is not nullable in PowerShell, so unlike C#, a `[string]` variable can never be `$null`. When you cast `$null` to a `[string]`, you get an empty string.

```powershell
PS> [string]$value = $null
PS> $null -eq $value
False
```

I see this one a lot when someone is trying to do the right thing by using strongly typed parameters and correctly checking everything for `$null`. If you want to know whether the caller used the parameter at all, ask `$PSBoundParameters`.

```powershell
if ($PSBoundParameters.ContainsKey('LastName')) {
    "LastName was passed"
}
```

While you might be tempted to reach for `[string]::IsNullOrEmpty($LastName)`, PowerShell will treat `$null` and the empty `[string]` as `$False` so don't overthink it:

```powershell
if ($LastName) {
    return "Hello $FirstName $LastName."
}
```

I go into more detail on this in [Everything you wanted to know about $null](/2018-12-23-Powershell-null-everything-you-wanted-to-know/?utm_source=blog&utm_medium=blog).


## Dynamic Scope

Here is a function that will pass all of its tests and still has a bug in it.

```powershell
function Invoke-SecureRequest {
    param([string]$Uri)
    if ($Uri -match '^https') {
        $secure = $True
    }
    if ($secure) {
        # Invoke-WebRequest $Uri
        return $True
    }
    return $False
}
```

But then you get that one user that always manages to break things:

```powershell
PS> Invoke-SecureRequest -URI "https://www.google.com"
True
PS> Invoke-SecureRequest -URI "http://www.google.com"
False
PS> $NotSecure="http://www.google.com"
PS> $Secure="https://www.google.com"
PS> Invoke-SecureRequest -URI $NotSecure
True
PS> Invoke-SecureRequest -URI $Secure
True
```

That example output will only match the first time you run it in a session. And that's the clue to understanding this one. You might have noticed that there are code paths in the function that do not set a value for `$secure`. That should be fine because we expect that it will be `$null` by default when it is not already set to a value (and that will be `$False` when evaluated). All your testing will prove it works correctly that way.

The catch is that PowerShell uses dynamic [scope](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_scopes) (most languages use lexical scope) so a function can read every variable from the scope that called it. When it assigns a value to one of those variables, it creates a new local variable with the same name, and the original is left alone. It's based on who called the function, not where the function was written.

The real version of this bug is the variable left over from your last F5/F8 run creating a dirty session, not a user who happens to name a variable `$Secure`. Strict Mode would have caught this one in a clean session, because the http test would throw. But once you have a dirty session with `$Secure` defined, the variable does exist and Strict Mode is happy. It just isn't the one you meant.

Let's look at a more direct demonstration of dynamic scope:

```powershell
function Get-ServerName {
    "Server is [$server]"
}
function Connect-Server {
    $server = 'SrvProd05'
    Get-ServerName
}
```

```powershell
PS> Connect-Server
Server is [SrvProd05]
PS> Get-ServerName
Server is []
```

`Get-ServerName` never defines `$server` and nobody passes it in. It works when `Connect-Server` calls it and comes back empty when we call it directly. A function that depends on a variable it was never given works fine in testing and fails when someone calls it from a new place.

I pretend that it doesn't work like that and pass everything a function needs through its parameters and output everything it produces. If you really need to change a variable outside the function, use a script scope modifier like `$script:Count` so it's obvious you are doing it on purpose.


## Variables you can't name

While we are on variables, PowerShell has a long list of [automatic variables](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables). Some of them have names that look like perfectly good variable names.

```powershell
PS> $host = 'SrvProd05'
Cannot overwrite variable Host because it is read-only or constant.
At line:1 char:1
+ $host = 'SrvProd05'
+ ~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : WriteError: (Host:String) [], SessionStateUnauthorizedAccessException
    + FullyQualifiedErrorId : VariableNotWritable
```

At least that one gives you an error, and so does `$error`. Others let you assign them with no error at all, and then they don't act like normal variables. `$input` is the one I run into the most.

Let's go back to our `Get-ServerName` function from the scope section, but call the variable `$input` this time.

```powershell
$input = 'SrvProd05'
function Get-ServerName {
    "Server is [$input]"
}
```

```powershell
PS> Get-ServerName
Server is []
PS> "[$input]"
[SrvProd05]
```

We just saw that a function can read variables from the scope that called it, so this should have worked. It doesn't, because every function gets its own automatic `$input` that holds whatever was piped into it. That hides the variable we set outside the function, and nothing was piped in, so it's empty.

`$input` isn't a normal variable inside the function either. It's an enumerator, so you can only read it once.

```powershell
function Measure-Names {
    "First [$(@($input).Count)]"
    "Second [$(@($input).Count)]"
}
```

```powershell
PS> 'Kevin','Alex' | Measure-Names
First [2]
Second [0]
```

The second read got nothing because the first read already used up the items. `$args`, `$matches`, `$event`, and `$_` can also be assigned without an error, and PowerShell will overwrite them when it needs them. Use a more specific name like `$serverName` or `$InputObject` and you never have to think about it.



# Paths

Admins work with file paths all day, and PowerShell has a couple of rules for paths that developers don't expect.

## Wildcards in paths

```powershell
PS> Set-Content -LiteralPath '.\report[1].txt' -Value 'data'
PS> Get-Item -Path '.\report[1].txt'
PS> Test-Path -Path '.\report[1].txt'
False
PS> Test-Path -LiteralPath '.\report[1].txt'
True
```

The file exists, but `Get-Item` returned nothing and `Test-Path` says it isn't there. The `-Path` parameter accepts [wildcards](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_wildcards), and `[1]` is a wildcard pattern that matches the character `1`. It found no file named `report1.txt`. Use `-LiteralPath` when the path came from somewhere you don't control.

## The current directory

PowerShell and dotnet make different assumptions about the current directory:

```powershell
PS C:\Temp> Test-Path -Path .\names.txt
True
PS C:\Temp> [System.IO.File]::ReadAllText('.\names.txt')
Exception calling "ReadAllText" with "1" argument(s): "Could not find file 'C:\Users\Kevin\names.txt'."
At line:1 char:1
+ [System.IO.File]::ReadAllText('.\names.txt')
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : FileNotFoundException
```

PowerShell's current location and the process's current directory are two different things. `Set-Location` changes the PowerShell location, but dotnet methods use the process directory, which is usually wherever PowerShell started. Make sure you give dotnet methods full paths like this:

```powershell
$path = Convert-Path -Path 'names.txt'
[System.IO.File]::ReadAllText($path)
```

The call to `Convert-Path` will fail if the file doesn't exist. You can build a path with `Join-Path` and the `$PWD` (present working directory). Unless you are on a PSDrive path that dotnet doesn't understand.

```powershell
$path = Join-Path -Path $PWD -ChildPath 'names.txt'
```



# Error handling

A developer sees `try/catch` and knows exactly what to do with it. Let's try it.

```powershell
try {
    Get-Item -Path C:\DoesNotExist
    "after Get-Item"
}
catch {
    "caught it"
}
```

```powershell
Get-Item : Cannot find path 'C:\DoesNotExist' because it does not exist.
At line:2 char:5
+     Get-Item -Path C:\DoesNotExist
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (C:\DoesNotExist:String) [Get-Item], ItemNotFoundException
    + FullyQualifiedErrorId : PathNotFound,Microsoft.PowerShell.Commands.GetItemCommand

after Get-Item
```

We got an error, but the script kept going and the `catch` never ran.

PowerShell has two kinds of errors. Terminating errors stop execution and can be caught. Non-terminating errors are written to the error stream and the command keeps going. Many cmdlets use non-terminating errors because an admin running `Test-Connection` against 500 servers wants all the good and bad results, not a script that stops at the first bad one.

To catch an error from a cmdlet, make it terminating with `-ErrorAction Stop`.

```powershell
try {
    Get-Item -Path C:\DoesNotExist -ErrorAction Stop
    "after Get-Item"
}
catch {
    "caught: $($_.Exception.Message)"
}
```

```powershell
caught: Cannot find path 'C:\DoesNotExist' because it does not exist.
```

Or set `$ErrorActionPreference = 'Stop'` at the top of a script to change the default for everything after it. I go into much more detail in [Everything you ever wanted to know about exceptions](/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/?utm_source=blog&utm_medium=blog).


## Native commands

Executables like `git`, `robocopy`, or `msiexec` don't throw errors at all. They return an exit code that PowerShell puts into `$LASTEXITCODE`:

```powershell
try {
    cmd /c exit 5
    "after cmd"
}
catch {
    "caught it"
}
```

```powershell
after cmd
```

```powershell
PS> $LASTEXITCODE
5
```

You have to check `$LASTEXITCODE` yourself after each call. Be careful, because not every tool uses `0` for success and everything else for failure. `robocopy` returns `1` when it copied files successfully.

In PowerShell 7.4 and newer, you can set `$PSNativeCommandUseErrorActionPreference = $True` so a non-zero exit code is treated as an error and respects `$ErrorActionPreference`. Turning this on makes robocopy's "success" exit code of 1 throw an error if `$ErrorActionPreference` is `Stop`.

Now that we know how to catch when a native command errors, let's look at the error stream of a command that fails.

```powershell
PS> $branch = git checkout nosuchbranch
error: pathspec 'nosuchbranch' did not match any file(s) known to git
PS> "branch [$branch]"
branch []
PS> $LASTEXITCODE
1
```

The error message went to the screen instead of into our variable. PowerShell only captures standard output. Standard error goes to the error stream, so it skips right past our assignment.

That would be easy enough to work around if standard error only had errors in it. But git also writes its normal status and progress messages there. Here is a checkout that worked:

```powershell
PS> $branch = git checkout feature
Switched to branch 'feature'
PS> "branch [$branch]"
branch []
PS> $LASTEXITCODE
0
```

Nothing went wrong, and we still didn't capture the message. If you want both streams, redirect standard error into the output with `2>&1`.

```powershell
PS> $result = git checkout main 2>&1
PS> $result.GetType().FullName
System.Management.Automation.ErrorRecord
```

We captured the message this time, but PowerShell wrapped every line from standard error in an error record. That's the same success message, now dressed up as an error.

In Windows PowerShell 5.1, this gets worse. If you set `$ErrorActionPreference = 'Stop'` like I suggested in the last section, those error records become terminating errors.

```powershell
PS> $ErrorActionPreference = 'Stop'
PS> $result = git checkout main 2>&1
git : Switched to branch 'main'
At line:1 char:11
+ $result = git checkout main 2>&1
+           ~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Switched to branch 'main':String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
```

The checkout worked, and the script still died. That's a common reason a script that works perfectly looks like it failed. PowerShell 7 doesn't throw here, but you still get error records back. Either way, let `$LASTEXITCODE` tell you whether the command worked, and treat anything on standard error as more output.


# Classes

PowerShell 5.0 introduced [classes](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes), mainly for writing DSC resources. Developers know classes, and they are excited to use them. But the further you get from the DSC use case, the rougher the feature gets. I could write an entire post about the frustrations with classes in PowerShell.

The first thing developers notice is that everything about `return` output we covered earlier is reversed inside a class method. Let's take our `New-Folder` function and make it a method:

```powershell
class Folder {
    [string] Create([string]$path) {
        New-Item -Path $path -ItemType Directory
        return "Created folder at $path"
    }
}
```

```powershell
PS> $result = [Folder]::new().Create("C:\Temp\TestFolder")
PS> $result
Created folder at C:\Temp\TestFolder
```

Inside a method, only `return` sends anything back and everything else is thrown away. That is what a developer expected from functions all along. So they get it here and nowhere else.

A few of the other rough edges:

* Classes are compiled when the script is parsed. To use a class from a module outside that module, you need `using module` at the top of the script. `Import-Module` isn't enough.
* Once a class has been loaded though using module, you can't reload a new version of it in the same session. You end up opening new terminals over and over while you develop.
* Method calls use the method syntax with commas and parentheses, so a script that mixes classes and functions has both calling styles side by side.

# AI makes the same mistakes

While I was writing this post, Copilot kept trying to autocomplete the output of my examples. Every time I started typing the result of `writeIntro("Kevin", "Marquette")`, it suggested `Dear Marquette, Kevin`. It wanted to "fix" my examples so they showed what a developer expected instead of what PowerShell does.

AI tools learned from a lot more C#, Python, and JavaScript than PowerShell, so they apply general programming patterns to PowerShell without understanding where it is different. They make the same mistakes developers make:

* Calling functions with parentheses and commas.
* Using `return` and expecting it to be the only output.
* Using `echo` or `Write-Host` for debug messages instead of `Write-Verbose`.
* Leaving output from commands like `New-Item` uncaptured inside a function.
* Using `ArrayList.Add()` without capturing the index.
* Returning a collection and expecting the caller to get an array.
* Using `>` or `==` instead of `-gt` and `-eq`.
* Using a method like `.Contains()` and expecting it to ignore case like the operators do.
* Putting `$null` on the right side of a comparison.
* Treating the string `"False"` from a config file as `$False`.
* Writing `"$user.Name"` instead of `"$($user.Name)"`.
* Checking a `[string]` parameter for `$null` to see if the caller used it.
* Reading a variable that was never set in the function, so it picks one up from the caller.
* Naming a variable `$input`, `$args`, or `$matches`.
* Using `-Path` instead of `-LiteralPath` for paths that came from somewhere else.
* Passing relative paths to dotnet methods.
* Wrapping cmdlets in `try/catch` without `-ErrorAction Stop`.
* Not checking `$LASTEXITCODE` after calling an executable.

If you use these tools to help write PowerShell, this list is a good review checklist. The code can often look right and still have one of these bugs.

# Why PowerShell works this way

I have spent this whole post showing things that work differently than developers expect. I'm not saying any of these are mistakes (even though I might not like them). They were decisions, and they make more sense when you remember who PowerShell was built for.

PowerShell was built for admins who were learning to automate. It's a shell first and a programming language second. Picture someone typing at a console:

* Spaces between arguments are faster to type than parentheses and commas.
* Typing an expression should show you the result without wrapping it in `print`.
* Commands should pass items down the pipeline one at a time, so the next command can start working on the first one right away.
* `>` should write to a file, because that's what it does in every other shell.
* Windows doesn't care about case, so the shell shouldn't either.
* Almost everything you type or read from a file starts out as text, so the shell should convert types for you.
* `*.log` should just work anywhere you can give a path.
* The variables you set at the console should be available to the commands you run next.
* One bad server out of 500 shouldn't stop the other 499.

## Verbosity is a feature

That same thinking explains the one thing developers complain about most: PowerShell is very verbose. `Get-ChildItem -Path C:\Temp -Filter *.log -Recurse` is a lot of typing compared to `ls`.

Commands follow a Verb-Noun pattern with a list of [approved verbs](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands) that you can see with `Get-Verb`. An admin who knows `Get-Service` can guess `Get-Process`, `Stop-Service`, and `Restart-Service` without looking anything up. Tab completion does most of the work, and aliases like `ls` and `gci` are still there for the console.

I will happily use aliases at the console and full command names and named parameters in scripts. We spend way more time reading code than writing it. A script gets written once and then read every time someone needs to fix it, change it, or figure out what it does.

I'll admit that I enjoy code golf. I have given presentations on how to squeeze a solution into the shortest number of characters possible, and a really long one-liner full of aliases can be a lot of fun at the console. But that doesn't belong in our scripts.

# Closing remarks

We covered a lot of ground: calling functions, output and return values, unrolling, operators, case sensitivity, type conversion, truthiness, strings, scope, automatic variables, paths, errors, native commands, and classes. If you came to PowerShell from another language, I hope this explains a few of the moments that made you want to throw your keyboard. If PowerShell is your first language, maybe now you will see why you get so much resistance from your developer friends.

Not all of this is going to matter to you today, and that's fine. My hope is that the next time PowerShell does something you don't expect, you'll remember there was a reason for it, and you'll know where to look.

Several of these topics have a deep dive of their own if you want to keep going: [arrays](/2018-10-15-Powershell-arrays-Everything-you-wanted-to-know/?utm_source=blog&utm_medium=blog), [hashtables](/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/?utm_source=blog&utm_medium=blog), [PSCustomObject](/2016-10-28-powershell-everything-you-wanted-to-know-about-pscustomobject/?utm_source=blog&utm_medium=blog), [$null](/2018-12-23-Powershell-null-everything-you-wanted-to-know/?utm_source=blog&utm_medium=blog), and [exceptions](/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/?utm_source=blog&utm_medium=blog).

If I missed one that tripped you up early on, let me know.
