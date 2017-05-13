docker

https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10

Register-PSRepository -Name DockerPS-Dev -SourceLocation https://ci.appveyor.com/nuget/docker-powershell-dev
Install-Module -Name Docker -Repository DockerPS-Dev -Scope CurrentUser
Import-module Docker


