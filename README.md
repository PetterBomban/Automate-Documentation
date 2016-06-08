# Automate-Documentation

![alt tag](https://raw.githubusercontent.com/PetterBomban/Automate-Documentation/master/img/preview2.png)

PowerShell script that adds server info to an SQLite database.

Also has a web-gui to view data from the database.

This is a long way from finished.

## Usage

```PowerShell
Get-ServerData -Database "C:\Users\SuperAdmin\SERVERS.SQLite" -DBTable "SERVERS" -Servers "MgmrSrv", "DC001" -Credentials (Get-Credential)
```

## Requirements

* Active Directory PowerShell Module
* [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite)
* Web-server that supports PHP and SQLite3


