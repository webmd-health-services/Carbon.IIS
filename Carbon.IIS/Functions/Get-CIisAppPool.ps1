
function Get-CIisAppPool
{
    <#
    .SYNOPSIS
    Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.

    .DESCRIPTION
    The `Get-CIisAppPool` function returns all IIS application pools that are installed on the current computer. To
    get a specific application pool, pass its name to the `Name` parameter. If the application pool doesn't exist,
    an error is written and nothing is returned.

    Carbon adds a `CommitChanges` method on each object returned that you can use to save configuration changes made
    to the returned objects.

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx

    .OUTPUTS
    Microsoft.Web.Administration.ApplicationPool.

    .EXAMPLE
    Get-CIisAppPool

    Demonstrates how to get *all* application pools.

    .EXAMPLE
    Get-CIisAppPool -Name 'Batcave'

    Gets the `Batcave` application pool.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        # The name of the application pool to return. If not supplied, all application pools are returned.
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-CIisServerManager
    $foundOne = $false
    $mgr.ApplicationPools |
        Where-Object {
            if( -not $PSBoundParameters.ContainsKey('Name') )
            {
                $foundOne = $true
                return $true
            }

            $isTheOne = $_.Name -eq $Name
            if( $isTheOne )
            {
                $foundOne = $true
            }
            return $isTheOne
        } |
        Add-IisServerManagerMember -ServerManager $mgr -PassThru

    if( -not $foundOne )
    {
        $msg = "IIS application pool ""$($Name)"" does not exist."
        Write-Error $msg -ErrorAction $ErrorActionPreference
    }
}

