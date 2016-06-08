<#
.Synopsis
   Gather data about one or more servers
.DESCRIPTION
   Gather data about one or more servers. In development.
.EXAMPLE
   "Neo", "Mouse" | Get-ServerData
.EXAMPLE
   Get-ServerData -servers "Neo", "Mouse"
#>
Function Get-ServerData 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$Servers,

        [Parameter(
            Mandatory = $true
        )]
        $Database,

        [Parameter(
            Mandatory = $true
        )]
        $DBTable,

        [Parameter(
            Mandatory = $true
        )]
        $Credentials,

        [Parameter()]
        [switch]$AllowDuplicates
    )

    $ErrorActionPreference = "Stop"

    ## Modules needed
    Import-Module ActiveDirectory, PSSQLite

    ## Create the database if it doesn't exist already
    if (!( Test-Path -Path $Database ))
    {
        $q = "CREATE TABLE $DBTable (_id INTEGER PRIMARY KEY autoincrement, GUID TEXT, Hostname TEXT, IPAddress TEXT, OS TEXT, Installed TEXT, Date TEXT, Comments TEXT)"
        Invoke-SqliteQuery -DataSource $Database -Query $q

        Write-Output "Database $Database created."
    }

    ## Scriptblock that runs for each server passed to this function
    $GatherData = {
        $property = [ordered]@{
            Hostname = (hostname)
            IPAddress = (Get-NetIPConfiguration).IPv4Address.IPAddress 
            OS = ((Get-WmiObject Win32_OperatingSystem).Caption)
            Date = (Get-date -Format d)
            Installed = ((Get-WindowsFeature | Where {$_.Installed -eq $true})).Name | Out-String
            #Services = (Get-Service | Where {$_.Status -eq "Running"})
        }
        New-Object psobject -Property $property
    }

    foreach ($Server in $Servers)
    {
        Write-Output "Gathering data from $Server."
        ## Run $GatherData on the server, passes the output to $data
        Invoke-Command -ComputerName $Server -Credential $Credentials -ScriptBlock $GatherData -OutVariable data #| Out-Null

        try 
        {
            ## Adds the server GUID to the $data object
            $GUID = (Get-ADComputer $Server).ObjectGUID.Guid
            $data | Add-Member -NotePropertyName GUID -NotePropertyValue $GUID
        }
        catch 
        {
            ## TODO
            Write-Error $Error[0]
        }

        ## Begin adding the server to the database
        try
        {
            ## Checks to see if the server is already entered.
            ## If it is, we just update the already existing entry. If not, we add a new one.
            $sql = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM SERVERS WHERE Hostname = '$Server'"
            if ( ($sql.GUID -eq $data.GUID) -and ($AllowDuplicates -eq $false) )
            {
                Write-Output "Detected already existing server, updating with new info. $Server."

                $Query = "UPDATE $DBTable SET GUID=@GUID, Hostname=@Hostname, IPAddress=@IPAddress, OS=@OS, Installed=@Installed, Date=@Date WHERE _id=@id"
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                    GUID = $data.GUID
                    Hostname = $data.Hostname
                    IPAddress = $data.IPAddress
                    OS = $data.OS
                    id = $sql._id
                    Date = $data.Date
                    Installed = $data.Installed
                } -ErrorAction Stop

                Write-Output "$Server -- Updated entry."
            }
            else 
            {
                Write-Output "Creating new entry for $Server."

                $Query = "INSERT INTO $DBTable (GUID, Hostname, IPAddress, OS, Installed, Date) VALUES (@GUID, @Hostname, @IPAddress, @OS, @Installed, @Date)"
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                    GUID = $data.GUID
                    Hostname = $data.Hostname
                    IPAddress = $data.IPAddress
                    OS = $data.OS
                    Date = $data.Date
                    Installed = $data.Installed
                } -ErrorAction Stop

                Write-Output "$Server -- Created entry."
            }
        }
        catch 
        {
            ## TODO
            Write-Error $Error[0]
        }

    }

    ## DEBUG
    Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM SERVERS"

    #Invoke-SqliteQuery -DataSource $Database -Query "DELETE FROM SERVERS"

}

$credential = Get-Credential

Get-ServerData -Database "C:\inetpub\wwwroot\Web\SERVERS.SQLite" -DBTable "SERVERS" -Servers "MgmrSrv", "DC001" -Credentials $credential #-AllowDuplicates