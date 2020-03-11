# So Many Files Repro Case

This sample application will reproduce a server hang with Fusionreactor output such as:

[ERROR] class models.entity1_cfc$cf
[ERROR] class models.config_cfc$cf
[ERROR] class models.entity10_cfc$cf
[ERROR] class models.entity1_cfc$cf
[ERROR] class models.entity100_cfc$cf
[ERROR] class models.entity10_cfc$cf

The application creates 1,000 database tables with one row apiece and 1,000 persistent entity files. 

## Requirements
Commandbox and either Docker or a local instance of MySQL with an empty **luceeFiles** database. (You will also want to change the MYSQL_ROOT_PASSWORD in .env )

## Pre-Installation

Clone this repo, then **box install** and **docker-compose pull -d**.

## App Bootstrap

The first time the app runs, it will create all the database tables and the persistent entities. This will likely take a couple of minutes. Use the link to reload the ORM (which will take 2-4 minutes) and when it is complete...

## Reproduce the issue

Use the links to open the same page on alternate localhost names. CF will make a new application for eeach **http_host**. It will not repeat the database or file creation bootstrap, but it will take a very long time to complete the requests.

## Enabling FusionReactor output

In the **.env** file, Change FR_ENABLE to **true** and input a valid FusionReactor license key under FR_LICENSE_KEY.
