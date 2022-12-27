
function Get-CIisAppPool
{
    <#
    .SYNOPSIS
    Gets IIS application pools.

    .DESCRIPTION
    The `Get-CIisAppPool` function returns all IIS application pools that are installed on the current computer. To
    get a specific application pool, pass its name to the `Name` parameter. If the application pool doesn't exist,
    an error is written and nothing is returned.

    You can get the application pool defaults settings by using the `Defaults` switch. If `Defaults` is true, then
    the `Name` parameter is ignored.

    If you make any changes to any of the objects returned by `Get-CIisAppPool`, call the `Save-CIisConfiguration`
    function to save those changes to IIS.

    This function disposes the current server manager object that Carbon.IIS uses internally. Make sure you have no
    pending, unsaved changes when calling `Get-CIisAppPool`.

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

    Demonstrates how to get IIS application pool defaults settings.
    #>
    [CmdletBinding(DefaultParameterSetName='AllAppPools')]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        # The name of the application pool to return. If not supplied, all application pools are returned. Wildcards
        # supported.
        [Parameter(Mandatory, ParameterSetName='AppPoolByWildcard', Position=0)]
        [String] $Name,

        # Instead of getting app pools or a specific app pool, return  application pool defaults settings. If true, the
        # `Name` parameter is ignored.
        [Parameter(Mandatory, ParameterSetName='Defaults')]
        [switch] $Defaults
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $WhatIfPreference = $false

    $mgr = Get-CIisServerManager

    if( $Defaults )
    {
        return $mgr.ApplicationPoolDefaults
    }

    $appPools = @()
    $mgr.ApplicationPools |
        Where-Object {
            if ($Name)
            {
                return $_.Name -like $Name
            }

            return $true
        } |
        Tee-Object -Variable 'appPools' |
        Write-Output

    if (($Name -and -not [wildcardpattern]::ContainsWildcardCharacters($Name) -and -not $appPools))
    {
        $msg = "IIS application pool ""$($Name)"" does not exist."
        Write-Error $msg -ErrorAction $ErrorActionPreference
    }
}

