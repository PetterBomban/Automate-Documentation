Function Get-ServerData 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "ServerSet1"
        )]
        [string[]]$Servers,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "ServerSet2"
        )]
        $VIServer,

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

    ## If we set the function to load servers from VMWare
    if($VIServer -ne "")
    {
        Import-Module Vmware.VimAutomation.Core
        Connect-VIServer $VIServer -Credential $Credentials -Force
        $LoadServers = Get-VM

        ## Strip the hostname of the domain name suffix and add the servers to the $Servers variable.
        $LoadServers | % {

            $ServerHostname = $_.Guest.HostName

            if (($ServerHostname -eq $null) -or ($ServerHostname -eq "") -or ($ServerHostname -eq $false))
            {
                return
            }
            else
            {
                $Srv = $ServerHostname.split(".")[0]
                $Servers += $Srv
            }
        }
        Write-Output "Detected:"
        Write-Output $Servers
        Disconnect-VIServer $VIServer -Confirm:$false -Force
    }

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
            IPAddress = (Get-NetIPConfiguration).IPv4Address.IPAddress | Out-String
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
        Invoke-Command -ComputerName $Server -Credential $Credentials -ScriptBlock $GatherData -OutVariable data | Out-Null

        try 
        {
            ## Adds the server GUID to the $data object
            $GUID = (Get-ADComputer $Server).ObjectGUID.Guid
            $data | Add-Member -NotePropertyName GUID -NotePropertyValue $GUID
        }
        catch 
        {
            ## TODO
            throw "COULD NOT ADD GUID TO data OBJECT. " + $_.Exception.Message
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
            throw "COULD NOT PERFORM SQL ACTIONS. " + $_.Exception.Message
        }

    }

    ## DEBUG
    Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM SERVERS"

    #Invoke-SqliteQuery -DataSource $Database -Query "DELETE FROM SERVERS"

}

## If you want to run this script automatically, you might need to store your
## credentials in a file. Uncomment the below to do this.
<#

    ## Where to store the credentials
    $File = "C:\Users\Veeam\Desktop\cred.txt"

    ## Create credentials
    ## Comment the line right below this one after first use
    (Get-Credential).Password | ConvertFrom-SecureString | Out-File $File -force

    ## Load password from file. Remember to change the "DOMAIN\USERNAME_HERE"-part.
    $password = Get-Content $File | ConvertTo-SecureString 
    $credential = New-Object System.Management.Automation.PsCredential("DOMAIN\USERNAME_HERE",$password)

    ## Use this if you want to run the script manually every time.
    #$credential = Get-Credential

#>

Get-ServerData -Database "C:\inetpub\wwwroot\Web\SERVERS.SQLite" -DBTable "SERVERS" -VIServer "192.168.0.9" -Credentials $credential