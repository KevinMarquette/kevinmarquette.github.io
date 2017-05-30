---
layout: post
title: "SQL: Running SQL 2017 CTP 2.0 in Docker"
date: 2017-04-23
tags: [SQL,Docker]
---

I saw an announcement for [SQL Server CTP 2017 CTP 2.0](https://redmondmag.com/articles/2017/04/19/sql-server-2017-preview.aspx) recently and I wanted to try it out. I went to the [eval page](https://www.microsoft.com/en-us/evalcenter/evaluate-sql-server-2017-ctp/) and I saw they have a [Docker image](https://hub.docker.com/r/microsoft/mssql-server-windows/) for Windows listed for this release.

It had a fresh update on the Docker site but did not reference SQL 2017 at the time of writing this. I figured it was worth a try to save having to install the full engine on my surface.<!--more-->

I fired up Docker and pulled the image.

    PS:> docker pull microsoft/mssql-server-windows

    Using default tag: latest
    latest: Pulling from microsoft/mssql-server-windows
    3889bb8d808b: Pull complete
    503d87f3196a: Pull complete
    87d2ab14f2da: Pull complete
    b09aa804afee: Pull complete
    835fc7fe99e6: Pull complete
    3641161f0cbc: Pull complete
    7b1619f329ad: Pull complete
    6769ec20632e: Pull complete
    898253442055: Pull complete
    28880976b6ff: Pull complete
    be1b01a79287: Pull complete
    c7778471ee62: Pull complete
    25cf3b6aa1e7: Pull complete
    ac61ad83a8cf: Pull complete
    Digest: sha256:b7b14c7c5bd544d867dc6ebc430cfcb8552963587f5db792707a50dc5d65707c
    Status: Downloaded newer image for microsoft/mssql-server-windows:latest

Now that I have it downloaded, let's fire it up.

    docker run -d -p 1433:1433 -e sa_password=<SA_PASSWORD> -e ACCEPT_EULA=Y microsoft/mssql-server-windows

Make sure you specify a SA password. This should start it up on the default local port of `1433` and accept the EULA for you.

At the time of this posting, I installed the [SQL Server Management Studio 17.0 RC3](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) to get the most current feature support. I could then connect to the instance on `localhost` using SA and the password specified above.

I can also connect with `Invoke-SqlCmd` from the PowerShell prompt.

    PS:> Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Username sa -Password <SA_PASSWORD> -Query 'select @@version' | 
        Select -ExpandProperty Column1

    Microsoft SQL Server vNext (CTP2.0) - 14.0.500.272 (X64)
        Apr 13 2017 11:44:40
        Copyright (C) 2017 Microsoft Corporation. All rights reserved.
        Enterprise Evaluation Edition (64-bit) on Windows Server 2016 Datacenter 10.0 <X64> (Build 14393: ) (Hypervisor)

If we cross compare the version with the [Microsoft SQL Server Version List](http://sqlserverbuilds.blogspot.com/), we can make sure we got the correct docker image. As it turns out, I had the exact version that I was looking for.

When we are all done, we can stop the container.

    docker ps
    docker stop --time=30 <CONTAINER_NAME>

The one thing I learned from doing this is that I need to be using Docker more. That was the easiest that I have ever setup a SQL Server.
