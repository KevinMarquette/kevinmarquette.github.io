
# Defensive programming

When writing your scripts, there are many conditions that you know will cause your script to fail. Defensive programming is about identifying those conditions and testing for them where needed. Most of us already do this to some degree.

## Does that resource exist?

The most common one is to check for a resource before you go to use it.

    if(Test-Path -Path $Path)
    {
        Get-Content -Path $Path
    }
    else
    {
        Write-Error "File does not exist"
    }

Check files before you open them. Check for folders before you save to them. Ping servers before you try other connections to them.

It is best to be pro-active on these, but often we find these are problems we need to check for while writing the script.

## Did I get a result?

Checking to make sure that you got a result is an easy one to test for. Any time I run a command that can return one or many objects, I also expect that it can return nothing.

    $ADUsers = Get-ADGroup $Group | Get-ADGroupMembers

    if($ADUsers -ne $null)
    {
        Do-Something $ADUsers
    }

I don't know what Get-ADGroupMember will do if it does not have any members. It may throw an error, write a warning or just error and let the script continue. By checking for the result to make sure you got one, you don't have to know how it handles that situation. Whatever that command does, your `$ADUsers` is still empty.

### Piping empty results

In the previous  example, I tested the value directly for `$null`. You can also leverage the pipeline for that empty value check.

    $ADUsers = Get-ADGroup $Group | Get-ADGroupMembers
    $ADUsers | Do-Something
    
### Foreach in $null

I use `foreach` often to deal with possible empty results.

    $ADUsers = Get-ADGroup $Group | Get-ADGroupMembers

    foreach($user in $ADUsers)
    {
        Do-Something $user
    }

In this case, if `$ADUsers` is `$null` then the loop is skipped. This works as long as you are on PowerShell 3.0 or newer.

## $null results

When testing for results is automatically part of your approach

## Check for $null objects

PowerShell is very forgiving. Many times you can try to access a property that does not exist and you will just get a $null value.

    PS:> $host.rum.ham

The `$host` does not have a rum.ham property but it lets you run that without any errors. This is different if you try to call a method on an object that does not exist.

    PS:> $host.rum.ham.ToString()
    You cannot call a method on a null-valued expression.

When you find yourself calling methods, test to make sure you have an object to call it on.

    if($host.rum.ham -ne $null)
    {
        $host.rum.ham.ToString()
    }

Some CmdLets also throw errors when they are given `$null` or empty objects. 

    Resolve-Path $null
    Test-Path ''
    Get-Member $null

When you find that, you should check those values before you pass them to those functions. I'll cover testing for `$null` in another post.

# Exception handling

When code runs into serious or unexpected issue, it will throw an error or exception.  You can either catch the exception or let your code crash. 

## try/catch exception

