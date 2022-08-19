
function Get-CIisAppPool
{
    <#
    .SYNOPSIS
    Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.

    .DESCRIPTION
    The `Get-CIisAppPool` function returns all IIS application pools that are installed on the current computer. To
    get a specific application pool, pass its name to the `Name` parameter. If the application pool doesn't exist,
    an error is written and nothing is returned.

    You can get the default settings for application pools by using the `Defaults` switch. If `Defaults` is true, then
    the `Name` parameter is ignored.

    If you make any changes to any of the objects returned by `Get-CIisAppPool`, call the `Save-CIisConfiguration`
    function to save those changes to IIS.

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

    .EXAMPLE
    Get-CIisAppPool -Defaults

    Demonstrates how to get IIS default application pool settings.
    #>
    [CmdletBinding(DefaultParameterSetName='AppPool')]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        # The name of the application pool to return. If not supplied, all application pools are returned.
        [String] $Name,

        # Instead of getting app pools or a specific app pool, return default application pool settings. If true, the
        # `Name` parameter is ignored.
        [switch] $Defaults
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = Get-CIisServerManager

    if( $Defaults )
    {
        return $mgr.ApplicationPoolDefaults
    }

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
        }

    if( -not $foundOne )
    {
        $msg = "IIS application pool ""$($Name)"" does not exist."
        Write-Error $msg -ErrorAction $ErrorActionPreference
    }
}

