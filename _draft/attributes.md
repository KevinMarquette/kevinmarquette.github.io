# Brandon Olin 
# @devblackops 

Class MyCommand : Attribute {
    [string]$Name
    [bool] $Hidden = $false

    MyCommand([string]$Name)
    {
        $this.Name = $Name
    }
}

[MyCommand('MyClass')]
class test {

    [MyCommand('MyClassProperty')]
    $Name = 'TestName'

    [MyCommand('myFunction')]
    [string] Hello(
        [MyCommand('myParam')]
        [string]
        $Name = "Kevin"
    )
    {
        [MyCommand('other')] 
        $temp = $null
        
        return "Hello $name"
    }
}

<#
class MainClass 
{
   public static void Main() 
   {
      System.Reflection.MemberInfo info = typeof(MyClass);
      object[] attributes = info.GetCustomAttributes(true);
      for (int i = 0; i < attributes.Length; i ++)
      {
         System.Console.WriteLine(attributes[i]);
      }
   } 
} 
#>

[test].CustomAttributes | fl *

[test].CustomAttributes[0].NamedArguments | Get-Member
[MyCommand] ([test].CustomAttributes[0]) | gm

# get custom attributes for class
[test].GetCustomAttributes( 'MyCommand') | fl *


[test].GetMember('Name').GetCustomAttributes('MyCommand')
[test].GetMember('Hello').GetCustomAttributes('MyCommand')
[test].GetMember('Hello').GetParameters().GetCustomAttributes('MyCommand') | Get-Member -Force

[test].GetMethod('Hello') | Get-Member -Force
[test].GetMethod('Hello') | fl *.GetParameters()


[MyCommand('other')] 
$t = [test]::new()
$T | Get-Member -Force
$T.gettype().GetCustomAttributes( 'MyCommand')
$t.psobject.Members | where name -eq name | Get-Member -Force


