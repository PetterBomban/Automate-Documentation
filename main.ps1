## Function for gather data from servers
Function Get-ServerData 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $servers
    )

    begin
    {
        ## Temporary
        $cred = Get-Credential

        ## List to contain jobs
        $JobList = @()

        ## Scriptblock that runs for each server passed to this function
        $GatherData = {
            param($computer, $cred)

            Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {

                ## Need some sort of system to decide what to run on the server...
                $property = @{
                    Server = (hostname)
                    IPAddress = (Get-NetIPConfiguration).IPv4Address.IPAddress
                }
                New-Object psobject -Property $property
            }
        }
    }

    process
    {
        foreach ($server in $servers)
        {
            ## Generate a unique job name, start it and add the name to the list
            $id = "$server - $([System.Guid]::NewGuid())"
            Start-Job -Name $id -ScriptBlock $GatherData -ArgumentList $server, $cred | Out-Null
            $JobList += $id
        }

        ## Wait for jobs to finish
        while (Get-Job -State Running)
        {
            Start-Sleep 5
        }

        ## Receive jobs
        foreach ($Job in $JobList)
        {
            ## Testing
            Receive-Job -Name $Job -OutVariable data | Out-Null

            Write-Output $data
        }
    }

    end
    {
        ## Clear the queue
        Remove-Job *
    }

}

"Neo", "Mouse" | Get-ServerData