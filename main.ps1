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
        $DBTable
    )

    ## Modules needed
    Import-Module ActiveDirectory, PSSQLite

    ## Temporary
    $Cred = Get-Credential -Credential "PETTERR\SuperAdmin"

    if (!( Test-Path -Path $Database ))
    {
        $q = "CREATE TABLE SERVERS (_id INTEGER PRIMARY KEY autoincrement, GUID TEXT, Hostname TEXT, IPAddress TEXT, OS TEXT)"
        Invoke-SqliteQuery -DataSource $Database -Query $q

        Write-Output "Database $Database created."
    }

    ## Scriptblock that runs for each server passed to this function
    $GatherData = {
        $property = [ordered]@{
            Hostname = (hostname)
            IPAddress = (Get-NetIPConfiguration).IPv4Address.IPAddress 
            OS = ((Get-WmiObject Win32_OperatingSystem).Caption)
            #Installed = (Get-WindowsFeature | Where {$_.Installed -eq $true})
            #Services = (Get-Service | Where {$_.Status -eq "Running"})
        }
        New-Object psobject -Property $property
    }

    foreach ($Server in $Servers)
    {
        Invoke-Command -ComputerName $Server -Credential $Cred -ScriptBlock $GatherData -OutVariable data | Out-Null

        $GUID = (Get-ADComputer $Server).ObjectGUID.Guid

        $data | Add-Member -NotePropertyName GUID -NotePropertyValue $GUID

        try
        {
            $sql = Invoke-SqliteQuery -Query "SELECT GUID FROM SERVERS" -DataSource $Database
            if ( $sql.GUID -eq $data.GUID )
            {
                Write-Output "Detected already existing server, updating with new info. $Server"

                $Query = "UPDATE $DBTable (GUID, Hostname, IPAddress, OS) VALUES (@GUID, @Hostname, @IPAddress, @OS)"
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                    GUID = $data.GUID
                    Hostname = $data.Hostname
                    IPAddress = $data.IPAddress
                    OS = $data.OS
                } -ErrorAction Stop
            }
            else 
            {
                $Query = "INSERT INTO $DBTable (GUID, Hostname, IPAddress, OS) VALUES (@GUID, @Hostname, @IPAddress, @OS)"
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                    GUID = $data.GUID
                    Hostname = $data.Hostname
                    IPAddress = $data.IPAddress
                    OS = $data.OS
                } -ErrorAction Stop
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

Get-ServerData -Database "C:\Users\SuperAdmin\SERVERS.SQLite" -DBTable "SERVERS" -Servers "MgmrSrv", "DC001"