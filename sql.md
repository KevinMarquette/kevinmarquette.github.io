---
layout: page
title: MSSQL Server
subtitle: Important reference material
tags: [MSSQL, SQL Server]
---

As a system admin, I often find myself working very closely with SQL server. Here is a collection of resources that I find myself turning to over and over.

* TOC
{:toc}

## MSSQL Server Version list 
This unofficial build chart lists all of the known Service Packs (SP), Cumulative Updates (CU), patches, hotfixes and other builds of MS SQL Server 2014, 2012, 2008 R2, 2008, 2005, 2000, 7.0, 6.5 and 6.0 that have been released. 

[MSSQL Server Version List](http://sqlserverbuilds.blogspot.com/)

## SQL Server Management Studio (SSMS)
SQL Server Management Studio (SSMS) is an integrated environment for accessing, configuring, managing, administering, and developing all components of SQL Server. SSMS combines a broad group of graphical tools with a number of rich script editors to provide developers and administrators of all skill levels access to SQL Server. This release features improved compatibility with previous versions of SQL Server, a stand-alone web installer, and toast notifications within SSMS when new releases become available.

[Download SQL Server Management Studio (SSMS)](https://msdn.microsoft.com/en-us/library/mt238290.aspx)

## xSqlServer DSC Resources
The xSQLServer module contains DSC resources for deployment and configuration of SQL Server in a way that is fully compliant with the requirements of System Center.

[xSqlServer](https://github.com/PowerShell/xSQLServer)

## SQL Server Backup, Integrity Check, and Index and Statistics Maintenance
The Ola Hallengren SQL Server Maintenance Solution comprises scripts for running backups, integrity checks, and index and statistics maintenance on all editions of Microsoft SQL Server 2005, SQL Server 2008, SQL Server 2008 R2, SQL Server 2012, SQL Server 2014, and SQL Server 2016. 

[Ola Hallengren SQL Server Maintenance Solution](https://ola.hallengren.com/)

## How to license SQL Server
Make sure you read up on your licensing options for SQL server. Here are some good articles to help understand what you are looking at.

* [SQL Server 2014 Licensing Changes](https://www.brentozar.com/archive/2014/04/sql-server-2014-licensing-changes/) 
* [Microsoft SQL 2014 Licensing in a VMware environment](https://www.vmguru.com/2015/03/microsoft-sql-2014-licensing-in-a-vmware-environment/)
* [Recommended Intel Xeon E5-2600 v4 Processors for SQL Server](http://www.sqlskills.com/blogs/glenn/recommended-intel-xeon-e5-2600-v4-processors-for-sql-server/)
* [Recommended Intel Processors for SQL Server 2014 – March 2015](https://sqlperformance.com/2015/03/system-configuration/recommended-cpus-sql-server-2014)
* [SQL Server 2016 licensing datasheet and guide](http://download.microsoft.com/download/9/C/6/9C6EB70A-8D52-48F4-9F04-08970411B7A3/SQL_Server_2016_Licensing_Guide_EN_US.pdf)
* [SQL Server 2014 licensing datasheet and guide](http://go.microsoft.com/fwlink/?LinkId=230678)

## sp_Blitz – Free SQL Server Health Check Script

You’ve got a Microsoft SQL Server that somebody else built, or that other people have made changes to over the years, and you’re not exactly sure what kind of shape it’s in. Are there dangerous configuration settings that are causing slow performance or unreliability?
You want a fast, easy, free health check that flags common issues in seconds, and for each warning, gives you a link to a web page with more in-depth advice.

[Brent Ozar's sp_Blitz](https://www.brentozar.com/blitz/)

## SQL Server Community Slack
General conversations about SQL Server

[Slack #dbatools](https://sqlcommunity.slack.com/messages/dbatools/)

## Running SQL Server in Docker

Here are the commands to download the image, start a container, invoke a query and then stop the container.

    docker pull microsoft/mssql-server-windows
    docker run -d -p 1433:1433 -e sa_password=<SA_PASSWORD> -e ACCEPT_EULA=Y microsoft/mssql-server-windows

    Invoke-Sqlcmd -ServerInstance localhost -Database tempdb -Username sa -Password <SA_PASSWORD> -Query 'select @@version' | 
        Select -ExpandProperty Column1

    docker ps
    docker stop --time=30 <CONTAINER_NAME>