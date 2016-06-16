# Automate-Documentation

![alt tag](https://raw.githubusercontent.com/PetterBomban/Automate-Documentation/master/img/preview.png)

PowerShell script that adds server info to an SQLite database.

Also has a web-gui to view data from the database.

This is a long way from finished.

## Usage


**Loading servers from string**
```PowerShell
Get-ServerData -Database "C:\inetpub\wwwroot\Web\SERVERS.SQLite" -DBTable "SERVERS" -Servers "MgmrSrv", "DC001" -Credentials (Get-Credential) - 
```
**Loading servers from VMWare (With PowerCLI)**
```PowerShell
Get-ServerData -Database "C:\inetpub\wwwroot\Web\SERVERS.SQLite" -DBTable "SERVERS"-Credentials (Get-Credential) -VIServer "192.168.0.9" -LoadFromVMWare
```

You can also use the `-AllowDuplicates` switch if you want to allow duplicate entries.

## Requirements

* Active Directory PowerShell Module
* [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite)
* Web-server that supports PHP and SQLite3
* PowerCLI (If you plan to load servers from VMWare)


